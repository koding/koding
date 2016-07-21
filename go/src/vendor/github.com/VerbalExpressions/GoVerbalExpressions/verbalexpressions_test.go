// Copyright 2013 Patrice FERLET
// Use of this source code is governed by MIT-style
// license that can be found in the LICENSE file
package verbalexpressions

import "testing"
import "strings"

func assertStringEquals(s1, s2 string, t *testing.T) {
	if s1 != s2 {
		t.Errorf("%s != %s", s1, s2)
	}
}

func TestChaining(t *testing.T) {

	exp := "http://www.google.com"
	v := New().StartOfLine().
		Then("http").
		Maybe("s").
		Then("://").
		Maybe("www.").
		Word().
		Then(".").
		Word().
		Maybe("/").
		EndOfLine()
	if !v.Test(exp) {
		t.Errorf("%v regexp doesn't match %s", v.Regex(), exp)
	}
}

func TestRange(t *testing.T) {

	exp := "abcdef 123"

	v := New().Range("a", "z", 0, 9)
	if v.Regex().String() != "(?m)[a-z0-9]" {
		t.Errorf("%s is not (?m)[a-z0-9]", v.Regex())
	}
	if !v.Test(exp) {
		t.Errorf("%v regexp doesn't match %s", v.Regex(), exp)
	}
	exp = "ABCDEF"
	if v.Test(exp) {
		t.Errorf("%v regexp should not match %s", v.Regex(), exp)
	}

}

func TestPanicOnRangeOddParams(t *testing.T) {

	defer func() {
		// if no panic... the test fails
		if r := recover(); r == nil {
			t.Errorf("Call must panic !")
		}
	}()

	New().Range("a", "z", 0, 9, 10)
}

func TestOneLine(t *testing.T) {
	s := "atlanta\narkansas\nalabama\narachnophobia"

	v := New().SearchOneLine(true).Find("a").EndOfLine().Regex()
	res := v.FindAllStringIndex(s, -1)
	if len(res) != 1 {
		t.Errorf("%v should be length 1, %d instead", res, len(res))
	}
	if len(res[0]) != 2 {
		t.Errorf("%v should be length 2, %d instead", res[0], len(res[0]))
	}

	v = New().SearchOneLine(false).Find("a").EndOfLine().Regex()
	res = v.FindAllStringIndex(s, -1)
	if len(res) != 3 {
		t.Errorf("%v should be length 3, %d instead", res, len(res))
	}
	for _, r := range res {
		if len(r) != 2 {
			t.Errorf("%v should be length 2, %d instead", r, len(r))
		}
	}
}

func TestAnythingBut(t *testing.T) {

	s := "This is a simple test"
	v := New().AnythingBut("im").Regex().FindAllString(s, -1)
	for _, st := range v {
		if strings.Contains(st, "i") {
			t.Errorf("%s should not find \"i\"", st)
		}
		if strings.Contains(st, "m") {
			t.Errorf("%s should not find \"m\"", st)
		}
	}
}

func TestAny(t *testing.T) {

	s := "foo1 foo5 foobar"
	v := New().Find("foo").Any("1234567890")
	res := v.Regex().FindAllString(s, -1)
	if len(res) != 2 {
		t.Errorf("len(res) : %d isn't 2", len(res))
	}
	//test alias
	v = New().Find("foo").AnyOf("1234567890")
	res = v.Regex().FindAllString(s, -1)
	if len(res) != 2 {
		t.Errorf("len(res) : %d isn't 2", len(res))
	}

}

func TestReplace(t *testing.T) {

	s := "foomode barmode themodebaz"
	expect := "foochanged barchanged thechangedbaz"

	v := New().Find("mode")
	res := v.Replace(s, "changed")

	if res != expect {
		t.Errorf("Replacement hasn't worked as expected %s != %s", res, expect)
	}

}

