// Copyright 2016 The Go Authors.  All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package main

import (
	"fmt"
	"os"
	"sort"
	"strings"
)

// Clean up the data from the Intel manual for correctness
// and to annotate details relevant to decoding or encoding,
// such as whether an instruction is valid only in certain
// operand size modes.

// encodeReplace maps (argument, encoding) pairs to the corrected argument.
// We use a suffix 1 for the register and 2 for the r/m in the modrm byte.
// We use a suffix V for a register number specified in the VEX.vvvv bits.
var encodeReplace = map[[2]string]string{
	{"mm", "ModRM:reg"}:        "mm1",
	{"mm", "ModRM:r/m"}:        "mm2",
	{"mm1", "ModRM:r/m"}:       "mm2",
	{"mm2", "ModRM:reg"}:       "mm1",
	{"mm/m32", "ModRM:r/m"}:    "mm2/m32",
	{"mm/m64", "ModRM:r/m"}:    "mm2/m64",
	{"xmm", "ModRM:reg"}:       "xmm1",
	{"xmm", "ModRM:r/m"}:       "xmm2",
	{"xmm/m64", "ModRM:r/m"}:   "xmm2/m64",
	{"xmm0", "ModRM:reg"}:      "xmm1",
	{"xmm1", "ModRM:r/m"}:      "xmm2",
	{"xmm1/m16", "ModRM:r/m"}:  "xmm2/m16",
	{"xmm1/m32", "ModRM:r/m"}:  "xmm2/m32",
	{"xmm1/m64", "ModRM:r/m"}:  "xmm2/m64",
	{"xmm1/m128", "ModRM:r/m"}: "xmm2/m128",
	{"xmm1/m256", "ModRM:r/m"}: "xmm2/m256",
	{"xmm/m16", "ModRM:r/m"}:   "xmm2/m16",
	{"xmm/m32", "ModRM:r/m"}:   "xmm2/m32",
	{"xmm/m64", "ModRM:r/m"}:   "xmm2/m64",
	{"xmm/m128", "ModRM:r/m"}:  "xmm2/m128",
	{"xmm/m256", "ModRM:r/m"}:  "xmm2/m256",
	{"xmm3", "ModRM:reg"}:      "xmm1",
	{"xmm3", "ModRM:r/m"}:      "xmm2",
	{"xmm3/m16", "ModRM:r/m"}:  "xmm2/m16",
	{"xmm3/m32", "ModRM:r/m"}:  "xmm2/m32",
	{"xmm3/m64", "ModRM:r/m"}:  "xmm2/m64",
	{"xmm3/m128", "ModRM:r/m"}: "xmm2/m128",
	{"xmm3/m256", "ModRM:r/m"}: "xmm2/m256",
	{"xmm2", "ModRM:reg"}:      "xmm1",
	{"xmm2/m16", "ModRM:reg"}:  "xmm1/m16",
	{"xmm2/m32", "ModRM:reg"}:  "xmm1/m32",
	{"xmm2/m64", "ModRM:reg"}:  "xmm1/m64",
	{"xmm2/m128", "ModRM:reg"}: "xmm1/m128",
	{"xmm2/m256", "ModRM:reg"}: "xmm1/m256",
	{"ymm", "ModRM:reg"}:       "ymm1",
	{"ymm", "ModRM:r/m"}:       "ymm2",
	{"ymm0", "ModRM:reg"}:      "ymm1",
	{"ymm1", "ModRM:r/m"}:      "ymm2",
	{"ymm1/m16", "ModRM:r/m"}:  "ymm2/m16",
	{"ymm1/m32", "ModRM:r/m"}:  "ymm2/m32",
	{"ymm1/m64", "ModRM:r/m"}:  "ymm2/m64",
	{"ymm1/m128", "ModRM:r/m"}: "ymm2/m128",
	{"ymm1/m256", "ModRM:r/m"}: "ymm2/m256",
	{"ymm3", "ModRM:reg"}:      "ymm1",
	{"ymm3", "ModRM:r/m"}:      "ymm2",
	{"ymm3/m16", "ModRM:r/m"}:  "ymm2/m16",
	{"ymm3/m32", "ModRM:r/m"}:  "ymm2/m32",
	{"ymm3/m64", "ModRM:r/m"}:  "ymm2/m64",
	{"ymm3/m128", "ModRM:r/m"}: "ymm2/m128",
	{"ymm3/m256", "ModRM:r/m"}: "ymm2/m256",
	{"ymm2", "ModRM:reg"}:      "ymm1",
	{"ymm2/m16", "ModRM:reg"}:  "ymm1/m16",
	{"ymm2/m32", "ModRM:reg"}:  "ymm1/m32",
	{"ymm2/m64", "ModRM:reg"}:  "ymm1/m64",
	{"ymm2/m128", "ModRM:reg"}: "ymm1/m128",
	{"ymm2/m256", "ModRM:reg"}: "ymm1/m256",
	{"xmm1", "VEX.vvvv"}:       "xmmV",
	{"xmm2", "VEX.vvvv"}:       "xmmV",
	{"ymm1", "VEX.vvvv"}:       "ymmV",
	{"ymm2", "VEX.vvvv"}:       "ymmV",
	{"xmm4", "imm8[7:4]"}:      "xmmIH",
	{"ymm4", "imm8[7:4]"}:      "ymmIH",
	{"r8", "opcode + rd"}:      "r8op",
	{"r16", "opcode + rd"}:     "r16op",
	{"r32", "opcode + rd"}:     "r32op",
	{"r64", "opcode + rd"}:     "r64op",
	{"reg/m32", "ModRM:r/m"}:   "r/m32",
	{"reg/m16", "ModRM:r/m"}:   "r32/m16",
	{"bnd", "ModRM:reg"}:       "bnd1",
	{"bnd2", "ModRM:reg"}:      "bnd1",
	{"bnd1/m64", "ModRM:r/m"}:  "bnd2/m64",
	{"bnd1/m128", "ModRM:r/m"}: "bnd2/m128",
	{"r32a", "ModRM:reg"}:      "r32",
	{"r64a", "ModRM:reg"}:      "r64",
	{"r32", "VEX.vvvv"}:        "r32V",
	{"r64", "VEX.vvvv"}:        "r64V",
	{"r32b", "VEX.vvvv"}:       "r32V",
	{"r64b", "VEX.vvvv"}:       "r64V",
	{"r64", "VEX.vvvv"}:        "r64V",
	{"ST", "ST(0)"}:            "ST(0)",
}

