// Copyright 2017 The Go Authors.  All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package x86csv

import (
	"reflect"
	"strings"
	"testing"
)

// This test makes it harder to break Reader unintentionally.
//
// Deeper testing is probably not required because 99% of the job is
// done by csv.Reader.
func TestReader(t *testing.T) {
	input := `# x86.csv v0.2
"ADDSUBPD xmm1, xmm2/m128","ADDSUBPD xmm2/m128, xmm1","addsubpd xmm2/m128, xmm1","66 0F D0 /r","V","V","SSE3","","rw,r","",""
"VPEXTRQ r/m64, xmm1, imm8","VPEXTRQ imm8, xmm1, r/m64","vpextrq imm8, xmm1, r/m64","VEX.128.66.0F3A.W1 16 /r ib","I","V","AVX","","w,r,r","",""
"XOR r8, r/m8","XORB r/m8, r8","xorb r/m8, r8","REX 32 /r","N.E.","V","","pseudo64","rw,r","Y","8"
`
	want := []Inst{
		{
			Intel:    "ADDSUBPD xmm1, xmm2/m128",
			Go:       "ADDSUBPD xmm2/m128, xmm1",
			GNU:      "addsubpd xmm2/m128, xmm1",
			Encoding: "66 0F D0 /r",
			Mode32:   "V",
			Mode64:   "V",
			CPUID:    "SSE3",
			Action:   "rw,r",
		},
		{
			Intel:    "VPEXTRQ r/m64, xmm1, imm8",
			Go:       "VPEXTRQ imm8, xmm1, r/m64",
			GNU:      "vpextrq imm8, xmm1, r/m64",
			Encoding: "VEX.128.66.0F3A.W1 16 /r ib",
			Mode32:   "I",
			Mode64:   "V",
			CPUID:    "AVX",
			Action:   "w,r,r",
		},
		{
			Intel:     "XOR r8, r/m8",
			Go:        "XORB r/m8, r8",
			GNU:       "xorb r/m8, r8",
			Encoding:  "REX 32 /r",
			Mode32:    "N.E.",
			Mode64:    "V",
			Tags:      "pseudo64",
			Action:    "rw,r",
			Multisize: "Y",
			Size:      "8",
		},
	}

	r := NewReader(strings.NewReader(input))
	inst, err := r.Read()
	if err != nil {
		t.Fatalf("Read(): %v", err)
	}
	restInsts, err := r.ReadAll()
	if err != nil {
		t.Fatalf("ReadAll(): %v", err)
	}
	if remainder, err := r.ReadAll(); remainder != nil || err != nil {
		t.Errorf("ReadAll() on exhausted r failed")
	}
	have := append([]*Inst{inst}, restInsts...)

	if len(want) != len(have) {
		t.Fatalf("len(have) is %d, want %d\n", len(have), len(want))
	}
	lines := strings.Split(input, "\n")
	lines = lines[1:] // Drop comment line
	for i := range want {
		if want[i] != *have[i] {
			t.Errorf("%s:\nhave: %v\nwant: %v", lines[i], have[i], want[i])
		}
	}
}

func TestSyntaxSplit(t *testing.T) {
	tests := []struct {
		syntax string
		opcode string
		args   []string
	}{
		{"RET", "RET", nil},
		{"CALLW* r/m16", "CALLW*", []string{"r/m16"}},
		{"JMP_FAR m16:16", "JMP_FAR", []string{"m16:16"}},
		{"movl CR0-CR7, rmr32", "movl", []string{"CR0-CR7", "rmr32"}},
		{"VFMSUBADD132PD xmm1, xmmV, xmm2/m128", "VFMSUBADD132PD", []string{"xmm1", "xmmV", "xmm2/m128"}},
	}

	for _, tt := range tests {
		op, args := instOpcode(tt.syntax), instArgs(tt.syntax)
		if op != tt.opcode {
			t.Errorf("%s: opcode mismatch (have `%s`, want `%s`)",
				tt.syntax, op, tt.opcode)
		}
		if !reflect.DeepEqual(args, tt.args) {
			t.Errorf("%s: args mismatch (have %v, want %s)",
				tt.syntax, args, tt.args)
		}
	}
}