func TestCaptures(t *testing.T) {

	s := "this is a foobarsystem to get bar"

	v := New().Anything().Find("foo").Find("bar").Word()
	res := v.Regex().FindAllStringSubmatch(s, -1)

	if len(res[0]) > 1 {
		t.Errorf("%v is not a slice of only one match (globale match)", res)
	}
	if res[0][0] != "this is a foobarsystem" {
		t.Errorf("global capture \"%s\" is not \"this is a foobarsystem\"", res[0][0])
	}

	v = New().Anything().Find("foo").BeginCapture().Find("bar").Word().EndCapture()
	res = v.Regex().FindAllStringSubmatch(s, -1)

	if len(res) != 1 {
		t.Errorf("%v is not slice length 1", res)
	}

	if res[0][0] != "this is a foobarsystem" {
		t.Errorf("global capture \"%s\" is not \"this is a foobarsystem\"", res[0][0])
	}
	if res[0][1] != "barsystem" {
		t.Errorf("capture %s is not barsystem", res[0][1])
	}

}

func TestSeveralCaptures(t *testing.T) {

	s := `
	this is a foobarsystem that matches my test
	And there, a new foobartest that should be ok
`

	v := New().Anything().Find("foo").
		BeginCapture().
		Find("bar").Word().
		EndCapture().
		SearchOneLine(false)
	res := v.Regex().FindAllStringSubmatch(s, -1)

	for i, r := range res {
		switch i {
		case 0:
			if r[1] != "barsystem" {
				t.Errorf("%s is not \"barsystem\"", r[1])
			}
		case 1:
			if r[1] != "bartest" {
				t.Errorf("%s is not \"bartest\"", r[1])
			}
		default:
			t.Errorf("%v is not allowed result", r)
		}
	}

}

func TestCaptureSeveralTimes(t *testing.T) {
	v := New().
		BeginCapture().
		Find("http"). // find http
		Maybe("s").   // + s if any
		Find("://").
		EndCapture(). // stop, so we will capture http:// and https://
		BeginCapture().
		Find("www.").Anything(). // capture url: www.google.com
		EndCapture()
	c := v.Captures("http://www.google.com")

	if len(c) != 1 {
		t.Errorf("capture length is not 1: %d", len(c))
	}

	if c[0][1] != "http://" {
		t.Errorf("first group should be http://, found: %s", c[0][1])
	}

	if c[0][2] != "www.google.com" {
		t.Errorf("first group should be www.google.com, found: %s", c[0][2])
	}

}

func TestCapturingSeveralGroups(t *testing.T) {

	s := `

<b>test 1</b>
<b>foo 2</b>

`
	v := New().
		Find("<b>").
		BeginCapture().
		Word().
		EndCapture().
		Any(" ").
		BeginCapture().
		Range("0", "9").
		EndCapture().
		Find("</b>")

	res := v.Captures(s)
	if len(res) != 2 {
		t.Errorf("%v is not length 2", res)
	}
	for i, r := range res {
		switch i {
		case 0:
			if r[1] != "test" || r[2] != "1" {
				t.Errorf("%s,%s is not test,1", r[1], r[2])
			}
		case 1:
			if r[1] != "foo" || r[2] != "2" {
				t.Errorf("%s,%s is not test,1", r[1], r[2])
			}
		default:
			t.Errorf("%d is not a valid result index for %v", i, res)
		}
	}

}

func TestORMethod(t *testing.T) {

	s := "foobarbaz footestbaz foonobaz"
	expected := []string{"foobarbaz", "footestbaz"}

	v := New().Find("foobarbaz").Or(New().Find("footestbaz"))
	if !v.Test(s) {
		t.Errorf("%s doesn't match %s", v.Regex(), s)
	}
	res := []string{}
	res = v.Regex().FindAllString(s, -1)

	if len(res) != 2 {
		t.Errorf("%v is not length 2", res)
	}

	for i, r := range res {
		if r != expected[i] {
			t.Errorf("%s is not expected value: %s", r, expected[i])
		}
	}

}