// A few instructions do not have the usual encoding descriptions.
// Supply them.
var encodings = map[string][]string{
	"FADD m32fp":            {"ModRM:r/m (r)"},
	"FADD m64fp":            {"ModRM:r/m (r)"},
	"FADD ST(0), ST(i)":     {"ST(0) (r, w)", "ST(i) (r)"},
	"FADD ST(i), ST(0)":     {"ST(i) (r, w)", "ST(0) (r)"},
	"FADDP ST(i), ST(0)":    {"ST(i) (r, w)", "ST(0) (r)"},
	"FIADD m32int":          {"ModRM:r/m (r)"},
	"FIADD m16int":          {"ModRM:r/m (r)"},
	"FBLD m80dec":           {"ModRM:r/m (r)"},
	"FBSTP m80bcd":          {"ModRM:r/m (w)"},
	"FCMOVB ST(0), ST(i)":   {"ST(0) (r, w)", "ST(i) (r)"},
	"FCMOVE ST(0), ST(i)":   {"ST(0) (r, w)", "ST(i) (r)"},
	"FCMOVBE ST(0), ST(i)":  {"ST(0) (r, w)", "ST(i) (r)"},
	"FCMOVU ST(0), ST(i)":   {"ST(0) (r, w)", "ST(i) (r)"},
	"FCMOVNB ST(0), ST(i)":  {"ST(0) (r, w)", "ST(i) (r)"},
	"FCMOVNE ST(0), ST(i)":  {"ST(0) (r, w)", "ST(i) (r)"},
	"FCMOVNBE ST(0), ST(i)": {"ST(0) (r, w)", "ST(i) (r)"},
	"FCMOVNU ST(0), ST(i)":  {"ST(0) (r, w)", "ST(i) (r)"},
	"FCOM m32fp":            {"ModRM:r/m (r)"},
	"FCOM m64fp":            {"ModRM:r/m (r)"},
	"FCOM ST(i)":            {"ST(i) (r)"},
	"FCOMP m32fp":           {"ModRM:r/m (r)"},
	"FCOMP m64fp":           {"ModRM:r/m (r)"},
	"FCOMP ST(i)":           {"ST(i) (r)"},
	"FCOMI ST, ST(i)":       {"ST(0) (r)", "ST(i) (r)"},
	"FCOMIP ST, ST(i)":      {"ST(0) (r)", "ST(i) (r)"},
	"FUCOMI ST, ST(i)":      {"ST(0) (r)", "ST(i) (r)"},
	"FUCOMIP ST, ST(i)":     {"ST(0) (r)", "ST(i) (r)"},
	"FDIV m32fp":            {"ModRM:r/m (r)"},
	"FDIV m64fp":            {"ModRM:r/m (r)"},
	"FDIV ST(0), ST(i)":     {"ST(0) (r, w)", "ST(i) (r)"},
	"FDIV ST(i), ST(0)":     {"ST(i) (r, w)", "ST(0) (r)"},
	"FDIVP ST(i), ST(0)":    {"ST(i) (r, w)", "ST(0) (r)"},
	"FIDIV m16int":          {"ModRM:r/m (r)"},
	"FIDIV m32int":          {"ModRM:r/m (r)"},
	"FIDIV m64int":          {"ModRM:r/m (r)"},
	"FDIVR m32fp":           {"ModRM:r/m (r)"},
	"FDIVR m64fp":           {"ModRM:r/m (r)"},
	"FDIVR ST(0), ST(i)":    {"ST(0) (r, w)", "ST(i) (r)"},
	"FDIVR ST(i), ST(0)":    {"ST(i) (r, w)", "ST(0) (r)"},
	"FDIVRP ST(i), ST(0)":   {"ST(i) (r, w)", "ST(0) (r)"},
	"FIDIVR m16int":         {"ModRM:r/m (r)"},
	"FIDIVR m32int":         {"ModRM:r/m (r)"},
	"FIDIVR m64int":         {"ModRM:r/m (r)"},
	"FFREE ST(i)":           {"ST(i) (w)"},
	"FICOM m16int":          {"ModRM:r/m (r)"},
	"FICOM m32int":          {"ModRM:r/m (r)"},
	"FICOMP m16int":         {"ModRM:r/m (r)"},
	"FICOMP m32int":         {"ModRM:r/m (r)"},
	"FILD m16int":           {"ModRM:r/m (r)"},
	"FILD m32int":           {"ModRM:r/m (r)"},
	"FILD m64int":           {"ModRM:r/m (r)"},
	"FIST m16int":           {"ModRM:r/m (w)"},
	"FIST m32int":           {"ModRM:r/m (w)"},
	"FISTP m16int":          {"ModRM:r/m (w)"},
	"FISTP m32int":          {"ModRM:r/m (w)"},
	"FISTP m64int":          {"ModRM:r/m (w)"},
	"FISTTP m16int":         {"ModRM:r/m (w)"},
	"FISTTP m32int":         {"ModRM:r/m (w)"},
	"FISTTP m64int":         {"ModRM:r/m (w)"},
	"FLD m32fp":             {"ModRM:r/m (r)"},
	"FLD m64fp":             {"ModRM:r/m (r)"},
	"FLD m80fp":             {"ModRM:r/m (r)"},
	"FLD ST(i)":             {"ST(i) (r)"},
	"FLDCW m2byte":          {"ModRM:r/m (r)"},
	"FLDENV m14/28byte":     {"ModRM:r/m (r)"},
	"FMUL m32fp":            {"ModRM:r/m (r)"},
	"FMUL m64fp":            {"ModRM:r/m (r)"},
	"FMUL ST(0), ST(i)":     {"ST(0) (r, w)", "ST(i) (r)"},
	"FMUL ST(i), ST(0)":     {"ST(i) (r, w)", "ST(0) (r)"},
	"FMULP ST(i), ST(0)":    {"ST(i) (r, w)", "ST(0) (r)"},
	"FIMUL m16int":          {"ModRM:r/m (r)"},
	"FIMUL m32int":          {"ModRM:r/m (r)"},
	"FRSTOR m94/108byte":    {"ModRM:r/m (r)"},
	"FSAVE m94/108byte":     {"ModRM:r/m (w)"},
	"FNSAVE m94/108byte":    {"ModRM:r/m (w)"},
	"FST m32fp":             {"ModRM:r/m (w)"},
	"FST m64fp":             {"ModRM:r/m (w)"},
	"FST m80fp":             {"ModRM:r/m (w)"},
	"FST ST(i)":             {"ST(i) (w)"},
	"FSTP m32fp":            {"ModRM:r/m (w)"},
	"FSTP m64fp":            {"ModRM:r/m (w)"},
	"FSTP m80fp":            {"ModRM:r/m (w)"},
	"FSTP ST(i)":            {"ST(i) (w)"},
	"FSTCW m2byte":          {"ModRM:r/m (w)"},
	"FNSTCW m2byte":         {"ModRM:r/m (w)"},
	"FSTENV m14/28byte":     {"ModRM:r/m (w)"},
	"FNSTENV m14/28byte":    {"ModRM:r/m (w)"},
	"FSTSW m2byte":          {"ModRM:r/m (w)"},
	"FSTSW AX":              {"AX (w)"},
	"FNSTSW m2byte":         {"ModRM:r/m (w)"},
	"FNSTSW AX":             {"AX (w)"},
	"FSUB m32fp":            {"ModRM:r/m (r)"},
	"FSUB m64fp":            {"ModRM:r/m (r)"},
	"FSUB ST(0), ST(i)":     {"ST(0) (r, w)", "ST(i) (r)"},
	"FSUB ST(i), ST(0)":     {"ST(i) (r, w)", "ST(0) (r)"},
	"FSUBP ST(i), ST(0)":    {"ST(i) (r, w)", "ST(0) (r)"},
	"FISUB m16int":          {"ModRM:r/m (r)"},
	"FISUB m32int":          {"ModRM:r/m (r)"},
	"FSUBR m32fp":           {"ModRM:r/m (r)"},
	"FSUBR m64fp":           {"ModRM:r/m (r)"},
	"FSUBR ST(0), ST(i)":    {"ST(0) (r, w)", "ST(i) (r)"},
	"FSUBR ST(i), ST(0)":    {"ST(i) (r, w)", "ST(0) (r)"},
	"FSUBRP ST(i), ST(0)":   {"ST(i) (r, w)", "ST(0) (r)"},
	"FISUBR m16int":         {"ModRM:r/m (r)"},
	"FISUBR m32int":         {"ModRM:r/m (r)"},
	"FISUBR m64int":         {"ModRM:r/m (r)"},
	"FUCOM ST(i)":           {"ST(i) (r)"},
	"FUCOMP ST(i)":          {"ST(i) (r)"},
	"FXCH ST(i)":            {"ST(i) (r, w)"},
	"POP DS":                {"DS (w)"},
	"POP ES":                {"ES (w)"},
	"POP FS":                {"FS (w)"},
	"POP GS":                {"GS (w)"},
	"POP SS":                {"SS (w)"},
	"POP CS":                {"CS (w)"},
	"PUSH CS":               {"CS (r)"},
	"PUSH DS":               {"DS (r)"},
	"PUSH ES":               {"ES (r)"},
	"PUSH FS":               {"FS (r)"},
	"PUSH GS":               {"GS (r)"},
	"PUSH SS":               {"SS (r)"},
	"INT 3":                 {"3 (r)"},

	// In manual but hard to parse
	"BNDLDX bnd, mib": {"ModRM:reg (w)", "ModRM:r/m (r)"},
	"BNDSTX mib, bnd": {"ModRM:r/m (r)", "ModRM:reg (r)"},

	// In manual but wrong
	"CALL rel16":    {"Offset"},
	"CALL rel32":    {"Offset"},
	"IN AL, imm8":   {"AL (w)", "imm8 (r)"},
	"IN AX, imm8":   {"AX (w)", "imm8 (r)"},
	"IN EAX, imm8":  {"EAX (w)", "imm8 (r)"},
	"IN AL, DX":     {"AL (w)", "DX (r)"},
	"IN AX, DX":     {"AX (w)", "DX (r)"},
	"IN EAX, DX":    {"EAX (w)", "DX (r)"},
	"OUT DX, AL":    {"DX (r)", "AL (r)"},
	"OUT DX, AX":    {"DX (r)", "AX (r)"},
	"OUT DX, EAX":   {"DX (r)", "EAX (r)"},
	"OUT imm8, AL":  {"imm8 (r)", "AL (r)"},
	"OUT imm8, AX":  {"imm8 (r)", "AX (r)"},
	"OUT imm8, EAX": {"imm8 (r)", "EAX (r)"},
	"XCHG AX, r16":  {"AX (r, w)", "opcode + rd (r, w)"},
	"XCHG EAX, r32": {"EAX (r, w)", "opcode + rd (r, w)"},
	"XCHG RAX, r64": {"RAX (r, w)", "opcode + rd (r, w)"},

	// Encoding not listed.
	"INVEPT r32, m128":   {"ModRM:reg (r)", "ModRM:r/m (r)"},
	"INVEPT r64, m128":   {"ModRM:reg (r)", "ModRM:r/m (r)"},
	"INVVPID r32, m128":  {"ModRM:reg (r)", "ModRM:r/m (r)"},
	"INVVPID r64, m128":  {"ModRM:reg (r)", "ModRM:r/m (r)"},
	"VMREAD r/m32, r32":  {"ModRM:r/m (w)", "ModRM:reg (r)"},
	"VMREAD r/m64, r64":  {"ModRM:r/m (w)", "ModRM:reg (r)"},
	"VMWRITE r32, r/m32": {"ModRM:reg (r)", "ModRM:r/m (r)"},
	"VMWRITE r64, r/m64": {"ModRM:reg (r)", "ModRM:r/m (r)"},
	"VMCLEAR m64":        {"ModRM:r/m (w)"},
	"VMPTRLD m64":        {"ModRM:r/m (r)"},
	"VMPTRST m64":        {"ModRM:r/m (w)"},
	"VMXON m64":          {"ModRM:r/m (r)"},
}

