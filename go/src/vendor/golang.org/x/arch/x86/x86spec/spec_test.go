// Copyright 2016 The Go Authors.  All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package main

import (
	"bytes"
	"fmt"
	"os"
	"sort"
	"strings"
	"testing"
)

var tests = []struct {
	pages  string
	output string
}{
	// TODO: If we get page information out of the table of contents,
	// we could avoid hard-coding page numbers that need updating with each manual.

	// Trivial.
	{"82", `
		"AAA","37","V","I","",""
	`},
	// Pseudo detection.
	{"84", `
		"AAD","D5 0A","V","I","","pseudo"
		"AAD imm8","D5 ib","V","I","",""
	`},
	// Operand-size and pseudo64 detection.
	{"95", `
		"ADD AL, imm8","04 ib","V","V","",""
		"ADD AX, imm16","05 iw","V","V","","operand16"
		"ADD EAX, imm32","05 id","V","V","","operand32"
		"ADD RAX, imm32","REX.W 05 id","N.E.","V","",""
		"ADD r/m8, imm8","80 /0 ib","V","V","",""
		"ADD r/m8, imm8","REX 80 /0 ib","N.E.","V","","pseudo64"
		"ADD r/m16, imm16","81 /0 iw","V","V","","operand16"
		"ADD r/m32, imm32","81 /0 id","V","V","","operand32"
		"ADD r/m64, imm32","REX.W 81 /0 id","N.E.","V","",""
		"ADD r/m16, imm8","83 /0 ib","V","V","","operand16"
		"ADD r/m32, imm8","83 /0 ib","V","V","","operand32"
		"ADD r/m64, imm8","REX.W 83 /0 ib","N.E.","V","",""
		"ADD r/m8, r8","00 /r","V","V","",""
		"ADD r/m8, r8","REX 00 /r","N.E.","V","","pseudo64"
		"ADD r/m16, r16","01 /r","V","V","","operand16"
		"ADD r/m32, r32","01 /r","V","V","","operand32"
		"ADD r/m64, r64","REX.W 01 /r","N.E.","V","",""
		"ADD r8, r/m8","02 /r","V","V","",""
		"ADD r8, r/m8","REX 02 /r","N.E.","V","","pseudo64"
		"ADD r16, r/m16","03 /r","V","V","","operand16"
		"ADD r32, r/m32","03 /r","V","V","","operand32"
		"ADD r64, r/m64","REX.W 03 /r","N.E.","V","",""
	`},
	{"961", `
		"PUSH r/m16","FF /6","V","V","","operand16"
		"PUSH r/m32","FF /6","V","N.E.","","operand32"
		"PUSH r/m64","FF /6","N.E.","V","","operand32,operand64"
		"PUSH r16op","50+rw","V","V","","operand16"
		"PUSH r32op","50+rd","V","N.E.","","operand32"
		"PUSH r64op","50+rd","N.E.","V","","operand32,operand64"
		"PUSH imm8","6A ib","V","V","",""
		"PUSH imm16","68 iw","V","V","","operand16"
		"PUSH imm32","68 id","V","V","","operand32"
		"PUSH CS","0E","V","I","",""
		"PUSH SS","16","V","I","",""
		"PUSH DS","1E","V","I","",""
		"PUSH ES","06","V","I","",""
		"PUSH FS","0F A0","V","V","",""
		"PUSH GS","0F A8","V","V","",""
	`},
	{"964", `
		"PUSHA","60","V","I","","operand16"
		"PUSHAD","60","V","I","","operand32"
	`},
	{"966", `
		"PUSHF","9C","V","V","","operand16"
		"PUSHFD","9C","V","N.E.","","operand32"
		"PUSHFQ","9C","N.E.","V","","operand32,operand64"
	`},
	{"872", `
		"POP r/m16","8F /0","V","V","","operand16"
		"POP r/m32","8F /0","V","N.E.","","operand32"
		"POP r/m64","8F /0","N.E.","V","","operand32,operand64"
		"POP r16op","58+rw","V","V","","operand16"
		"POP r32op","58+rd","V","N.E.","","operand32"
		"POP r64op","58+rd","N.E.","V","","operand32,operand64"
		"POP DS","1F","V","I","",""
		"POP ES","07","V","I","",""
		"POP SS","17","V","I","",""
		"POP FS","0F A1","V","V","","operand16"
		"POP FS","0F A1","V","N.E.","","operand32"
		"POP FS","0F A1","N.E.","V","","operand32,operand64"
		"POP GS","0F A9","V","V","","operand16"
		"POP GS","0F A9","V","N.E.","","operand32"
		"POP GS","0F A9","N.E.","V","","operand32,operand64"
	`},
	{"224", `
		"CMPSB","A6","V","V","",""
		"CMPSW","A7","V","V","","operand16"
		"CMPSD","A7","V","V","","operand32"
		"CMPSQ","REX.W A7","N.E.","V","",""
	`},
	{"228,654", `
		"CMPSD xmm1, xmm2/m64, imm8","F2 0F C2 /r ib","V","V","SSE2",""
		"VCMPSD xmm1, xmmV, xmm2/m64, imm8","VEX.NDS.LIG.F2.0F.WIG C2 /r ib","V","V","AVX",""
		"MOVSD xmm1, xmm2/m64","F2 0F 10 /r","V","V","SSE2",""
		"VMOVSD xmm1, xmmV, xmm2","VEX.NDS.LIG.F2.0F.WIG 10 /r","V","V","AVX","modrm_regonly"
		"VMOVSD xmm1, m64","VEX.LIG.F2.0F.WIG 10 /r","V","V","AVX","modrm_memonly"
		"MOVSD xmm2/m64, xmm1","F2 0F 11 /r","V","V","SSE2",""
		"VMOVSD xmm2, xmmV, xmm1","VEX.NDS.LIG.F2.0F.WIG 11 /r","V","V","AVX","modrm_regonly"
		"VMOVSD m64, xmm1","VEX.LIG.F2.0F.WIG 11 /r","V","V","AVX","modrm_memonly"
	`},
	{"277", `
		"CRC32 r32, r/m8","F2 0F 38 F0 /r","V","V","","operand16,operand32"
		"CRC32 r32, r/m8","F2 REX 0F 38 F0 /r","N.E.","V","","pseudo64"
		"CRC32 r32, r/m16","F2 0F 38 F1 /r","V","V","","operand16"
		"CRC32 r32, r/m32","F2 0F 38 F1 /r","V","V","","operand32"
		"CRC32 r64, r/m8","F2 REX.W 0F 38 F0 /r","N.E.","V","",""
		"CRC32 r64, r/m64","F2 REX.W 0F 38 F1 /r","N.E.","V","",""
	`},
	{"540", `
		"LDS r16, m16:16","C5 /r","V","I","","operand16"
		"LDS r32, m16:32","C5 /r","V","I","","operand32"
		"LSS r16, m16:16","0F B2 /r","V","V","","operand16"
		"LSS r32, m16:32","0F B2 /r","V","V","","operand32"
		"LSS r64, m16:64","REX.W 0F B2 /r","N.E.","V","",""
		"LES r16, m16:16","C4 /r","V","I","","operand16"
		"LES r32, m16:32","C4 /r","V","I","","operand32"
		"LFS r16, m16:16","0F B4 /r","V","V","","operand16"
		"LFS r32, m16:32","0F B4 /r","V","V","","operand32"
		"LFS r64, m16:64","REX.W 0F B4 /r","N.E.","V","",""
		"LGS r16, m16:16","0F B5 /r","V","V","","operand16"
		"LGS r32, m16:32","0F B5 /r","V","V","","operand32"
		"LGS r64, m16:64","REX.W 0F B5 /r","N.E.","V","",""
	`},
	// Condition code preferences.
	{"205,206,207", `
		"CMOVA r16, r/m16","0F 47 /r","V","V","","operand16"
		"CMOVA r32, r/m32","0F 47 /r","V","V","","operand32"
		"CMOVA r64, r/m64","REX.W 0F 47 /r","N.E.","V","",""
		"CMOVAE r16, r/m16","0F 43 /r","V","V","","operand16"
		"CMOVAE r32, r/m32","0F 43 /r","V","V","","operand32"
		"CMOVAE r64, r/m64","REX.W 0F 43 /r","N.E.","V","",""
		"CMOVB r16, r/m16","0F 42 /r","V","V","","operand16"
		"CMOVB r32, r/m32","0F 42 /r","V","V","","operand32"
		"CMOVB r64, r/m64","REX.W 0F 42 /r","N.E.","V","",""
		"CMOVBE r16, r/m16","0F 46 /r","V","V","","operand16"
		"CMOVBE r32, r/m32","0F 46 /r","V","V","","operand32"
		"CMOVBE r64, r/m64","REX.W 0F 46 /r","N.E.","V","",""
		"CMOVC r16, r/m16","0F 42 /r","V","V","","operand16,pseudo"
		"CMOVC r32, r/m32","0F 42 /r","V","V","","operand32,pseudo"
		"CMOVC r64, r/m64","REX.W 0F 42 /r","N.E.","V","","pseudo"
		"CMOVE r16, r/m16","0F 44 /r","V","V","","operand16"
		"CMOVE r32, r/m32","0F 44 /r","V","V","","operand32"
		"CMOVE r64, r/m64","REX.W 0F 44 /r","N.E.","V","",""
		"CMOVG r16, r/m16","0F 4F /r","V","V","","operand16"
		"CMOVG r32, r/m32","0F 4F /r","V","V","","operand32"
		"CMOVG r64, r/m64","REX.W 0F 4F /r","N.E.","V","",""
		"CMOVGE r16, r/m16","0F 4D /r","V","V","","operand16"
		"CMOVGE r32, r/m32","0F 4D /r","V","V","","operand32"
		"CMOVGE r64, r/m64","REX.W 0F 4D /r","N.E.","V","",""
		"CMOVL r16, r/m16","0F 4C /r","V","V","","operand16"
		"CMOVL r32, r/m32","0F 4C /r","V","V","","operand32"
		"CMOVL r64, r/m64","REX.W 0F 4C /r","N.E.","V","",""
		"CMOVLE r16, r/m16","0F 4E /r","V","V","","operand16"
		"CMOVLE r32, r/m32","0F 4E /r","V","V","","operand32"
		"CMOVLE r64, r/m64","REX.W 0F 4E /r","N.E.","V","",""
		"CMOVNA r16, r/m16","0F 46 /r","V","V","","operand16,pseudo"
		"CMOVNA r32, r/m32","0F 46 /r","V","V","","operand32,pseudo"
		"CMOVNA r64, r/m64","REX.W 0F 46 /r","N.E.","V","","pseudo"
		"CMOVNAE r16, r/m16","0F 42 /r","V","V","","operand16,pseudo"
		"CMOVNAE r32, r/m32","0F 42 /r","V","V","","operand32,pseudo"
		"CMOVNAE r64, r/m64","REX.W 0F 42 /r","N.E.","V","","pseudo"
		"CMOVNB r16, r/m16","0F 43 /r","V","V","","operand16,pseudo"
		"CMOVNB r32, r/m32","0F 43 /r","V","V","","operand32,pseudo"
		"CMOVNB r64, r/m64","REX.W 0F 43 /r","N.E.","V","","pseudo"
		"CMOVNBE r16, r/m16","0F 47 /r","V","V","","operand16,pseudo"
		"CMOVNBE r32, r/m32","0F 47 /r","V","V","","operand32,pseudo"
		"CMOVNBE r64, r/m64","REX.W 0F 47 /r","N.E.","V","","pseudo"
		"CMOVNC r16, r/m16","0F 43 /r","V","V","","operand16,pseudo"
		"CMOVNC r32, r/m32","0F 43 /r","V","V","","operand32,pseudo"
		"CMOVNC r64, r/m64","REX.W 0F 43 /r","N.E.","V","","pseudo"
		"CMOVNE r16, r/m16","0F 45 /r","V","V","","operand16"
		"CMOVNE r32, r/m32","0F 45 /r","V","V","","operand32"
		"CMOVNE r64, r/m64","REX.W 0F 45 /r","N.E.","V","",""
		"CMOVNG r16, r/m16","0F 4E /r","V","V","","operand16,pseudo"
		"CMOVNG r32, r/m32","0F 4E /r","V","V","","operand32,pseudo"
		"CMOVNG r64, r/m64","REX.W 0F 4E /r","N.E.","V","","pseudo"
		"CMOVNGE r16, r/m16","0F 4C /r","V","V","","operand16,pseudo"
		"CMOVNGE r32, r/m32","0F 4C /r","V","V","","operand32,pseudo"
		"CMOVNGE r64, r/m64","REX.W 0F 4C /r","N.E.","V","","pseudo"
		"CMOVNL r16, r/m16","0F 4D /r","V","V","","operand16,pseudo"
		"CMOVNL r32, r/m32","0F 4D /r","V","V","","operand32,pseudo"
		"CMOVNL r64, r/m64","REX.W 0F 4D /r","N.E.","V","","pseudo"
		"CMOVNLE r16, r/m16","0F 4F /r","V","V","","operand16,pseudo"
		"CMOVNLE r32, r/m32","0F 4F /r","V","V","","operand32,pseudo"
		"CMOVNLE r64, r/m64","REX.W 0F 4F /r","N.E.","V","","pseudo"
		"CMOVNO r16, r/m16","0F 41 /r","V","V","","operand16"
		"CMOVNO r32, r/m32","0F 41 /r","V","V","","operand32"
		"CMOVNO r64, r/m64","REX.W 0F 41 /r","N.E.","V","",""
		"CMOVNP r16, r/m16","0F 4B /r","V","V","","operand16"
		"CMOVNP r32, r/m32","0F 4B /r","V","V","","operand32"
		"CMOVNP r64, r/m64","REX.W 0F 4B /r","N.E.","V","",""
		"CMOVNS r16, r/m16","0F 49 /r","V","V","","operand16"
		"CMOVNS r32, r/m32","0F 49 /r","V","V","","operand32"
		"CMOVNS r64, r/m64","REX.W 0F 49 /r","N.E.","V","",""
		"CMOVNZ r16, r/m16","0F 45 /r","V","V","","operand16,pseudo"
		"CMOVNZ r32, r/m32","0F 45 /r","V","V","","operand32,pseudo"
		"CMOVNZ r64, r/m64","REX.W 0F 45 /r","N.E.","V","","pseudo"
		"CMOVO r16, r/m16","0F 40 /r","V","V","","operand16"
		"CMOVO r32, r/m32","0F 40 /r","V","V","","operand32"
		"CMOVO r64, r/m64","REX.W 0F 40 /r","N.E.","V","",""
		"CMOVP r16, r/m16","0F 4A /r","V","V","","operand16"
		"CMOVP r32, r/m32","0F 4A /r","V","V","","operand32"
		"CMOVP r64, r/m64","REX.W 0F 4A /r","N.E.","V","",""
		"CMOVPE r16, r/m16","0F 4A /r","V","V","","operand16,pseudo"
		"CMOVPE r32, r/m32","0F 4A /r","V","V","","operand32,pseudo"
		"CMOVPE r64, r/m64","REX.W 0F 4A /r","N.E.","V","","pseudo"
		"CMOVPO r16, r/m16","0F 4B /r","V","V","","operand16,pseudo"
		"CMOVPO r32, r/m32","0F 4B /r","V","V","","operand32,pseudo"
		"CMOVPO r64, r/m64","REX.W 0F 4B /r","N.E.","V","","pseudo"
		"CMOVS r16, r/m16","0F 48 /r","V","V","","operand16"
		"CMOVS r32, r/m32","0F 48 /r","V","V","","operand32"
		"CMOVS r64, r/m64","REX.W 0F 48 /r","N.E.","V","",""
		"CMOVZ r16, r/m16","0F 44 /r","V","V","","operand16,pseudo"
		"CMOVZ r32, r/m32","0F 44 /r","V","V","","operand32,pseudo"
		"CMOVZ r64, r/m64","REX.W 0F 44 /r","N.E.","V","","pseudo"
	`},
	// Condition code preferences, but also Intel manual is also missing /r in the syntax lines.
	{"1043,1044", `
		"SETA r/m8","0F 97 /r","V","V","",""
		"SETA r/m8","REX 0F 97 /r","N.E.","V","","pseudo64"
		"SETAE r/m8","0F 93 /r","V","V","",""
		"SETAE r/m8","REX 0F 93 /r","N.E.","V","","pseudo64"
		"SETB r/m8","0F 92 /r","V","V","",""
		"SETB r/m8","REX 0F 92 /r","N.E.","V","","pseudo64"
		"SETBE r/m8","0F 96 /r","V","V","",""
		"SETBE r/m8","REX 0F 96 /r","N.E.","V","","pseudo64"
		"SETC r/m8","0F 92 /r","V","V","","pseudo"
		"SETC r/m8","REX 0F 92 /r","N.E.","V","","pseudo"
		"SETE r/m8","0F 94 /r","V","V","",""
		"SETE r/m8","REX 0F 94 /r","N.E.","V","","pseudo64"
		"SETG r/m8","0F 9F /r","V","V","",""
		"SETG r/m8","REX 0F 9F /r","N.E.","V","","pseudo64"
		"SETGE r/m8","0F 9D /r","V","V","",""
		"SETGE r/m8","REX 0F 9D /r","N.E.","V","","pseudo64"
		"SETL r/m8","0F 9C /r","V","V","",""
		"SETL r/m8","REX 0F 9C /r","N.E.","V","","pseudo64"
		"SETLE r/m8","0F 9E /r","V","V","",""
		"SETLE r/m8","REX 0F 9E /r","N.E.","V","","pseudo64"
		"SETNA r/m8","0F 96 /r","V","V","","pseudo"
		"SETNA r/m8","REX 0F 96 /r","N.E.","V","","pseudo"
		"SETNAE r/m8","0F 92 /r","V","V","","pseudo"
		"SETNAE r/m8","REX 0F 92 /r","N.E.","V","","pseudo"
		"SETNB r/m8","0F 93 /r","V","V","","pseudo"
		"SETNB r/m8","REX 0F 93 /r","N.E.","V","","pseudo"
		"SETNBE r/m8","0F 97 /r","V","V","","pseudo"
		"SETNBE r/m8","REX 0F 97 /r","N.E.","V","","pseudo"
		"SETNC r/m8","0F 93 /r","V","V","","pseudo"
		"SETNC r/m8","REX 0F 93 /r","N.E.","V","","pseudo"
		"SETNE r/m8","0F 95 /r","V","V","",""
		"SETNE r/m8","REX 0F 95 /r","N.E.","V","","pseudo64"
		"SETNG r/m8","0F 9E /r","V","V","","pseudo"
		"SETNG r/m8","REX 0F 9E /r","N.E.","V","","pseudo"
		"SETNGE r/m8","0F 9C /r","V","V","","pseudo"
		"SETNGE r/m8","REX 0F 9C /r","N.E.","V","","pseudo"
		"SETNL r/m8","0F 9D /r","V","V","","pseudo"
		"SETNL r/m8","REX 0F 9D /r","N.E.","V","","pseudo"
		"SETNLE r/m8","0F 9F /r","V","V","","pseudo"
		"SETNLE r/m8","REX 0F 9F /r","N.E.","V","","pseudo"
		"SETNO r/m8","0F 91 /r","V","V","",""
		"SETNO r/m8","REX 0F 91 /r","N.E.","V","","pseudo64"
		"SETNP r/m8","0F 9B /r","V","V","",""
		"SETNP r/m8","REX 0F 9B /r","N.E.","V","","pseudo64"
		"SETNS r/m8","0F 99 /r","V","V","",""
		"SETNS r/m8","REX 0F 99 /r","N.E.","V","","pseudo64"
		"SETNZ r/m8","0F 95 /r","V","V","","pseudo"
		"SETNZ r/m8","REX 0F 95 /r","N.E.","V","","pseudo"
		"SETO r/m8","0F 90 /r","V","V","",""
		"SETO r/m8","REX 0F 90 /r","N.E.","V","","pseudo64"
		"SETP r/m8","0F 9A /r","V","V","",""
		"SETP r/m8","REX 0F 9A /r","N.E.","V","","pseudo64"
		"SETPE r/m8","0F 9A /r","V","V","","pseudo"
		"SETPE r/m8","REX 0F 9A /r","N.E.","V","","pseudo"
		"SETPO r/m8","0F 9B /r","V","V","","pseudo"
		"SETPO r/m8","REX 0F 9B /r","N.E.","V","","pseudo"
		"SETS r/m8","0F 98 /r","V","V","",""
		"SETS r/m8","REX 0F 98 /r","N.E.","V","","pseudo64"
		"SETZ r/m8","0F 94 /r","V","V","","pseudo"
		"SETZ r/m8","REX 0F 94 /r","N.E.","V","","pseudo"
	`},
	{"520,521,522,523", `
		"JA rel8","77 cb","V","V","",""
		"JAE rel8","73 cb","V","V","",""
		"JB rel8","72 cb","V","V","",""
		"JBE rel8","76 cb","V","V","",""
		"JC rel8","72 cb","V","V","","pseudo"
		"JCXZ rel8","E3 cb","V","N.E.","","address16"
		"JECXZ rel8","E3 cb","V","V","","address32"
		"JRCXZ rel8","E3 cb","N.E.","V","","address64"
		"JE rel8","74 cb","V","V","",""
		"JG rel8","7F cb","V","V","",""
		"JGE rel8","7D cb","V","V","",""
		"JL rel8","7C cb","V","V","",""
		"JLE rel8","7E cb","V","V","",""
		"JNA rel8","76 cb","V","V","","pseudo"
		"JNAE rel8","72 cb","V","V","","pseudo"
		"JNB rel8","73 cb","V","V","","pseudo"
		"JNBE rel8","77 cb","V","V","","pseudo"
		"JNC rel8","73 cb","V","V","","pseudo"
		"JNE rel8","75 cb","V","V","",""
		"JNG rel8","7E cb","V","V","","pseudo"
		"JNGE rel8","7C cb","V","V","","pseudo"
		"JNL rel8","7D cb","V","V","","pseudo"
		"JNLE rel8","7F cb","V","V","","pseudo"
		"JNO rel8","71 cb","V","V","",""
		"JNP rel8","7B cb","V","V","",""
		"JNS rel8","79 cb","V","V","",""
		"JNZ rel8","75 cb","V","V","","pseudo"
		"JO rel8","70 cb","V","V","",""
		"JP rel8","7A cb","V","V","",""
		"JPE rel8","7A cb","V","V","","pseudo"
		"JPO rel8","7B cb","V","V","","pseudo"
		"JS rel8","78 cb","V","V","",""
		"JZ rel8","74 cb","V","V","","pseudo"
		"JA rel16","0F 87 cw","V","N.S.","","operand16"
		"JA rel32","0F 87 cd","V","V","","operand32"
		"JAE rel16","0F 83 cw","V","N.S.","","operand16"
		"JAE rel32","0F 83 cd","V","V","","operand32"
		"JB rel16","0F 82 cw","V","N.S.","","operand16"
		"JB rel32","0F 82 cd","V","V","","operand32"
		"JBE rel16","0F 86 cw","V","N.S.","","operand16"
		"JBE rel32","0F 86 cd","V","V","","operand32"
		"JC rel16","0F 82 cw","V","N.S.","","pseudo"
		"JC rel32","0F 82 cd","V","V","","pseudo"
		"JE rel16","0F 84 cw","V","N.S.","","operand16"
		"JE rel32","0F 84 cd","V","V","","operand32"
		"JZ rel16","0F 84 cw","V","N.S.","","operand16,pseudo"
		"JZ rel32","0F 84 cd","V","V","","operand32,pseudo"
		"JG rel16","0F 8F cw","V","N.S.","","operand16"
		"JG rel32","0F 8F cd","V","V","","operand32"
		"JGE rel16","0F 8D cw","V","N.S.","","operand16"
		"JGE rel32","0F 8D cd","V","V","","operand32"
		"JL rel16","0F 8C cw","V","N.S.","","operand16"
		"JL rel32","0F 8C cd","V","V","","operand32"
		"JLE rel16","0F 8E cw","V","N.S.","","operand16"
		"JLE rel32","0F 8E cd","V","V","","operand32"
		"JNA rel16","0F 86 cw","V","N.S.","","pseudo"
		"JNA rel32","0F 86 cd","V","V","","pseudo"
		"JNAE rel16","0F 82 cw","V","N.S.","","pseudo"
		"JNAE rel32","0F 82 cd","V","V","","pseudo"
		"JNB rel16","0F 83 cw","V","N.S.","","pseudo"
		"JNB rel32","0F 83 cd","V","V","","pseudo"
		"JNBE rel16","0F 87 cw","V","N.S.","","pseudo"
		"JNBE rel32","0F 87 cd","V","V","","pseudo"
		"JNC rel16","0F 83 cw","V","N.S.","","pseudo"
		"JNC rel32","0F 83 cd","V","V","","pseudo"
		"JNE rel16","0F 85 cw","V","N.S.","","operand16"
		"JNE rel32","0F 85 cd","V","V","","operand32"
		"JNG rel16","0F 8E cw","V","N.S.","","pseudo"
		"JNG rel32","0F 8E cd","V","V","","pseudo"
		"JNGE rel16","0F 8C cw","V","N.S.","","pseudo"
		"JNGE rel32","0F 8C cd","V","V","","pseudo"
		"JNL rel16","0F 8D cw","V","N.S.","","pseudo"
		"JNL rel32","0F 8D cd","V","V","","pseudo"
		"JNLE rel16","0F 8F cw","V","N.S.","","pseudo"
		"JNLE rel32","0F 8F cd","V","V","","pseudo"
		"JNO rel16","0F 81 cw","V","N.S.","","operand16"
		"JNO rel32","0F 81 cd","V","V","","operand32"
		"JNP rel16","0F 8B cw","V","N.S.","","operand16"
		"JNP rel32","0F 8B cd","V","V","","operand32"
		"JNS rel16","0F 89 cw","V","N.S.","","operand16"
		"JNS rel32","0F 89 cd","V","V","","operand32"
		"JNZ rel16","0F 85 cw","V","N.S.","","pseudo"
		"JNZ rel32","0F 85 cd","V","V","","pseudo"
		"JO rel16","0F 80 cw","V","N.S.","","operand16"
		"JO rel32","0F 80 cd","V","V","","operand32"
		"JP rel16","0F 8A cw","V","N.S.","","operand16"
		"JP rel32","0F 8A cd","V","V","","operand32"
		"JPE rel16","0F 8A cw","V","N.S.","","pseudo"
		"JPE rel32","0F 8A cd","V","V","","pseudo"
		"JPO rel16","0F 8B cw","V","N.S.","","pseudo"
		"JPO rel32","0F 8B cd","V","V","","pseudo"
		"JS rel16","0F 88 cw","V","N.S.","","operand16"
		"JS rel32","0F 88 cd","V","V","","operand32"
		"JA rel32","0F 87 cd","N.S.","V","","operand16,operand64"
		"JAE rel32","0F 83 cd","N.S.","V","","operand16,operand64"
		"JB rel32","0F 82 cd","N.S.","V","","operand16,operand64"
		"JBE rel32","0F 86 cd","N.S.","V","","operand16,operand64"
		"JE rel32","0F 84 cd","N.S.","V","","operand16,operand64"
		"JG rel32","0F 8F cd","N.S.","V","","operand16,operand64"
		"JGE rel32","0F 8D cd","N.S.","V","","operand16,operand64"
		"JL rel32","0F 8C cd","N.S.","V","","operand16,operand64"
		"JLE rel32","0F 8E cd","N.S.","V","","operand16,operand64"
		"JNE rel32","0F 85 cd","N.S.","V","","operand16,operand64"
		"JNO rel32","0F 81 cd","N.S.","V","","operand16,operand64"
		"JNP rel32","0F 8B cd","N.S.","V","","operand16,operand64"
		"JNS rel32","0F 89 cd","N.S.","V","","operand16,operand64"
		"JO rel32","0F 80 cd","N.S.","V","","operand16,operand64"
		"JP rel32","0F 8A cd","N.S.","V","","operand16,operand64"
		"JS rel32","0F 88 cd","N.S.","V","","operand16,operand64"
	`},
	// Pseudo-ops in floating point.
	{"362", `
		"FCOM m32fp","D8 /2","V","V","",""
		"FCOM m64fp","DC /2","V","V","",""
		"FCOM ST(i)","D8 D0+i","V","V","",""
		"FCOM","D8 D1","V","V","","pseudo"
		"FCOMP m32fp","D8 /3","V","V","",""
		"FCOMP m64fp","DC /3","V","V","",""
		"FCOMP ST(i)","D8 D8+i","V","V","",""
		"FCOMP","D8 D9","V","V","","pseudo"
		"FCOMPP","DE D9","V","V","",""
	`},
	{"358", `
		"FCLEX","9B DB E2","V","V","","pseudo"
		"FNCLEX","DB E2","V","V","",""
	`},
	// Unsigned immediates.
	{"340,", `
		"ENTER imm16u, 0","C8 iw 00","V","V","","pseudo"
		"ENTER imm16u, 1","C8 iw 01","V","V","","pseudo"
		"ENTER imm16u, imm8","C8 iw ib","V","V","",""
	`},
	// Rewriting of arguments to match encoding (xmm1 vs xmm2).
	{"785", `
		"PEXTRB r32/m8, xmm1, imm8","66 0F 3A 14 /r ib","V","V","SSE4_1",""
		"PEXTRD r/m32, xmm1, imm8","66 0F 3A 16 /r ib","V","V","SSE4_1","operand16,operand32"
		"PEXTRQ r/m64, xmm1, imm8","66 REX.W 0F 3A 16 /r ib","N.E.","V","SSE4_1",""
		"VPEXTRB r32/m8, xmm1, imm8","VEX.128.66.0F3A.W0 14 /r ib","V","V","AVX",""
		"VPEXTRD r32/m32, xmm1, imm8","VEX.128.66.0F3A.W0 16 /r ib","V","V","AVX",""
		"VPEXTRQ r64/m64, xmm1, imm8","VEX.128.66.0F3A.W1 16 /r ib","I","V","AVX",""
	`},
	{"843", `
		"PMOVMSKB r32, mm2","0F D7 /r","V","V","SSE",""
		"PMOVMSKB r32, xmm2","66 0F D7 /r","V","V","SSE2","modrm_regonly"
		"VPMOVMSKB r32, xmm2","VEX.128.66.0F.WIG D7 /r","V","V","AVX","modrm_regonly"
		"VPMOVMSKB r32, ymm2","VEX.256.66.0F.WIG D7 /r","V","V","AVX2","modrm_regonly"
	`},
	{"343", `
		"EXTRACTPS r/m32, xmm1, imm8","66 0F 3A 17 /r ib","V","V","SSE4_1",""
		"VEXTRACTPS r/m32, xmm1, imm8","VEX.128.66.0F3A.WIG 17 /r ib","V","V","AVX",""
	`},
	{"624", `
		"MOVHPS xmm1, m64","0F 16 /r","V","V","SSE","modrm_memonly"
		"MOVHPS m64, xmm1","0F 17 /r","V","V","SSE","modrm_memonly"
		"VMOVHPS xmm1, xmmV, m64","VEX.NDS.128.0F.WIG 16 /r","V","V","AVX","modrm_memonly"
		"VMOVHPS m64, xmm1","VEX.128.0F.WIG 17 /r","V","V","AVX","modrm_memonly"
	`},
	{"979", `
		"RDFSBASE rmr32","F3 0F AE /0","I","V","FSGSBASE","modrm_regonly,operand16,operand32"
		"RDFSBASE rmr64","F3 REX.W 0F AE /0","I","V","FSGSBASE","modrm_regonly"
		"RDGSBASE rmr32","F3 0F AE /1","I","V","FSGSBASE","modrm_regonly,operand16,operand32"
		"RDGSBASE rmr64","F3 REX.W 0F AE /1","I","V","FSGSBASE","modrm_regonly"
	`},
	{"988", `
		"RDRAND rmr16","0F C7 /6","V","V","RDRAND","modrm_regonly,operand16"
		"RDRAND rmr32","0F C7 /6","V","V","RDRAND","modrm_regonly,operand32"
		"RDRAND rmr64","REX.W 0F C7 /6","I","V","RDRAND","modrm_regonly"
	`},
	{"1135", `
		"VEXTRACTI128 xmm2/m128, ymm1, imm8","VEX.256.66.0F3A.W0 39 /r ib","V","V","AVX2",""
	`},
	{"1248", `
		"WRFSBASE rmr32","F3 0F AE /2","I","V","FSGSBASE","modrm_regonly,operand16,operand32"
		"WRFSBASE rmr64","F3 REX.W 0F AE /2","I","V","FSGSBASE","modrm_regonly"
		"WRGSBASE rmr32","F3 0F AE /3","I","V","FSGSBASE","modrm_regonly,operand16,operand32"
		"WRGSBASE rmr64","F3 REX.W 0F AE /3","I","V","FSGSBASE","modrm_regonly"
	`},
	{"1229", `
		"VPMASKMOVD xmm1, xmmV, m128","VEX.NDS.128.66.0F38.W0 8C /r","V","V","AVX2","modrm_memonly"
		"VPMASKMOVD ymm1, ymmV, m256","VEX.NDS.256.66.0F38.W0 8C /r","V","V","AVX2","modrm_memonly"
		"VPMASKMOVQ xmm1, xmmV, m128","VEX.NDS.128.66.0F38.W1 8C /r","V","V","AVX2","modrm_memonly"
		"VPMASKMOVQ ymm1, ymmV, m256","VEX.NDS.256.66.0F38.W1 8C /r","V","V","AVX2","modrm_memonly"
		"VPMASKMOVD m128, xmmV, xmm1","VEX.NDS.128.66.0F38.W0 8E /r","V","V","AVX2","modrm_memonly"
		"VPMASKMOVD m256, ymmV, ymm1","VEX.NDS.256.66.0F38.W0 8E /r","V","V","AVX2","modrm_memonly"
		"VPMASKMOVQ m128, xmmV, xmm1","VEX.NDS.128.66.0F38.W1 8E /r","V","V","AVX2","modrm_memonly"
		"VPMASKMOVQ m256, ymmV, ymm1","VEX.NDS.256.66.0F38.W1 8E /r","V","V","AVX2","modrm_memonly"
	`},
	{"537", `
		"LDDQU xmm1, m128","F2 0F F0 /r","V","V","SSE3","modrm_memonly"
		"VLDDQU xmm1, m128","VEX.128.F2.0F.WIG F0 /r","V","V","AVX","modrm_memonly"
		"VLDDQU ymm1, m256","VEX.256.F2.0F.WIG F0 /r","V","V","AVX","modrm_memonly"
	`},
	{"624,626", `
		"MOVHPS xmm1, m64","0F 16 /r","V","V","SSE","modrm_memonly"
		"MOVHPS m64, xmm1","0F 17 /r","V","V","SSE","modrm_memonly"
		"VMOVHPS xmm1, xmmV, m64","VEX.NDS.128.0F.WIG 16 /r","V","V","AVX","modrm_memonly"
		"VMOVHPS m64, xmm1","VEX.128.0F.WIG 17 /r","V","V","AVX","modrm_memonly"
		"MOVLHPS xmm1, xmm2","0F 16 /r","V","V","SSE","modrm_regonly"
		"VMOVLHPS xmm1, xmmV, xmm2","VEX.NDS.128.0F.WIG 16 /r","V","V","AVX","modrm_regonly"
	`},
	// CPU features
	{"758", `
		"PCLMULQDQ xmm1, xmm2/m128, imm8","66 0F 3A 44 /r ib","V","V","PCLMULQDQ",""
		"VPCLMULQDQ xmm1, xmmV, xmm2/m128, imm8","VEX.NDS.128.66.0F3A.WIG 44 /r ib","V","V","PCLMULQDQ+AVX",""
	`},
	// Fonts
	{"486", `
		"INC r/m8","FE /0","V","V","",""
		"INC r/m8","REX FE /0","N.E.","V","","pseudo64"
		"INC r/m16","FF /0","V","V","","operand16"
		"INC r/m32","FF /0","V","V","","operand32"
		"INC r/m64","REX.W FF /0","N.E.","V","",""
		"INC r16op","40+rw","V","N.E.","","operand16"
		"INC r32op","40+rd","V","N.E.","","operand32"
	`},
	// Intel manual has spurious trailing "m64" and "m128" in the opcode.
	{"238", `
		"CMPXCHG8B m64","0F C7 /1","V","V","","modrm_memonly,operand16,operand32"
		"CMPXCHG16B m128","REX.W 0F C7 /1","N.E.","V","","modrm_memonly"
	`},
	// Intel manual missing cw and cd in opcode.
	{"1260", `
		"XBEGIN rel16","C7 F8 cw","V","V","RTM","operand16"
		"XBEGIN rel32","C7 F8 cd","V","V","RTM","operand32,operand64"
	`},
	// Special cases
	{"180", `
		"CALL rel16","E8 cw","V","N.S.","","operand16"
		"CALL rel32","E8 cd","V","V","","operand32"
		"CALL r/m16","FF /2","V","N.E.","","operand16"
		"CALL r/m32","FF /2","V","N.E.","","operand32"
		"CALL r/m64","FF /2","N.E.","V","",""
		"CALL_FAR ptr16:16","9A cd","V","I","","operand16"
		"CALL_FAR ptr16:32","9A cp","V","I","","operand32"
		"CALL_FAR m16:16","FF /3","V","V","","operand16"
		"CALL_FAR m16:32","FF /3","V","V","","operand32"
		"CALL_FAR m16:64","REX.W FF /3","N.E.","V","",""
		"CALL rel32","E8 cd","N.S.","V","","operand16,operand64"
	`},
	{"525", `
		"JMP rel8","EB cb","V","V","",""
		"JMP rel16","E9 cw","V","N.S.","","operand16"
		"JMP rel32","E9 cd","V","V","","operand32"
		"JMP r/m16","FF /4","V","N.S.","","operand16"
		"JMP r/m32","FF /4","V","N.S.","","operand32"
		"JMP r/m64","FF /4","N.E.","V","",""
		"JMP_FAR ptr16:16","EA cd","V","I","","operand16"
		"JMP_FAR ptr16:32","EA cp","V","I","","operand32"
		"JMP_FAR m16:16","FF /5","V","V","","operand16"
		"JMP_FAR m16:32","FF /5","V","V","","operand32"
		"JMP_FAR m16:64","REX.W FF /5","N.E.","V","",""
		"JMP rel32","E9 cd","N.S.","V","","operand16,operand64"
	`},
	{"698", `
		"NOP","90","V","V","","pseudo"
		"NOP r/m16","0F 1F /0","V","V","","operand16"
		"NOP r/m32","0F 1F /0","V","V","","operand32"
	`},
	{"747", `
		"PAUSE","F3 90","V","V","","pseudo"
	`},
	{"1029,1030", `
		"SAL r/m8, 1","D0 /4","V","V","","pseudo"
		"SAL r/m8, 1","REX D0 /4","N.E.","V","","pseudo"
		"SAL r/m8, CL","D2 /4","V","V","","pseudo"
		"SAL r/m8, CL","REX D2 /4","N.E.","V","","pseudo"
		"SAL r/m8, imm8","C0 /4 ib","V","V","","pseudo"
		"SAL r/m8, imm8","REX C0 /4 ib","N.E.","V","","pseudo"
		"SAL r/m16, 1","D1 /4","V","V","","operand16,pseudo"
		"SAL r/m16, CL","D3 /4","V","V","","operand16,pseudo"
		"SAL r/m16, imm8","C1 /4 ib","V","V","","operand16,pseudo"
		"SAL r/m32, 1","D1 /4","V","V","","operand32,pseudo"
		"SAL r/m64, 1","REX.W D1 /4","N.E.","V","","pseudo"
		"SAL r/m32, CL","D3 /4","V","V","","operand32,pseudo"
		"SAL r/m64, CL","REX.W D3 /4","N.E.","V","","pseudo"
		"SAL r/m32, imm8","C1 /4 ib","V","V","","operand32,pseudo"
		"SAL r/m64, imm8","REX.W C1 /4 ib","N.E.","V","","pseudo"
		"SAR r/m8, 1","D0 /7","V","V","",""
		"SAR r/m8, 1","REX D0 /7","N.E.","V","","pseudo64"
		"SAR r/m8, CL","D2 /7","V","V","",""
		"SAR r/m8, CL","REX D2 /7","N.E.","V","","pseudo64"
		"SAR r/m8, imm8","C0 /7 ib","V","V","",""
		"SAR r/m8, imm8","REX C0 /7 ib","N.E.","V","","pseudo64"
		"SAR r/m16, 1","D1 /7","V","V","","operand16"
		"SAR r/m16, CL","D3 /7","V","V","","operand16"
		"SAR r/m16, imm8","C1 /7 ib","V","V","","operand16"
		"SAR r/m32, 1","D1 /7","V","V","","operand32"
		"SAR r/m64, 1","REX.W D1 /7","N.E.","V","",""
		"SAR r/m32, CL","D3 /7","V","V","","operand32"
		"SAR r/m64, CL","REX.W D3 /7","N.E.","V","",""
		"SAR r/m32, imm8","C1 /7 ib","V","V","","operand32"
		"SAR r/m64, imm8","REX.W C1 /7 ib","N.E.","V","",""
		"SHL r/m8, 1","D0 /4","V","V","",""
		"SHL r/m8, 1","REX D0 /4","N.E.","V","","pseudo64"
		"SHL r/m8, CL","D2 /4","V","V","",""
		"SHL r/m8, CL","REX D2 /4","N.E.","V","","pseudo64"
		"SHL r/m8, imm8","C0 /4 ib","V","V","",""
		"SHL r/m8, imm8","REX C0 /4 ib","N.E.","V","","pseudo64"
		"SHL r/m16, 1","D1 /4","V","V","","operand16"
		"SHL r/m16, CL","D3 /4","V","V","","operand16"
		"SHL r/m16, imm8","C1 /4 ib","V","V","","operand16"
		"SHL r/m32, 1","D1 /4","V","V","","operand32"
		"SHL r/m64, 1","REX.W D1 /4","N.E.","V","",""
		"SHL r/m32, CL","D3 /4","V","V","","operand32"
		"SHL r/m64, CL","REX.W D3 /4","N.E.","V","",""
		"SHL r/m32, imm8","C1 /4 ib","V","V","","operand32"
		"SHL r/m64, imm8","REX.W C1 /4 ib","N.E.","V","",""
		"SHR r/m8, 1","D0 /5","V","V","",""
		"SHR r/m8, 1","REX D0 /5","N.E.","V","","pseudo64"
		"SHR r/m8, CL","D2 /5","V","V","",""
		"SHR r/m8, CL","REX D2 /5","N.E.","V","","pseudo64"
		"SHR r/m8, imm8","C0 /5 ib","V","V","",""
		"SHR r/m8, imm8","REX C0 /5 ib","N.E.","V","","pseudo64"
		"SHR r/m16, 1","D1 /5","V","V","","operand16"
		"SHR r/m16, CL","D3 /5","V","V","","operand16"
		"SHR r/m16, imm8","C1 /5 ib","V","V","","operand16"
		"SHR r/m32, 1","D1 /5","V","V","","operand32"
		"SHR r/m64, 1","REX.W D1 /5","N.E.","V","",""
		"SHR r/m32, CL","D3 /5","V","V","","operand32"
		"SHR r/m64, CL","REX.W D3 /5","N.E.","V","",""
		"SHR r/m32, imm8","C1 /5 ib","V","V","","operand32"
		"SHR r/m64, imm8","REX.W C1 /5 ib","N.E.","V","",""
	`},
	{"564", `
		"LSL r16, r/m16","0F 03 /r","V","V","","operand16"
		"LSL r32, r32/m16","0F 03 /r","V","V","","operand32"
		"LSL r64, r32/m16","REX.W 0F 03 /r","N.E.","V","",""
	`},
	{"1000", `
		"RET","C3","V","V","",""
		"RET_FAR","CB","V","V","",""
		"RET imm16u","C2 iw","V","V","",""
		"RET_FAR imm16u","CA iw","V","V","",""
	`},
	{"1245", `
		"WAIT","9B","V","V","","pseudo"
		"FWAIT","9B","V","V","",""
	`},
	{"1263", `
		"XCHG AX, r16op","90+rw","V","V","","operand16,pseudo"
		"XCHG r16op, AX","90+rw","V","V","","operand16"
		"XCHG EAX, r32op","90+rd","V","V","","operand32,pseudo"
		"XCHG RAX, r64op","REX.W 90+rd","N.E.","V","","pseudo"
		"XCHG r32op, EAX","90+rd","V","V","","operand32"
		"XCHG r64op, RAX","REX.W 90+rd","N.E.","V","",""
		"XCHG r/m8, r8","86 /r","V","V","",""
		"XCHG r/m8, r8","REX 86 /r","N.E.","V","","pseudo64"
		"XCHG r8, r/m8","86 /r","V","V","","pseudo"
		"XCHG r8, r/m8","REX 86 /r","N.E.","V","","pseudo"
		"XCHG r/m16, r16","87 /r","V","V","","operand16"
		"XCHG r16, r/m16","87 /r","V","V","","operand16,pseudo"
		"XCHG r/m32, r32","87 /r","V","V","","operand32"
		"XCHG r/m64, r64","REX.W 87 /r","N.E.","V","",""
		"XCHG r32, r/m32","87 /r","V","V","","operand32,pseudo"
		"XCHG r64, r/m64","REX.W 87 /r","N.E.","V","","pseudo"
	`},
	{"1063", `
		"SLDT r/m16","0F 00 /0","V","V","","operand16"
		"SLDT r64/m16","REX.W 0F 00 /0","N.E.","V","",""
		"SLDT r32/m16","0F 00 /0","V","V","","operand32"
	`},
	{"1065", `
		"SMSW r/m16","0F 01 /4","V","V","","operand16"
		"SMSW r32/m16","0F 01 /4","V","V","","operand32"
		"SMSW r64/m16","REX.W 0F 01 /4","N.E.","V","",""
	`},
	{"1083", `
		"STR r/m16","0F 00 /1","V","V","","operand16"
		"STR r32/m16","0F 00 /1","V","V","","operand32"
		"STR r64/m16","REX.W 0F 00 /1","N.E.","V","",""
	`},
	{"533,1027", `
		"LAHF","9F","V","V","",""
		"SAHF","9E","V","V","",""
	`},
	{"662", `
		"MOVSX r16, r/m8","0F BE /r","V","V","","operand16"
		"MOVSX r32, r/m8","0F BE /r","V","V","","operand32"
		"MOVSX r64, r/m8","REX.W 0F BE /r","N.E.","V","",""
		"MOVSX r32, r/m16","0F BF /r","V","V","","operand32"
		"MOVSX r64, r/m16","REX.W 0F BF /r","N.E.","V","",""
		"MOVSXD r64, r/m32","REX.W 63 /r","N.E.","V","",""
		"MOVSX r16, r/m16","0F BF /r","V","V","","operand16"
		"MOVSXD r16, r/m32","63 /r","N.E.","V","","operand16"
		"MOVSXD r32, r/m32","63 /r","N.E.","V","","operand32"
	`},
	{"668", `
		"MOVZX r16, r/m8","0F B6 /r","V","V","","operand16"
		"MOVZX r32, r/m8","0F B6 /r","V","V","","operand32"
		"MOVZX r64, r/m8","REX.W 0F B6 /r","N.E.","V","",""
		"MOVZX r32, r/m16","0F B7 /r","V","V","","operand32"
		"MOVZX r64, r/m16","REX.W 0F B7 /r","N.E.","V","",""
		"MOVZX r16, r/m16","0F B7 /r","V","V","","operand16"
	`},
	{"1253,1260", `
		"XACQUIRE","F2","V","V","HLE","pseudo"
		"XRELEASE","F3","V","V","HLE","pseudo"
		"XBEGIN rel16","C7 F8 cw","V","V","RTM","operand16"
		"XBEGIN rel32","C7 F8 cd","V","V","RTM","operand32,operand64"
	`},
	{"547", `
		"LEAVE","C9","V","V","","operand16"
		"LEAVE","C9","V","N.E.","","operand32"
		"LEAVE","C9","N.E.","V","","operand32,operand64"
	`},
	{"484", `
		"IN AL, imm8u","E4 ib","V","V","",""
		"IN AX, imm8u","E5 ib","V","V","","operand16"
		"IN EAX, imm8u","E5 ib","V","V","","operand32,operand64"
		"IN AL, DX","EC","V","V","",""
		"IN AX, DX","ED","V","V","","operand16"
		"IN EAX, DX","ED","V","V","","operand32,operand64"
	`},
	{"488", `
		"INSB","6C","V","V","",""
		"INSW","6D","V","V","","operand16"
		"INSD","6D","V","V","","operand32,operand64"
	`},
	{"707", `
		"OUT imm8u, AL","E6 ib","V","V","",""
		"OUT imm8u, AX","E7 ib","V","V","","operand16"
		"OUT imm8u, EAX","E7 ib","V","V","","operand32,operand64"
		"OUT DX, AL","EE","V","V","",""
		"OUT DX, AX","EF","V","V","","operand16"
		"OUT DX, EAX","EF","V","V","","operand32,operand64"
	`},
	{"709", `
		"OUTSB","6E","V","V","",""
		"OUTSW","6F","V","V","","operand16"
		"OUTSD","6F","V","V","","operand32,operand64"
	`},
	{"881,966", `
		"POPF","9D","V","V","","operand16"
		"POPFD","9D","V","N.E.","","operand32"
		"POPFQ","9D","N.E.","V","","operand32,operand64"
		"PUSHF","9C","V","V","","operand16"
		"PUSHFD","9C","V","N.E.","","operand32"
		"PUSHFQ","9C","N.E.","V","","operand32,operand64"
	`},
	{"610", `
		"MOVD mm1, r/m32","0F 6E /r","V","V","MMX","operand16,operand32"
		"MOVQ mm1, r/m64","REX.W 0F 6E /r","N.E.","V","MMX",""
		"MOVD r/m32, mm1","0F 7E /r","V","V","MMX","operand16,operand32"
		"MOVQ r/m64, mm1","REX.W 0F 7E /r","N.E.","V","MMX",""
		"VMOVD xmm1, r32/m32","VEX.128.66.0F.W0 6E /r","V","V","AVX",""
		"VMOVQ xmm1, r64/m64","VEX.128.66.0F.W1 6E /r","N.E.","V","AVX",""
		"MOVD xmm1, r/m32","66 0F 6E /r","V","V","SSE2","operand16,operand32"
		"MOVQ xmm1, r/m64","66 REX.W 0F 6E /r","N.E.","V","SSE2",""
		"MOVD r/m32, xmm1","66 0F 7E /r","V","V","SSE2","operand16,operand32"
		"MOVQ r/m64, xmm1","66 REX.W 0F 7E /r","N.E.","V","SSE2",""
		"VMOVD r32/m32, xmm1","VEX.128.66.0F.W0 7E /r","V","V","AVX",""
		"VMOVQ r64/m64, xmm1","VEX.128.66.0F.W1 7E /r","N.E.","V","AVX",""
	`},
	{"534", `
		"LAR r16, r/m16","0F 02 /r","V","V","","operand16"
		"LAR r32, r32/m16","0F 02 /r","V","V","","operand32"
		"LAR r64, r64/m16","REX.W 0F 02 /r","N.E.","V","",""
	`},
	{"360", `
		"FCMOVB ST(0), ST(i)","DA C0+i","V","V","",""
		"FCMOVE ST(0), ST(i)","DA C8+i","V","V","",""
		"FCMOVBE ST(0), ST(i)","DA D0+i","V","V","",""
		"FCMOVU ST(0), ST(i)","DA D8+i","V","V","",""
		"FCMOVNB ST(0), ST(i)","DB C0+i","V","V","",""
		"FCMOVNE ST(0), ST(i)","DB C8+i","V","V","",""
		"FCMOVNBE ST(0), ST(i)","DB D0+i","V","V","",""
		"FCMOVNU ST(0), ST(i)","DB D8+i","V","V","",""
	`},
	{"413", `
		"FSAVE m94/108byte","9B DD /6","V","V","","pseudo"
		"FNSAVE m94/108byte","DD /6","V","V","",""
	`},
	{"446,449", `
		"FXRSTOR m512byte","0F AE /1","V","V","","operand16,operand32"
		"FXRSTOR64 m512byte","REX.W 0F AE /1","N.E.","V","",""
		"FXSAVE m512byte","0F AE /0","V","V","","operand16,operand32"
		"FXSAVE64 m512byte","REX.W 0F AE /0","N.E.","V","",""
	`},
	// The way extra instructions are inserted, the MOV TR and MOV Sreg extra instructions
	// appear in every test of a page containing MOV instructions.
	// So be it: we definitely won't lose them!
	{"594,595", `
		"MOV r/m8, r8","88 /r","V","V","",""
		"MOV r/m8, r8","REX 88 /r","N.E.","V","","pseudo64"
		"MOV r/m16, r16","89 /r","V","V","","operand16"
		"MOV r/m32, r32","89 /r","V","V","","operand32"
		"MOV r/m64, r64","REX.W 89 /r","N.E.","V","",""
		"MOV r8, r/m8","8A /r","V","V","",""
		"MOV r8, r/m8","REX 8A /r","N.E.","V","","pseudo64"
		"MOV r16, r/m16","8B /r","V","V","","operand16"
		"MOV r32, r/m32","8B /r","V","V","","operand32"
		"MOV r64, r/m64","REX.W 8B /r","N.E.","V","",""
		"MOV r/m16, Sreg","8C /r","V","V","","operand16"
		"MOV r/m64, Sreg","REX.W 8C /r","N.E.","V","",""
		"MOV Sreg, r/m16","8E /r","V","V","","operand16"
		"MOV Sreg, r64/m16","REX.W 8E /r","N.E.","V","",""
		"MOV AL, moffs8","A0 cm","V","V","","ignoreREXW"
		"MOV AL, moffs8","REX.W A0 cm","N.E.","V","","pseudo"
		"MOV AX, moffs16","A1 cm","V","V","","operand16"
		"MOV EAX, moffs32","A1 cm","V","V","","operand32"
		"MOV RAX, moffs64","REX.W A1 cm","N.E.","V","",""
		"MOV moffs8, AL","A2 cm","V","V","","ignoreREXW"
		"MOV moffs8, AL","REX.W A2 cm","N.E.","V","","pseudo"
		"MOV moffs16, AX","A3 cm","V","V","","operand16"
		"MOV moffs32, EAX","A3 cm","V","V","","operand32"
		"MOV moffs64, RAX","REX.W A3 cm","N.E.","V","",""
		"MOV r8op, imm8u","B0+rb ib","V","V","",""
		"MOV r8op, imm8u","REX B0+rb ib","N.E.","V","","pseudo64"
		"MOV r16op, imm16","B8+rw iw","V","V","","operand16"
		"MOV r32op, imm32","B8+rd id","V","V","","operand32"
		"MOV r64op, imm64","REX.W B8+rd io","N.E.","V","",""
		"MOV r/m8, imm8u","C6 /0 ib","V","V","",""
		"MOV r/m8, imm8u","REX C6 /0 ib","N.E.","V","","pseudo64"
		"MOV r/m16, imm16","C7 /0 iw","V","V","","operand16"
		"MOV r/m32, imm32","C7 /0 id","V","V","","operand32"
		"MOV r/m64, imm32","REX.W C7 /0 id","N.E.","V","",""
		"MOV TR0-TR7, rmr32","0F 26 /r","V","N.E.","","modrm_regonly"
		"MOV TR0-TR7, rmr64","0F 26 /r","N.E.","V","","modrm_regonly"
		"MOV rmr32, TR0-TR7","0F 24 /r","V","N.E.","","modrm_regonly"
		"MOV rmr64, TR0-TR7","0F 24 /r","N.E.","V","","modrm_regonly"
		"MOV Sreg, r32/m16","8E /r","V","V","","operand32"
		"MOV r/m32, Sreg","8C /r","V","V","","operand32"
	`},
	{"599", `
		"MOV rmr32, CR0-CR7","0F 20 /r","V","N.E.","","modrm_regonly"
		"MOV rmr64, CR0-CR7","0F 20 /r","N.E.","V","","modrm_regonly"
		"MOV rmr64, CR8","REX.R + 0F 20 /0","N.E.","V","","modrm_regonly,pseudo"
		"MOV CR0-CR7, rmr32","0F 22 /r","V","N.E.","","modrm_regonly"
		"MOV CR0-CR7, rmr64","0F 22 /r","N.E.","V","","modrm_regonly"
		"MOV CR8, rmr64","REX.R + 0F 22 /0","N.E.","V","","modrm_regonly,pseudo"
		"MOV TR0-TR7, rmr32","0F 26 /r","V","N.E.","","modrm_regonly"
		"MOV TR0-TR7, rmr64","0F 26 /r","N.E.","V","","modrm_regonly"
		"MOV rmr32, TR0-TR7","0F 24 /r","V","N.E.","","modrm_regonly"
		"MOV rmr64, TR0-TR7","0F 24 /r","N.E.","V","","modrm_regonly"
		"MOV Sreg, r32/m16","8E /r","V","V","","operand32"
		"MOV r/m32, Sreg","8C /r","V","V","","operand32"
	`},
	{"602", `
		"MOV rmr32, DR0-DR7","0F 21 /r","V","N.E.","","modrm_regonly"
		"MOV rmr64, DR0-DR7","0F 21 /r","N.E.","V","","modrm_regonly"
		"MOV DR0-DR7, rmr32","0F 23 /r","V","N.E.","","modrm_regonly"
		"MOV DR0-DR7, rmr64","0F 23 /r","N.E.","V","","modrm_regonly"
		"MOV TR0-TR7, rmr32","0F 26 /r","V","N.E.","","modrm_regonly"
		"MOV TR0-TR7, rmr64","0F 26 /r","N.E.","V","","modrm_regonly"
		"MOV rmr32, TR0-TR7","0F 24 /r","V","N.E.","","modrm_regonly"
		"MOV rmr64, TR0-TR7","0F 24 /r","N.E.","V","","modrm_regonly"
		"MOV Sreg, r32/m16","8E /r","V","V","","operand32"
		"MOV r/m32, Sreg","8C /r","V","V","","operand32"
	`},
	{"148,150,155,157,160", `
		"BNDCL bnd1, r/m32","F3 0F 1A /r","V","N.E.","MPX",""
		"BNDCL bnd1, r/m64","F3 0F 1A /r","N.E.","V","MPX",""
		"BNDCU bnd1, r/m32","F2 0F 1A /r","V","N.E.","MPX",""
		"BNDCU bnd1, r/m64","F2 0F 1A /r","N.E.","V","MPX",""
		"BNDCN bnd1, r/m32","F2 0F 1B /r","V","N.E.","MPX",""
		"BNDCN bnd1, r/m64","F2 0F 1B /r","N.E.","V","MPX",""
		"BNDMK bnd1, m32","F3 0F 1B /r","V","N.E.","MPX","modrm_memonly"
		"BNDMK bnd1, m64","F3 0F 1B /r","N.E.","V","MPX","modrm_memonly"
		"BNDMOV bnd1, bnd2/m64","66 0F 1A /r","V","N.E.","MPX",""
		"BNDMOV bnd1, bnd2/m128","66 0F 1A /r","N.E.","V","MPX",""
		"BNDMOV bnd2/m64, bnd1","66 0F 1B /r","V","N.E.","MPX",""
		"BNDMOV bnd2/m128, bnd1","66 0F 1B /r","N.E.","V","MPX",""
		"BNDSTX mib, bnd1","0F 1B /r","V","V","MPX",""
	`},
	{"169", `
		"BSWAP r32op","0F C8+rd","V","V","","operand32"
		"BSWAP r64op","REX.W 0F C8+rd","N.E.","V","",""
		"BSWAP r16op","0F C8+rd","V","V","","operand16"
	`},
	{"296,300", `
		"CVTSD2SI r32, xmm2/m64","F2 0F 2D /r","V","V","SSE2","operand16,operand32"
		"CVTSD2SI r64, xmm2/m64","F2 REX.W 0F 2D /r","N.E.","V","SSE2",""
		"VCVTSD2SI r32, xmm2/m64","VEX.LIG.F2.0F.W0 2D /r","V","V","AVX",""
		"VCVTSD2SI r64, xmm2/m64","VEX.LIG.F2.0F.W1 2D /r","N.E.","V","AVX",""
		"CVTSI2SD xmm1, r/m32","F2 0F 2A /r","V","V","SSE2","operand16,operand32"
		"CVTSI2SD xmm1, r/m64","F2 REX.W 0F 2A /r","N.E.","V","SSE2",""
		"VCVTSI2SD xmm1, xmmV, r/m32","VEX.NDS.LIG.F2.0F.W0 2A /r","V","V","AVX",""
		"VCVTSI2SD xmm1, xmmV, r/m64","VEX.NDS.LIG.F2.0F.W1 2A /r","N.E.","V","AVX",""
	`},
	{"686", `
		"MULX r32, r32V, r/m32","VEX.NDD.LZ.F2.0F38.W0 F6 /r","V","V","BMI2",""
		"MULX r64, r64V, r/m64","VEX.NDD.LZ.F2.0F38.W1 F6 /r","N.E.","V","BMI2",""
	`},
}

