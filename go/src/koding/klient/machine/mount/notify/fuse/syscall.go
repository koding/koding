package fuse

import (
	"os"
	"path/filepath"
	"syscall"

	"github.com/jacobsa/fuse/fuseops"
)

// getMountPointParentInode gets the moutpoint parent directory inode from its
// filesystem. The presence of this function allows to add dot-dot direntry when
// calling readDir on root direcory.
func getMountPointParentInode(mountpoint string) fuseops.InodeID {
	info, err := os.Lstat(filepath.Dir(mountpoint))
	if err != nil {
		return 0
	}

	if sys := info.Sys(); sys != nil {
		stat, ok := sys.(*syscall.Stat_t)
		if !ok || stat == nil {
			return 0
		}
		return fuseops.InodeID(stat.Ino)
	}

	return 0
}
