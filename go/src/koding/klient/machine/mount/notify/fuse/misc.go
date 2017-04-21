package fuse

import (
	"context"
	"os"
	"syscall"

	xnetctx "golang.org/x/net/context"
)

// toErrno is a modified version of hanwen/go-fuse `ToStatus`` function. It
// converts error interface to system's error number or returns ENOSYS if the
// error code cannot be obtained.
func toErrno(err error) syscall.Errno {
	switch err {
	case nil:
		return 0
	case os.ErrPermission:
		return syscall.EPERM
	case os.ErrExist:
		return syscall.EEXIST
	case os.ErrNotExist:
		return syscall.ENOENT
	case os.ErrInvalid:
		return syscall.EINVAL
	}

	switch t := err.(type) {
	case syscall.Errno:
		return t
	case *os.SyscallError:
		return t.Err.(syscall.Errno)
	case *os.PathError:
		return toErrno(t.Err)
	case *os.LinkError:
		return toErrno(t.Err)
	}

	return syscall.ENOSYS
}

// ignoreCtxCancel filters out context.Canceled errors.
func ignoreCtxCancel(err error) error {
	switch err {
	case context.Canceled, xnetctx.Canceled:
		return nil
	default:
		return err
	}
}

func nonil(err ...error) error {
	for _, e := range err {
		if e != nil {
			return e
		}
	}
	return nil
}
