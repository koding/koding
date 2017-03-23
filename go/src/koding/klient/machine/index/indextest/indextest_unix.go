// +build !windows

package indextest

import (
	"os"
	"syscall"
)

// Sync causes all buffered modifications to file metadata and data to be
// written to the underlying file systems. This function must be called in order
// to not receive false negative test results.
func Sync() {
	// Disable sync(2) test calls on continuous integration environments.
	if os.Getenv("CI") == "" {
		syscall.Sync()
	}
}
