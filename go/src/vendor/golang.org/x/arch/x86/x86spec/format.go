// Copyright 2016 The Go Authors.  All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Derive format specifications.

package main

import (
	"sort"
	"strings"
)

func format(insts []*instruction) {
	// Determine opcodes that come in multiple sizes
	// and could need disambiguating suffixes.
	// Mark those with multisize=true.
	sort.Sort(bySyntax(insts))
	needSize := make(map[string]bool)
	for i := 0; i < 2; i++ {
		seen := make(map[string]bool)
		for _, inst := range insts {
			if hasTag(inst, "pseudo") || hasTag(inst, "pseudo64") {
				continue
			}
			switch i {
			case 0:
				if inst.valid32 != "V" {
					continue
				}
			case 1:
				if inst.valid64 != "V" {
					continue
				}
			}
			unsized := stripSize.Replace(inst.syntax)
			if seen[unsized] {
				op, _ := splitSyntax(inst.syntax)
				needSize[op] = true
			}
			seen[unsized] = true
		}
	}

	for _, inst := range insts {
		op, _ := splitSyntax(inst.syntax)
		if needSize[op] || forceNeedSize[op] {
			inst.multisize = "Y"
		}
	}

	// Assign data sizes.
	for _, inst := range insts {
		if inst.multisize != "Y" {
			continue
		}
		op, args := splitSyntax(inst.syntax)
	Args:
		for i := startArg[op]; i < len(args); i++ {
			switch args[i] {
			case "AL", "r8", "r8op", "r/m8":
				inst.datasize = 8
				break Args
			case "AX", "r16", "r16op", "r/m16":
				inst.datasize = 16
				break Args
			case "EAX", "r32", "r32op", "r/m32", "rmr32", "m32fp", "m32int":
				inst.datasize = 32
				break Args
			case "RAX", "r64", "r64op", "r/m64", "rmr64", "m64fp", "m64int":
				inst.datasize = 64
				break Args
			case "m80fp":
				inst.datasize = 80
				break Args
			case "xmm2/m128":
				inst.datasize = 128
				break Args
			case "ymm2/m256":
				inst.datasize = 256
				break Args
			}
		}
	}

	// Determine GNU syntax for instructions.
	// With a few exceptions, it's the Intel opcode plus an optional suffix,
	// followed by the reversed argument list.
	for _, inst := range insts {
		op, args := splitSyntax(inst.syntax)
		intelOp := op
		op = strings.ToLower(op)
		if custom, ok := gnuOpcode[inst.syntax]; ok {
			op = custom
		} else {
			if inst.multisize == "Y" {
				suffix := defaultSizeSuffix[inst.datasize]
				if custom, ok := gnuSizeSuffix[op]; ok {
					suffix = custom[inst.datasize]
				}
				op += suffix
			}
		}
		switch intelOp {
		case "BOUND", "ENTER":
			// no reversal
		default:
			for i, j := 0, len(args)-1; i < j; i, j = i+1, j-1 {
				args[i], args[j] = args[j], args[i]
			}
		}
		inst.gnuSyntax = joinSyntax(op, args)
	}

	// Determine Go syntax for instructions.
	// Similar to GNU syntax (really they are both similar to "AT&T" syntax)
	// but upper case and not reversing the argument list for a few instructions,
	// like comparisons.
	for _, inst := range insts {
		intelOp, args := splitSyntax(inst.syntax)

		// start with GNU op, because it has suffixes already
		op, _ := splitSyntax(inst.gnuSyntax)
		op = strings.ToUpper(op)
		if custom, ok := goOpcode[inst.syntax]; ok {
			op = custom
		} else if custom, ok := goOpcode[intelOp]; ok {
			op = custom
		} else if custom, ok := goOpcode[op]; ok {
			op = custom
		} else if suffix, ok := goSizeSuffix[op]; ok {
			op += suffix[inst.datasize]
		}

		switch intelOp {
		case "CMP":
			// no reversal
		case "CMPPD", "CMPPS", "CMPSD", "CMPSS":
			// rotate destination to end but don't swap comparison operands
			if len(args) == 3 {
				args[0], args[1], args[2] = args[2], args[0], args[1]
				break
			}
			fallthrough
		default:
			for i, j := 0, len(args)-1; i < j; i, j = i+1, j-1 {
				args[i], args[j] = args[j], args[i]
			}
		}
		inst.goSyntax = joinSyntax(op, args)
	}
}

