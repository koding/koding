package ar

import (
	"io"
	"io/ioutil"
	"os"
	"testing"
	"time"
)

func TestAr(t *testing.T) {
	f, err := os.Open("testdata/pack.a")
	if err != nil {
		t.Fatal(err)
	}
	defer f.Close()
	ar := NewReader(f)

	hdr, err := ar.Next()
	if err != nil {
		t.Fatal(err)
	}
	if hdr.Name != "test.txt" {
		t.Errorf("got name %q, expected %q", hdr.Name, "test.txt")
	}
	if hdr.Size != 26 {
		t.Errorf("got size %d, expected 26", hdr.Size)
	}
	data, err := ioutil.ReadAll(ar)
	if err != nil {
		t.Fatal("read error", err)
	}
	if string(data) != "This is a test text file.\n" {
		t.Errorf("bad data %q, expected %q", data, "This is a test text file.\n")
	}

	hdr, err = ar.Next()
	if err != nil {
		t.Fatal(err)
	}
	expected := &Header{Name: "gophercolor16x16", Stamp: time.Unix(0, 0), Size: 785, Mode: 0644}
	if *hdr != *expected {
		t.Errorf("got %+v, expected %+v", hdr, expected)
	}
	data, err = ioutil.ReadAll(ar)
	if err != nil {
		t.Fatal(err)
	}
	if len(data) != 785 {
		t.Errorf("bad data size %d, expected 785", len(data))
	}

	hdr, err = ar.Next()
	if hdr != nil || err != io.EOF {
		t.Errorf("expected no header and EOF, got %+v and %v", hdr, err)
	}
}
