// Copyright 2016 The Go Authors.  All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// X86spec reads the ``Intel® 64 and IA-32 Architectures Software Developer's Manual''
// to collect instruction encoding details and writes those details to standard output
// in CSV format.
//
// Usage:
//
//	x86spec [-f file] [-u url] >x86.csv
//
// The -f flag specifies the input file (default x86manual.pdf), the Intel instruction
// set reference manual in PDF form.
// If the input file does not exist, it will be created by downloading the manual.
//
// The -u flag specifies the URL from which to download the manual
// (default https://golang.org/s/x86manual, which redirects to Intel's site).
// The URL is downloaded only when the file named by the -f flag is missing.
//
// There are additional debugging flags, not shown. Run x86spec -help for the list.
//
// File Format
//
// TODO: Mention comments at top of file.
// TODO: Mention that this is version 0.2 of the file.
// TODO: Mention that file format will change incompatibly until version 1.0.
//
// Each CSV line contains these fields:
//
// 1. The Intel manual instruction mnemonic. For example, "SHR r/m32, imm8".
//
// 2. The Go assembler instruction mnemonic. For example, "SHRL imm8, r/m32".
//
// 3. The GNU binutils instruction mnemonic. For example, "shrl imm8, r/m32".
//
// 4. The instruction encoding. For example, "C1 /4 ib".
//
// 5. The validity of the instruction in 32-bit (aka compatiblity, legacy) mode.
//
// 6. The validity of the instruction in 64-bit mode.
//
// 7. The CPUID feature flags that signal support for the instruction.
//
// 8. Additional comma-separated tags containing hints about the instruction.
//
// 9. The read/write actions of the instruction on the arguments used in
// the Intel mnemonic. For example, "rw,r" to denote that "SHR r/m32, imm8"
// reads and writes its first argument but only reads its second argument.
//
// 10. Whether the opcode used in the Intel mnemonic has encoding forms
// distinguished only by operand size, like most arithmetic instructions.
// The string "Y" indicates yes, the string "" indicates no.
//
// 11. The data size of the operation in bits. In general this is the size corresponding
// to the Go and GNU assembler opcode suffix.
//
// The complete line used for the above examples is:
//
//	"SHR r/m32, imm8","SHRL imm8, r/m32","shrl imm8, r/m32","C1 /5 ib","V","V","","operand32","rw,r","Y","32"
//
// Mnemonics
//
// The instruction mnemonics are as used in the Intel manual, with a few exceptions.
//
// Mnemonics claiming general memory forms but that really require fixed addressing modes
// are omitted in favor of their equivalents with implicit arguments..
// For example, "CMPS m16, m16" (really CMPS [SI], [DI]) is omitted in favor of "CMPSW".
//
// Instruction forms with an explicit REP, REPE, or REPNE prefix are also omitted.
// Encoders and decoders are expected to handle those prefixes separately.
//
// Perhaps most significantly, the argument syntaxes used in the mnemonic indicate
// exactly how to derive the argument from the instruction encoding, or vice versa.
//
// Immediate values: imm8, imm8u, imm16, imm16u, imm32, imm64.
// Immediates are signed by default; the u suffixes indicates an unsigned value.
//
// Memory operands. The forms m, m128, m14/28byte, m16, m16&16, m16&32, m16&64, m16:16, m16:32,
// m16:64, m16int, m256, m2byte, m32, m32&32, m32fp, m32int, m512byte, m64, m64fp, m64int,
// m8, m80bcd, m80dec, m80fp, m94/108byte. These operands always correspond to the
// memory address specified by the r/m half of the modrm encoding.
//
// Integer registers.
// The forms r8, r16, r32, r64 indicate a register selected by the modrm reg encoding.
// The forms rmr16, rmr32, rmr64 indicate a register (never memory) selected by the modrm r/m encoding.
// The forms r/m8, r/m16, r/m32, and r/m64 indicate a register or memory selected by the modrm r/m encoding.
// Forms with two sizes, like r32/m16 also indicate a register or memory selected by the modrm r/m encodng,
// but the size for a register argument differs from the size of a memory argument.
// The forms r8V, r16V, r32V, r64V indicate a register selected by the VEX.vvvv bits.
//
// Multimedia registers.
// The forms mm1, xmm1, and ymm1 indicate a multimedia register selected by the
// modrm reg encoding.
// The forms mm2, xmm2, and ymm2 indicate a register (never memory) selected by
// the modrm r/m encoding.
// The forms mm2/m64, xmm2/m128, and so on indicate a register or memory
// selected by the modrm r/m encoding.
// The forms xmmV and ymmV indicate a register selected by the VEX.vvvv bits.
// The forms xmmI and ymmI indicate a register selected by the top four bits of an /is4 immediate byte.
//
// Bound registers.
// The form bnd1 indicate a  bound register selected by the modrm reg encoding.
// The form bnd2 indicates a bound register (never memory) selected by the modrm r/m encoding.
// The forms bnd2/m64 and bnd2/m128 indicate a register or memorys selected by the modrm r/m encoding.
// TODO: Describe mib.
//
// One-of-a-kind operands: rel8, rel16, rel32, ptr16:16, ptr16:32,
// moffs8, moffs16, moffs32, moffs64, vm32x, vm32y, vm64x, and vm64y
// are all as in the Intel manual.
//
// Encodings
//
// The encodings are also as used in the Intel manual, with automated corrections.
// For example, the Intel manual sometimes omits the modrm /r indicator or other trailing bytes,
// and it also contains typographical errors.
// These problems are corrected so that the CSV data may be used to generate
// tools for processing x86 machine code.
// See https://golang.org/x/arch/x86/x86map for one such generator.
//
// Valid32 and Valid64
//
// These columns hold validity abbreviations as defined in the Intel manual:
// V, I, N.E., N.P., N.S., or N.I.
// Tools processing the data are typically only concerned with whether the
// column is "V" (valid) or not.
// This data is also corrected compared to the manual.
// For example, the manual lists many instruction forms using REX bytes
// with an incorrect "V" in the Valid32 column.
//
// CPUID Feature Flags
//
// This column specifies CPUID feature flags that must be present in order
// to use the instruction. If multiple flags are required,
// they are listed separated by plus signs, as in PCLMULQDQ+AVX.
// The column can also list one of the values 486, Pentium, PentiumII, and P6,
// indicating that the instruction was introduced on that architecture version.
//
// Tags
//
// The tag column does not correspond to a traditional column in the Intel manual tables.
// Instead, it is itself a comma-separated list of tags or hints derived by analysis
// of the instruction set or the instruction encodings.
//
// The tags address16, address32, and address64 indicate that the instruction form
// applies when using the specified addressing size. It may therefore be necessary to use an
// address size prefix byte to access the instruction.
// If two address tags are listed, the instruction can be used with either of those
// address sizes. An instruction will never list all three address sizes.
// (In fact, today, no instruction lists two address sizes, but that may change.)
//
// The tags operand16, operand32, and operand64 indicate that the instruction form
// applies when using the specified operand size. It may therefore be necessary to use an
// operand size prefix byte to access the instruction.
// If two operand tags are listed,  the instruction can be used with either of those
// operand sizes. An instruction will never list all three operand sizes.
//
// The tags modrm_regonly or modrm_memonly indicate that the modrm byte's
// r/m encoding must specify a register or memory, respectively.
// Especially in newer instructions, the modrm constraint may be the only way
// to distinguish two instruction forms. For example the MOVHLPS and MOVLPS
// instructions share the same encoding, except that the former requires the
// modrm byte's r/m to indicate a register, while the latter requires it to indicate memory.
//
// The tags pseudo and pseudo64 indicate that this instruction form is redundant
// with others listed in the table and should be ignored when generating disassembly
// or instruction scanning programs. The pseudo64 tag is reserved for the case where
// the manual lists an instruction twice, once with the optional 64-bit mode REX byte.
// Since most decoders will handle the REX byte separately, the form with the
// unnecessary REX is tagged pseudo64.
//
// Corrections and Additions
//
// The x86spec program makes various corrections to the Intel manual data
// as part of extracting the information. Those corrections are described above.
//
// The x86spec program also adds a few well-known undocumented instructions,
// such as UD1 and FFREEP.
//
// Examples
//
// The latest version of the CSV file is available in this Git repository and also
// online at https://golang.org/s/x86.csv. It is meant to be human-readable for
// quick reference and also to be input for generating tools that operate on
// x86 machine code.
//
// To print instruction syntaxes introduced by the Pentium II and P6,
// using https://rsc.io/csv2tsv to prepare the table for processing by awk:
//
//	csv2tsv x86.csv | awk -F'\t' '$5 == "PentiumII" || $5 == "P6" { print $1 }'
//
// The x86map program (https://golang.org/x/arch/x86/x86map)
// reads the CSV file and generates an x86 instruction decoder in the form
// of a simple byte-code program. This decoder is the core of the disassembler
// in the x86asm package (https://golang.org/x/arch/x86/x86asm).
//
package main