var forceNeedSize = map[string]bool{
	"SAL": true,
}

var stripSize = strings.NewReplacer(
	"rel8", "rel8", // leave these alone
	"rel16", "rel16",
	"rel32", "rel32",
	"8", "#",
	"16", "#",
	"32", "#",
	"64", "#",
	"xmm2/m128", "xy/#",
	"ymm2/m256", "xy/#",
	"EAX", "AX",
)

var defaultSizeSuffix = map[int]string{
	8:  "b",
	16: "w",
	32: "l",
	64: "q",
}

var gnuSizeSuffix = map[string]map[int]string{
	"cvtsd2si":   {64: "q"},
	"cvtss2si":   {64: "q"},
	"cvttsd2si":  {64: "q"},
	"cvttss2si":  {64: "q"},
	"vcvtsd2si":  {64: "q"},
	"vcvtss2si":  {64: "q"},
	"vcvttsd2si": {64: "q"},
	"vcvttss2si": {64: "q"},

	"vcvtpd2dq":  {128: "x", 256: "y"},
	"vcvtpd2ps":  {128: "x", 256: "y"},
	"vcvttpd2dq": {128: "x", 256: "y"},
	"vcvttpd2ps": {128: "x", 256: "y"},

	"fadd":  {32: "s", 64: "l"},
	"fcom":  {32: "s", 64: "l"},
	"fcomp": {32: "s", 64: "l"},
	"fdiv":  {32: "s", 64: "l"},
	"fdivr": {32: "s", 64: "l"},
	"fmul":  {32: "s", 64: "l"},
	"fsub":  {32: "s", 64: "l"},
	"fsubr": {32: "s", 64: "l"},

	"fld":  {32: "s", 64: "l", 80: "t"},
	"fst":  {32: "s", 64: "l", 80: "t"},
	"fstp": {32: "s", 64: "l", 80: "t"},

	"fiadd":  {32: "l"},
	"ficom":  {32: "l"},
	"ficomp": {32: "l"},
	"fidiv":  {32: "l"},
	"fidivr": {32: "l"},
	"fimul":  {32: "l"},
	"fist":   {32: "l"},
	"fisub":  {32: "l"},
	"fisubr": {32: "l"},

	"fild":   {32: "l", 64: "ll"},
	"fistp":  {32: "l", 64: "ll"},
	"fisttp": {32: "l", 64: "ll"},

	"fldenv": {64: "l"},

	// These can be distinguished by register name (%rcx vs %ecx)
	// and objdump refuses to put suffixes on them.
	"bswap":    {},
	"rdfsbase": {},
	"rdgsbase": {},
	"rdrand":   {},
	"rdseed":   {},
	"wrfsbase": {},
	"wrgsbase": {},
}

