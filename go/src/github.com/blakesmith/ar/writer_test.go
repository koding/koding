package ar

import (
	"bytes"
	"io/ioutil"
	"os"
	"testing"
	"time"
)

func TestGlobalHeaderWrite(t *testing.T) {
	var buf bytes.Buffer
	writer := NewWriter(&buf)
	if err := writer.WriteGlobalHeader(); err != nil {
		t.Errorf(err.Error())
	}

	globalHeader := buf.Bytes()
	expectedHeader := []byte("!<arch>\n")
	if !bytes.Equal(globalHeader, expectedHeader) {
		t.Errorf("Global header should be %s but is %s", expectedHeader, globalHeader)
	}
}

func TestSimpleFile(t *testing.T) {
	hdr := new(Header)
	body := "Hello world!\n"
	hdr.ModTime = time.Unix(1361157466, 0)
	hdr.Name = "hello.txt"
	hdr.Size = int64(len(body))
	hdr.Mode = 0644
	hdr.Uid = 501
	hdr.Gid = 20

	var buf bytes.Buffer
	writer := NewWriter(&buf)
	writer.WriteGlobalHeader()
	writer.WriteHeader(hdr)
	_, err := writer.Write([]byte(body))
	if err != nil {
		t.Errorf(err.Error())
	}

	f, _ := os.Open("./fixtures/hello.a")
	defer f.Close()

	b, err := ioutil.ReadAll(f)
	if err != nil {
		t.Errorf(err.Error())
	}

	actual := buf.Bytes()
	if !bytes.Equal(b, actual) {
		t.Errorf("Expected %s to equal %s", actual, b)
	}
}

func TestWriteTooLong(t *testing.T) {
	body := "Hello world!\n"

	hdr := new(Header)
	hdr.Size = 1

	var buf bytes.Buffer
	writer := NewWriter(&buf)
	writer.WriteHeader(hdr)
	_, err := writer.Write([]byte(body))
	if err != ErrWriteTooLong {
		t.Errorf("Error should have been: %s", ErrWriteTooLong)
	}
}