// opAction lists the read/write actions for individual opcodes,
// where the manual does not.
var opAction = map[string][]string{
	"ADC":         {"rw", "r"},
	"ADD":         {"rw", "r"},
	"AND":         {"rw", "r"},
	"BLENDVPD":    {"rw", "r", "r"},
	"BLENDVPS":    {"rw", "r", "r"},
	"IN":          {"w", "r"},
	"MOV":         {"w", "r"},
	"OR":          {"rw", "r"},
	"OUT":         {"r", "r"},
	"PBLENDVB":    {"rw", "r", "r"},
	"RCL":         {"rw", "r"},
	"RCR":         {"rw", "r"},
	"ROL":         {"rw", "r"},
	"ROR":         {"rw", "r"},
	"SAL":         {"rw", "r"},
	"SAR":         {"rw", "r"},
	"SBB":         {"rw", "r"},
	"SHL":         {"rw", "r"},
	"SHLD":        {"rw", "r", "r"},
	"SHR":         {"rw", "r"},
	"SHRD":        {"rw", "r", "r"},
	"SUB":         {"rw", "r", "r"},
	"TEST":        {"r", "r"},
	"VBLENDVPD":   {"rw", "r", "r"},
	"VBLENDVPS":   {"rw", "r", "r"},
	"VPBLENDVB":   {"rw", "r", "r"},
	"VPMASKMOVD":  {"w", "r", "r"},
	"VPMASKMOVQ":  {"w", "r", "r"},
	"VPSLLVD":     {"w", "r", "r"},
	"VPSRAVD":     {"w", "r", "r"},
	"VPSRLVD":     {"w", "r", "r"},
	"VPSRLVQ":     {"w", "r", "r"},
	"VINSERTI128": {"w", "r", "r"},
	"VPBLENDD":    {"w", "r", "r"},
	"VPERMD":      {"w", "r", "r"},
	"VPERMPS":     {"w", "r", "r"},
	"VPERM2I128":  {"w", "r", "r"},
	"VPSLLVQ":     {"w", "r", "r"},
	"XCHG":        {"rw", "rw"},
	"XOR":         {"rw", "r"},
}

// encodeOK lists valid arg, encoding pairs.
// Any pair not listed gets a warning.
var encodeOK = map[[2]string]bool{
	{"0", "imm8"}:                true,
	{"1", "1"}:                   true,
	{"1", "imm8"}:                true,
	{"<XMM0>", "<XMM0>"}:         true,
	{"<XMM0>", "implicit XMM0"}:  true,
	{"AL", "AL"}:                 true,
	{"AL", "AL/AX/EAX/RAX"}:      true,
	{"AX", "AL/AX/EAX/RAX"}:      true,
	{"AX", "AX"}:                 true,
	{"AX", "AX/EAX/RAX"}:         true,
	{"CL", "CL"}:                 true,
	{"CR0-CR7", "ModRM:reg"}:     true,
	{"CR8", ""}:                  true,
	{"CS", "CS"}:                 true,
	{"DR0-DR7", "ModRM:reg"}:     true,
	{"DS", "DS"}:                 true,
	{"DX", "DX"}:                 true,
	{"EAX", "AL/AX/EAX/RAX"}:     true,
	{"EAX", "AX/EAX/RAX"}:        true,
	{"EAX", "EAX"}:               true,
	{"ES", "ES"}:                 true,
	{"FS", "FS"}:                 true,
	{"GS", "GS"}:                 true,
	{"RAX", "AL/AX/EAX/RAX"}:     true,
	{"RAX", "AX/EAX/RAX"}:        true,
	{"RAX", "RAX"}:               true,
	{"ST", "ST(0)"}:              true,
	{"ST(0)", "ST(0)"}:           true,
	{"ST(i)", "ST(i)"}:           true,
	{"Sreg", "ModRM:reg"}:        true,
	{"bnd1", "ModRM:reg"}:        true,
	{"bnd2/m128", "ModRM:r/m"}:   true,
	{"bnd2/m64", "ModRM:r/m"}:    true,
	{"imm16", "imm16"}:           true,
	{"imm16", "imm8"}:            true,
	{"imm16", "imm8/16/32"}:      true,
	{"imm16", "imm8/16/32"}:      true,
	{"imm16", "imm8/16/32/64"}:   true,
	{"imm16", "iw"}:              true,
	{"imm32", "imm8"}:            true,
	{"imm32", "imm8/16/32"}:      true,
	{"imm32", "imm8/16/32"}:      true,
	{"imm32", "imm8/16/32/64"}:   true,
	{"imm64", "imm8/16/32/64"}:   true,
	{"imm8", "imm8"}:             true,
	{"imm8", "imm8/16/32"}:       true,
	{"imm8", "imm8/16/32"}:       true,
	{"imm8", "imm8/16/32/64"}:    true,
	{"imm8", "imm8[3:0]"}:        true,
	{"m", "ModRM:r/m"}:           true,
	{"m128", "ModRM:r/m"}:        true,
	{"m14/28byte", "ModRM:r/m"}:  true,
	{"m16", "ModRM:r/m"}:         true,
	{"m16&16", "ModRM:r/m"}:      true,
	{"m16&32", "ModRM:r/m"}:      true,
	{"m16&64", "ModRM:r/m"}:      true,
	{"m16:16", "ModRM:r/m"}:      true,
	{"m16:16", "Offset"}:         true,
	{"m16:32", "ModRM:r/m"}:      true,
	{"m16:32", "Offset"}:         true,
	{"m16:64", "ModRM:r/m"}:      true,
	{"m16:64", "Offset"}:         true,
	{"m16int", "ModRM:r/m"}:      true,
	{"m256", "ModRM:r/m"}:        true,
	{"m2byte", "ModRM:r/m"}:      true,
	{"m32", "ModRM:r/m"}:         true,
	{"m32&32", "ModRM:r/m"}:      true,
	{"m32fp", "ModRM:r/m"}:       true,
	{"m32int", "ModRM:r/m"}:      true,
	{"m512byte", "ModRM:r/m"}:    true,
	{"m64", "ModRM:r/m"}:         true,
	{"m64fp", "ModRM:r/m"}:       true,
	{"m64int", "ModRM:r/m"}:      true,
	{"m8", "ModRM:r/m"}:          true,
	{"m80bcd", "ModRM:r/m"}:      true,
	{"m80dec", "ModRM:r/m"}:      true,
	{"m80fp", "ModRM:r/m"}:       true,
	{"m94/108byte", "ModRM:r/m"}: true,
	{"mem", "ModRM:r/m"}:         true,
	{"mib", "ModRM:r/m"}:         true,
	{"mm/m32", "ModRM:r/m"}:      true,
	{"mm1", "ModRM:reg"}:         true,
	{"mm2", "ModRM:r/m"}:         true,
	{"mm2/m32", "ModRM:r/m"}:     true,
	{"mm2/m64", "ModRM:r/m"}:     true,
	{"moffs16", "Moffs"}:         true,
	{"moffs32", "Moffs"}:         true,
	{"moffs64", "Moffs"}:         true,
	{"moffs8", "Moffs"}:          true,
	{"ptr16:16", "Offset"}:       true,
	{"ptr16:32", "Offset"}:       true,
	{"r/m16", "ModRM:r/m"}:       true,
	{"r/m32", "ModRM:r/m"}:       true,
	{"r/m64", "ModRM:r/m"}:       true,
	{"r/m8", "ModRM:r/m"}:        true,
	{"r16", "ModRM:reg"}:         true,
	{"r16op", "opcode + rd"}:     true,
	{"r32", "ModRM:reg"}:         true,
	{"r32", "VEX.vvvv"}:          true,
	{"r32/m16", "ModRM:r/m"}:     true,
	{"r32/m8", "ModRM:r/m"}:      true,
	{"r32V", "VEX.vvvv"}:         true,
	{"r32op", "opcode + rd"}:     true,
	{"r64", "ModRM:reg"}:         true,
	{"r64/m16", "ModRM:r/m"}:     true,
	{"r64V", "VEX.vvvv"}:         true,
	{"r64op", "opcode + rd"}:     true,
	{"r8", "ModRM:reg"}:          true,
	{"r8op", "opcode + rd"}:      true,
	{"rel16", "Offset"}:          true,
	{"rel32", "Offset"}:          true,
	{"rel8", "Offset"}:           true,
	{"rmr16", "ModRM:r/m"}:       true,
	{"rmr32", "ModRM:r/m"}:       true,
	{"rmr64", "ModRM:r/m"}:       true,
	{"xmm/m128", "ModRM:r/m"}:    true,
	{"xmm/m32", "ModRM:r/m"}:     true,
	{"xmm1", "ModRM:reg"}:        true,
	{"xmm2", "ModRM:r/m"}:        true,
	{"xmm2/m128", "ModRM:r/m"}:   true,
	{"xmm2/m16", "ModRM:r/m"}:    true,
	{"xmm2/m32", "ModRM:r/m"}:    true,
	{"xmm2/m64", "ModRM:r/m"}:    true,
	{"xmm2/m8", "ModRM:r/m"}:     true,
	{"xmmIH", "imm8[7:4]"}:       true,
	{"xmmV", "VEX.vvvv"}:         true,
	{"ymm1", "ModRM:reg"}:        true,
	{"ymm2", "ModRM:r/m"}:        true,
	{"ymm2/m256", "ModRM:r/m"}:   true,
	{"ymmIH", "imm8[7:4]"}:       true,
	{"ymmV", "VEX.vvvv"}:         true,
	{"vm32x", "vsib"}:            true,
	{"vm64x", "vsib"}:            true,
	{"vm32y", "vsib"}:            true,
	{"vm64y", "vsib"}:            true,
	{"SS", "SS"}:                 true,
	{"3", "3"}:                   true,
}