func TestOutput(t *testing.T) {
	if _, err := os.Stat(*flagFile); os.IsNotExist(err) {
		t.Skipf("no x86manual: %v", err)
	}

	for _, tt := range tests {
		*flagDebugPage = tt.pages
		onlySomePages = true
		insts := parse()
		insts = cleanup(insts)
		out := new(bytes.Buffer)
		write(out, insts)
		have := out.String()
		want := reformat(tt.output)
		if have != want {
			t.Errorf("p.%v: incorrect output\nhave:\n%s\nwant:\n%s\ndiffs:\n%s", tt.pages, strings.TrimRight(have, "\n"), strings.TrimRight(want, "\n"), strings.TrimRight(diffs(have, want), "\n"))
		}
	}
}

func indent(s string) string {
	s = strings.TrimRight(s, "\n")
	return strings.Join(strings.Split(s, "\n"), "\n\t")
}

func reformat(s string) string {
	var out string
	for _, line := range strings.Split(s, "\n") {
		line = strings.TrimSpace(line)
		if line != "" {
			out += line + "\n"
		}
	}
	return out
}

func diffs(have, want string) string {
	old := strings.Split(strings.TrimRight(want, "\n"), "\n")
	new := strings.Split(strings.TrimRight(have, "\n"), "\n")

	sort.Strings(old)
	sort.Strings(new)

	var buf bytes.Buffer
	for len(old) > 0 || len(new) > 0 {
		switch {
		case len(new) == 0 || len(old) > 0 && old[0] < new[0]:
			fmt.Fprintf(&buf, "- %s\n", old[0])
			old = old[1:]
		case len(old) == 0 || len(new) > 0 && old[0] > new[0]:
			fmt.Fprintf(&buf, "+ %s\n", new[0])
			new = new[1:]
		default:
			old = old[1:]
			new = new[1:]
		}
	}
	return buf.String()
}
