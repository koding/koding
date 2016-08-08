// Copyright 2012 The Gorilla Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package schema

import (
	"encoding/hex"
	"errors"
	"reflect"
	"strings"
	"testing"
	"time"
)

type IntAlias int

// All cases we want to cover, in a nutshell.
type S1 struct {
	F01 int        `schema:"f1"`
	F02 *int       `schema:"f2"`
	F03 []int      `schema:"f3"`
	F04 []*int     `schema:"f4"`
	F05 *[]int     `schema:"f5"`
	F06 *[]*int    `schema:"f6"`
	F07 S2         `schema:"f7"`
	F08 *S1        `schema:"f8"`
	F09 int        `schema:"-"`
	F10 []S1       `schema:"f10"`
	F11 []*S1      `schema:"f11"`
	F12 *[]S1      `schema:"f12"`
	F13 *[]*S1     `schema:"f13"`
	F14 int        `schema:"f14"`
	F15 IntAlias   `schema:"f15"`
	F16 []IntAlias `schema:"f16"`
	F17 S19        `schema:"f17"`
}

type S2 struct {
	F01 *[]*int `schema:"f1"`
}

type S19 [2]byte

func (id *S19) UnmarshalText(text []byte) error {
	buf, err := hex.DecodeString(string(text))
	if err != nil {
		return err
	}
	if len(buf) > len(*id) {
		return errors.New("out of range")
	}
	for i := range buf {
		(*id)[i] = buf[i]
	}
	return nil
}

