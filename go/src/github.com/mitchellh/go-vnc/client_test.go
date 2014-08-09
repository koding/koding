package vnc

import (
	"fmt"
	"net"
	"testing"
)

func newMockServer(t *testing.T, version string) string {
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("error listening: %s", err)
	}

	go func() {
		defer ln.Close()
		c, err := ln.Accept()
		if err != nil {
			t.Fatalf("error accepting conn: %s", err)
		}
		defer c.Close()

		_, err = c.Write([]byte(fmt.Sprintf("RFB %s\n", version)))
		if err != nil {
			t.Fatal("failed writing version")
		}
	}()

	return ln.Addr().String()
}

func TestClient_LowMajorVersion(t *testing.T) {
	nc, err := net.Dial("tcp", newMockServer(t, "002.009"))
	if err != nil {
		t.Fatalf("error connecting to mock server: %s", err)
	}

	_, err = Client(nc, &ClientConfig{})
	if err == nil {
		t.Fatal("error expected")
	}

	if err.Error() != "unsupported major version, less than 3: 2" {
		t.Fatalf("unexpected error: %s", err)
	}
}

func TestClient_LowMinorVersion(t *testing.T) {
	nc, err := net.Dial("tcp", newMockServer(t, "003.007"))
	if err != nil {
		t.Fatalf("error connecting to mock server: %s", err)
	}

	_, err = Client(nc, &ClientConfig{})
	if err == nil {
		t.Fatal("error expected")
	}

	if err.Error() != "unsupported minor version, less than 8: 7" {
		t.Fatalf("unexpected error: %s", err)
	}
}