import (
	"bufio"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"sort"
	"strings"
)

const (
	specFormatVersion = "0.2"
)

var (
	flagDebugPage = flag.String("debugpage", "", "debug page `n` of the manual (can be comma-separated list)")
	flagURL       = flag.String("u", "https://golang.org/s/x86manual", "use `url` for download if needed")
	flagFile      = flag.String("f", "x86manual.pdf", "read manual from `file`, downloading if necessary")
	flagCompat    = flag.Bool("compat", false, "print compatibility statements")

	debugging     bool
	onlySomePages bool
)

type instruction struct {
	page      int
	opcode    string
	syntax    string
	valid64   string
	valid32   string
	cpuid     string
	desc      string
	tags      []string
	args      []string
	seq       int // for use by cleanup
	compat    string
	action    string
	multisize string
	datasize  int
	gnuSyntax string
	goSyntax  string
}

func main() {
	log.SetFlags(0)
	log.SetPrefix("x86spec: ")
	flags()
	download()
	insts := parse()
	insts = cleanup(insts)
	format(insts)
	sort.Sort(bySyntax(insts))
	write(os.Stdout, insts)
}

func flags() {
	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "usage: x86spec [options]\n")
		flag.PrintDefaults()
		os.Exit(2)
	}
	flag.Parse()
	if flag.NArg() != 0 {
		flag.Usage()
	}
	debugging = *flagDebugPage != ""
	onlySomePages = *flagDebugPage != ""
}