func TestAll(t *testing.T) {
	v := map[string][]string{
		"f1":             {"1"},
		"f2":             {"2"},
		"f3":             {"31", "32"},
		"f4":             {"41", "42"},
		"f5":             {"51", "52"},
		"f6":             {"61", "62"},
		"f7.f1":          {"71", "72"},
		"f8.f8.f7.f1":    {"81", "82"},
		"f9":             {"9"},
		"f10.0.f10.0.f6": {"101", "102"},
		"f10.0.f10.1.f6": {"103", "104"},
		"f11.0.f11.0.f6": {"111", "112"},
		"f11.0.f11.1.f6": {"113", "114"},
		"f12.0.f12.0.f6": {"121", "122"},
		"f12.0.f12.1.f6": {"123", "124"},
		"f13.0.f13.0.f6": {"131", "132"},
		"f13.0.f13.1.f6": {"133", "134"},
		"f14":            {},
		"f15":            {"151"},
		"f16":            {"161", "162"},
		"f17":            {"1a2b"},
	}
	f2 := 2
	f41, f42 := 41, 42
	f61, f62 := 61, 62
	f71, f72 := 71, 72
	f81, f82 := 81, 82
	f101, f102, f103, f104 := 101, 102, 103, 104
	f111, f112, f113, f114 := 111, 112, 113, 114
	f121, f122, f123, f124 := 121, 122, 123, 124
	f131, f132, f133, f134 := 131, 132, 133, 134
	var f151 IntAlias = 151
	var f161, f162 IntAlias = 161, 162
	e := S1{
		F01: 1,
		F02: &f2,
		F03: []int{31, 32},
		F04: []*int{&f41, &f42},
		F05: &[]int{51, 52},
		F06: &[]*int{&f61, &f62},
		F07: S2{
			F01: &[]*int{&f71, &f72},
		},
		F08: &S1{
			F08: &S1{
				F07: S2{
					F01: &[]*int{&f81, &f82},
				},
			},
		},
		F09: 0,
		F10: []S1{
			S1{
				F10: []S1{
					S1{F06: &[]*int{&f101, &f102}},
					S1{F06: &[]*int{&f103, &f104}},
				},
			},
		},
		F11: []*S1{
			&S1{
				F11: []*S1{
					&S1{F06: &[]*int{&f111, &f112}},
					&S1{F06: &[]*int{&f113, &f114}},
				},
			},
		},
		F12: &[]S1{
			S1{
				F12: &[]S1{
					S1{F06: &[]*int{&f121, &f122}},
					S1{F06: &[]*int{&f123, &f124}},
				},
			},
		},
		F13: &[]*S1{
			&S1{
				F13: &[]*S1{
					&S1{F06: &[]*int{&f131, &f132}},
					&S1{F06: &[]*int{&f133, &f134}},
				},
			},
		},
		F14: 0,
		F15: f151,
		F16: []IntAlias{f161, f162},
		F17: S19{0x1a, 0x2b},
	}

	s := &S1{}
	_ = NewDecoder().Decode(s, v)

	vals := func(values []*int) []int {
		r := make([]int, len(values))
		for k, v := range values {
			r[k] = *v
		}
		return r
	}

	if s.F01 != e.F01 {
		t.Errorf("f1: expected %v, got %v", e.F01, s.F01)
	}
	if s.F02 == nil {
		t.Errorf("f2: expected %v, got nil", *e.F02)
	} else if *s.F02 != *e.F02 {
		t.Errorf("f2: expected %v, got %v", *e.F02, *s.F02)
	}
	if s.F03 == nil {
		t.Errorf("f3: expected %v, got nil", e.F03)
	} else if len(s.F03) != 2 || s.F03[0] != e.F03[0] || s.F03[1] != e.F03[1] {
		t.Errorf("f3: expected %v, got %v", e.F03, s.F03)
	}
	if s.F04 == nil {
		t.Errorf("f4: expected %v, got nil", e.F04)
	} else {
		if len(s.F04) != 2 || *(s.F04)[0] != *(e.F04)[0] || *(s.F04)[1] != *(e.F04)[1] {
			t.Errorf("f4: expected %v, got %v", vals(e.F04), vals(s.F04))
		}
	}
	if s.F05 == nil {
		t.Errorf("f5: expected %v, got nil", e.F05)
	} else {
		sF05, eF05 := *s.F05, *e.F05
		if len(sF05) != 2 || sF05[0] != eF05[0] || sF05[1] != eF05[1] {
			t.Errorf("f5: expected %v, got %v", eF05, sF05)
		}
	}
	if s.F06 == nil {
		t.Errorf("f6: expected %v, got nil", vals(*e.F06))
	} else {
		sF06, eF06 := *s.F06, *e.F06
		if len(sF06) != 2 || *(sF06)[0] != *(eF06)[0] || *(sF06)[1] != *(eF06)[1] {
			t.Errorf("f6: expected %v, got %v", vals(eF06), vals(sF06))
		}
	}
	if s.F07.F01 == nil {
		t.Errorf("f7.f1: expected %v, got nil", vals(*e.F07.F01))
	} else {
		sF07, eF07 := *s.F07.F01, *e.F07.F01
		if len(sF07) != 2 || *(sF07)[0] != *(eF07)[0] || *(sF07)[1] != *(eF07)[1] {
			t.Errorf("f7.f1: expected %v, got %v", vals(eF07), vals(sF07))
		}
	}
	if s.F08 == nil {
		t.Errorf("f8: got nil")
	} else if s.F08.F08 == nil {
		t.Errorf("f8.f8: got nil")
	} else if s.F08.F08.F07.F01 == nil {
		t.Errorf("f8.f8.f7.f1: expected %v, got nil", vals(*e.F08.F08.F07.F01))
	} else {
		sF08, eF08 := *s.F08.F08.F07.F01, *e.F08.F08.F07.F01
		if len(sF08) != 2 || *(sF08)[0] != *(eF08)[0] || *(sF08)[1] != *(eF08)[1] {
			t.Errorf("f8.f8.f7.f1: expected %v, got %v", vals(eF08), vals(sF08))
		}
	}
	if s.F09 != e.F09 {
		t.Errorf("f9: expected %v, got %v", e.F09, s.F09)
	}
	if s.F10 == nil {
		t.Errorf("f10: got nil")
	} else if len(s.F10) != 1 {
		t.Errorf("f10: expected 1 element, got %v", s.F10)
	} else {
		if len(s.F10[0].F10) != 2 {
			t.Errorf("f10.0.f10: expected 1 element, got %v", s.F10[0].F10)
		} else {
			sF10, eF10 := *s.F10[0].F10[0].F06, *e.F10[0].F10[0].F06
			if sF10 == nil {
				t.Errorf("f10.0.f10.0.f6: expected %v, got nil", vals(eF10))
			} else {
				if len(sF10) != 2 || *(sF10)[0] != *(eF10)[0] || *(sF10)[1] != *(eF10)[1] {
					t.Errorf("f10.0.f10.0.f6: expected %v, got %v", vals(eF10), vals(sF10))
				}
			}
			sF10, eF10 = *s.F10[0].F10[1].F06, *e.F10[0].F10[1].F06
			if sF10 == nil {
				t.Errorf("f10.0.f10.0.f6: expected %v, got nil", vals(eF10))
			} else {
				if len(sF10) != 2 || *(sF10)[0] != *(eF10)[0] || *(sF10)[1] != *(eF10)[1] {
					t.Errorf("f10.0.f10.0.f6: expected %v, got %v", vals(eF10), vals(sF10))
				}
			}
		}
	}
	if s.F11 == nil {
		t.Errorf("f11: got nil")
	} else if len(s.F11) != 1 {
		t.Errorf("f11: expected 1 element, got %v", s.F11)
	} else {
		if len(s.F11[0].F11) != 2 {
			t.Errorf("f11.0.f11: expected 1 element, got %v", s.F11[0].F11)
		} else {
			sF11, eF11 := *s.F11[0].F11[0].F06, *e.F11[0].F11[0].F06
			if sF11 == nil {
				t.Errorf("f11.0.f11.0.f6: expected %v, got nil", vals(eF11))
			} else {
				if len(sF11) != 2 || *(sF11)[0] != *(eF11)[0] || *(sF11)[1] != *(eF11)[1] {
					t.Errorf("f11.0.f11.0.f6: expected %v, got %v", vals(eF11), vals(sF11))
				}
			}
			sF11, eF11 = *s.F11[0].F11[1].F06, *e.F11[0].F11[1].F06
			if sF11 == nil {
				t.Errorf("f11.0.f11.0.f6: expected %v, got nil", vals(eF11))
			} else {
				if len(sF11) != 2 || *(sF11)[0] != *(eF11)[0] || *(sF11)[1] != *(eF11)[1] {
					t.Errorf("f11.0.f11.0.f6: expected %v, got %v", vals(eF11), vals(sF11))
				}
			}
		}
	}
	if s.F12 == nil {
		t.Errorf("f12: got nil")
	} else if len(*s.F12) != 1 {
		t.Errorf("f12: expected 1 element, got %v", *s.F12)
	} else {
		sF12, eF12 := *(s.F12), *(e.F12)
		if len(*sF12[0].F12) != 2 {
			t.Errorf("f12.0.f12: expected 1 element, got %v", *sF12[0].F12)
		} else {
			sF122, eF122 := *(*sF12[0].F12)[0].F06, *(*eF12[0].F12)[0].F06
			if sF122 == nil {
				t.Errorf("f12.0.f12.0.f6: expected %v, got nil", vals(eF122))
			} else {
				if len(sF122) != 2 || *(sF122)[0] != *(eF122)[0] || *(sF122)[1] != *(eF122)[1] {
					t.Errorf("f12.0.f12.0.f6: expected %v, got %v", vals(eF122), vals(sF122))
				}
			}
			sF122, eF122 = *(*sF12[0].F12)[1].F06, *(*eF12[0].F12)[1].F06
			if sF122 == nil {
				t.Errorf("f12.0.f12.0.f6: expected %v, got nil", vals(eF122))
			} else {
				if len(sF122) != 2 || *(sF122)[0] != *(eF122)[0] || *(sF122)[1] != *(eF122)[1] {
					t.Errorf("f12.0.f12.0.f6: expected %v, got %v", vals(eF122), vals(sF122))
				}
			}
		}
	}
	if s.F13 == nil {
		t.Errorf("f13: got nil")
	} else if len(*s.F13) != 1 {
		t.Errorf("f13: expected 1 element, got %v", *s.F13)
	} else {
		sF13, eF13 := *(s.F13), *(e.F13)
		if len(*sF13[0].F13) != 2 {
			t.Errorf("f13.0.f13: expected 1 element, got %v", *sF13[0].F13)
		} else {
			sF132, eF132 := *(*sF13[0].F13)[0].F06, *(*eF13[0].F13)[0].F06
			if sF132 == nil {
				t.Errorf("f13.0.f13.0.f6: expected %v, got nil", vals(eF132))
			} else {
				if len(sF132) != 2 || *(sF132)[0] != *(eF132)[0] || *(sF132)[1] != *(eF132)[1] {
					t.Errorf("f13.0.f13.0.f6: expected %v, got %v", vals(eF132), vals(sF132))
				}
			}
			sF132, eF132 = *(*sF13[0].F13)[1].F06, *(*eF13[0].F13)[1].F06
			if sF132 == nil {
				t.Errorf("f13.0.f13.0.f6: expected %v, got nil", vals(eF132))
			} else {
				if len(sF132) != 2 || *(sF132)[0] != *(eF132)[0] || *(sF132)[1] != *(eF132)[1] {
					t.Errorf("f13.0.f13.0.f6: expected %v, got %v", vals(eF132), vals(sF132))
				}
			}
		}
	}
	if s.F14 != e.F14 {
		t.Errorf("f14: expected %v, got %v", e.F14, s.F14)
	}
	if s.F15 != e.F15 {
		t.Errorf("f15: expected %v, got %v", e.F15, s.F15)
	}
	if s.F16 == nil {
		t.Errorf("f16: nil")
	} else if len(s.F16) != len(e.F16) {
		t.Errorf("f16: expected len %d, got %d", len(e.F16), len(s.F16))
	} else if !reflect.DeepEqual(s.F16, e.F16) {
		t.Errorf("f16: expected %v, got %v", e.F16, s.F16)
	}
	if s.F17 != e.F17 {
		t.Errorf("f17: expected %v, got %v", e.F17, s.F17)
	}
}