func TestMultipleMethod(t *testing.T) {

	v := New().Multiple("foo")
	assertStringEquals(v.Regex().String(), "(?m)(?:foo)+", t)

	// it the same... but to cover...
	v = New().Multiple("foo", 1)
	assertStringEquals(v.Regex().String(), "(?m)(?:foo)+", t)

	v = New().Multiple("foo", 0)
	assertStringEquals(v.Regex().String(), "(?m)(?:foo)*", t)

	v = New().Multiple("foo", 0, 1)
	assertStringEquals(v.Regex().String(), "(?m)(?:foo)?", t)

	v = New().Multiple("foo", 0, 10)
	assertStringEquals(v.Regex().String(), "(?m)(?:foo){,10}", t)

	v = New().Multiple("foo", 10)
	assertStringEquals(v.Regex().String(), "(?m)(?:foo){10,}", t)

	v = New().Multiple("foo", 10, 10)
	assertStringEquals(v.Regex().String(), "(?m)(?:foo){10,10}", t)

	v = New().Multiple("foo", 1, 10)
	assertStringEquals(v.Regex().String(), "(?m)(?:foo){1,10}", t)

}

func TestPanicMultipleMethod(t *testing.T) {
	defer func() {
		if r := recover(); r == nil {
			t.Errorf("We should have panic here !")
		}
	}()
	_ = New().Multiple("foo", 1, 10, 15)
}

func TestSomethingMethods(t *testing.T) {

	s := "abcdefghi"

	v := New().Find("ab").Something().Find("ef")
	res := v.Regex().FindAllString(s, -1)

	if res[0] != "abcdef" {
		t.Errorf("%v hasn't %s ", res, "abcdef")
	}

	v = New().Find("ab").SomethingBut("d")
	res = v.Regex().FindAllString(s, -1)
	if res[0] != "abc" {
		t.Errorf("%v hasn't %s ", res, "abc")
	}

}

func TestAllWithDot(t *testing.T) {

	s := `
foo bar
baz
`
	v := New().Find("bar").Anything().Then("baz")
	res := v.Test(s)
	if res {
		t.Errorf("Error, %s should not match bar.baz", v.Regex())
	}

	v.MatchAllWithDot(true)
	res = v.Test(s)
	if !res {
		t.Errorf("Error, %s should match bar.baz", v.Regex())
	}

}

func TestWithAnyCase(t *testing.T) {
	s := "A MESSAGE IN CAPS"

	v := New().Find("message").WithAnyCase(true)
	res := v.Test(s)
	if !res {
		t.Errorf("Error, message should match MESSAGE", v.Regex())
	}
}

func TestModifiers(t *testing.T) {
	v := New()
	assertStringEquals(v.getFlags(), "m", t)

	v.SearchOneLine(true)
	assertStringEquals(v.getFlags(), "", t)

	v.SearchOneLine(false)
	assertStringEquals(v.getFlags(), "m", t)

	v.WithAnyCase(true)
	assertStringEquals(v.getFlags(), "mi", t)

	v.WithAnyCase(false)
	assertStringEquals(v.getFlags(), "m", t)

	v.MatchAllWithDot(true)
	assertStringEquals(v.getFlags(), "ms", t)

	v.MatchAllWithDot(false)
	assertStringEquals(v.getFlags(), "m", t)

	v.flags = 16
	assertStringEquals(v.getFlags(), "", t)
}

func TestGlobalModifier(t *testing.T) {

	s := "aaa aab aba abc"

	v := New().BeginCapture().Find("aa").AnythingBut(" ").EndCapture()

	res := v.Captures(s)

	if len(res) != 2 {
		t.Errorf("Initial state, GLOBAL on: %v is not lenght 2", res)
	}

	v.StopAtFirst(true)
	res = v.Captures(s)
	if len(res) > 1 {
		t.Errorf("%v is not lenght 1", res)
	}

	v.StopAtFirst(false)
	res = v.Captures(s)
	if len(res) != 2 {
		t.Errorf("State 2, GLOBAL reactivated: %v is not lenght 2", res)
	}

}

