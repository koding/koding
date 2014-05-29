package sftp

import (
	"bytes"
	"testing"
)

var marshalUint32Tests = []struct {
	v    uint32
	want []byte
}{
	{1, []byte{0, 0, 0, 1}},
	{256, []byte{0, 0, 1, 0}},
	{^uint32(0), []byte{255, 255, 255, 255}},
}

func TestMarshalUint32(t *testing.T) {
	for _, tt := range marshalUint32Tests {
		got := marshalUint32(nil, tt.v)
		if !bytes.Equal(tt.want, got) {
			t.Errorf("marshalUint32(%d): want %v, got %v", tt.v, tt.want, got)
		}
	}
}

var marshalUint64Tests = []struct {
	v    uint64
	want []byte
}{
	{1, []byte{0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x1}},
	{256, []byte{0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x1, 0x0}},
	{^uint64(0), []byte{0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff}},
	{1 << 32, []byte{0x0, 0x0, 0x0, 0x1, 0x0, 0x0, 0x0, 0x0}},
}

func TestMarshalUint64(t *testing.T) {
	for _, tt := range marshalUint64Tests {
		got := marshalUint64(nil, tt.v)
		if !bytes.Equal(tt.want, got) {
			t.Errorf("marshalUint64(%d): want %#v, got %#v", tt.v, tt.want, got)
		}
	}
}

var marshalStringTests = []struct {
	v    string
	want []byte
}{
	{"", []byte{0, 0, 0, 0}},
	{"/foo", []byte{0x0, 0x0, 0x0, 0x4, 0x2f, 0x66, 0x6f, 0x6f}},
}

func TestMarshalString(t *testing.T) {
	for _, tt := range marshalStringTests {
		got := marshalString(nil, tt.v)
		if !bytes.Equal(tt.want, got) {
			t.Errorf("marshalString(%q): want %#v, got %#v", tt.v, tt.want, got)
		}
	}
}

var marshalTests = []struct {
	v    interface{}
	want []byte
}{
	{uint8(1), []byte{1}},
	{byte(1), []byte{1}},
	{uint32(1), []byte{0, 0, 0, 1}},
	{uint64(1), []byte{0, 0, 0, 0, 0, 0, 0, 1}},
	{"foo", []byte{0x0, 0x0, 0x0, 0x3, 0x66, 0x6f, 0x6f}},
	{struct {
		V uint32
		S string
	}{}, []byte{0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0}},
	{struct {
		V uint32
		S string
	}{500, "blah"}, []byte{0x0, 0x0, 0x1, 0xf4, 0x0, 0x0, 0x0, 0x4, 0x62, 0x6c, 0x61, 0x68}},
	{[]uint32{1, 2, 3, 4}, []byte{0x0, 0x0, 0x0, 0x1, 0x0, 0x0, 0x0, 0x2, 0x0, 0x0, 0x0, 0x3, 0x0, 0x0, 0x0, 0x4}},
	{struct {
		Q struct{ V uint64 }
		S string
		T []struct {
			V  uint32
			V2 uint32
		}
	}{}, []byte{0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0}},
}

func TestMarshal(t *testing.T) {
	for _, tt := range marshalTests {
		got := marshal(nil, tt.v)
		if !bytes.Equal(tt.want, got) {
			t.Errorf("marshal(%v): want %#v, got %#v", tt.v, tt.want, got)
		}
	}
}

var unmarshalUint32Tests = []struct {
	b    []byte
	want uint32
	rest []byte
}{
	{[]byte{0, 0, 0, 0}, 0, nil},
	{[]byte{0, 0, 1, 0}, 256, nil},
	{[]byte{255, 0, 0, 255}, 4278190335, nil},
}

func TestUnmarshalUint32(t *testing.T) {
	for _, tt := range unmarshalUint32Tests {
		got, rest := unmarshalUint32(tt.b)
		if got != tt.want || !bytes.Equal(rest, tt.rest) {
			t.Errorf("unmarshalUint32(%v): want %v, %#v, got %v, %#v", tt.b, tt.want, tt.rest, got, rest)
		}
	}
}