func BenchmarkAll(b *testing.B) {
	v := map[string][]string{
		"f1":             {"1"},
		"f2":             {"2"},
		"f3":             {"31", "32"},
		"f4":             {"41", "42"},
		"f5":             {"51", "52"},
		"f6":             {"61", "62"},
		"f7.f1":          {"71", "72"},
		"f8.f8.f7.f1":    {"81", "82"},
		"f9":             {"9"},
		"f10.0.f10.0.f6": {"101", "102"},
		"f10.0.f10.1.f6": {"103", "104"},
		"f11.0.f11.0.f6": {"111", "112"},
		"f11.0.f11.1.f6": {"113", "114"},
		"f12.0.f12.0.f6": {"121", "122"},
		"f12.0.f12.1.f6": {"123", "124"},
		"f13.0.f13.0.f6": {"131", "132"},
		"f13.0.f13.1.f6": {"133", "134"},
	}

	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		s := &S1{}
		_ = NewDecoder().Decode(s, v)
	}
}

// ----------------------------------------------------------------------------

type S3 struct {
	F01 bool
	F02 float32
	F03 float64
	F04 int
	F05 int8
	F06 int16
	F07 int32
	F08 int64
	F09 string
	F10 uint
	F11 uint8
	F12 uint16
	F13 uint32
	F14 uint64
}

func TestDefaultConverters(t *testing.T) {
	v := map[string][]string{
		"F01": {"true"},
		"F02": {"4.2"},
		"F03": {"4.3"},
		"F04": {"-42"},
		"F05": {"-43"},
		"F06": {"-44"},
		"F07": {"-45"},
		"F08": {"-46"},
		"F09": {"foo"},
		"F10": {"42"},
		"F11": {"43"},
		"F12": {"44"},
		"F13": {"45"},
		"F14": {"46"},
	}
	e := S3{
		F01: true,
		F02: 4.2,
		F03: 4.3,
		F04: -42,
		F05: -43,
		F06: -44,
		F07: -45,
		F08: -46,
		F09: "foo",
		F10: 42,
		F11: 43,
		F12: 44,
		F13: 45,
		F14: 46,
	}
	s := &S3{}
	_ = NewDecoder().Decode(s, v)
	if s.F01 != e.F01 {
		t.Errorf("F01: expected %v, got %v", e.F01, s.F01)
	}
	if s.F02 != e.F02 {
		t.Errorf("F02: expected %v, got %v", e.F02, s.F02)
	}
	if s.F03 != e.F03 {
		t.Errorf("F03: expected %v, got %v", e.F03, s.F03)
	}
	if s.F04 != e.F04 {
		t.Errorf("F04: expected %v, got %v", e.F04, s.F04)
	}
	if s.F05 != e.F05 {
		t.Errorf("F05: expected %v, got %v", e.F05, s.F05)
	}
	if s.F06 != e.F06 {
		t.Errorf("F06: expected %v, got %v", e.F06, s.F06)
	}
	if s.F07 != e.F07 {
		t.Errorf("F07: expected %v, got %v", e.F07, s.F07)
	}
	if s.F08 != e.F08 {
		t.Errorf("F08: expected %v, got %v", e.F08, s.F08)
	}
	if s.F09 != e.F09 {
		t.Errorf("F09: expected %v, got %v", e.F09, s.F09)
	}
	if s.F10 != e.F10 {
		t.Errorf("F10: expected %v, got %v", e.F10, s.F10)
	}
	if s.F11 != e.F11 {
		t.Errorf("F11: expected %v, got %v", e.F11, s.F11)
	}
	if s.F12 != e.F12 {
		t.Errorf("F12: expected %v, got %v", e.F12, s.F12)
	}
	if s.F13 != e.F13 {
		t.Errorf("F13: expected %v, got %v", e.F13, s.F13)
	}
	if s.F14 != e.F14 {
		t.Errorf("F14: expected %v, got %v", e.F14, s.F14)
	}
}

func TestOn(t *testing.T) {
	v := map[string][]string{
		"F01": {"on"},
	}
	s := S3{}
	err := NewDecoder().Decode(&s, v)
	if err != nil {
		t.Fatal(err)
	}
	if !s.F01 {
		t.Fatal("Value was not set to true")
	}
}

// ----------------------------------------------------------------------------

