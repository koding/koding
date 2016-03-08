package vnc

import (
	"testing"
	"net"
	"time"
	"bytes"
)

type fakeNetConnection struct {
	DataToSend []byte
	Test *testing.T
	ExpectData []byte
	Finished bool
	Matched bool
}

func (fc fakeNetConnection) Read(b []byte) (n int, err error) {
	for i := 0; i < 16; i++ {
		b[i] = fc.DataToSend[i]
	}

	fc.Finished = false

	return len(b), nil
}

func (fc *fakeNetConnection) Write(b []byte) (n int, err error) {
	fc.Matched = bytes.Equal(b, fc.ExpectData)
	fc.Finished = true

	return len(b), nil
}

func (fc *fakeNetConnection) Close() error { return nil; }
func (fc *fakeNetConnection) LocalAddr() net.Addr { return nil; }
func (fc *fakeNetConnection) RemoteAddr() net.Addr { return nil; }
func (fc *fakeNetConnection) SetDeadline(t time.Time) error { return nil; }
func (fc *fakeNetConnection) SetReadDeadline(t time.Time) error { return nil; }
func (fc *fakeNetConnection) SetWriteDeadline(t time.Time) error { return nil; }

func TestClientAuthNone_Impl(t *testing.T) {
	var raw interface{}
	raw = new(ClientAuthNone)
	if _, ok := raw.(ClientAuth); !ok {
		t.Fatal("ClientAuthNone doesn't implement ClientAuth")
	}
}

func TestClientAuthPasswordSuccess_Impl(t *testing.T) {
	// Values ripped using WireShark
	randomValue := []byte{
		0xa4,
		0x51,
		0x3f,
		0xa5,
		0x1f,
		0x87,
		0x06,
		0x10,
		0xa4,
		0x5f,
		0xae,
		0xbf,
		0x4d,
		0xac,
		0x12,
		0x22,
	}

	expectedResponse := []byte{
		0x71,
		0xe4,
		0x41,
		0x30,
		0x43,
		0x65,
		0x4e,
		0x39,
		0xda,
		0x6d,
		0x49,
		0x93,
		0x43,
		0xf6,
		0x5e,
		0x29,
	}

	raw := PasswordAuth{Password: "Ch_#!T@8"}

	// Only about 12 hours into Go at the moment...
	// if _, ok := raw.(ClientAuth); !ok {
	// 	t.Fatal("PasswordAuth doesn't implement ClientAuth")
	// }

	conn := &fakeNetConnection{DataToSend: randomValue, ExpectData: expectedResponse, Test: t}
	err := raw.Handshake(conn)

	if (err != nil) {
		t.Fatal(err)
	}

	if !conn.Matched {
		t.Fatal("PasswordAuth didn't pass the right response back to the wire")
	}

	if !conn.Finished {
		t.Fatal("PasswordAuth didn't complete properly")
	}
}

func TestClientAuthPasswordReject_Impl(t *testing.T) {
	// Values ripped using WireShark
	randomValue := []byte{
		0xa4,
		0x51,
		0x3f,
		0xa5,
		0x1f,
		0x87,
		0x06,
		0x10,
		0xa4,
		0x5f,
		0xae,
		0xbf,
		0x4d,
		0xac,
		0x12,
		0x22,
	}

	expectedResponse := []byte{
		0x71,
		0xe4,
		0x41,
		0x30,
		0x43,
		0x65,
		0x4e,
		0x39,
		0xda,
		0x6d,
		0x49,
		0x93,
		0x43,
		0xf6,
		0x5e,
		0x29,
	}

	raw := PasswordAuth{Password: "Ch_#!T@"}

	conn := &fakeNetConnection{DataToSend: randomValue, ExpectData: expectedResponse, Test: t}
	err := raw.Handshake(conn)

	if (err != nil) {
		t.Fatal(err)
	}

	if conn.Matched {
		t.Fatal("PasswordAuth didn't pass the right response back to the wire")
	}

	if !conn.Finished {
		t.Fatal("PasswordAuth didn't complete properly")
	}
}