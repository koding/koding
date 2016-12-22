// +build linux

package index

import (
	"os"
	"syscall"
	"time"
)

// ctimeFromSys uses system specific calls to obtain file metadata change time.
func ctimeFromSys(fi os.FileInfo) int64 {
	stat, ok := fi.Sys().(*syscall.Stat_t)
	if !ok || stat == nil {
		return 0
	}

	return time.Unix(int64(stat.Ctim.Sec), int64(stat.Ctim.Nsec)).UnixNano()
}
