package fuse

import (
	"bytes"
	"errors"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"

	"koding/kites/config"
	"koding/klient/fs"
	"koding/klient/machine/index"
	"koding/klient/machine/mount/notify"

	"github.com/jacobsa/fuse"
	"github.com/jacobsa/fuse/fuseutil"
	"golang.org/x/net/context"
)

// TODO(rjeczalik): add promise update ops, so attrs updates are served
// right away, without waiting for index update.

// TODO(rjeczalik): symlink support: add node.Entry.Nlink field and
// add support for in Unlink, ForgotInode and CreateSymlink methods.

// Builder provides a default notify.Builder for the FUSE filesystem.
var Builder notify.Builder = builder{}

type builder struct{}

// Build implements the notify.Builder interface.
func (builder) Build(opts *notify.BuildOpts) (notify.Notifier, error) {
	di, err := fs.Statfs(opts.CacheDir)
	if err != nil {
		return nil, err
	}

	o := &Options{
		Index:    opts.Index,
		Disk:     di,
		Cache:    opts.Cache,
		CacheDir: opts.CacheDir,
		Mount:    filepath.Base(opts.Path),
		MountDir: opts.Path,
		// intentionally separate env to not enable fuse logging
		// for regular kd debug
		Debug: os.Getenv("KD_MOUNT_DEBUG") == "1",
	}

	if err := o.Valid(); err != nil {
		return nil, err
	}

	return NewFilesystem(o)
}

// Options configures FUSE filesystem.
type Options struct {
	Index    *index.Index // metadata index
	Disk     *fs.DiskInfo // filesystem information
	Cache    notify.Cache // used to request cache updates
	CacheDir string       // path of the cache directory of the mount
	Mount    string       // name of the mount
	MountDir string       // path of the mount directory
	User     *config.User // owner of the mount; if nil, config.CurrentUser is used
	Debug    bool         // turns on fuse debug logging
}

// Valid checks if provided options are valid.
func (o *Options) Valid() error {
	const sep = string(os.PathSeparator)

	if o.Index == nil {
		return errors.New("index is nil")
	}
	if o.Disk == nil {
		return errors.New("disk info is nil")
	}
	if o.Cache == nil {
		return errors.New("cache is nil")
	}
	if o.MountDir == "" {
		return errors.New("mount directory is empty")
	}
	if o.CacheDir == "" {
		return errors.New("cache directory is empty")
	}
	if !strings.HasSuffix(o.CacheDir, sep) {
		o.CacheDir = o.CacheDir + sep
	}
	if !strings.HasSuffix(o.MountDir, sep) {
		o.MountDir = o.MountDir + sep
	}

	return nil
}

func (o *Options) user() *config.User {
	if o.User != nil {
		return o.User
	}
	return config.CurrentUser
}

var _ fuseutil.FileSystem = (*Filesystem)(nil)

// Filesystem implements fuseutil.FileSystem.
//
// List operations are backend by index.
// Write and read operations are backed by cache,
// which is populated lazily by notify.Cache.
type Filesystem struct {
	// NotImplementedFileSystem provides stubs for the following methods:
	//
	//   - MkNode
	//   - CreateSymlink
	//   - ReadSymlink
	//
	fuseutil.NotImplementedFileSystem
	Options

	// Cancel the background context of all fuse operatins.
	cancel func()

	// Dynamic filesystem state.
	dirHandles  *DirHandleGroup
	fileHandles *FileHandleGroup
}

// FSWrapFunc allows to attach middlerares to underling filesystems.
type FSWrapFunc func(fuseutil.FileSystem) fuseutil.FileSystem

// NewFilesystem creates new Filesystem value.
func NewFilesystem(opts *Options, wraps ...FSWrapFunc) (*Filesystem, error) {
	if err := opts.Valid(); err != nil {
		return nil, err
	}

	// Best-effort attempt of unmounting already existing mount.
	_ = Umount(opts.MountDir)

	// Ignore mkdir errors since it can return `file exists` error. Other errors
	// will cause FUSE backend fail.
	_ = os.MkdirAll(opts.MountDir, 0755)

	ctx, cancel := context.WithCancel(context.Background())

	gen := generator(MinHandleID)
	fs := &Filesystem{
		Options:     *opts,
		cancel:      cancel,
		dirHandles:  NewDirHandleGroup(opts.MountDir, gen),
		fileHandles: NewFileHandleGroup(gen),
	}

	// Attach additional filesystem wrappers if any.
	var fuseFS fuseutil.FileSystem = fs
	for _, wrap := range wraps {
		fuseFS = wrap(fuseFS)
	}

	m, err := fuse.Mount(opts.MountDir, fuseutil.NewFileSystemServer(fuseFS), fs.Config())
	if err != nil {
		return nil, err
	}

	go m.Join(ctx)

	return fs, nil
}

// Config constructs fuse configuration.
func (fs *Filesystem) Config() *fuse.MountConfig {
	var logger *log.Logger

	if fs.Debug {
		logger = log.New(os.Stderr, "fuse", log.LstdFlags|log.Lshortfile)
	}

	return &fuse.MountConfig{
		FSName:                  fs.Mount,
		VolumeName:              filepath.Base(fs.MountDir),
		DisableWritebackCaching: true,
		EnableVnodeCaching:      false,
		Options:                 map[string]string{"allow_other": ""},
		DebugLogger:             logger,
		ErrorLogger:             logger,
	}
}

// Close implements the notify.Notifier interface. It cleans up filesystem
// resources and tries to umount created device.
func (fs *Filesystem) Close() error {
	fs.cancel()
	fs.Destroy()

	return Umount(fs.MountDir)
}

// Umount unmounts FUSE filesystem.
func Umount(dir string) error {
	umountCmd := func(name string, args ...string) error {
		if p, err := exec.Command(name, args...).CombinedOutput(); err != nil {
			return fmt.Errorf("%s: %s", err, bytes.TrimSpace(p))
		}

		return nil
	}

	if runtime.GOOS == "linux" {
		if err := fuse.Unmount(dir); err != nil {
			return umountCmd("fusermount", "-uz", dir) // Try lazy umount.
		}
		return nil
	}

	// Under Darwin fuse.Umount uses syscall.Umount without syscall.MNT_FORCE flag,
	// so we replace that implementation with diskutil.
	return umountCmd("diskutil", "unmount", "force", dir)
}
