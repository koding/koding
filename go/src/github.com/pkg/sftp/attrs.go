package sftp

// ssh_FXP_ATTRS support
// see http://tools.ietf.org/html/draft-ietf-secsh-filexfer-02#section-5

import (
	"os"
	"syscall"
	"time"
)

const (
	ssh_FILEXFER_ATTR_SIZE        = 0x00000001
	ssh_FILEXFER_ATTR_UIDGID      = 0x00000002
	ssh_FILEXFER_ATTR_PERMISSIONS = 0x00000004
	ssh_FILEXFER_ATTR_ACMODTIME   = 0x00000008
	ssh_FILEXFER_ATTR_EXTENDED    = 0x80000000
)

type attr struct {
	name  string
	size  uint64
	mode  os.FileMode
	mtime time.Time
}

// Name returns the base name of the file.
func (a *attr) Name() string { return a.name }

// Size returns the length in bytes for regular files; system-dependent for others.
func (a *attr) Size() int64 { return int64(a.size) }

// Mode returns file mode bits.
func (a *attr) Mode() os.FileMode { return a.mode }

// ModTime returns the last modification time of the file.
func (a *attr) ModTime() time.Time { return a.mtime }

// IsDir returns true if the file is a directory.
func (a *attr) IsDir() bool { return a.Mode().IsDir() }

func (a *attr) Sys() interface{} { return a }

func unmarshalAttrs(b []byte) (*attr, []byte) {
	flags, b := unmarshalUint32(b)
	var a attr
	if flags&ssh_FILEXFER_ATTR_SIZE == ssh_FILEXFER_ATTR_SIZE {
		a.size, b = unmarshalUint64(b)
	}
	if flags&ssh_FILEXFER_ATTR_UIDGID == ssh_FILEXFER_ATTR_UIDGID {
		_, b = unmarshalUint32(b) // discarded
	}
	if flags&ssh_FILEXFER_ATTR_UIDGID == ssh_FILEXFER_ATTR_UIDGID {
		_, b = unmarshalUint32(b) // discarded
	}
	if flags&ssh_FILEXFER_ATTR_PERMISSIONS == ssh_FILEXFER_ATTR_PERMISSIONS {
		var mode uint32
		mode, b = unmarshalUint32(b)
		a.mode = toFileMode(mode)
	}
	if flags&ssh_FILEXFER_ATTR_ACMODTIME == ssh_FILEXFER_ATTR_ACMODTIME {
		var mtime uint32
		_, b = unmarshalUint32(b) // discarded
		mtime, b = unmarshalUint32(b)
		a.mtime = time.Unix(int64(mtime), 0)
	}
	if flags&ssh_FILEXFER_ATTR_EXTENDED == ssh_FILEXFER_ATTR_EXTENDED {
		var count uint32
		count, b = unmarshalUint32(b)
		for i := uint32(0); i < count; i++ {
			_, b = unmarshalString(b)
			_, b = unmarshalString(b)
		}
	}
	return &a, b
}

// toFileMode converts sftp filemode bits to the os.FileMode specification
func toFileMode(mode uint32) os.FileMode {
	var fm = os.FileMode(mode & 0777)
	switch mode & syscall.S_IFMT {
	case syscall.S_IFBLK:
		fm |= os.ModeDevice
	case syscall.S_IFCHR:
		fm |= os.ModeDevice | os.ModeCharDevice
	case syscall.S_IFDIR:
		fm |= os.ModeDir
	case syscall.S_IFIFO:
		fm |= os.ModeNamedPipe
	case syscall.S_IFLNK:
		fm |= os.ModeSymlink
	case syscall.S_IFREG:
		// nothing to do
	case syscall.S_IFSOCK:
		fm |= os.ModeSocket
	}
	if mode&syscall.S_ISGID != 0 {
		fm |= os.ModeSetgid
	}
	if mode&syscall.S_ISUID != 0 {
		fm |= os.ModeSetuid
	}
	if mode&syscall.S_ISVTX != 0 {
		fm |= os.ModeSticky
	}
	return fm
}