func TestStartEndWithOR(t *testing.T) {
	s := `
foo
no
bar
bar foo bar
ok
not
test
foo bar foo
bar
`
	// This is a very hight problem
	// This should generate (?m)^(?:foo)$|^(?:bar)$
	v := New().
		StartOfLine().
		Find("foo").
		EndOfLine().
		Or(New().
		StartOfLine().
		Find("bar").
		EndOfLine())

	t.Log(v.Regex())
	res := v.Regex().FindAllStringSubmatch(s, -1)
	if len(res) != 3 {
		t.Errorf("%v is not length 3", res)
	}

	// another possibility
	v = New().
		StartOfLine().
		Find("foo").
		EndOfLine().
		Or(New().Find("bar"))

	res = v.Regex().FindAllStringSubmatch(s, -1)
	if len(res) != 6 {
		t.Errorf("%v is not length 6", res)
	}
}

func TestLineBreak(t *testing.T) {
	s := `
foo
bar
baz
`
	v := New().Find("foo").LineBreak().Find("bar")
	if !v.Test(s) {
		t.Errorf("%v should match %s", v.Regex(), s)
	}

	v = New().Find("foo").Br().Find("bar")
	if !v.Test(s) {
		t.Errorf("%v should match %s", v.Regex(), s)
	}
}

func TestTABMethod(t *testing.T) {
	s := "foo	bar baz"
	v := New().Find("foo").Tab().Find("bar")
	r := v.Test(s)
	if !r {
		t.Errorf("%v should match %s", v.Regex(), s)
	}
}

func TestToString(t *testing.T) {

	res := tostring(int64(15))
	if res != "15" {
		t.Errorf("%v is not string \"15\"", res)
	}

	res = tostring(uint64(15))
	if res != "15" {
		t.Errorf("%v is not string \"15\"", res)
	}

	res = tostring(uint(15))
	if res != "15" {
		t.Errorf("%v is not string \"15\"", res)
	}

}

func TestToStringMustPanic(t *testing.T) {

	defer func() {
		if r := recover(); r == nil {
			t.Errorf("ToString must panic with unsupported types")
		}
	}()

	s := make(chan int)
	_ = tostring(s)

}

func TestNotMethod(t *testing.T) {

	s := `foobarbaz
footestbaz
fooexceptingbaz
foootherokbaz
foofoofoo
foonotcap
`

	v := New().
		Find("foo").
		BeginCapture().
		Not("excepting").
		EndCapture().
		Then("baz")
	res := v.Captures(s)
	t.Log(res)
	if len(res) != 3 {
		t.Errorf("%v is not length 3", res)
	}
	for i, r := range res {
		switch i {
		case 0:
			if r[1] != "bar" {
				t.Errorf("%s is not bar", r)
			}
		case 1:
			if r[1] != "test" {
				t.Errorf("%s is not bar", r)
			}
		case 2:
			if r[1] != "otherok" {
				t.Errorf("%s is not bar", r)
			}
		}
	}

}

func TestAndOrCumulate(t *testing.T) {

	s := `AB
BC
AC
BB
CC
A
B
B
C
A
C
C
C`

	v1 := New().Find("B")
	t.Log(v1.Regex())
	v2 := New().Find("c").WithAnyCase(true).Or(v1) // Find B or C
	v := New().Find("A").And(v2)                   // Find A and (B or C)

	t.Log(v.Regex())
	res := v.Regex().FindAllStringSubmatch(s, -1)

	if len(res) != 2 {
		t.Errorf("%v is not length 2", res)
	}

	if res[0][0] != "AB" {
		t.Errorf("%v is not AB ", res[0][0])
	}
	if res[1][0] != "AC" {
		t.Errorf("%v is not AC ", res[1][0])
	}

}