// instBlacklist lists the instruction syntaxes to ignore when parsing.
// We exclude Intel's general forms for these not-actually-general instructions.
// The syntax makes it look like arbitrary memory operands can be used when in fact
// the exact address is fixed in all cases - [DI] or [SI], for example
var instBlacklist = map[string]bool{
	"CMPS m16, m16":       true,
	"CMPS m32, m32":       true,
	"CMPS m64, m64":       true,
	"CMPS m8, m8":         true,
	"INS m16, DX":         true,
	"INS m32, DX":         true,
	"INS m8, DX":          true,
	"LODS m16":            true,
	"LODS m32":            true,
	"LODS m64":            true,
	"LODS m8":             true,
	"MOVS m16, m16":       true,
	"MOVS m32, m32":       true,
	"MOVS m64, m64":       true,
	"MOVS m8, m8":         true,
	"OUTS DX, m16":        true,
	"OUTS DX, m32":        true,
	"OUTS DX, m8":         true,
	"REP INS m16, DX":     true,
	"REP INS m32, DX":     true,
	"REP INS m8, DX":      true,
	"REP INS r/m32, DX":   true,
	"REP LODS AL":         true,
	"REP LODS AX":         true,
	"REP LODS EAX":        true,
	"REP LODS RAX":        true,
	"REP MOVS m16, m16":   true,
	"REP MOVS m32, m32":   true,
	"REP MOVS m64, m64":   true,
	"REP MOVS m8, m8":     true,
	"REP OUTS DX, m16":    true,
	"REP OUTS DX, m32":    true,
	"REP OUTS DX, m8":     true,
	"REP OUTS DX, r/m16":  true,
	"REP OUTS DX, r/m32":  true,
	"REP OUTS DX, r/m8":   true,
	"REP STOS m16":        true,
	"REP STOS m32":        true,
	"REP STOS m64":        true,
	"REP STOS m8":         true,
	"REPE CMPS m16, m16":  true,
	"REPE CMPS m32, m32":  true,
	"REPE CMPS m64, m64":  true,
	"REPE CMPS m8, m8":    true,
	"REPE SCAS m16":       true,
	"REPE SCAS m32":       true,
	"REPE SCAS m64":       true,
	"REPE SCAS m8":        true,
	"REPNE CMPS m16, m16": true,
	"REPNE CMPS m32, m32": true,
	"REPNE CMPS m64, m64": true,
	"REPNE CMPS m8, m8":   true,
	"REPNE SCAS m16":      true,
	"REPNE SCAS m32":      true,
	"REPNE SCAS m64":      true,
	"REPNE SCAS m8":       true,
	"SCAS m16":            true,
	"SCAS m32":            true,
	"SCAS m64":            true,
	"SCAS m8":             true,
	"STOS m16":            true,
	"STOS m32":            true,
	"STOS m64":            true,
	"STOS m8":             true,
	"XLAT m8":             true,

	// Neither xed nor objdump decode VSIB plausibly.
	// Too early to add these.
	"VGATHERDPD xmm1, vm32x, xmm2": true,
	"VGATHERDPD ymm1, vm32x, ymm2": true,
	"VGATHERDPS xmm1, vm32x, xmm2": true,
	"VGATHERDPS ymm1, vm32y, ymm2": true,
	"VGATHERQPD xmm1, vm64x, xmm2": true,
	"VGATHERQPD ymm1, vm64y, ymm2": true,
	"VGATHERQPS xmm1, vm64x, xmm2": true,
	"VGATHERQPS xmm1, vm64y, xmm2": true,
	"VPGATHERDD xmm1, vm32x, xmm2": true,
	"VPGATHERDD ymm1, vm32y, ymm2": true,
	"VPGATHERDQ xmm1, vm32x, xmm2": true,
	"VPGATHERDQ ymm1, vm32x, ymm2": true,
	"VPGATHERQD xmm1, vm64x, xmm2": true,
	"VPGATHERQD xmm1, vm64y, xmm2": true,
	"VPGATHERQQ xmm1, vm64x, xmm2": true,
	"VPGATHERQQ ymm1, vm64y, ymm2": true,
}

// condPrefs lists preferences for condition code suffixes.
// The first suffix in each pair takes priority over the second.
var condPrefs = [][2]string{
	{"B", "C"},
	{"B", "NAE"},
	{"AE", "NB"},
	{"AE", "NC"},
	{"E", "Z"},
	{"NE", "NZ"},
	{"BE", "NA"},
	{"A", "NBE"},
	{"P", "PE"},
	{"NP", "PO"},
	{"L", "NGE"},
	{"GE", "NL"},
	{"LE", "NG"},
	{"G", "NLE"},
}

// conv16 specifies replacements to turn a 16-bit syntax into a 32-bit syntax.
// If the conv16 can be applied to one form to create a new form with the same
// fixed instruction prefix, the pair is tagged as operand16 and operand32
// respectively.
var conv16 = strings.NewReplacer(
	"16:16", "16:32",
	"16", "32",
	"AX", "EAX",
	"CBW", "CWDE",
	"CMPSW", "CMPSD",
	"CWD", "CDQ",
	"INSW", "INSD",
	"IRET", "IRETD",
	"LODSW", "LODSD",
	"MOVSW", "MOVSD",
	"OUTSW", "OUTSD",
	"POPA", "POPAD",
	"POPF", "POPFD",
	"PUSHA", "PUSHAD",
	"PUSHF", "PUSHFD",
	"SCASW", "SCASD",
	"STOSW", "STOSD",
)

