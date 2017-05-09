// +build darwin dragonfly freebsd linux nacl netbsd openbsd solaris

package node

import (
	"os"
	"syscall"
)

// Inode gets file inode number.
func Inode(info os.FileInfo) uint64 {
	if stat, ok := info.Sys().(*syscall.Stat_t); ok && stat != nil {
		return uint64(stat.Ino)
	}

	panic("file inode does not exist: " + info.Name())
}
