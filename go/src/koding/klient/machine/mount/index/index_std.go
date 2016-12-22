// +build !darwin,!linux

package index

import (
	"os"
	"syscall"
	"time"
)

// ctimeFromSys is a stub for platforms that does not have ctime implementation.
func ctimeFromSys(_ os.FileInfo) int64 {
	return 0
}