// fixup records additional modifications needed that are not derived
// from the instructions in the manual. It is keyed by the syntax and opcode.
var fixup = map[[2]string][]fixer{
	// NOP is a very special case overloading XCHG AX, AX.
	// The decoder handles it in custom code; exclude from the usual tables.
	{"NOP", "90"}: {fixAddTag("pseudo")},

	// PAUSE is a special case of NOP.
	{"PAUSE", "F3 90"}: {fixAddTag("pseudo")}, // used to add 'keepop' tag but not sure what that means

	// Far CALL, JMP, RET are given L prefix (long) for disambiguation.
	{"CALL m16:16", "FF /3"}:       {fixRename("CALL_FAR")},
	{"CALL m16:32", "FF /3"}:       {fixRename("CALL_FAR")},
	{"CALL m16:64", "REX.W FF /3"}: {fixRename("CALL_FAR")},
	{"CALL ptr16:16", "9A cd"}:     {fixRename("CALL_FAR")},
	{"CALL ptr16:32", "9A cp"}:     {fixRename("CALL_FAR")},
	{"JMP m16:16", "FF /5"}:        {fixRename("JMP_FAR")},
	{"JMP m16:32", "FF /5"}:        {fixRename("JMP_FAR")},
	{"JMP m16:64", "REX.W FF /5"}:  {fixRename("JMP_FAR")},
	{"JMP ptr16:16", "EA cd"}:      {fixRename("JMP_FAR")},
	{"JMP ptr16:32", "EA cp"}:      {fixRename("JMP_FAR")},
	{"RET imm16", "CA iw"}:         {fixRename("RET_FAR"), fixArg(0, "imm16u")},
	{"RET", "CB"}:                  {fixRename("RET_FAR")},

	// Unsigned immediates. (RET far imm16 handled above.)
	// Some of these are just preferences for disassembling.
	{"ENTER imm16, imm8", "C8 iw ib"}:  {fixArg(1, "imm8b")},
	{"RET imm16", "C2 iw"}:             {fixArg(0, "imm16u")},
	{"IN AL, imm8", "E4 ib"}:           {fixArg(1, "imm8u")},
	{"IN AX, imm8", "E5 ib"}:           {fixArg(1, "imm8u")},
	{"IN EAX, imm8", "E5 ib"}:          {fixArg(1, "imm8u"), fixAddTag("operand64")},
	{"OUT imm8, AL", "E6 ib"}:          {fixArg(0, "imm8u")},
	{"OUT imm8, AX", "E7 ib"}:          {fixArg(0, "imm8u")},
	{"OUT imm8, EAX", "E7 ib"}:         {fixArg(0, "imm8u"), fixAddTag("operand64")},
	{"MOV r8op, imm8", "B0+rb ib"}:     {fixArg(1, "imm8u")},
	{"MOV r8op, imm8", "REX B0+rb ib"}: {fixArg(1, "imm8u"), fixAddTag("pseudo64")},
	{"MOV r/m8, imm8", "C6 /0 ib"}:     {fixArg(1, "imm8u")},
	{"MOV r/m8, imm8", "REX C6 /0 ib"}: {fixArg(1, "imm8u"), fixAddTag("pseudo64")},

	// The listings for MOVSX and MOVSXD do not list some variants that
	// assemblers seem to allow.
	// As a result, this instruction got the wrong tag.
	// The other instructions are listed in extraInsts.
	{"MOVSX r32, r/m16", "0F BF /r"}: {fixRemoveTag("operand16"), fixAddTag("operand32")},
	{"MOVZX r32, r/m16", "0F B7 /r"}: {fixRemoveTag("operand16")},

	// Listings are incomplete or incorrect. Fix tags to adjust for new instructions below.
	{"SLDT r/m16", "0F 00 /0"}:             {fixRemoveTag("operand32")},
	{"STR r/m16", "0F 00 /1"}:              {fixAddTag("operand16")},
	{"BSWAP r32op", "0F C8+rd"}:            {fixRemoveTag("operand16")},
	{"MOV Sreg, r/m16", "8E /r"}:           {fixRemoveTag("operand32")},
	{"MOV Sreg, r/m64", "REX.W 8E /r"}:     {fixArg(1, "r/m16")},
	{"MOV r/m64, Sreg", "REX.W 8C /r"}:     {fixArg(0, "r/m16")},
	{"MOV r/m16, Sreg", "8C /r"}:           {fixRemoveTag("operand32")},
	{"MOV r/m64, imm32", "REX.W C7 /0 io"}: {fixOpcode("REX.W C7 /0 id")},

	// On 64-bit, these ignore 64-bit mode change.
	{"POP FS", "0F A1"}: {fixIfValid("N.E.", "V", fixAddTag("operand64"))},
	{"POP GS", "0F A9"}: {fixIfValid("N.E.", "V", fixAddTag("operand64"))},
	{"LEAVE", "C9"}:     {fixIfValid("N.E.", "V", fixAddTag("operand64"))},

	{"IN EAX, DX", "ED"}:         {fixAddTag("operand64")},
	{"INSD", "6D"}:               {fixAddTag("operand64")},
	{"OUT DX, EAX", "EF"}:        {fixAddTag("operand64")},
	{"OUTSD", "6F"}:              {fixAddTag("operand64")},
	{"XBEGIN rel32", "C7 F8 cd"}: {fixAddTag("operand64")},

	// Treat FWAIT, not WAIT, as canonical.
	{"FWAIT", "9B"}: {fixRemoveTag("pseudo")},
	{"WAIT", "9B"}:  {fixAddTag("pseudo")},

	// LAHF and SAHF are listed as "Invalid*" for 64-bit mode.
	// They are actually defined, so Valid from our point of view.
	// It's just that only a very few 64-bit processors allowed them.
	{"LAHF", "9F"}: {fixValid("V", "V")},
	{"SAHF", "9E"}: {fixValid("V", "V")},

	// The JZ forms are listed twice in the table, which confuses things.
	{"JZ rel16", "0F 84 cw"}: {fixAddTag("operand16"), fixRemoveTag("operand32")},
	{"JZ rel32", "0F 84 cd"}: {fixAddTag("operand32"), fixRemoveTag("operand16")},

	// XCHG has two of every instruction, which makes things bad.
	// The XX hack below takes care of most problems but this one remains.
	{"XCHG r/m16, r16", "87 /r"}: {fixRemoveTag("pseudo")},

	// MOV CR8 is just the obvious extension of the MOV CR0-CR7 form.
	{"MOV rmr64, CR8", "REX.R + 0F 20 /0"}: {fixAddTag("pseudo")},
	{"MOV CR8, rmr64", "REX.R + 0F 22 /0"}: {fixAddTag("pseudo")},

	// TODO: EXPLAIN ALL THESE
	{"ADCX r32, r/m32", "66 0F 38 F6 /r"}: {fixAddTag("operand16"), fixAddTag("operand32")},
	{"ADOX r32, r/m32", "F3 0F 38 F6 /r"}: {fixAddTag("operand16"), fixAddTag("operand32")},
	{"POPFQ", "9D"}:                       {fixAddTag("operand32"), fixAddTag("operand64")},
	{"PUSHFQ", "9C"}:                      {fixAddTag("operand32"), fixAddTag("operand64")},
	{"JCXZ rel8", "E3 cb"}:                {fixAddTag("address16")},
	{"JECXZ rel8", "E3 cb"}:               {fixAddTag("address32")},
	{"JRCXZ rel8", "E3 cb"}:               {fixAddTag("address64")},
	{"PUSH r64op", "50+rd"}:               {fixAddTag("operand32"), fixAddTag("operand64")},
	{"PUSH r/m64", "FF /6"}:               {fixAddTag("operand32"), fixAddTag("operand64")},
	{"POP r64op", "58+rd"}:                {fixAddTag("operand32"), fixAddTag("operand64")},
	{"POP r/m64", "8F /0"}:                {fixAddTag("operand32"), fixAddTag("operand64")},
	{"SMSW r/m16", "0F 01 /4"}:            {fixAddTag("operand16")},
	{"SMSW r32/m16", "0F 01 /4"}:          {fixRemoveTag("operand16"), fixAddTag("operand32")},

	// Express to the decoder that the rel16 only applies in 16-bit operand mode.
	{"JA rel16", "0F 87 cw"}:  {fixAddTag("operand16")},
	{"JAE rel16", "0F 83 cw"}: {fixAddTag("operand16")},
	{"JB rel16", "0F 82 cw"}:  {fixAddTag("operand16")},
	{"JBE rel16", "0F 86 cw"}: {fixAddTag("operand16")},
	{"JE rel16", "0F 84 cw"}:  {fixAddTag("operand16")},
	{"JG rel16", "0F 8F cw"}:  {fixAddTag("operand16")},
	{"JGE rel16", "0F 8D cw"}: {fixAddTag("operand16")},
	{"JL rel16", "0F 8C cw"}:  {fixAddTag("operand16")},
	{"JLE rel16", "0F 8E cw"}: {fixAddTag("operand16")},
	{"JNE rel16", "0F 85 cw"}: {fixAddTag("operand16")},
	{"JNO rel16", "0F 81 cw"}: {fixAddTag("operand16")},
	{"JNP rel16", "0F 8B cw"}: {fixAddTag("operand16")},
	{"JNS rel16", "0F 89 cw"}: {fixAddTag("operand16")},
	{"JO rel16", "0F 80 cw"}:  {fixAddTag("operand16")},
	{"JP rel16", "0F 8A cw"}:  {fixAddTag("operand16")},
	{"JS rel16", "0F 88 cw"}:  {fixAddTag("operand16")},

	{"JA rel32", "0F 87 cd"}:  {fixAddTag("operand32")},
	{"JAE rel32", "0F 83 cd"}: {fixAddTag("operand32")},
	{"JB rel32", "0F 82 cd"}:  {fixAddTag("operand32")},
	{"JBE rel32", "0F 86 cd"}: {fixAddTag("operand32")},
	{"JE rel32", "0F 84 cd"}:  {fixAddTag("operand32")},
	{"JG rel32", "0F 8F cd"}:  {fixAddTag("operand32")},
	{"JGE rel32", "0F 8D cd"}: {fixAddTag("operand32")},
	{"JL rel32", "0F 8C cd"}:  {fixAddTag("operand32")},
	{"JLE rel32", "0F 8E cd"}: {fixAddTag("operand32")},
	{"JNE rel32", "0F 85 cd"}: {fixAddTag("operand32")},
	{"JNO rel32", "0F 81 cd"}: {fixAddTag("operand32")},
	{"JNP rel32", "0F 8B cd"}: {fixAddTag("operand32")},
	{"JNS rel32", "0F 89 cd"}: {fixAddTag("operand32")},
	{"JO rel32", "0F 80 cd"}:  {fixAddTag("operand32")},
	{"JP rel32", "0F 8A cd"}:  {fixAddTag("operand32")},
	{"JS rel32", "0F 88 cd"}:  {fixAddTag("operand32")},

	{"LSL r16, r/m16", "0F 03 /r"}: {fixAddTag("operand16")},
}

