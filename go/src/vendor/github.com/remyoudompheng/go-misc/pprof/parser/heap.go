package parser

import (
	"bufio"
	"bytes"
	"errors"
	"fmt"
	"io"
	"regexp"
	"strconv"
	"strings"
)

type HeapProfParser struct {
	R      *bufio.Reader
	lineno int
	Freq   int64
	// Total.
	LiveObj    int64
	LiveBytes  int64
	AllocObj   int64
	AllocBytes int64
}

var (
	heapRe           = regexp.MustCompile(`(\d+): (\d+) \[(\d+): (\d+)\] @`)
	errInvalidHeader = errors.New("malformed heap profile header")
)

type errBadLineHeader int

func (e errBadLineHeader) Error() string {
	return fmt.Sprintf("line %d: header in wrong format", int(e))
}

func isDigit(r rune) bool { return '0' <= r && r <= '9' }

// parseLine parses "xx: yyyy [zz: tttt] @" as the
// 4 numbers xx, yyyy, zz, tttt.
func parseLine(s []byte) (a, b, c, d int64, err error) {
	// s is in correct format if splitting at digits
	// yields ": ", " [", ": ", "] @".
	seps := bytes.FieldsFunc(s, isDigit)
	switch {
	case !bytes.Equal(seps[0], []byte(": ")),
		!bytes.Equal(seps[1], []byte(" [")),
		!bytes.Equal(seps[2], []byte(": ")),
		!bytes.Equal(seps[3], []byte("] @")):
		err = errBadLineHeader(0)
		return
	}
	for i, x := range s {
		if x == ':' {
			s = s[i+2:]
			break
		}
		a = a*10 + int64(x-'0')
	}
	for i, x := range s {
		if x == ' ' {
			s = s[i+2:]
			break
		}
		b = b*10 + int64(x-'0')
	}
	for i, x := range s {
		if x == ':' {
			s = s[i+2:]
			break
		}
		c = c*10 + int64(x-'0')
	}
	for i, x := range s {
		if x == ']' {
			s = s[i+2:]
			break
		}
		d = d*10 + int64(x-'0')
	}
	return
}

func NewHeapProfParser(r io.Reader) (*HeapProfParser, error) {
	const prefix = "heap profile: "
	b := bufio.NewReader(r)
	// Read totals.
	head, err := b.ReadSlice('@')
	if !bytes.HasPrefix(head, []byte(prefix)) {
		return nil, errInvalidHeader
	}
	head = head[len(prefix):]
	uo, ub, ao, ab, err := parseLine(head)
	if err != nil {
		println(string(head))
		return nil, err
	}
	p := &HeapProfParser{
		R:       b,
		LiveObj: uo, LiveBytes: ub,
		AllocObj: ao, AllocBytes: ab}
	p.lineno++
	// Read frequency.
	line, err := b.ReadSlice('\n')
	line = bytes.TrimSpace(line) // "heap/xxxx"
	if !bytes.HasPrefix(line, []byte("heap/")) {
		return nil, errInvalidHeader
	}
	line = line[5:]
	for _, x := range line {
		if x < '0' || x > '9' {
			return nil, errInvalidHeader
		}
		p.Freq = p.Freq*10 + int64(x-'0')
	}
	return p, nil
}

type HeapRecord struct {
	Trace []uint64 // A call trace (callee first).

	LiveObj    int64
	LiveBytes  int64
	AllocObj   int64
	AllocBytes int64
}

func (p *HeapProfParser) ReadRecord() (h HeapRecord, err error) {
	p.lineno++
	head, err := p.R.ReadSlice('@') // "xx: yy [zz: tt] @"
	if err != nil {
		return
	}
	lo, lb, ao, ab, err := parseLine(head)
	if err != nil {
		return h, errBadLineHeader(p.lineno)
	}
	h.LiveObj, h.LiveBytes = lo, lb
	h.AllocObj, h.AllocBytes = ao, ab
	// The call trace.
	line, err := p.R.ReadSlice('\n') // " 0x1234 0x2345 0x3456\n"
	line = bytes.TrimSpace(line)
	words := strings.Split(string(line), " ")
	trace := make([]uint64, len(words))
	for i, s := range words {
		// reverse stack trace.
		trace[i], err = strconv.ParseUint(s, 0, 64) // parse 0x1234
		if err != nil {
			return
		}
	}
	h.Trace = trace
	return h, nil
}

