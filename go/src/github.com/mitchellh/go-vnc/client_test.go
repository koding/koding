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

func TestParseProtocolVersion(t *testing.T) {
	tests := []struct {
		proto        []byte
		major, minor uint
		isErr        bool
	}{
		// Valid ProtocolVersion messages.
		{[]byte{82, 70, 66, 32, 48, 48, 51, 46, 48, 48, 56, 10}, 3, 8, false},   // RFB 003.008\n
		{[]byte{82, 70, 66, 32, 48, 48, 51, 46, 56, 56, 57, 10}, 3, 889, false}, // RFB 003.889\n -- OS X 10.10.3
		{[]byte{82, 70, 66, 32, 48, 48, 48, 46, 48, 48, 48, 10}, 0, 0, false},   // RFB 000.0000\n
		// Invalid messages.
		{[]byte{82, 70, 66, 32, 51, 46, 56, 10}, 0, 0, true}, // RFB 3.8\n -- too short; not zero padded
		{[]byte{82, 70, 66, 10}, 0, 0, true},                 // RFB\n -- too short
		{[]byte{}, 0, 0, true},                               // (empty) -- too short
	}

	for _, tt := range tests {
		major, minor, err := parseProtocolVersion(tt.proto)
		if err != nil && !tt.isErr {
			t.Fatalf("parseProtocolVersion(%v) unexpected error %v", tt.proto, err)
		}
		if err == nil && tt.isErr {
			t.Fatalf("parseProtocolVersion(%v) expected error", tt.proto)
		}
		if major != tt.major {
			t.Errorf("parseProtocolVersion(%v) major = %v, want %v", tt.proto, major, tt.major)
		}
		if major != tt.major {
			t.Errorf("parseProtocolVersion(%v) minor = %v, want %v", tt.proto, minor, tt.minor)
		}
	}
}
