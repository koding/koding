package vdeck

import (
	"reflect"
	"strings"
	"testing"
)

var vcard = VCard{
	FullName: "Anonymous Coward",
	Name:     NameField{FamilyName: "Anonymous", GivenName: "Coward"},
	Tel: []TypedString{
		TypedString{Type: []string{"CELL"}, Value: "+33612345678"},
		TypedString{Type: []string{"WORK"}, Value: "+33123456789"},
	},
	Email: []TypedString{
		TypedString{Value: "anonymous.coward@example.com"},
		TypedString{Type: []string{"internet", "pref"}, Value: "coward@anonymous.org"},
	},
	Address: []AddrField{AddrField{
		Type:    []string{"HOME"},
		Street:  "42 Coward St",
		Country: "Sealand",
	}},
	Uid:        "coward",
	Categories: []string{"A", "b", "cat,comma"},
	Version:    "3.0",
}

const expected = `
BEGIN:VCARD
FN:Anonymous Coward
N:Anonymous;Coward;;;
ADR;TYPE=HOME:;;42 Coward St;;;;Sealand
TEL;TYPE=CELL:+33612345678
TEL;TYPE=WORK:+33123456789
EMAIL:anonymous.coward@example.com
EMAIL;TYPE=internet,pref:coward@anonymous.org
CATEGORIES:A,b,cat\,comma
UID:coward
VERSION:3.0
END:VCARD
`

func TestPrint(t *testing.T) {
	s := strings.TrimSpace(vcard.String())
	s2 := strings.TrimSpace(expected)
	if s != s2 {
		t.Logf("got %s, expected %s", s, s2)
	}

	vc, err := ParseVcard(strings.NewReader(expected))
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(*vc, vcard) {
		t.Logf("got %s, expected %s", *vc, vcard)
	}
}

func TestEscape(t *testing.T) {
	s := joinList([]string{"a", "b", "c,d"}, ',')
	if s != "a,b,c\\,d" {
		t.Errorf("got %q, expected %q", s, "a,b,c\\,d")
	}

	s2 := joinList(splitList(s, ','), ',')
	if s != s2 {
		t.Errorf("got %q, expected %q", s2, s)
	}

	slice := splitList("Hello;World;;;", ';')
	expect := []string{"Hello", "World", "", "", ""}
	if !reflect.DeepEqual(slice, expect) {
		t.Errorf("got %q, expected %q", slice, expect)
	}
}

func BenchmarkParse(b *testing.B) {
	for i := 0; i < b.N; i++ {
		_, err := ParseVcard(strings.NewReader(expected))
		if err != nil {
			b.Fatal(err)
		}
	}
}

func BenchmarkPrint(b *testing.B) {
	var s string
	for i := 0; i < b.N; i++ {
		s = vcard.String()
	}
	_ = s
}
