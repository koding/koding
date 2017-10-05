// Copyright 2017 The Go Authors.  All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Package x86csv provides means to work with "x86.csv".
// Only latest version of "x86.csv" format is supported.
//
// Terminology:
//   given "OPCODE [ARGS...]" line;
// Opcode - instruction name/mnemonic/class.
// Args   - instruction operands.
// Syntax - Opcode with Args.
package x86csv

import (
	"strings"
)

// An Inst describes single x86 instruction encoding form.
type Inst struct {
	// Intel syntax (example: "SHR r/m32, imm8").
	Intel string

	// Go assembler syntax (example: "SHRL imm8, r/m32").
	Go string

	// GNU binutils syntax (example: "shrl imm8, r/m32").
	GNU string

	// Binary encoding (example: "C1 /4 ib").
	Encoding string

	// Validity in 32bit mode ("V", "I" or "N.E.").
	Mode32 string

	// Validity in 64bit mode ("V", "I", "N.E.", "N.P.", "N.I." or "N.S.").
	Mode64 string

	// CPUID feature flags required (comma-separated).
	CPUID string

	// Hints about instruction (comma-separated).
	// See "x86spec" package to see detailed overview of possible
	// tags and their meaning.
	Tags string

	// Read/write action of the instruction on its arguments, in Intel order.
	// For example, "rw,r" denotes that "SHR r/m32, imm8" reads and writes
	// its first argument but only reads its second argument.
	Action string

	// Whether Intel syntax has encoding forms distinguished only by
	// operand size, like most arithmetic instructions ("" or "Y").
	Multisize string

	// Size of the data operation in bits ("8" for MOVB, "16" for MOVW, and so on)
	Size string
}

// IntelOpcode returns the opcode in the Intel syntax.
func (inst *Inst) IntelOpcode() string { return instOpcode(inst.Intel) }

// GoOpcode returns the opcode in Go (Plan9) syntax.
func (inst *Inst) GoOpcode() string { return instOpcode(inst.Go) }

// GNUOpcode returns the opcode in GNU binutils (mostly AT&T) syntax.
func (inst *Inst) GNUOpcode() string { return instOpcode(inst.GNU) }

// IntelArgs returns the arguments in the Intel syntax.
func (inst *Inst) IntelArgs() []string { return instArgs(inst.Intel) }

// GoArgs returns the arguments in Go (Plan9) syntax.
func (inst *Inst) GoArgs() []string { return instArgs(inst.Go) }

// GNUArgs returns the arguments in GNU binutils (mostly AT&T) syntax.
func (inst *Inst) GNUArgs() []string { return instArgs(inst.GNU) }

// instOpcode returns the opcode from an instruction syntax.
func instOpcode(syntax string) string {
	i := strings.Index(syntax, " ")
	if i == -1 {
		return syntax
	}
	return syntax[:i]
}

// instArgs returns the arguments from an instruction syntax.
func instArgs(syntax string) []string {
	i := strings.Index(syntax, " ")
	if i < 0 {
		return nil
	}
	args := strings.Split(syntax[i+1:], ",")
	for i := range args {
		args[i] = strings.TrimSpace(args[i])
	}
	return args
}
