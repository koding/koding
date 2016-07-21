package parser

import (
	"bufio"
	"encoding/binary"
	"errors"
	"fmt"
	"io"
)

type CpuProfParser struct {
	R      *bufio.Reader
	Order  binary.ByteOrder
	Size   int
	Period uint64 // profiling period in µs.
	read   func() (uint64, error)
	trace  []uint64
}

var errBadProfileHeader = errors.New("corrupted CPU profile header")

func NewCpuProfParser(r io.Reader) (*CpuProfParser, error) {
	b := bufio.NewReader(r)
	chunk, err := b.Peek(16)
	if err != nil {
		return nil, err
	}
	// A CPU profile starts with integers 0, and 3, with program's
	// word size and endianness.
	size := 32
	first := binary.LittleEndian.Uint64(chunk[:8])
	if first == 0 {
		size = 64
	}
	var order binary.ByteOrder
	if size == 32 {
		n := binary.LittleEndian.Uint32(chunk[4:8])
		if n == 3 {
			order = binary.LittleEndian
		} else {
			order = binary.BigEndian
		}
	} else {
		n := binary.LittleEndian.Uint64(chunk[8:16])
		if n == 3 {
			order = binary.LittleEndian
		} else {
			order = binary.BigEndian
		}
	}
	p := &CpuProfParser{R: b, Order: order, Size: size}
	if size == 32 {
		p.read = func() (n uint64, err error) {
			s, err := b.Peek(4)
			if err == nil {
				n = uint64(order.Uint32(s[:]))
			}
			b.Read(s)
			return
		}
	} else {
		p.read = func() (n uint64, err error) {
			s, err := b.Peek(8)
			if err == nil {
				n = order.Uint64(s)
			}
			b.Read(s)
			return
		}
	}

	headerCount, _ := p.read()
	headerWords, _ := p.read()
	version, _ := p.read()
	period, _ := p.read()
	padding, err := p.read()
	if err != nil {
		return nil, err
	}

	if headerCount != 0 || headerWords != 3 || version != 0 || padding != 0 {
		return nil, errBadProfileHeader
	}
	p.Period = period
	return p, nil
}

// ReadTrace returns a stack trace from the CPU profile. The returned
// slice becomed invalid after the next call to ReadTrace.
func (p *CpuProfParser) ReadTrace() ([]uint64, uint64, error) {
	t := p.trace[:0]
	count, _ := p.read()    // multiplicity
	length, err := p.read() // length of stack trace
	if err != nil {
		return nil, 0, err
	}
	if length > 1<<20 {
		return nil, 0, fmt.Errorf("unusually large stack large of depth %d", length)
	}
	for i := 0; i < int(length); i++ {
		pc, err := p.read()
		if err != nil {
			return nil, 0, err
		}
		t = append(t, pc)
	}
	p.trace = t
	return t, count, nil
}