func TestInlineStruct(t *testing.T) {
	s1 := &struct {
		F01 bool
	}{}
	s2 := &struct {
		F01 int
	}{}
	v1 := map[string][]string{
		"F01": {"true"},
	}
	v2 := map[string][]string{
		"F01": {"42"},
	}
	decoder := NewDecoder()
	_ = decoder.Decode(s1, v1)
	if s1.F01 != true {
		t.Errorf("s1: expected %v, got %v", true, s1.F01)
	}
	_ = decoder.Decode(s2, v2)
	if s2.F01 != 42 {
		t.Errorf("s2: expected %v, got %v", 42, s2.F01)
	}
}

// ----------------------------------------------------------------------------

type Foo struct {
	F01 int
	F02 Bar
	Bif []Baz
}

type Bar struct {
	F01 string
	F02 string
	F03 string
	F14 string
	S05 string
	Str string
}

type Baz struct {
	F99 []string
}

func TestSimpleExample(t *testing.T) {
	data := map[string][]string{
		"F01":       {"1"},
		"F02.F01":   {"S1"},
		"F02.F02":   {"S2"},
		"F02.F03":   {"S3"},
		"F02.F14":   {"S4"},
		"F02.S05":   {"S5"},
		"F02.Str":   {"Str"},
		"Bif.0.F99": {"A", "B", "C"},
	}

	e := &Foo{
		F01: 1,
		F02: Bar{
			F01: "S1",
			F02: "S2",
			F03: "S3",
			F14: "S4",
			S05: "S5",
			Str: "Str",
		},
		Bif: []Baz{{
			F99: []string{"A", "B", "C"}},
		},
	}

	s := &Foo{}
	_ = NewDecoder().Decode(s, data)

	if s.F01 != e.F01 {
		t.Errorf("F01: expected %v, got %v", e.F01, s.F01)
	}
	if s.F02.F01 != e.F02.F01 {
		t.Errorf("F02.F01: expected %v, got %v", e.F02.F01, s.F02.F01)
	}
	if s.F02.F02 != e.F02.F02 {
		t.Errorf("F02.F02: expected %v, got %v", e.F02.F02, s.F02.F02)
	}
	if s.F02.F03 != e.F02.F03 {
		t.Errorf("F02.F03: expected %v, got %v", e.F02.F03, s.F02.F03)
	}
	if s.F02.F14 != e.F02.F14 {
		t.Errorf("F02.F14: expected %v, got %v", e.F02.F14, s.F02.F14)
	}
	if s.F02.S05 != e.F02.S05 {
		t.Errorf("F02.S05: expected %v, got %v", e.F02.S05, s.F02.S05)
	}
	if s.F02.Str != e.F02.Str {
		t.Errorf("F02.Str: expected %v, got %v", e.F02.Str, s.F02.Str)
	}
	if len(s.Bif) != len(e.Bif) {
		t.Errorf("Bif len: expected %d, got %d", len(e.Bif), len(s.Bif))
	} else {
		if len(s.Bif[0].F99) != len(e.Bif[0].F99) {
			t.Errorf("Bif[0].F99 len: expected %d, got %d", len(e.Bif[0].F99), len(s.Bif[0].F99))
		}
	}
}

// ----------------------------------------------------------------------------

type S4 struct {
	F01 int64
	F02 float64
	F03 bool
}

func TestConversionError(t *testing.T) {
	data := map[string][]string{
		"F01": {"foo"},
		"F02": {"bar"},
		"F03": {"baz"},
	}
	s := &S4{}
	e := NewDecoder().Decode(s, data)

	m := e.(MultiError)
	if len(m) != 3 {
		t.Errorf("Expected 3 errors, got %v", m)
	}
}

// ----------------------------------------------------------------------------

type S5 struct {
	F01 []string
}

func TestEmptyValue(t *testing.T) {
	data := map[string][]string{
		"F01": {"", "foo"},
	}
	s := &S5{}
	NewDecoder().Decode(s, data)
	if len(s.F01) != 1 {
		t.Errorf("Expected 1 values in F01")
	}
}

func TestEmptyValueZeroEmpty(t *testing.T) {
	data := map[string][]string{
		"F01": {"", "foo"},
	}
	s := S5{}
	d := NewDecoder()
	d.ZeroEmpty(true)
	err := d.Decode(&s, data)
	if err != nil {
		t.Fatal(err)
	}
	if len(s.F01) != 2 {
		t.Errorf("Expected 1 values in F01")
	}
}

// ----------------------------------------------------------------------------

type S6 struct {
	id string
}

func TestUnexportedField(t *testing.T) {
	data := map[string][]string{
		"id": {"identifier"},
	}
	s := &S6{}
	NewDecoder().Decode(s, data)
	if s.id != "" {
		t.Errorf("Unexported field expected to be ignored")
	}
}

// ----------------------------------------------------------------------------

type S7 struct {
	ID string
}

func TestMultipleValues(t *testing.T) {
	data := map[string][]string{
		"ID": {"0", "1"},
	}

	s := S7{}
	NewDecoder().Decode(&s, data)
	if s.ID != "1" {
		t.Errorf("Last defined value must be used when multiple values for same field are provided")
	}
}

type S8 struct {
	ID string `json:"id"`
}

func TestSetAliasTag(t *testing.T) {
	data := map[string][]string{
		"id": {"foo"},
	}

	s := S8{}
	dec := NewDecoder()
	dec.SetAliasTag("json")
	dec.Decode(&s, data)
	if s.ID != "foo" {
		t.Fatalf("Bad value: got %q, want %q", s.ID, "foo")
	}
}

func TestZeroEmpty(t *testing.T) {
	data := map[string][]string{
		"F01": {""},
		"F03": {"true"},
	}
	s := S4{1, 1, false}
	d := NewDecoder()
	d.ZeroEmpty(true)

	err := d.Decode(&s, data)
	if err != nil {
		t.Fatal(err)
	}
	if s.F01 != 0 {
		t.Errorf("F01: got %v, want %v", s.F01, 0)
	}
	if s.F02 != 1 {
		t.Errorf("F02: got %v, want %v", s.F02, 1)
	}
	if s.F03 != true {
		t.Errorf("F03: got %v, want %v", s.F03, true)
	}
}

