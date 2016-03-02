package go8

import (
	"bufio"
	"encoding/binary"
	"fmt"
	"io"
	"path/filepath"

	"github.com/remyoudompheng/go-misc/debug/goobj"
)

type Reader struct {
	Version goobj.Version

	rd       *bufio.Reader
	syms     [256]string
	pc       int
	fset     goobj.FileSet // Record per-file line information.
	fnamebuf []string
	fname    string
	fstart   int
	imports  map[int]string
}

func NewReader(r io.Reader) *Reader {
	return &Reader{
		rd:      bufio.NewReader(r),
		imports: make(map[int]string),
	}
}

func (r *Reader) Files() (*goobj.FileSet, map[int]string) {
	return &r.fset, r.imports
}

func read2(r *bufio.Reader) (uint16, error) {
	var buf [2]byte
	_, err := io.ReadFull(r, buf[:])
	return binary.LittleEndian.Uint16(buf[:]), err
}

func read4(r *bufio.Reader) (uint32, error) {
	var buf [4]byte
	_, err := io.ReadFull(r, buf[:])
	return binary.LittleEndian.Uint32(buf[:]), err
}

func read8(r *bufio.Reader) (uint64, error) {
	var buf [8]byte
	_, err := io.ReadFull(r, buf[:])
	return binary.LittleEndian.Uint64(buf[:]), err
}

type errOpOutOfRange int

func (e errOpOutOfRange) Error() string { return fmt.Sprintf("opcode %d out of range", int(e)) }

type errIO struct {
	When string
	Err  error
}

func (e *errIO) Error() string {
	return fmt.Sprintf("error while reading %s: %s", e.When, e.Err)
}

func (r *Reader) ReadProg() (p Prog, err error) {
	op, err := read2(r.rd)
	if err != nil {
		return
	}
	if op <= AXXX || op >= ALAST {
		return p, errOpOutOfRange(op)
	}
	if r.Version == goobj.GO1 {
		if int(op) >= len(go1ops) {
			return p, errOpOutOfRange(op)
		}
		op = go1ops[op]
	}
	switch op {
	case ANAME, ASIGNAME:
		sig := uint32(0)
		if op == ASIGNAME {
			sig, err = read4(r.rd)
			if err != nil {
				return p, &errIO{When: "SIGNAME op", Err: err}
			}
		}
		typ, err1 := r.rd.ReadByte()
		sym, err2 := r.rd.ReadByte()
		bname, err := r.rd.ReadString(0)
		switch {
		case err1 != nil:
			return p, &errIO{When: "symbol type", Err: err1}
		case err2 != nil:
			return p, &errIO{When: "symbol id", Err: err2}
		case err != nil:
			return p, &errIO{When: "symbol value", Err: err}
		}
		name := string(bname[:len(bname)-1])
		// Register symbol.
		r.syms[sym] = name
		switch typ {
		case D_EXTERN, D_STATIC:
			// cross reference
		case D_FILE:
			// filename
			r.fnamebuf = append(r.fnamebuf, name[1:])
		}
		_, _ = sig, typ
		return Prog{Op: int(op), Name: name}, nil
	}

	// Common instruction data.
	line, err := read4(r.rd)
	from, err1 := r.ReadAddr()
	to, err2 := r.ReadAddr()
	switch {
	case err != nil:
		return p, &errIO{When: "line number", Err: err}
	case err1 != nil:
		return p, &errIO{When: "from address", Err: err}
	case err2 != nil:
		return p, &errIO{When: "to address", Err: err}
	}
	p = Prog{pc: r.pc,
		Op: int(op), Line: int(line),
		From: from, To: to}
	switch op {
	case AHISTORY:
		// register line information
		if p.To.Offset == -1 {
			// imported library.
			r.imports[int(line)] = filepath.Join(r.fnamebuf...)
			r.fnamebuf = nil
			break
		}
		// HISTORY (line A)
		// HISTORY (line B)
		// means that fname spans lines[A:B]
		if r.fnamebuf != nil {
			fname := filepath.Join(r.fnamebuf...)
			r.fnamebuf = nil
			r.fset.Enter(fname, int(line))
		} else {
			r.fset.Exit(int(line))
		}
	default:
		r.pc++
		if p.Line != 0 {
			p.Pos = r.fset.Position(int(line))
		}
	}

	return p, nil
}

func (r *Reader) ReadAddr() (Addr, error) {
	a := Addr{Type: D_NONE, Index: D_NONE, Scale: 0}
	tag, err := r.rd.ReadByte()
	//s, err := r.rd.Peek(16)
	//fmt.Printf("%v\n", s)
	if tag&T_INDEX != 0 {
		var index, scale byte
		index, err = r.rd.ReadByte()
		scale, err = r.rd.ReadByte()
		a.Index, a.Scale = int(index), int(scale)
	}
	if tag&T_OFFSET != 0 {
		o32, e := read4(r.rd)
		a.Offset, err = int32(o32), e
	}
	if tag&T_OFFSET2 != 0 {
		o32, e := read4(r.rd)
		a.Offset2, err = int32(o32), e
	}
	if tag&T_SYM != 0 {
		a.Sym, err = r.ReadSym()
	}
	if err != nil {
		return a, err
	}
	// Constants.
	switch {
	case tag&T_FCONST != 0:
		a.Type = D_FCONST
		a.FloatIEEE, err = read8(r.rd)
	case tag&T_SCONST != 0:
		a.Type = D_SCONST
		_, err = io.ReadFull(r.rd, a.StringVal[:])
	}
	// Other
	if tag&T_TYPE != 0 {
		var typ byte
		typ, err = r.rd.ReadByte()
		a.Type = int(typ)
	}
	if tag&T_GOTYPE != 0 {
		a.GoType, err = r.ReadSym()
	}
	// TODO: finish this.
	return a, err
}

func (r *Reader) ReadSym() (string, error) {
	b, err := r.rd.ReadByte()
	return r.syms[b], err
}