var extraInsts = []*instruction{
	// Undocumented.
	{syntax: "ICEBP", opcode: "F1", valid32: "V", valid64: "V"},
	{syntax: "UD1", opcode: "0F B9", valid32: "V", valid64: "V"},
	{syntax: "FFREEP ST(i)", opcode: "DF C0+i", valid32: "V", valid64: "V", action: "w"},

	// Where did these come from? They were in version 0.01 of the csv table.
	{syntax: "MOVNTSD m64, xmm1", opcode: "F2 0F 2B /r", valid32: "V", valid64: "V", cpuid: "SSE", action: "w,r"},
	{syntax: "MOVNTSS m32, xmm1", opcode: "F3 0F 2B /r", valid32: "V", valid64: "V", cpuid: "SSE", action: "w,r"},

	// These express to the decoder that in 64-bit mode
	// an operand prefix does not affect the size of the relative offset.
	{syntax: "CALL rel32", opcode: "E8 cd", valid32: "N.S.", valid64: "V", tags: []string{"operand16", "operand64"}, action: "r"},
	{syntax: "JMP rel32", opcode: "E9 cd", valid32: "N.S.", valid64: "V", tags: []string{"operand16", "operand64"}, action: "r"},
	{syntax: "JA rel32", opcode: "0F 87 cd", valid32: "N.S.", valid64: "V", tags: []string{"operand16", "operand64"}, action: "r"},
	{syntax: "JAE rel32", opcode: "0F 83 cd", valid32: "N.S.", valid64: "V", tags: []string{"operand16", "operand64"}, action: "r"},
	{syntax: "JB rel32", opcode: "0F 82 cd", valid32: "N.S.", valid64: "V", tags: []string{"operand16", "operand64"}, action: "r"},
	{syntax: "JBE rel32", opcode: "0F 86 cd", valid32: "N.S.", valid64: "V", tags: []string{"operand16", "operand64"}, action: "r"},
	{syntax: "JE rel32", opcode: "0F 84 cd", valid32: "N.S.", valid64: "V", tags: []string{"operand16", "operand64"}, action: "r"},
	{syntax: "JG rel32", opcode: "0F 8F cd", valid32: "N.S.", valid64: "V", tags: []string{"operand16", "operand64"}, action: "r"},
	{syntax: "JGE rel32", opcode: "0F 8D cd", valid32: "N.S.", valid64: "V", tags: []string{"operand16", "operand64"}, action: "r"},
	{syntax: "JL rel32", opcode: "0F 8C cd", valid32: "N.S.", valid64: "V", tags: []string{"operand16", "operand64"}, action: "r"},
	{syntax: "JLE rel32", opcode: "0F 8E cd", valid32: "N.S.", valid64: "V", tags: []string{"operand16", "operand64"}, action: "r"},
	{syntax: "JNE rel32", opcode: "0F 85 cd", valid32: "N.S.", valid64: "V", tags: []string{"operand16", "operand64"}, action: "r"},
	{syntax: "JNO rel32", opcode: "0F 81 cd", valid32: "N.S.", valid64: "V", tags: []string{"operand16", "operand64"}, action: "r"},
	{syntax: "JNP rel32", opcode: "0F 8B cd", valid32: "N.S.", valid64: "V", tags: []string{"operand16", "operand64"}, action: "r"},
	{syntax: "JNS rel32", opcode: "0F 89 cd", valid32: "N.S.", valid64: "V", tags: []string{"operand16", "operand64"}, action: "r"},
	{syntax: "JO rel32", opcode: "0F 80 cd", valid32: "N.S.", valid64: "V", tags: []string{"operand16", "operand64"}, action: "r"},
	{syntax: "JP rel32", opcode: "0F 8A cd", valid32: "N.S.", valid64: "V", tags: []string{"operand16", "operand64"}, action: "r"},
	{syntax: "JS rel32", opcode: "0F 88 cd", valid32: "N.S.", valid64: "V", tags: []string{"operand16", "operand64"}, action: "r"},

	// Disassemblers recognize these, but they're not in the manual.
	// Not sure if they really exist.

	// The 16-16 and 32-32 forms don't really make sense since there's nothing to extend.
	{syntax: "MOVSX r16, r/m16", opcode: "0F BF /r", valid32: "V", valid64: "V", tags: []string{"operand16"}, action: "w,r"},
	{syntax: "MOVSXD r16, r/m32", opcode: "63 /r", valid32: "N.E.", valid64: "V", tags: []string{"operand16"}, action: "w,r"},
	{syntax: "MOVSXD r32, r/m32", opcode: "63 /r", valid32: "N.E.", valid64: "V", tags: []string{"operand32"}, action: "w,r"},
	{syntax: "MOVZX r16, r/m16", opcode: "0F B7 /r", valid32: "V", valid64: "V", tags: []string{"operand16"}, action: "w,r"},

	{syntax: "LAR r64, r/m16", opcode: "REX.W 0F 02 /r", valid32: "N.E.", valid64: "V", action: "w,r"},
	{syntax: "SLDT r32/m16", opcode: "0F 00 /0", valid32: "V", valid64: "V", tags: []string{"operand32"}, action: "w"},
	{syntax: "STR r32/m16", opcode: "0F 00 /1", valid32: "V", valid64: "V", tags: []string{"operand32"}, action: "w"},
	{syntax: "STR r64/m16", opcode: "REX.W 0F 00 /1", valid32: "N.E.", valid64: "V", action: "w"},

	{syntax: "BSWAP r16op", opcode: "0F C8+rd", valid32: "V", valid64: "V", tags: []string{"operand16"}, action: "rw"},

	// Do these exist?
	// I am not sure where they came from, and xed doesn't recognize them.
	//{syntax: "MOV TR0-TR7, rmr32", opcode: "0F 26 /r", valid32: "V", valid64: "N.E.", tags: []string{"modrm_regonly"}, action: "w,r"},
	//{syntax: "MOV TR0-TR7, rmr64", opcode: "0F 26 /r", valid32: "N.E.", valid64: "V", tags: []string{"modrm_regonly"}, action: "w,r"},
	//{syntax: "MOV rmr32, TR0-TR7", opcode: "0F 24 /r", valid32: "V", valid64: "N.E.", tags: []string{"modrm_regonly"}, action: "w,r"},
	//{syntax: "MOV rmr64, TR0-TR7", opcode: "0F 24 /r", valid32: "N.E.", valid64: "V", tags: []string{"modrm_regonly"}, action: "w,r"},
	{syntax: "MOV Sreg, r32/m16", opcode: "8E /r", valid32: "V", valid64: "V", tags: []string{"operand32"}, action: "w,r"},
	{syntax: "MOV r/m32, Sreg", opcode: "8C /r", valid32: "V", valid64: "V", tags: []string{"operand32"}, action: "w,r"},
}

type fixer func(*instruction)

func fixAddTag(tag string) fixer {
	return func(inst *instruction) {
		addTag(inst, tag)
	}
}

func fixRemoveTag(tag string) fixer {
	return func(inst *instruction) {
		removeTag(inst, tag)
	}
}

func fixRename(op string) fixer {
	return func(inst *instruction) {
		_, args := splitSyntax(inst.syntax)
		inst.syntax = joinSyntax(op, args)
	}
}

func fixArg(i int, arg string) fixer {
	return func(inst *instruction) {
		op, args := splitSyntax(inst.syntax)
		args[i] = arg
		inst.syntax = joinSyntax(op, args)
	}
}

func fixIfValid(valid32, valid64 string, fix fixer) fixer {
	return func(inst *instruction) {
		if inst.valid32 == valid32 && inst.valid64 == valid64 {
			fix(inst)
		}
	}
}

func fixValid(valid32, valid64 string) fixer {
	return func(inst *instruction) {
		inst.valid32 = valid32
		inst.valid64 = valid64
	}
}