var gnuOpcode = map[string]string{
	// Simple name changes.
	"CBW":    "cbtw",
	"CDQ":    "cltd",
	"CDQE":   "cltq",
	"CMPSD":  "cmpsl",
	"CQO":    "cqto",
	"CWD":    "cwtd",
	"CWDE":   "cwtl",
	"INSD":   "insl",
	"LODSD":  "lodsl",
	"MOVSD":  "movsl",
	"OUTSD":  "outsl",
	"PUSHAD": "pushal",
	"PUSHFD": "pushfl",
	"POPAD":  "popal",
	"POPFD":  "popfl",
	"STOSD":  "stosl",
	"XLATB":  "xlat",
	"POPA":   "popaw",
	"POPF":   "popfw",
	"PUSHA":  "pushaw",
	"PUSHF":  "pushfw",
	"SCASD":  "scasl",

	// Two-operand FDIV and FDIVR are inverted, but only for the ST(i), ST(0) form.
	// I think this is a bug in the GNU tools but perhaps one that must be historically maintained.
	"FDIV ST(i), ST(0)":   "fdivr",
	"FDIVR ST(i), ST(0)":  "fdiv",
	"FDIVP ST(i), ST(0)":  "fdivrp",
	"FDIVRP ST(i), ST(0)": "fdivp",
	"FSUB ST(i), ST(0)":   "fsubr",
	"FSUBR ST(i), ST(0)":  "fsub",
	"FSUBP ST(i), ST(0)":  "fsubrp",
	"FSUBRP ST(i), ST(0)": "fsubp",

	"MOV r64op, imm64": "movabsq",
	"MOV moffs64, RAX": "movabsq",
	"MOV RAX, moffs64": "movabsq",

	"MOV moffs8, AL": "movb/movb/movabsb",
	"MOV AL, moffs8": "movb/movb/movabsb",

	"LGDT m16&32": "lgdtw/lgdtl",
	"LIDT m16&32": "lidtw/lidtl",
	"SGDT m":      "sgdtw/sgdtl/sgdt",
	"SIDT m":      "sidtw/sidtl/sidt",
	"LEAVE":       "leavew/leavel/leaveq",

	"MOVBE r16, m16": "movbeww",
	"MOVBE m16, r16": "movbeww",
	"MOVBE m32, r32": "movbell",
	"MOVBE r32, m32": "movbell",
	"MOVBE m64, r64": "movbeqq",
	"MOVBE r64, m64": "movbeqq",

	"MOVSX r16, r/m16":  "movsww",
	"MOVSX r16, r/m8":   "movsbw",
	"MOVSX r32, r/m16":  "movswl",
	"MOVSX r32, r/m8":   "movsbl",
	"MOVSX r64, r/m16":  "movswq",
	"MOVSX r64, r/m8":   "movsbq",
	"MOVSXD r64, r/m32": "movslq",
	"MOVZX r16, r/m16":  "movzww",
	"MOVZX r16, r/m8":   "movzbw",
	"MOVZX r32, r/m16":  "movzwl",
	"MOVZX r32, r/m8":   "movzbl",
	"MOVZX r64, r/m16":  "movzwq",
	"MOVZX r64, r/m8":   "movzbq",

	"CALL r/m16": "callw*",
	"CALL r/m32": "calll*",
	"CALL r/m64": "callq*",

	"JMP r/m16": "jmpw*",
	"JMP r/m32": "jmpl*",
	"JMP r/m64": "jmpq*",

	"CALL_FAR m16:16": "lcallw*",
	"CALL_FAR m16:32": "lcalll*",
	"CALL_FAR m16:64": "lcallq*",

	"JMP_FAR m16:16": "ljmpw*",
	"JMP_FAR m16:32": "ljmpl*",
	"JMP_FAR m16:64": "ljmpq*",

	"CALL_FAR ptr16:16": "lcallw",
	"CALL_FAR ptr16:32": "lcalll",
	"JMP_FAR ptr16:16":  "ljmpw",
	"JMP_FAR ptr16:32":  "ljmpl",

	"STR r32/m16":       "str{l/w}",
	"SMSW r32/m16":      "smsw{l/w}",
	"SLDT r32/m16":      "sldt{l/w}",
	"MOV Sreg, r32/m16": "mov{l/w}",
	"MOV r32/m16, Sreg": "mov{l/w}",

	"STR r64/m16":       "str{q/w}",
	"SMSW r64/m16":      "smsw{q/w}",
	"SLDT r64/m16":      "sldt{q/w}",
	"MOV Sreg, r64/m16": "mov{q/w}",
	"MOV r64/m16, Sreg": "mov{q/w}",

	"FLDENV m14/28byte":  "fldenvs/fldenvl",
	"FNSAVE m94/108byte": "fnsaves/fnsavel",
	"FNSTENV m14/28byte": "fnstenvs/fnstenvl",
	"FRSTOR m94/108byte": "frstors/frstorl",

	"IRETD":              "iretl",
	"IRET":               "iretw",
	"RET_FAR imm16u":     "lretw/lretl/lretl",
	"RET_FAR":            "lretw/lretl/lretl",
	"ENTER imm16, imm8b": "enterw/enterl/enterq",
	"RET":                "retw/retl/retq",
	"SYSRET":             "sysretw/sysretl/sysretl",

	"RET imm16u": "retw/retl/retq",

	"PUSH CS": "pushw/pushl/pushq",
	"PUSH DS": "pushw/pushl/pushq",
	"PUSH ES": "pushw/pushl/pushq",
	"PUSH FS": "pushw/pushl/pushq",
	"PUSH GS": "pushw/pushl/pushq",
	"PUSH SS": "pushw/pushl/pushq",

	"PUSH imm16": "pushw",

	"POP CS": "popw/popl/popq",
	"POP DS": "popw/popl/popq",
	"POP ES": "popw/popl/popq",
	"POP FS": "popw/popl/popq",
	"POP GS": "popw/popl/popq",
	"POP SS": "popw/popl/popq",

	"PUSH imm32": "-/pushl/pushq",
	"PUSH imm8":  "pushw/pushl/pushq",
}