var unmarshalUint64Tests = []struct {
	b    []byte
	want uint64
	rest []byte
}{
	{[]byte{0, 0, 0, 0, 0, 0, 0, 0}, 0, nil},
	{[]byte{0, 0, 0, 0, 0, 0, 1, 0}, 256, nil},
	{[]byte{255, 0, 0, 0, 0, 0, 0, 255}, 18374686479671623935, nil},
}

func TestUnmarshalUint64(t *testing.T) {
	for _, tt := range unmarshalUint64Tests {
		got, rest := unmarshalUint64(tt.b)
		if got != tt.want || !bytes.Equal(rest, tt.rest) {
			t.Errorf("unmarshalUint64(%v): want %v, %#v, got %v, %#v", tt.b, tt.want, tt.rest, got, rest)
		}
	}
}

var unmarshalStringTests = []struct {
	b    []byte
	want string
	rest []byte
}{
	{marshalString(nil, ""), "", nil},
	{marshalString(nil, "blah"), "blah", nil},
}

func TestUnmarshalString(t *testing.T) {
	for _, tt := range unmarshalStringTests {
		got, rest := unmarshalString(tt.b)
		if got != tt.want || !bytes.Equal(rest, tt.rest) {
			t.Errorf("unmarshalUint64(%v): want %q, %#v, got %q, %#v", tt.b, tt.want, tt.rest, got, rest)
		}
	}
}

type ssh_fx_init struct {
	Type       byte
	Version    uint32
	Extensions []struct {
		Name, Data string
	}
}

var sendPacketTests = []struct {
	p    interface{}
	want []byte
}{
	{ssh_fx_init{
		Type:    ssh_FXP_INIT,
		Version: 3,
		Extensions: []struct{ Name, Data string }{
			{"posix-rename@openssh.com", "1"},
		},
	}, []byte{0x0, 0x0, 0x0, 0x26, 0x1, 0x0, 0x0, 0x0, 0x3, 0x0, 0x0, 0x0, 0x18, 0x70, 0x6f, 0x73, 0x69, 0x78, 0x2d, 0x72, 0x65, 0x6e, 0x61, 0x6d, 0x65, 0x40, 0x6f, 0x70, 0x65, 0x6e, 0x73, 0x73, 0x68, 0x2e, 0x63, 0x6f, 0x6d, 0x0, 0x0, 0x0, 0x1, 0x31}},
}

func TestSendPacket(t *testing.T) {
	for _, tt := range sendPacketTests {
		var w bytes.Buffer
		sendPacket(&w, tt.p)
		if got := w.Bytes(); !bytes.Equal(tt.want, got) {
			t.Errorf("sendPacket(%v): want %#v, got %#v", tt.p, tt.want, got)
		}
	}
}

func sp(p interface{}) []byte {
	var w bytes.Buffer
	sendPacket(&w, p)
	return w.Bytes()
}

var recvPacketTests = []struct {
	b    []byte
	want uint8
	rest []byte
}{
	{sp(ssh_fx_init{
		Type:    ssh_FXP_INIT,
		Version: 3,
		Extensions: []struct{ Name, Data string }{
			{"posix-rename@openssh.com", "1"},
		},
	}), ssh_FXP_INIT, []byte{0x0, 0x0, 0x0, 0x3, 0x0, 0x0, 0x0, 0x18, 0x70, 0x6f, 0x73, 0x69, 0x78, 0x2d, 0x72, 0x65, 0x6e, 0x61, 0x6d, 0x65, 0x40, 0x6f, 0x70, 0x65, 0x6e, 0x73, 0x73, 0x68, 0x2e, 0x63, 0x6f, 0x6d, 0x0, 0x0, 0x0, 0x1, 0x31}},
}

func TestRecvPacket(t *testing.T) {
	for _, tt := range recvPacketTests {
		r := bytes.NewReader(tt.b)
		got, rest, _ := recvPacket(r)
		if got != tt.want || !bytes.Equal(rest, tt.rest) {
			t.Errorf("recvPacket(%#v): want %v, %#v, got %v, %#v", tt.b, tt.want, tt.rest, got, rest)
		}
	}
}