func fixOpcode(opcode string) fixer {
	return func(inst *instruction) {
		inst.opcode = opcode
	}
}

func cleanup(insts []*instruction) []*instruction {
	var haveOp map[string]bool
	if onlySomePages {
		haveOp = map[string]bool{}
	}

	// Clean individual instruction encodings and opcode sequences.
	sawJZ := map[string]bool{}
	out := insts[:0]
	for seq, inst := range insts {
		inst.seq = seq

		// There are two copies each of JZ rel16 and JZ rel32. Delete the second.
		if strings.HasPrefix(inst.syntax, "JZ rel") {
			if sawJZ[inst.syntax] {
				continue
			}
			sawJZ[inst.syntax] = true
		}
		out = append(out, inst)

		// Intel CMPXCHG16B and CMPXCHG8B have surprise "m64" or " m128" at end of encoding.
		surprises := []string{
			" m64",
			" m128",
		}
		for _, s := range surprises {
			if strings.HasSuffix(inst.syntax, s) && strings.HasSuffix(inst.opcode, s) {
				inst.opcode = strings.TrimSuffix(inst.opcode, s)
			}
		}

		op, args := splitSyntax(inst.syntax)
		op = strings.TrimRight(op, "*")
		inst.syntax = joinSyntax(op, args)

		// Check argument names in syntax against encoding details.
		if enc, ok := encodings[inst.syntax]; ok {
			inst.args = enc
		}
		if len(args) == len(inst.args)+1 && args[len(args)-1] == "imm8" {
			fixed := make([]string, len(args))
			copy(fixed, inst.args)
			fixed[len(args)-1] = "imm8"
			inst.args = fixed
		} else if len(args) == 0 && len(inst.args) == 1 && inst.args[0] == "NA" {
			inst.args = []string{}
		} else if len(args) != len(inst.args) {
			fmt.Fprintf(os.Stderr, "p.%d: %s has %d args but %d encoding details:\n\t%s\n", inst.page, inst.syntax, len(args), len(inst.args), strings.Join(inst.args, "; "))
			inst.syntax = joinSyntax(op, args)
			continue
		}

		var action []string
		for i, arg := range args {
			arg = strings.TrimSpace(arg)
			arg = strings.TrimRight(arg, "*")
			if (arg == "reg" || strings.HasPrefix(arg, "reg/")) && containsAll(inst.desc, "upper bits", "r64", "zero") {
				arg = "r32" + strings.TrimPrefix(arg, "reg")
			}

			enc := inst.args[i]
			enc = strings.TrimSpace(enc)
			switch {
			case strings.HasSuffix(enc, " (r))"):
				enc = strings.TrimSuffix(enc, ")")
			case strings.HasSuffix(enc, " (R)"):
				enc = strings.TrimSuffix(enc, " (R)") + " (r)"
			case strings.HasSuffix(enc, " (W)"):
				enc = strings.TrimSuffix(enc, " (W)") + " (w)"
			case strings.HasSuffix(enc, " (r,w)"):
				enc = strings.TrimSuffix(enc, " (r,w)") + " (r, w)"
			case enc == "Imm8":
				enc = "imm8"
			case enc == "imm8/26/32":
				enc = "imm8/16/32"
			case enc == "BaseReg (R): VSIB:base, VectorReg(R): VSIB:index":
				enc = "vsib (r)"
			}
			inst.args[i] = enc

			switch {
			case strings.HasSuffix(enc, " (r)"):
				action = append(action, "r")
				enc = strings.TrimSuffix(enc, " (r)")
			case strings.HasSuffix(enc, " (w)"):
				action = append(action, "w")
				enc = strings.TrimSuffix(enc, " (w)")
			case strings.HasSuffix(enc, " (r, w)"):
				action = append(action, "rw")
				enc = strings.TrimSuffix(enc, " (r, w)")
			case strings.HasPrefix(enc, "imm"), enc == "Offset", enc == "iw", arg == "1", arg == "0", arg == "3":
				action = append(action, "r")
			case i < len(opAction[op]):
				action = append(action, opAction[op][i])
			default:
				fmt.Fprintf(os.Stderr, "p.%d: %s has encoding %s for %s but no r/w annotations\n", inst.page, inst.syntax, enc, arg)
				action = append(action, "?")
			}

			if arg == "mem" && op == "LDDQU" {
				arg = "m128"
			}
			if arg == "reg" && op == "LAR" {
				arg = "r32"
			}
			if actual := encodeReplace[[2]string{arg, enc}]; actual != "" {
				arg = actual
			}

			if (arg == "r8" || arg == "r16" || arg == "r32" || arg == "r64") && enc == "ModRM:r/m" {
				addTag(inst, "modrm_regonly")
				arg = "rmr" + arg[1:]
			}
			if (arg == "xmm2" || arg == "ymm2") && enc == "ModRM:r/m" {
				addTag(inst, "modrm_regonly")
			}

			if (arg == "m8" || arg == "m16" || arg == "m32" || arg == "m64" || arg == "m128" || arg == "m256") && enc == "ModRM:r/m" {
				addTag(inst, "modrm_memonly")
			}

			if arg == "r64" && (inst.syntax == "MOV r64, CR8" || inst.syntax == "MOV CR8, r64") {
				arg = "rmr64"
				addTag(inst, "modrm_regonly")
			}
			if arg == "CR8" {
				enc = ""
			}

			if !encodeOK[[2]string{arg, enc}] {
				fmt.Fprintf(os.Stderr, "p.%d: %s has invalid encoding %s for %s\n\t{%q, %q}: true,\n", inst.page, inst.syntax, enc, arg, arg, enc)
			}

			args[i] = arg

			// Intel SETcc and others are missing the /r.
			// But CALL rel16 and CALL rel32 have a bad encoding table so ignore the ModRM there.
			if strings.HasPrefix(enc, "ModRM") && !strings.Contains(inst.opcode, " /") && op != "CALL" {
				inst.opcode += " /r"
			}
			if strings.HasPrefix(enc, "ModRM:reg") && !strings.Contains(inst.opcode, "/r") {
				// The opcode is taken up with something else. Bug in table.
				fmt.Fprintf(os.Stderr, "p.%d: %s has invalid encoding %s: no reg field in %s\n", inst.page, inst.syntax, arg, inst.opcode)
			}
			// XBEGIN is missing cw cd.
			if enc == "Offset" && arg == "rel16" && !strings.Contains(inst.opcode, " cw") {
				inst.opcode += " cw"
			}
			if enc == "Offset" && arg == "rel32" && !strings.Contains(inst.opcode, " cd") {
				inst.opcode += " cd"
			}
			if enc == "Moffs" && !strings.Contains(inst.opcode, "cm") {
				inst.opcode += " cm"
			}

			inst.action = strings.Join(action, ",")
		}

		inst.syntax = joinSyntax(op, args)

		// The Intel manual lists each XCHG form with arguments in both orders.
		// While this is technically correct, it confuses lots of the analysis.
		// Change half of them to start with a fake "XX" byte.
		if op == "XCHG" && !strings.HasPrefix(args[0], "r/") && !strings.HasSuffix(args[0], "op") {
			inst.opcode = "XX " + inst.opcode
		}

		// Intel manual is not great about disabling REX instructions on 32-bit systems.
		if strings.Contains(inst.opcode, "REX") && inst.valid32 == "V" {
			inst.valid32 = "N.E."
		}

		if inst.valid32 == "V" {
			switch {
			case containsAll(inst.compat, "not supported", "earlier than the Intel486"):
				inst.cpuid = "486"
			case containsAll(inst.compat, "not supported", "earlier than the Pentium"),
				containsAll(inst.compat, "were introduced", "with the Pentium"):
				inst.cpuid = "Pentium"
			case containsAll(inst.compat, "were introduced", "in the Pentium II"):
				inst.cpuid = "PentiumII"
			case containsAll(inst.compat, "were introduced", "in the P6 family"),
				containsAll(inst.compat, "were introduced in P6 family"):
				addTag(inst, "P6")
			}
		}

		if onlySomePages {
			op, _ := splitSyntax(inst.syntax)
			haveOp[op] = true
		}
	}

	insts = out
	sort.Sort(byOpcode(insts))

	// Detect operand size dependencies.
	var last *instruction
	for _, inst := range insts {
		if last != nil {
			f1, _ := splitOpcode(last.opcode)
			f2, _ := splitOpcode(inst.opcode)
			if f1 == f2 {
				// Conflict: cannot distinguish instructions based on fixed prefix.
				if is16vs32pair(last, inst) {
					addTag(last, "operand16")
					addTag(inst, "operand32")
					continue
				}
				if is16vs32pair(inst, last) {
					addTag(last, "operand32")
					addTag(inst, "operand16")
					last = inst
					continue
				}
			}
		}
		last = inst
	}

	// Detect pseudo-ops, defined as opcode entries subsumed by more general ones.
	seen := map[string]*instruction{}
	for _, inst := range insts {
		if strings.HasPrefix(inst.opcode, "9B ") { // FWAIT prefix
			addTag(inst, "pseudo")
			continue
		}
		if inst.opcode == "F0" || inst.opcode == "F2" || inst.opcode == "F3" {
			addTag(inst, "pseudo")
			continue
		}
		if strings.HasPrefix(inst.syntax, "REP ") || strings.HasPrefix(inst.syntax, "REPE ") || strings.HasPrefix(inst.syntax, "REPNE ") {
			addTag(inst, "pseudo")
			continue
		}
		if strings.HasPrefix(inst.syntax, "SAL ") { // SHL is canonical
			addTag(inst, "pseudo")
			continue
		}
		if old := seen[inst.opcode]; old != nil {
			if condLess(old.syntax, inst.syntax) {
				addTag(inst, "pseudo")
				continue
			}
			if xchgLess(inst.syntax, old.syntax) {
				old.tags = append(old.tags, "pseudo")
				seen[inst.opcode] = inst
				continue
			}
		}

		seen[inst.opcode] = inst

		if last != nil && canGenerate(last.opcode, inst.opcode) {
			addTag(inst, "pseudo")
			continue
		}
		last = inst
	}
	for _, inst := range insts {
		if strings.Contains(inst.opcode, "REX ") {
			if old := seen[strings.Replace(inst.opcode, "REX ", "", 1)]; old != nil && old.syntax == inst.syntax {
				addTag(inst, "pseudo64")
				continue
			} else if old != nil && hasTag(old, "pseudo") {
				addTag(inst, "pseudo")
				continue
			}
		}
		if strings.Contains(inst.opcode, "REX.W ") {
			if old := seen[strings.Replace(inst.opcode, "REX.W ", "", -1)]; old != nil && old.syntax == inst.syntax {
				addTag(old, "ignoreREXW")
				addTag(inst, "pseudo")
				continue
			} else if old != nil && hasTag(old, "pseudo") {
				addTag(inst, "pseudo")
				continue
			} else if old != nil && !hasTag(old, "operand16") && !hasTag(old, "operand32") {
				// There is a 64-bit form of this instruction.
				// Mark this one as only valid in the non-64-bit operand modes.
				addTag(old, "operand16")
				addTag(old, "operand32")
				continue
			}
		}
	}

	// Undo XCHG hack above.
	for _, inst := range insts {
		if strings.HasPrefix(inst.opcode, "XX ") {
			inst.opcode = strings.TrimPrefix(inst.opcode, "XX ")
			addTag(inst, "pseudo")
			removeTag(inst, "pseudo64")
		}
	}

	// Last ditch effort. Manual fixes.
	// Some things are too hard to infer.
	for _, inst := range insts {
		for _, fix := range fixup[[2]string{inst.syntax, inst.opcode}] {
			fix(inst)
		}
		sort.Strings(inst.tags)
	}

	sort.Sort(bySeq(insts))

	if onlySomePages {
		for _, inst := range extraInsts {
			op, _ := splitSyntax(inst.syntax)
			if haveOp[op] {
				insts = append(insts, inst)
			}
		}
	} else {
		insts = append(insts, extraInsts...)
	}
	return insts
}