func TestNoZeroEmpty(t *testing.T) {
	data := map[string][]string{
		"F01": {""},
		"F03": {"true"},
	}
	s := S4{1, 1, false}
	d := NewDecoder()
	d.ZeroEmpty(false)
	err := d.Decode(&s, data)
	if err != nil {
		t.Fatal(err)
	}
	if s.F01 != 1 {
		t.Errorf("F01: got %v, want %v", s.F01, 1)
	}
	if s.F02 != 1 {
		t.Errorf("F02: got %v, want %v", s.F02, 1)
	}
	if s.F03 != true {
		t.Errorf("F03: got %v, want %v", s.F03, true)
	}
}

// ----------------------------------------------------------------------------

type S9 struct {
	Id string
}

type S10 struct {
	S9
}

func TestEmbeddedField(t *testing.T) {
	data := map[string][]string{
		"Id": {"identifier"},
	}
	s := &S10{}
	NewDecoder().Decode(s, data)
	if s.Id != "identifier" {
		t.Errorf("Missing support for embedded fields")
	}
}

type S11 struct {
	S10
}

func TestMultipleLevelEmbeddedField(t *testing.T) {
	data := map[string][]string{
		"Id": {"identifier"},
	}
	s := &S11{}
	err := NewDecoder().Decode(s, data)
	if s.Id != "identifier" {
		t.Errorf("Missing support for multiple-level embedded fields (%v)", err)
	}
}

func TestInvalidPath(t *testing.T) {
	data := map[string][]string{
		"Foo.Bar": {"baz"},
	}
	s := S9{}
	err := NewDecoder().Decode(&s, data)
	expectedErr := `schema: invalid path "Foo.Bar"`
	if err.Error() != expectedErr {
		t.Fatalf("got %q, want %q", err, expectedErr)
	}
}

func TestInvalidPathIgnoreUnknownKeys(t *testing.T) {
	data := map[string][]string{
		"Foo.Bar": {"baz"},
	}
	s := S9{}
	dec := NewDecoder()
	dec.IgnoreUnknownKeys(true)
	err := dec.Decode(&s, data)
	if err != nil {
		t.Fatal(err)
	}
}

// ----------------------------------------------------------------------------

type S1NT struct {
	F1  int
	F2  *int
	F3  []int
	F4  []*int
	F5  *[]int
	F6  *[]*int
	F7  S2
	F8  *S1
	F9  int `schema:"-"`
	F10 []S1
	F11 []*S1
	F12 *[]S1
	F13 *[]*S1
}

