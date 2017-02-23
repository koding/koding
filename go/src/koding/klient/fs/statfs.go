// +build !linux,!darwin

package fs

import (
	"errors"
	"runtime"
)

func Statfs(string) (*DiskInfo, error) {
	return nil, errors.New("not implemented on " + runtime.GOOS)
}