func hasTag(inst *instruction, tag string) bool {
	for _, t := range inst.tags {
		if t == tag {
			return true
		}
	}
	return false
}

func removeTag(inst *instruction, tag string) {
	if !hasTag(inst, tag) {
		return
	}
	out := inst.tags[:0]
	for _, t := range inst.tags {
		if t != tag {
			out = append(out, t)
		}
	}
	inst.tags = out
}

func addTag(inst *instruction, tag string) {
	if !hasTag(inst, tag) {
		inst.tags = append(inst.tags, tag)
	}
}

type byOpcode []*instruction

func (x byOpcode) Len() int      { return len(x) }
func (x byOpcode) Swap(i, j int) { x[i], x[j] = x[j], x[i] }
func (x byOpcode) Less(i, j int) bool {
	if x[i].opcode != x[j].opcode {
		return opcodeLess(x[i].opcode, x[j].opcode)
	}
	if condLess(x[i].syntax, x[j].syntax) {
		return true
	}
	if condLess(x[j].syntax, x[i].syntax) {
		return false
	}
	if x[i].syntax != x[j].syntax {
		return x[i].syntax < x[j].syntax
	}
	return x[i].seq < x[j].seq
}

type bySeq []*instruction

func (x bySeq) Len() int      { return len(x) }
func (x bySeq) Swap(i, j int) { x[i], x[j] = x[j], x[i] }
func (x bySeq) Less(i, j int) bool {
	return x[i].seq < x[j].seq
}

type bySyntax []*instruction

func (x bySyntax) Len() int      { return len(x) }
func (x bySyntax) Swap(i, j int) { x[i], x[j] = x[j], x[i] }
func (x bySyntax) Less(i, j int) bool {
	if x[i].syntax != x[j].syntax {
		return x[i].syntax < x[j].syntax
	}
	return x[i].opcode < x[j].opcode
}

// condLess reports whether the conditional instruction syntax
// x should be considered less than y.
// We sort condition codes we prefer ahead of condition codes we don't,
// so that the latter are recorded as the pseudo-operations.
func condLess(x, y string) bool {
	x, _ = splitSyntax(x)
	y, _ = splitSyntax(y)
	for _, pref := range condPrefs {
		if strings.HasSuffix(x, pref[0]) && strings.HasSuffix(y, pref[1]) && strings.TrimSuffix(x, pref[0]) == strings.TrimSuffix(y, pref[1]) {
			return true
		}
	}
	return false
}

// xchgLess reports whether the xchg instruction x should be considered less than y.
func xchgLess(x, y string) bool {
	return strings.HasPrefix(x, "XCHG ") && x > y
}

// opcodeLess reports whether opcode string x should be considered less than y.
// We sort wildcard fields like "ib" before literal bytes like "0A".
func opcodeLess(x, y string) bool {
	for i := 0; i < len(x) || i < len(y); i++ {
		if i >= len(x) {
			return true
		}
		if i >= len(y) {
			return false
		}
		if x[i] != y[i] {
			// sort word before doubleword
			if x[i] == 'w' && y[i] == 'd' {
				return true
			}
			if x[i] == 'd' && y[i] == 'w' {
				return false
			}
			// Sort lower-case before non-lower-case.
			// This sorts "ib" before literal bytes like "0A", for example.
			return x[i]-'a' < y[i]-'a'
		}
	}
	return false
}

// splitOpcode splits an opcode into its fixed and variable portions.
// For example "05 iw" splits into "05" and "iw".
func splitOpcode(x string) (fixed, variable string) {
	i := 0
	for i < len(x) {
		c := x[i]
		if '0' <= c && c <= '9' || 'A' <= c && c <= 'Z' || c == ' ' || c == '.' || c == '+' {
			i++
			continue
		}
		if i+2 <= len(x) && c == '/' {
			i += 2
			continue
		}
		break
	}
	return strings.TrimSpace(x[:i]), x[i:]
}

// canGenerate reports whether opcode string x can generate opcode string y.
// For example "D5 ib" can generate "D5 0A".
// Any string x is not considered to generate itself.
func canGenerate(x, y string) bool {
	i := 0
	for i < len(x) && i < len(y) && x[i] == y[i] {
		i++
	}
	if i == len(x) || i == len(y) {
		return false
	}
	switch x[i:] {
	case "ib":
		return len(y[i:]) == 2 && allHex(y[i:])
	case "0+i":
		return len(y[i:]) == 1 && '0' <= y[i] && y[i] <= '7'
	case "8+i":
		return len(y[i:]) == 1 && (y[i] == '8' || y[i] == '9' || 'A' <= y[i] && y[i] <= 'F')
	}
	return false
}

// allHex reports whether s is entirely hex digits.
func allHex(s string) bool {
	for _, c := range s {
		if '0' <= c && c <= '9' || 'A' <= c && c <= 'F' {
			continue
		}
		return false
	}
	return true
}

// is16vs32pair reports whether x and y are the 16- and 32-bit variants of the same instruction,
// based on analysis of the mnemonic syntax.
func is16vs32pair(x, y *instruction) bool {
	return conv16.Replace(x.syntax) == y.syntax ||
		strings.Replace(x.syntax, "r16, r/", "r32, r32/", -1) == y.syntax || // LSL etc
		strings.Replace(x.syntax, "r16", "r32", 1) == y.syntax // MOVSXD, MOVSX, etc
}

func containsAll(x string, targ ...string) bool {
	for _, y := range targ {
		i := strings.Index(x, y)
		if i < 0 {
			return false
		}
		x = x[i+len(y):]
	}
	return true
}
