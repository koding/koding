// +build !darwin
// +build !dragonfly
// +build !freebsd
// +build !linux
// +build !nacl
// +build !netbsd
// +build !openbsd
// +build !solaris

package node

import "os"

// Inode always returns zero.
func Inode(_ os.FileInfo) uint64 { return 0 }