func download() {
	_, err := os.Stat(*flagFile)
	if !os.IsNotExist(err) {
		return
	}

	// Try downloading.
	log.Printf("downloading manual to %s", *flagFile)
	resp, err := http.Get(*flagURL)
	if err != nil {
		log.Fatal(err)
	}
	if resp.StatusCode != 200 {
		log.Fatal(resp.Status)
	}
	f, err := os.Create(*flagFile)
	if err != nil {
		log.Fatal(err)
	}
	_, err = io.Copy(f, resp.Body)
	if err != nil {
		log.Fatal(err)
	}
	if err := f.Close(); err != nil {
		log.Fatal(err)
	}
}

func write(w io.Writer, insts []*instruction) {
	bw := bufio.NewWriter(w)
	defer bw.Flush()
	for _, inst := range insts {
		datasize := ""
		if inst.datasize != 0 {
			datasize = fmt.Sprint(inst.datasize)
		}
		writeCSV(bw, inst.syntax, inst.goSyntax, inst.gnuSyntax, inst.opcode, inst.valid32, inst.valid64, inst.cpuid, strings.Join(inst.tags, ","), inst.action, inst.multisize, datasize)
	}
}

// Note: not using encoding/csv because we want the CSV to use quotes always,
// so that it is a little easier to process with non-CSV tools like grep,
// but the encoding/csv package does not have an "always quote" writing mode.
func writeCSV(w io.Writer, args ...string) {
	for i, arg := range args {
		if i > 0 {
			fmt.Fprintf(w, ",")
		}
		fmt.Fprintf(w, `"%s"`, strings.Replace(arg, `"`, `""`, -1))
	}
	fmt.Fprintf(w, "\n")
}
