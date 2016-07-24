package go6

import (
	"bytes"
	"fmt"
	"math"

	"github.com/remyoudompheng/go-misc/debug/goobj"
)

type Prog struct {
	pc   int
	Op   int
	Name string
	Line int
	Pos  goobj.Position // interpreted line number

	From Addr
	To   Addr
}

func (p Prog) PC() int                  { return p.pc }
func (p Prog) Opname() string           { return opnames[p.Op] }
func (p Prog) Position() goobj.Position { return p.Pos }

func (p Prog) String() string {
	switch p.Op {
	case ANAME:
		return fmt.Sprintf("%-8s %q", opnames[p.Op], p.Name)
	case AHISTORY:
		return fmt.Sprintf("HISTORY %s", p.To)
	case AGLOBL, ADATA:
		return fmt.Sprintf("%-8s %s,$%d,%s", opnames[p.Op],
			p.From.Sym, p.From.Scale, p.To)
	case ATEXT:
		return fmt.Sprintf("%-8s %s,$%d,0x%x", opnames[p.Op],
			p.From.Sym, p.From.Scale, p.To.Offset)
	}
	buf := new(bytes.Buffer)
	fmt.Fprintf(buf, "%-8s %s", opnames[p.Op], p.From)
	if p.To.Type != D_NONE {
		fmt.Fprintf(buf, ",%s", p.To)
	}
	return buf.String()
}

type Addr struct {
	Type   int
	Sym    string
	Index  int
	Scale  int
	Offset int64

	GoType string

	FloatIEEE uint64
	StringVal [8]byte
}

func (a Addr) String() string {
	idxsuf := ""
	if a.Type != D_ADDR && a.Index != D_NONE {
		idxsuf = fmt.Sprintf("(%s*%d)", regnames[a.Index], a.Scale)
	}
	// Registers.
	if a.Type >= D_INDIR {
		if a.Offset != 0 {
			return fmt.Sprintf("%d(%s)%s", a.Offset, regnames[a.Type-D_INDIR], idxsuf)
		} else {
			return "(" + regnames[a.Type-D_INDIR] + ")" + idxsuf
		}
	}
	if D_AL <= a.Type && a.Type <= D_GS {
		if a.Offset != 0 {
			return fmt.Sprintf("%d,%s%s", a.Offset, regnames[a.Type], idxsuf)
		} else {
			return regnames[a.Type] + idxsuf
		}
	}
	// Addresses.
	switch a.Type {
	case D_NONE:
		return ""
	case D_EXTERN:
		return fmt.Sprintf("%s+%d(SB)%s", a.Sym, a.Offset, idxsuf)
	case D_STATIC:
		// TODO: symbol version.
		return fmt.Sprintf("%s<?>+%d(SB)%s", a.Sym, a.Offset, idxsuf)
	case D_AUTO:
		return fmt.Sprintf("%s+%d(SP)%s", a.Sym, a.Offset, idxsuf)
	case D_PARAM:
		return fmt.Sprintf("%s+%d(FP)%s", a.Sym, a.Offset, idxsuf)
	case D_CONST:
		// integer immediate
		return fmt.Sprintf("$%d%s", a.Offset, idxsuf)
	case D_FCONST:
		f := math.Float64frombits(a.FloatIEEE)
		return fmt.Sprintf("$%v", f)
	case D_SCONST:
		// chunk of string literal
		s := a.StringVal[:]
		s = bytes.TrimRight(s, "\x00")
		return fmt.Sprintf("$%q%s", s, idxsuf)
	case D_ADDR:
		ind := a
		ind.Type = a.Index
		ind.Index = D_NONE
		return fmt.Sprintf("$%s", ind)
	case D_BRANCH:
		return fmt.Sprintf("%d", a.Offset)
	}
	panic("ignored type " + regnames[a.Type])
}
