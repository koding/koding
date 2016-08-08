package go5

import (
	"bytes"
	"fmt"
	"math"

	"github.com/remyoudompheng/go-misc/debug/goobj"
)

const NREG = 16

type Prog struct {
	pc     int
	Op     int
	Suffix Suffix
	Name   string
	Line   int
	Pos    goobj.Position // interpreted line number

	From Addr
	Reg  int
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
	}
	buf := new(bytes.Buffer)
	n1, _ := buf.WriteString(opnames[p.Op])
	n2, _ := buf.WriteString(p.Suffix.String())
	if n1+n2 <= 8 {
		zero := [8]byte{' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '}
		buf.Write(zero[:8-n1-n2])
	}
	switch p.Op {
	case AWORD:
	case ADWORD:
	case ADATA:
		fmt.Fprintf(buf, " %s/%d,%s", p.From, p.Reg, p.To)
	case AGLOBL:
		// Make it clearer than 5l: the constants are flags and size.
		fmt.Fprintf(buf, " %s,$%d,$%d", p.From, p.Reg, p.To.Offset)
	case ASWPW, ASWPBU:
	default:
		switch {
		case p.Reg == NREG:
			fmt.Fprintf(buf, " %s,%s", p.From, p.To)
		case p.From.Type == D_FREG:
			fmt.Fprintf(buf, " %s,F%d,%s", p.From, p.Reg, p.To)
		default:
			fmt.Fprintf(buf, " %s,R%d,%s", p.From, p.Reg, p.To)
		}
	}
	return buf.String()
}

var suffixes = []string{
	C_SCOND_EQ:   ".EQ",
	C_SCOND_NE:   ".NE",
	C_SCOND_HS:   ".HS",
	C_SCOND_LO:   ".LO",
	C_SCOND_MI:   ".MI",
	C_SCOND_PL:   ".PL",
	C_SCOND_VS:   ".VS",
	C_SCOND_VC:   ".VC",
	C_SCOND_HI:   ".HI",
	C_SCOND_LS:   ".LS",
	C_SCOND_GE:   ".GE",
	C_SCOND_LT:   ".LT",
	C_SCOND_GT:   ".GT",
	C_SCOND_LE:   ".LE",
	C_SCOND_NONE: "",
	C_SCOND_NV:   ".NV",
}

type Suffix int

func (s Suffix) String() string {
	suf := suffixes[s&C_SCOND]
	if s&C_SBIT != 0 {
		suf += ".S"
	}
	if s&C_PBIT != 0 {
		suf += ".P"
	}
	if s&C_WBIT != 0 {
		suf += ".W"
	}
	if s&C_UBIT != 0 {
		suf += ".U"
	}
	return suf
}

type Addr struct {
	Type    int
	Reg     int
	Sym     string
	Class   int // D_EXTERN...
	Offset  int32
	Offset2 int32

	GoType string

	FloatIEEE uint64
	StringVal [8]byte
}

var shifts = []string{"<<", ">>", "->", "@>"}

func (a Addr) String() string {
	// Constants.
	switch a.Type {
	case D_CONST2:
		return fmt.Sprintf("$%d-%d", a.Offset, a.Offset2)
	case D_OCONST:
		return fmt.Sprintf("$*$%d", a.Offset)
	case D_SCONST:
		s := a.StringVal[:]
		s = bytes.TrimRight(s, "\x00")
		return fmt.Sprintf("$%q", s)
	case D_FCONST:
		return fmt.Sprintf("$%v", math.Float64frombits(a.FloatIEEE))
	}
	// Addresses.
	buf := new(bytes.Buffer)
	switch a.Class {
	case D_NONE:
		// Registers.
		switch a.Type {
		case D_NONE:
		case D_CONST:
			fmt.Fprintf(buf, "$%d", a.Offset)
		case D_OREG:
			fmt.Fprintf(buf, "%d", a.Offset)
		case D_SHIFT:
			v := a.Offset
			reg := v & 0xf            // 4 bits
			hasreg2 := v&0x10 != 0    // 1 bit
			op := (v & (3 << 5)) >> 5 // 2 bits
			arg := (v >> 7) & 0x1f    // 5 bits
			if hasreg2 {
				// R1 >> R2
				fmt.Fprintf(buf, "R%d%sR%d", reg, shifts[op], arg/2)
			} else {
				// R1 >> 7
				fmt.Fprintf(buf, "R%d%s%d", reg, shifts[op], arg)
			}
		case D_REG:
			return fmt.Sprintf("R%d", a.Reg)
		case D_REGREG:
			fmt.Fprintf(buf, "(R%d,R%d)", a.Reg, a.Offset)
		case D_REGREG2:
			fmt.Fprintf(buf, "R%d,R%d", a.Reg, a.Offset)
		case D_FREG:
			fmt.Fprintf(buf, "F%d", a.Reg)
		case D_BRANCH:
			return fmt.Sprintf("%s+%d", a.Sym, a.Offset)
		default:
			err := fmt.Errorf("impossible address class %s/%s",
				regnames[a.Type], regnames[a.Class])
			panic(err)
		}
		if a.Reg != NREG {
			switch a.Type {
			case D_NONE:
				err := fmt.Errorf("no reg argument for type %s", regnames[a.Type])
				panic(err)
			case D_REG, D_FREG, D_REGREG, D_REGREG2:
				// ok.
			default:
				fmt.Fprintf(buf, "(R%d)", a.Reg)
			}
		}
		return buf.String()
	case D_EXTERN:
		if a.Type == D_CONST {
			buf.WriteByte('$')
		}
		fmt.Fprintf(buf, "%s+%d(SB)", a.Sym, a.Offset)
	case D_STATIC:
		if a.Type == D_CONST {
			buf.WriteByte('$')
		}
		fmt.Fprintf(buf, "%s<>+%d(SB)", a.Sym, a.Offset)
	case D_AUTO:
		if a.Type == D_CONST {
			buf.WriteByte('$')
		}
		fmt.Fprintf(buf, "%s+%d(SP)", a.Sym, a.Offset)
	case D_PARAM:
		if a.Type == D_CONST {
			buf.WriteByte('$')
		}
		fmt.Fprintf(buf, "%s+%d(FP)", a.Sym, a.Offset)
	default:
		panic("ignored type " + regnames[a.Type] + " class " + regnames[a.Class])
	}
	return buf.String()
}