func TestAllNT(t *testing.T) {
	v := map[string][]string{
		"f1":             {"1"},
		"f2":             {"2"},
		"f3":             {"31", "32"},
		"f4":             {"41", "42"},
		"f5":             {"51", "52"},
		"f6":             {"61", "62"},
		"f7.f1":          {"71", "72"},
		"f8.f8.f7.f1":    {"81", "82"},
		"f9":             {"9"},
		"f10.0.f10.0.f6": {"101", "102"},
		"f10.0.f10.1.f6": {"103", "104"},
		"f11.0.f11.0.f6": {"111", "112"},
		"f11.0.f11.1.f6": {"113", "114"},
		"f12.0.f12.0.f6": {"121", "122"},
		"f12.0.f12.1.f6": {"123", "124"},
		"f13.0.f13.0.f6": {"131", "132"},
		"f13.0.f13.1.f6": {"133", "134"},
	}
	f2 := 2
	f41, f42 := 41, 42
	f61, f62 := 61, 62
	f71, f72 := 71, 72
	f81, f82 := 81, 82
	f101, f102, f103, f104 := 101, 102, 103, 104
	f111, f112, f113, f114 := 111, 112, 113, 114
	f121, f122, f123, f124 := 121, 122, 123, 124
	f131, f132, f133, f134 := 131, 132, 133, 134
	e := S1NT{
		F1: 1,
		F2: &f2,
		F3: []int{31, 32},
		F4: []*int{&f41, &f42},
		F5: &[]int{51, 52},
		F6: &[]*int{&f61, &f62},
		F7: S2{
			F01: &[]*int{&f71, &f72},
		},
		F8: &S1{
			F08: &S1{
				F07: S2{
					F01: &[]*int{&f81, &f82},
				},
			},
		},
		F9: 0,
		F10: []S1{
			S1{
				F10: []S1{
					S1{F06: &[]*int{&f101, &f102}},
					S1{F06: &[]*int{&f103, &f104}},
				},
			},
		},
		F11: []*S1{
			&S1{
				F11: []*S1{
					&S1{F06: &[]*int{&f111, &f112}},
					&S1{F06: &[]*int{&f113, &f114}},
				},
			},
		},
		F12: &[]S1{
			S1{
				F12: &[]S1{
					S1{F06: &[]*int{&f121, &f122}},
					S1{F06: &[]*int{&f123, &f124}},
				},
			},
		},
		F13: &[]*S1{
			&S1{
				F13: &[]*S1{
					&S1{F06: &[]*int{&f131, &f132}},
					&S1{F06: &[]*int{&f133, &f134}},
				},
			},
		},
	}

	s := &S1NT{}
	_ = NewDecoder().Decode(s, v)

	vals := func(values []*int) []int {
		r := make([]int, len(values))
		for k, v := range values {
			r[k] = *v
		}
		return r
	}

	if s.F1 != e.F1 {
		t.Errorf("f1: expected %v, got %v", e.F1, s.F1)
	}
	if s.F2 == nil {
		t.Errorf("f2: expected %v, got nil", *e.F2)
	} else if *s.F2 != *e.F2 {
		t.Errorf("f2: expected %v, got %v", *e.F2, *s.F2)
	}
	if s.F3 == nil {
		t.Errorf("f3: expected %v, got nil", e.F3)
	} else if len(s.F3) != 2 || s.F3[0] != e.F3[0] || s.F3[1] != e.F3[1] {
		t.Errorf("f3: expected %v, got %v", e.F3, s.F3)
	}
	if s.F4 == nil {
		t.Errorf("f4: expected %v, got nil", e.F4)
	} else {
		if len(s.F4) != 2 || *(s.F4)[0] != *(e.F4)[0] || *(s.F4)[1] != *(e.F4)[1] {
			t.Errorf("f4: expected %v, got %v", vals(e.F4), vals(s.F4))
		}
	}
	if s.F5 == nil {
		t.Errorf("f5: expected %v, got nil", e.F5)
	} else {
		sF5, eF5 := *s.F5, *e.F5
		if len(sF5) != 2 || sF5[0] != eF5[0] || sF5[1] != eF5[1] {
			t.Errorf("f5: expected %v, got %v", eF5, sF5)
		}
	}
	if s.F6 == nil {
		t.Errorf("f6: expected %v, got nil", vals(*e.F6))
	} else {
		sF6, eF6 := *s.F6, *e.F6
		if len(sF6) != 2 || *(sF6)[0] != *(eF6)[0] || *(sF6)[1] != *(eF6)[1] {
			t.Errorf("f6: expected %v, got %v", vals(eF6), vals(sF6))
		}
	}
	if s.F7.F01 == nil {
		t.Errorf("f7.f1: expected %v, got nil", vals(*e.F7.F01))
	} else {
		sF7, eF7 := *s.F7.F01, *e.F7.F01
		if len(sF7) != 2 || *(sF7)[0] != *(eF7)[0] || *(sF7)[1] != *(eF7)[1] {
			t.Errorf("f7.f1: expected %v, got %v", vals(eF7), vals(sF7))
		}
	}
	if s.F8 == nil {
		t.Errorf("f8: got nil")
	} else if s.F8.F08 == nil {
		t.Errorf("f8.f8: got nil")
	} else if s.F8.F08.F07.F01 == nil {
		t.Errorf("f8.f8.f7.f1: expected %v, got nil", vals(*e.F8.F08.F07.F01))
	} else {
		sF8, eF8 := *s.F8.F08.F07.F01, *e.F8.F08.F07.F01
		if len(sF8) != 2 || *(sF8)[0] != *(eF8)[0] || *(sF8)[1] != *(eF8)[1] {
			t.Errorf("f8.f8.f7.f1: expected %v, got %v", vals(eF8), vals(sF8))
		}
	}
	if s.F9 != e.F9 {
		t.Errorf("f9: expected %v, got %v", e.F9, s.F9)
	}
	if s.F10 == nil {
		t.Errorf("f10: got nil")
	} else if len(s.F10) != 1 {
		t.Errorf("f10: expected 1 element, got %v", s.F10)
	} else {
		if len(s.F10[0].F10) != 2 {
			t.Errorf("f10.0.f10: expected 1 element, got %v", s.F10[0].F10)
		} else {
			sF10, eF10 := *s.F10[0].F10[0].F06, *e.F10[0].F10[0].F06
			if sF10 == nil {
				t.Errorf("f10.0.f10.0.f6: expected %v, got nil", vals(eF10))
			} else {
				if len(sF10) != 2 || *(sF10)[0] != *(eF10)[0] || *(sF10)[1] != *(eF10)[1] {
					t.Errorf("f10.0.f10.0.f6: expected %v, got %v", vals(eF10), vals(sF10))
				}
			}
			sF10, eF10 = *s.F10[0].F10[1].F06, *e.F10[0].F10[1].F06
			if sF10 == nil {
				t.Errorf("f10.0.f10.0.f6: expected %v, got nil", vals(eF10))
			} else {
				if len(sF10) != 2 || *(sF10)[0] != *(eF10)[0] || *(sF10)[1] != *(eF10)[1] {
					t.Errorf("f10.0.f10.0.f6: expected %v, got %v", vals(eF10), vals(sF10))
				}
			}
		}
	}
	if s.F11 == nil {
		t.Errorf("f11: got nil")
	} else if len(s.F11) != 1 {
		t.Errorf("f11: expected 1 element, got %v", s.F11)
	} else {
		if len(s.F11[0].F11) != 2 {
			t.Errorf("f11.0.f11: expected 1 element, got %v", s.F11[0].F11)
		} else {
			sF11, eF11 := *s.F11[0].F11[0].F06, *e.F11[0].F11[0].F06
			if sF11 == nil {
				t.Errorf("f11.0.f11.0.f6: expected %v, got nil", vals(eF11))
			} else {
				if len(sF11) != 2 || *(sF11)[0] != *(eF11)[0] || *(sF11)[1] != *(eF11)[1] {
					t.Errorf("f11.0.f11.0.f6: expected %v, got %v", vals(eF11), vals(sF11))
				}
			}
			sF11, eF11 = *s.F11[0].F11[1].F06, *e.F11[0].F11[1].F06
			if sF11 == nil {
				t.Errorf("f11.0.f11.0.f6: expected %v, got nil", vals(eF11))
			} else {
				if len(sF11) != 2 || *(sF11)[0] != *(eF11)[0] || *(sF11)[1] != *(eF11)[1] {
					t.Errorf("f11.0.f11.0.f6: expected %v, got %v", vals(eF11), vals(sF11))
				}
			}
		}
	}
	if s.F12 == nil {
		t.Errorf("f12: got nil")
	} else if len(*s.F12) != 1 {
		t.Errorf("f12: expected 1 element, got %v", *s.F12)
	} else {
		sF12, eF12 := *(s.F12), *(e.F12)
		if len(*sF12[0].F12) != 2 {
			t.Errorf("f12.0.f12: expected 1 element, got %v", *sF12[0].F12)
		} else {
			sF122, eF122 := *(*sF12[0].F12)[0].F06, *(*eF12[0].F12)[0].F06
			if sF122 == nil {
				t.Errorf("f12.0.f12.0.f6: expected %v, got nil", vals(eF122))
			} else {
				if len(sF122) != 2 || *(sF122)[0] != *(eF122)[0] || *(sF122)[1] != *(eF122)[1] {
					t.Errorf("f12.0.f12.0.f6: expected %v, got %v", vals(eF122), vals(sF122))
				}
			}
			sF122, eF122 = *(*sF12[0].F12)[1].F06, *(*eF12[0].F12)[1].F06
			if sF122 == nil {
				t.Errorf("f12.0.f12.0.f6: expected %v, got nil", vals(eF122))
			} else {
				if len(sF122) != 2 || *(sF122)[0] != *(eF122)[0] || *(sF122)[1] != *(eF122)[1] {
					t.Errorf("f12.0.f12.0.f6: expected %v, got %v", vals(eF122), vals(sF122))
				}
			}
		}
	}
	if s.F13 == nil {
		t.Errorf("f13: got nil")
	} else if len(*s.F13) != 1 {
		t.Errorf("f13: expected 1 element, got %v", *s.F13)
	} else {
		sF13, eF13 := *(s.F13), *(e.F13)
		if len(*sF13[0].F13) != 2 {
			t.Errorf("f13.0.f13: expected 1 element, got %v", *sF13[0].F13)
		} else {
			sF132, eF132 := *(*sF13[0].F13)[0].F06, *(*eF13[0].F13)[0].F06
			if sF132 == nil {
				t.Errorf("f13.0.f13.0.f6: expected %v, got nil", vals(eF132))
			} else {
				if len(sF132) != 2 || *(sF132)[0] != *(eF132)[0] || *(sF132)[1] != *(eF132)[1] {
					t.Errorf("f13.0.f13.0.f6: expected %v, got %v", vals(eF132), vals(sF132))
				}
			}
			sF132, eF132 = *(*sF13[0].F13)[1].F06, *(*eF13[0].F13)[1].F06
			if sF132 == nil {
				t.Errorf("f13.0.f13.0.f6: expected %v, got nil", vals(eF132))
			} else {
				if len(sF132) != 2 || *(sF132)[0] != *(eF132)[0] || *(sF132)[1] != *(eF132)[1] {
					t.Errorf("f13.0.f13.0.f6: expected %v, got %v", vals(eF132), vals(sF132))
				}
			}
		}
	}
}

