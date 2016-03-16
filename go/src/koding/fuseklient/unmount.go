package fuseklient

import "github.com/jacobsa/fuse"

func Unmount(dir string) error {
	return fuse.Unmount(dir)
}