var startArg = map[string]int{
	"CRC32": 1,
}

var goSizeSuffix = map[string]map[int]string{
	"BSWAP": {16: "W", 32: "L", 64: "Q"},
}

var goOpcode = map[string]string{
	// Overriding the GNU rewrites.
	"CBW":     "CBW",
	"CDQ":     "CDQ",
	"CDQE":    "CDQE",
	"CQO":     "CQO",
	"CWD":     "CWD",
	"CWDE":    "CWDE",
	"SYSRET":  "SYSRET",
	"MOVABSQ": "MOVQ",

	// Our own rewrites, of either GNU or Intel syntax.
	"CVTPD2DQ":   "CVTPD2PL",
	"CVTDQ2PD":   "CVTPL2PD",
	"CVTDQ2PS":   "CVTPL2PS",
	"CVTPS2DQ":   "CVTPS2PL",
	"CVTSD2SI":   "CVTSD2SL",
	"CVTSD2SIQ":  "CVTSD2SQ",
	"CVTSI2SDL":  "CVTSL2SD",
	"CVTSI2SDQ":  "CVTSQ2SD",
	"CVTSI2SSL":  "CVTSL2SS",
	"CVTSI2SSQ":  "CVTSQ2SS",
	"CVTSS2SI":   "CVTSS2SL",
	"CVTSS2SIQ":  "CVTSS2SQ",
	"CVTTPD2DQ":  "CVTTPD2PL",
	"CVTTPS2DQ":  "CVTTPS2PL",
	"CVTTSD2SI":  "CVTTSD2SL",
	"CVTTSD2SIQ": "CVTTSD2SQ",
	"CVTTSS2SI":  "CVTTSS2SL",
	"CVTTSS2SIQ": "CVTTSS2SQ",

	"LOOPE":      "LOOPEQ",
	"MASKMOVDQU": "MASKMOVOU",
	"MOVDQA":     "MOVO",
	"MOVDQU":     "MOVOU",
	"MOVNTDQ":    "MOVNTO",
	"MOVQ2DQ":    "MOVQOZX",
	"MOVDQ2Q":    "MOVQ",
	"MOVSBL":     "MOVBLSX",
	"MOVSBQ":     "MOVBQSX",
	"MOVSBW":     "MOVBWSX",
	"MOVSLQ":     "MOVLQSX",
	"MOVSWL":     "MOVWLSX",
	"MOVSWQ":     "MOVWQSX",
	"MOVZBL":     "MOVBLZX",
	"MOVZBQ":     "MOVBQZX",
	"MOVZBW":     "MOVBWZX",
	"MOVZLQ":     "MOVLQZX",
	"MOVZWL":     "MOVWLZX",
	"MOVZWQ":     "MOVWQZX",
	"PACKSSDW":   "PACKSSLW",
	"PADDD":      "PADDL",
	"PCMPEQD":    "PCMPEQL",
	"PCMPGTD":    "PCMPGTL",
	"PMADDWD":    "PMADDWL",
	"PMULUDQ":    "PMULULQ",
	"PSLLD":      "PSLLL",
	"PSLLDQ":     "PSLLO",
	"PSRAD":      "PSRAL",
	"PSRLD":      "PSRLL",
	"PSRLDQ":     "PSRLO",
	"PSUBD":      "PSUBL",
	"PUNPCKLWD":  "PUNPCKLWL",
	"PUNPCKHDQ":  "PUNPCKHLQ",
	"PUNPCKHWD":  "PUNPCKHWL",
	"PUNPCKLDQ":  "PUNPCKLLQ",
	"PUSHA":      "PUSHAW",
	"PUSHAD":     "PUSHAL",
	"PUSHF":      "PUSHFW",
	"PUSHFD":     "PUSHFL",
	"RET_FAR":    "RETFW/RETFL/RETFQ",
	"CALLQ":      "CALL",
	"CALLL":      "CALL",
	"CALLW":      "CALL",
	"MOVSXDW":    "MOVWQSX",
	"MOVSXDL":    "MOVLQSX",

	"SHLDW": "SHLW",
	"SHLDL": "SHLL",
	"SHLDQ": "SHLQ",
	"SHRDW": "SHRW",
	"SHRDL": "SHRL",
	"SHRDQ": "SHRQ",

	"CMOVAW":   "CMOVWHI",
	"CMOVAEW":  "CMOVWCC",
	"CMOVBW":   "CMOVWCS",
	"CMOVBEW":  "CMOVWLS",
	"CMOVCW":   "CMOVWCS",
	"CMOVCCW":  "CMOVWCC",
	"CMOVCSW":  "CMOVWCS",
	"CMOVEW":   "CMOVWEQ",
	"CMOVEQW":  "CMOVWEQ",
	"CMOVGW":   "CMOVWGT",
	"CMOVGEW":  "CMOVWGE",
	"CMOVGTW":  "CMOVWGT",
	"CMOVHIW":  "CMOVWHI",
	"CMOVHSW":  "CMOVWCC",
	"CMOVLW":   "CMOVWLT",
	"CMOVLEW":  "CMOVWLE",
	"CMOVLSW":  "CMOVWLS",
	"CMOVLTW":  "CMOVWLT",
	"CMOVLOW":  "CMOVWCS",
	"CMOVMIW":  "CMOVWMI",
	"CMOVNAW":  "CMOVWLS",
	"CMOVNAEW": "CMOVWCS",
	"CMOVNBW":  "CMOVWCC",
	"CMOVNBEW": "CMOVWHI",
	"CMOVNCW":  "CMOVWCC",
	"CMOVNEW":  "CMOVWNE",
	"CMOVNGW":  "CMOVWLE",
	"CMOVNGEW": "CMOVWLT",
	"CMOVNLW":  "CMOVWGE",
	"CMOVNLEW": "CMOVWGT",
	"CMOVNOW":  "CMOVWOC",
	"CMOVNPW":  "CMOVWPC",
	"CMOVNSW":  "CMOVWPL",
	"CMOVNZW":  "CMOVWNE",
	"CMOVOW":   "CMOVWOS",
	"CMOVOCW":  "CMOVWOC",
	"CMOVOSW":  "CMOVWOS",
	"CMOVPW":   "CMOVWPS",
	"CMOVPCW":  "CMOVWPC",
	"CMOVPEW":  "CMOVWPS",
	"CMOVPOW":  "CMOVWPC",
	"CMOVPSW":  "CMOVWPS",
	"CMOVSW":   "CMOVWMI",
	"CMOVZW":   "CMOVWEQ",

	"CMOVAL":   "CMOVLHI",
	"CMOVAEL":  "CMOVLCC",
	"CMOVBL":   "CMOVLCS",
	"CMOVBEL":  "CMOVLLS",
	"CMOVCL":   "CMOVLCS",
	"CMOVCCL":  "CMOVLCC",
	"CMOVCSL":  "CMOVLCS",
	"CMOVEL":   "CMOVLEQ",
	"CMOVEQL":  "CMOVLEQ",
	"CMOVGL":   "CMOVLGT",
	"CMOVGEL":  "CMOVLGE",
	"CMOVGTL":  "CMOVLGT",
	"CMOVHIL":  "CMOVLHI",
	"CMOVHSL":  "CMOVLCC",
	"CMOVLL":   "CMOVLLT",
	"CMOVLEL":  "CMOVLLE",
	"CMOVLSL":  "CMOVLLS",
	"CMOVLTL":  "CMOVLLT",
	"CMOVLOL":  "CMOVLCS",
	"CMOVMIL":  "CMOVLMI",
	"CMOVNAL":  "CMOVLLS",
	"CMOVNAEL": "CMOVLCS",
	"CMOVNBL":  "CMOVLCC",
	"CMOVNBEL": "CMOVLHI",
	"CMOVNCL":  "CMOVLCC",
	"CMOVNEL":  "CMOVLNE",
	"CMOVNGL":  "CMOVLLE",
	"CMOVNGEL": "CMOVLLT",
	"CMOVNLL":  "CMOVLGE",
	"CMOVNLEL": "CMOVLGT",
	"CMOVNOL":  "CMOVLOC",
	"CMOVNPL":  "CMOVLPC",
	"CMOVNSL":  "CMOVLPL",
	"CMOVNZL":  "CMOVLNE",
	"CMOVOL":   "CMOVLOS",
	"CMOVOCL":  "CMOVLOC",
	"CMOVOSL":  "CMOVLOS",
	"CMOVPL":   "CMOVLPS",
	"CMOVPCL":  "CMOVLPC",
	"CMOVPEL":  "CMOVLPS",
	"CMOVPOL":  "CMOVLPC",
	"CMOVPSL":  "CMOVLPS",
	"CMOVSL":   "CMOVLMI",
	"CMOVZL":   "CMOVLEQ",

	"CMOVAQ":   "CMOVQHI",
	"CMOVAEQ":  "CMOVQCC",
	"CMOVBQ":   "CMOVQCS",
	"CMOVBEQ":  "CMOVQLS",
	"CMOVCQ":   "CMOVQCS",
	"CMOVCCQ":  "CMOVQCC",
	"CMOVCSQ":  "CMOVQCS",
	"CMOVEQ":   "CMOVQEQ",
	"CMOVEQQ":  "CMOVQEQ",
	"CMOVGQ":   "CMOVQGT",
	"CMOVGEQ":  "CMOVQGE",
	"CMOVGTQ":  "CMOVQGT",
	"CMOVHIQ":  "CMOVQHI",
	"CMOVHSQ":  "CMOVQCC",
	"CMOVLQ":   "CMOVQLT",
	"CMOVLEQ":  "CMOVQLE",
	"CMOVLSQ":  "CMOVQLS",
	"CMOVLTQ":  "CMOVQLT",
	"CMOVLOQ":  "CMOVQCS",
	"CMOVMIQ":  "CMOVQMI",
	"CMOVNAQ":  "CMOVQLS",
	"CMOVNAEQ": "CMOVQCS",
	"CMOVNBQ":  "CMOVQCC",
	"CMOVNBEQ": "CMOVQHI",
	"CMOVNCQ":  "CMOVQCC",
	"CMOVNEQ":  "CMOVQNE",
	"CMOVNGQ":  "CMOVQLE",
	"CMOVNGEQ": "CMOVQLT",
	"CMOVNLQ":  "CMOVQGE",
	"CMOVNLEQ": "CMOVQGT",
	"CMOVNOQ":  "CMOVQOC",
	"CMOVNPQ":  "CMOVQPC",
	"CMOVNSQ":  "CMOVQPL",
	"CMOVNZQ":  "CMOVQNE",
	"CMOVOQ":   "CMOVQOS",
	"CMOVOCQ":  "CMOVQOC",
	"CMOVOSQ":  "CMOVQOS",
	"CMOVPQ":   "CMOVQPS",
	"CMOVPCQ":  "CMOVQPC",
	"CMOVPEQ":  "CMOVQPS",
	"CMOVPOQ":  "CMOVQPC",
	"CMOVPSQ":  "CMOVQPS",
	"CMOVSQ":   "CMOVQMI",
	"CMOVZQ":   "CMOVQEQ",

	"SETA":   "SETHI",
	"SETAE":  "SETCC",
	"SETB":   "SETCS",
	"SETBE":  "SETLS",
	"SETC":   "SETCS",
	"SETCC":  "SETCC",
	"SETCS":  "SETCS",
	"SETE":   "SETEQ",
	"SETEQ":  "SETEQ",
	"SETG":   "SETGT",
	"SETGE":  "SETGE",
	"SETGT":  "SETGT",
	"SETHI":  "SETHI",
	"SETHS":  "SETCC",
	"SETL":   "SETLT",
	"SETLE":  "SETLE",
	"SETLS":  "SETLS",
	"SETLT":  "SETLT",
	"SETLO":  "SETCS",
	"SETMI":  "SETMI",
	"SETNA":  "SETLS",
	"SETNAE": "SETCS",
	"SETNB":  "SETCC",
	"SETNBE": "SETHI",
	"SETNC":  "SETCC",
	"SETNE":  "SETNE",
	"SETNG":  "SETLE",
	"SETNGE": "SETLT",
	"SETNL":  "SETGE",
	"SETNLE": "SETGT",
	"SETNO":  "SETOC",
	"SETNP":  "SETPC",
	"SETNS":  "SETPL",
	"SETNZ":  "SETNE",
	"SETO":   "SETOS",
	"SETOC":  "SETOC",
	"SETOS":  "SETOS",
	"SETP":   "SETPS",
	"SETPC":  "SETPC",
	"SETPE":  "SETPS",
	"SETPO":  "SETPC",
	"SETPS":  "SETPS",
	"SETS":   "SETMI",
	"SETZ":   "SETEQ",

	"FADD":   "FADDD",
	"FADDP":  "FADDDP",
	"FADDS":  "FADDF",
	"FCOM":   "FCOMD",
	"FCOMS":  "FCOMF",
	"FCOMPS": "FCOMFP",
	"FDIV":   "FDIVD",
	"FDIVS":  "FDIVF",
	"FDIVRS": "FDIVFR",
}
