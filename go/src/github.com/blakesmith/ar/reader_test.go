package ar

import (
	"bytes"
	"io"
	"os"
	"testing"
	"time"
)

func TestReadHeader(t *testing.T) {
	f, err := os.Open("./fixtures/hello.a")
	defer f.Close()

	if err != nil {
		t.Errorf(err.Error())
	}
	reader := NewReader(f)
	header, err := reader.Next()
	if err != nil {
		t.Errorf(err.Error())
	}

	expectedName := "hello.txt"
	if header.Name != expectedName {
		t.Errorf("Header name should be %s but is %s", expectedName, header.Name)
	}
	expectedModTime := time.Unix(1361157466, 0)
	if header.ModTime != expectedModTime {
		t.Errorf("ModTime should be %s but is %s", expectedModTime, header.ModTime)
	}
	expectedUid := 501
	if header.Uid != expectedUid {
		t.Errorf("Uid should be %s but is %s", expectedUid, header.Uid)
	}
	expectedGid := 20
	if header.Gid != expectedGid {
		t.Errorf("Gid should be %s but is %s", expectedGid, header.Gid)
	}
	expectedMode := int64(0644)
	if header.Mode != expectedMode {
		t.Errorf("Mode should be %s but is %s", expectedMode, header.Mode)
	}
}

func TestReadBody(t *testing.T) {
	f, err := os.Open("./fixtures/hello.a")
	defer f.Close()

	if err != nil {
		t.Errorf(err.Error())
	}
	reader := NewReader(f)
	_, err = reader.Next()
	if err != nil && err != io.EOF {
		t.Errorf(err.Error())
	}
	var buf bytes.Buffer
	io.Copy(&buf, reader)

	expected := []byte("Hello world!\n")
	actual := buf.Bytes()
	if !bytes.Equal(actual, expected) {
		t.Errorf("Data value should be %s but is %s", expected, actual)
	}
}

func TestReadMulti(t *testing.T) {
	f, err := os.Open("./fixtures/multi_archive.a")
	defer f.Close()

	if err != nil {
		t.Errorf(err.Error())
	}
	reader := NewReader(f)
	var buf bytes.Buffer
	for {
		_, err := reader.Next()
		if err == io.EOF {
			break
		}
		if err != nil {
			t.Errorf(err.Error())
		}
		io.Copy(&buf, reader)
	}
	expected := []byte("Hello world!\nI love lamp.\n")
	actual := buf.Bytes()
	if !bytes.Equal(expected, actual) {
		t.Errorf("Concatted byte buffer should be %s but is %s", expected, actual)
	}
}