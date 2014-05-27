package sftp

import (
	"bytes"
	"os"
	"reflect"
	"testing"
)

// ensure that attrs implemenst os.FileInfo
var _ os.FileInfo = new(attr)

var unmarshalAttrsTests = []struct {
	b    []byte
	want attr
	rest []byte
}{
	{marshal(nil, struct{ Flags uint32 }{}), attr{}, nil},
	{marshal(nil, struct {
		Flags uint32
		Size  uint64
	}{ssh_FILEXFER_ATTR_SIZE, 20}), attr{size: 20}, nil},
	{marshal(nil, struct {
		Flags       uint32
		Size        uint64
		Permissions uint32
	}{ssh_FILEXFER_ATTR_SIZE | ssh_FILEXFER_ATTR_PERMISSIONS, 20, 0644}), attr{size: 20, mode: os.FileMode(0644)}, nil},
	{marshal(nil, struct {
		Flags                 uint32
		Size                  uint64
		Uid, Gid, Permissions uint32
	}{ssh_FILEXFER_ATTR_SIZE | ssh_FILEXFER_ATTR_UIDGID | ssh_FILEXFER_ATTR_UIDGID | ssh_FILEXFER_ATTR_PERMISSIONS, 20, 1000, 1000, 0644}), attr{size: 20, mode: os.FileMode(0644)}, nil},
}

func TestUnmarshalAttrs(t *testing.T) {
	for _, tt := range unmarshalAttrsTests {
		got, rest := unmarshalAttrs(tt.b)
		if !reflect.DeepEqual(*got, tt.want) || !bytes.Equal(tt.rest, rest) {
			t.Errorf("unmarshalAttrs(%#v): want %#v, %#v, got: %#v, %#v", tt.b, tt.want, tt.rest, got, rest)
		}
	}
}