// AdjustRecord modifies a heap profile record according to the
// MemProfileRate to give an estimate of the real memory usage.
// It also cleans up irrelevant parts of the stack trace like
// calls to runtime.new.
func (p *HeapProfParser) AdjustRecord(rec *HeapRecord, symtable func(uint64) string) {
	// We only support heap profiling version 1. In this method,
	// after each sample, a uniform integer n is chosen in [0, R)
	// and the next sample is triggered after n allocated bytes.
	//
	// Large allocations of at least R bytes will be always sampled.
	//
	// The probability that a value of AllocBytes be a sampling
	// threshold is about 2/R, so a small allocation of k bytes
	// has roughly a 2k/R probability of being sampled. So we want
	// to multiply by R/2k.
	//
	// For medium-sized allocations (k >= R/2), a block may be skipped
	// with probability 1 - k/R, so we may want to multiply by R/k. But
	// the evalutation is difficult, and the Perl pprof script does
	// not do that.
	objsize := int64(0)
	if rec.LiveObj != 0 {
		objsize = rec.LiveBytes / rec.LiveObj
	}
	if objsize == 0 && rec.AllocObj != 0 {
		objsize = rec.AllocBytes / rec.AllocObj
	}
	ratio := 1.0
	if objsize <= p.Freq/2 {
		ratio = float64(p.Freq/2) / float64(objsize)
	}
	rec.AllocBytes = int64(ratio * float64(rec.AllocBytes))
	rec.AllocObj = int64(ratio * float64(rec.AllocObj))
	rec.LiveBytes = int64(ratio * float64(rec.LiveBytes))
	rec.LiveObj = int64(ratio * float64(rec.LiveObj))

	for i, addr := range rec.Trace {
		sym := symtable(addr)
		if !allocfuncs[sym] {
			rec.Trace = rec.Trace[i:]
			break
		}
	}
}

// allocfuncs lists functions from the Go runtime related
// to memory allocation and that needn't be taken into
// account when reading a heap profile.
// The list is taken from misc/pprof.
var allocfuncs = map[string]bool{
	"catstring":                 true,
	"copyin":                    true,
	"gostring":                  true,
	"gostringsize":              true,
	"growslice1":                true,
	"appendslice1":              true,
	"hash_init":                 true,
	"hash_subtable_new":         true,
	"hash_conv":                 true,
	"hash_grow":                 true,
	"hash_insert_internal":      true,
	"hash_insert":               true,
	"mapassign":                 true,
	"runtime.mapassign":         true,
	"runtime.appendslice":       true,
	"runtime.mapassign1":        true,
	"makechan":                  true,
	"makemap":                   true,
	"mal":                       true,
	"runtime.new":               true,
	"makeslice1":                true,
	"runtime.malloc":            true,
	"unsafe.New":                true,
	"runtime.mallocgc":          true,
	"runtime.catstring":         true,
	"runtime.growslice":         true,
	"runtime.ifaceT2E":          true,
	"runtime.ifaceT2I":          true,
	"runtime.makechan":          true,
	"runtime.makechan_c":        true,
	"runtime.makemap":           true,
	"runtime.makemap_c":         true,
	"runtime.makeslice":         true,
	"runtime.mal":               true,
	"runtime.settype":           true,
	"runtime.settype_flush":     true,
	"runtime.slicebytetostring": true,
	"runtime.sliceinttostring":  true,
	"runtime.stringtoslicebyte": true,
	"runtime.stringtosliceint":  true,
}
