package fuseklient

import "github.com/jacobsa/fuse"

func unmount(dir string) error {
	return fuse.Unmount(dir)
}
