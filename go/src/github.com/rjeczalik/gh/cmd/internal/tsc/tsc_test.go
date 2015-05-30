package tsc

import (
	"bytes"
	"io"
	"path/filepath"
	"testing"
)

var script = filepath.Join("testdata", "script.tsc")

func pipe() (*bytes.Buffer, func() io.Writer) {
	buf := &bytes.Buffer{}
	fn := func() io.Writer { return buf }
	return buf, fn
}

func TestScript(t *testing.T) {
	cases := [...]struct {
		args    []string
		name    string
		payload interface{}
		output  []byte
	}{{
		nil,
		"name",
		"payload",
		[]byte("name=name\npayload=payload\n"),
	}, {
		[]string{"-flag", "value"},
		"name",
		"payload",
		[]byte("name=name\npayload=payload\nFlag=value\n"),
	}, {
		[]string{"-a", "b", "-c", "d", "-e", "f"},
		"name",
		"payload",
		[]byte("name=name\npayload=payload\nA=b\nC=d\nE=f\n"),
	}}
	for i, cas := range cases {
		sc, err := New(script, cas.args)
		if err != nil {
			t.Errorf("New()=%v (i=%d)", err, i)
			continue
		}
		buf, out := pipe()
		sc.OutputFunc = out
		sc.Webhook(cas.name, cas.payload)
		if !bytes.Equal(buf.Bytes(), cas.output) {
			t.Errorf("want output=%q; got %q (i=%d)", cas.output, buf.Bytes(), i)
			continue
		}
	}
}
