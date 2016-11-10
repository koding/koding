package object_test

import (
	"bytes"
	"koding/kites/kloud/utils/object"
	"strings"
	"testing"
)

type Value struct {
	S string
}

func (v *Value) String() string {
	return v.S
}

type FooBar struct {
	Field1  string
	Field2  int
	Field3  Value
	XField4 []byte `json:"Field4"`
}

func TestPrinter(t *testing.T) {
	v := []interface{}{
		FooBar{Field1: "1", Field2: 2, Field3: Value{S: "3"}, XField4: []byte{4}},
		&FooBar{Field1: "2", Field2: 4, Field3: Value{S: "6"}, XField4: []byte{8}},
	}

	want := `
FIELD1  FIELD2  FIELD3  FIELD4
1       2       {3}     [4]
2       4       6       [8]
`

	var buf bytes.Buffer

	p := object.Printer{
		Tag: "json",
		W:   &buf,
	}

	if err := p.Print(v); err != nil {
		t.Fatalf("Print()=%s", err)
	}

	want = strings.TrimSpace(want)
	got := strings.TrimSpace(buf.String())

	if got != want {
		t.Fatalf("got:\n%s\nwant:\n%s\n", got, want)
	}
}
