package journal

import (
	"io"
	"io/ioutil"
	"net"
	"testing"
)

func TestPrintf(t *testing.T) {
	err := Printf("hello %s", "world")
	if err != nil {
		t.Fatal(err)
	}
}

func TestSend(t *testing.T) {
	err := Send("MESSAGE=hello world")
	t.Log(err)
}

func TestSendMultiline(t *testing.T) {
	err := Send("MESSAGE=hello\nworld")
	t.Log(err)
}

func BenchmarkPrintf(b *testing.B) {
	conn, _ := net.ListenUnixgram("unixgram", &net.UnixAddr{Name: "@dummy", Net: "unixgram"})
	go io.Copy(ioutil.Discard, conn)
	defer conn.Close()

	h := &Handle{path: "@dummy"}
	for i := 0; i < b.N; i++ {
		h.Printf("hello %s", "world")
	}
}

func BenchmarkSend(b *testing.B) {
	conn, _ := net.ListenUnixgram("unixgram", &net.UnixAddr{Name: "@dummy", Net: "unixgram"})
	go io.Copy(ioutil.Discard, conn)
	defer conn.Close()

	h := &Handle{path: "@dummy"}
	for i := 0; i < b.N; i++ {
		h.Send("MESSAGE=hello world")
	}
}