// ----------------------------------------------------------------------------

type S12A struct {
	ID []int
}

func TestCSVSlice(t *testing.T) {
	data := map[string][]string{
		"ID": {"0,1"},
	}

	s := S12A{}
	NewDecoder().Decode(&s, data)
	if len(s.ID) != 2 {
		t.Errorf("Expected two values in the result list, got %+v", s.ID)
	}
	if s.ID[0] != 0 || s.ID[1] != 1 {
		t.Errorf("Expected []{0, 1} got %+v", s)
	}
}

type S12B struct {
	ID []string
}

//Decode should not split on , into a slice for string only
func TestCSVStringSlice(t *testing.T) {
	data := map[string][]string{
		"ID": {"0,1"},
	}

	s := S12B{}
	NewDecoder().Decode(&s, data)
	if len(s.ID) != 1 {
		t.Errorf("Expected one value in the result list, got %+v", s.ID)
	}
	if s.ID[0] != "0,1" {
		t.Errorf("Expected []{0, 1} got %+v", s)
	}
}

//Invalid data provided by client should not panic (github issue 33)
func TestInvalidDataProvidedByClient(t *testing.T) {
	defer func() {
		if r := recover(); r != nil {
			t.Errorf("Panicked calling decoder.Decode: %v", r)
		}
	}()

	type S struct {
		f string
	}

	data := map[string][]string{
		"f.f": {"v"},
	}

	err := NewDecoder().Decode(new(S), data)
	if err == nil {
		t.Errorf("invalid path in decoder.Decode should return an error.")
	}
}

// underlying cause of error in issue 33
func TestInvalidPathInCacheParsePath(t *testing.T) {
	type S struct {
		f string
	}

	typ := reflect.ValueOf(new(S)).Elem().Type()
	c := newCache()
	_, err := c.parsePath("f.f", typ)
	if err == nil {
		t.Errorf("invalid path in cache.parsePath should return an error.")
	}
}

// issue 32
func TestDecodeToTypedField(t *testing.T) {
	type Aa bool
	s1 := &struct{ Aa }{}
	v1 := map[string][]string{"Aa": {"true"}}
	NewDecoder().Decode(s1, v1)
	if s1.Aa != Aa(true) {
		t.Errorf("s1: expected %v, got %v", true, s1.Aa)
	}
}

// issue 37
func TestRegisterConverter(t *testing.T) {
	type Aa int
	type Bb int
	s1 := &struct {
		Aa
		Bb
	}{}
	decoder := NewDecoder()

	decoder.RegisterConverter(s1.Aa, func(s string) reflect.Value { return reflect.ValueOf(1) })
	decoder.RegisterConverter(s1.Bb, func(s string) reflect.Value { return reflect.ValueOf(2) })

	v1 := map[string][]string{"Aa": {"4"}, "Bb": {"5"}}
	decoder.Decode(s1, v1)

	if s1.Aa != Aa(1) {
		t.Errorf("s1.Aa: expected %v, got %v", 1, s1.Aa)
	}
	if s1.Bb != Bb(2) {
		t.Errorf("s1.Bb: expected %v, got %v", 2, s1.Bb)
	}
}

// Issue #40
func TestRegisterConverterSlice(t *testing.T) {
	decoder := NewDecoder()
	decoder.RegisterConverter([]string{}, func(input string) reflect.Value {
		return reflect.ValueOf(strings.Split(input, ","))
	})

	result := struct {
		Multiple []string `schema:"multiple"`
	}{}

	expected := []string{"one", "two", "three"}
	decoder.Decode(&result, map[string][]string{
		"multiple": []string{"one,two,three"},
	})
	for i := range expected {
		if got, want := expected[i], result.Multiple[i]; got != want {
			t.Errorf("%d: got %s, want %s", i, got, want)
		}
	}
}

type S13 struct {
	Value []S14
}

type S14 struct {
	F1 string
	F2 string
}

func (n *S14) UnmarshalText(text []byte) error {
	textParts := strings.Split(string(text), " ")
	if len(textParts) < 2 {
		return errors.New("Not a valid name!")
	}

	n.F1, n.F2 = textParts[0], textParts[len(textParts)-1]
	return nil
}

type S15 struct {
	Value []S16
}

type S16 struct {
	F1 string
	F2 string
}

