// Imported from https://github.com/bazil/fuse.
package fuseklient

type MountInfo struct {
	FSName string
	Type   string
}

func GetMountByPath(path string) (*MountInfo, error) {
	return getMountInfo(path)
}

// cstr converts a nil-terminated C string into a Go string
func cstr(ca []int8) string {
	s := make([]byte, 0, len(ca))
	for _, c := range ca {
		if c == 0x00 {
			break
		}
		s = append(s, byte(c))
	}
	return string(s)
}