func TestCustomTypeSlice(t *testing.T) {
	data := map[string][]string{
		"Value.0": []string{"Louisa May Alcott"},
		"Value.1": []string{"Florence Nightingale"},
		"Value.2": []string{"Clara Barton"},
	}

	s := S13{}
	decoder := NewDecoder()

	if err := decoder.Decode(&s, data); err != nil {
		t.Fatal(err)
	}

	if len(s.Value) != 3 {
		t.Fatalf("Expected 3 values in the result list, got %+v", s.Value)
	}
	if s.Value[0].F1 != "Louisa" || s.Value[0].F2 != "Alcott" {
		t.Errorf("Expected S14{'Louisa', 'Alcott'} got %+v", s.Value[0])
	}
	if s.Value[1].F1 != "Florence" || s.Value[1].F2 != "Nightingale" {
		t.Errorf("Expected S14{'Florence', 'Nightingale'} got %+v", s.Value[1])
	}
	if s.Value[2].F1 != "Clara" || s.Value[2].F2 != "Barton" {
		t.Errorf("Expected S14{'Clara', 'Barton'} got %+v", s.Value[2])
	}
}

func TestCustomTypeSliceWithError(t *testing.T) {
	data := map[string][]string{
		"Value.0": []string{"Louisa May Alcott"},
		"Value.1": []string{"Florence Nightingale"},
		"Value.2": []string{"Clara"},
	}

	s := S13{}
	decoder := NewDecoder()

	if err := decoder.Decode(&s, data); err == nil {
		t.Error("Not detecting error in conversion")
	}
}

func TestNoTextUnmarshalerTypeSlice(t *testing.T) {
	data := map[string][]string{
		"Value.0": []string{"Louisa May Alcott"},
		"Value.1": []string{"Florence Nightingale"},
		"Value.2": []string{"Clara Barton"},
	}

	s := S15{}
	decoder := NewDecoder()

	if err := decoder.Decode(&s, data); err == nil {
		t.Error("Not detecting when there's no converter")
	}
}

// ----------------------------------------------------------------------------

type S17 struct {
	Value S14
}

type S18 struct {
	Value S16
}

func TestCustomType(t *testing.T) {
	data := map[string][]string{
		"Value": []string{"Louisa May Alcott"},
	}

	s := S17{}
	decoder := NewDecoder()

	if err := decoder.Decode(&s, data); err != nil {
		t.Fatal(err)
	}

	if s.Value.F1 != "Louisa" || s.Value.F2 != "Alcott" {
		t.Errorf("Expected S14{'Louisa', 'Alcott'} got %+v", s.Value)
	}
}

func TestCustomTypeWithError(t *testing.T) {
	data := map[string][]string{
		"Value": []string{"Louisa"},
	}

	s := S17{}
	decoder := NewDecoder()

	if err := decoder.Decode(&s, data); err == nil {
		t.Error("Not detecting error in conversion")
	}
}

func TestNoTextUnmarshalerType(t *testing.T) {
	data := map[string][]string{
		"Value": []string{"Louisa May Alcott"},
	}

	s := S18{}
	decoder := NewDecoder()

	if err := decoder.Decode(&s, data); err == nil {
		t.Error("Not detecting when there's no converter")
	}
}

func TestExpectedType(t *testing.T) {
	data := map[string][]string{
		"bools":   []string{"1", "a"},
		"date":    []string{"invalid"},
		"Foo.Bar": []string{"a", "b"},
	}

	type B struct {
		Bar *int
	}
	type A struct {
		Bools []bool    `schema:"bools"`
		Date  time.Time `schema:"date"`
		Foo   B
	}

	a := A{}

	err := NewDecoder().Decode(&a, data)

	e := err.(MultiError)["bools"].(ConversionError)
	if e.Type != reflect.TypeOf(false) && e.Index == 1 {
		t.Errorf("Expected bool, index: 1 got %+v, index: %d", e.Type, e.Index)
	}
	e = err.(MultiError)["date"].(ConversionError)
	if e.Type != reflect.TypeOf(time.Time{}) {
		t.Errorf("Expected time.Time got %+v", e.Type)
	}
	e = err.(MultiError)["Foo.Bar"].(ConversionError)
	if e.Type != reflect.TypeOf(0) {
		t.Errorf("Expected int got %+v", e.Type)
	}
}

type R1 struct {
	A string `schema:"a,required"`
	B struct {
		C int     `schema:"c,required"`
		D float64 `schema:"d"`
		E string  `schema:"e,required"`
	} `schema:"b"`
	F []string `schema:"f,required"`
	G []int    `schema:"g,othertag"`
	H bool     `schema:"h,required"`
}

func TestRequiredField(t *testing.T) {
	var a R1
	v := map[string][]string{
		"a":   []string{"bbb"},
		"b.c": []string{"88"},
		"b.d": []string{"9"},
		"f":   []string{""},
		"h":   []string{"true"},
	}
	err := NewDecoder().Decode(&a, v)
	if err == nil {
		t.Errorf("error nil, b.e is empty expect")
		return
	}
	// b.e empty
	v["b.e"] = []string{""} // empty string
	err = NewDecoder().Decode(&a, v)
	if err == nil {
		t.Errorf("error nil, b.e is empty expect")
		return
	}

	// all fields ok
	v["b.e"] = []string{"nonempty"}
	err = NewDecoder().Decode(&a, v)
	if err != nil {
		t.Errorf("error: %v", err)
		return
	}

	// set f empty
	v["f"] = []string{}
	err = NewDecoder().Decode(&a, v)
	if err == nil {
		t.Errorf("error nil, f is empty expect")
		return
	}
	v["f"] = []string{"nonempty"}

	// b.c type int with empty string
	v["b.c"] = []string{""}
	err = NewDecoder().Decode(&a, v)
	if err == nil {
		t.Errorf("error nil, b.c is empty expect")
		return
	}
	v["b.c"] = []string{"3"}

	// h type bool with empty string
	v["h"] = []string{""}
	err = NewDecoder().Decode(&a, v)
	if err == nil {
		t.Errorf("error nil, h is empty expect")
		return
	}
}
