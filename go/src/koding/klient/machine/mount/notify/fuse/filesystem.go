package fuse

import (
	stdcontext "context"
	"errors"
	"log"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"koding/kites/config"
	"koding/klient/fs"
	"koding/klient/machine/index"
	"koding/klient/machine/index/node"
	"koding/klient/machine/mount/notify"

	"github.com/jacobsa/fuse"
	"github.com/jacobsa/fuse/fuseops"
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

// HandleInfo contains information about file handle destination.
type HandleInfo struct {
	InodeID fuseops.InodeID
	File    *os.File
}

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

	cancel func()

	// Dynamic filesystem state.
	dirHandles  *DirHandleGroup
	fileHandles *FileHandleGroup

	mu        sync.RWMutex
	seqHandle uint64
	handles   map[fuseops.HandleID]HandleInfo
}

var _ fuseutil.FileSystem = (*Filesystem)(nil)

// NewFilesystem creates new Filesystem value.
func NewFilesystem(opts *Options) (*Filesystem, error) {
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
		dirHandles:  NewDirHandleGroup(gen),
		fileHandles: NewFileHandleGroup(gen),
		seqHandle:   uint64(3),
		handles:     make(map[fuseops.HandleID]HandleInfo),
	}

	m, err := fuse.Mount(opts.MountDir, fuseutil.NewFileSystemServer(fs), fs.Config())
	if err != nil {
		return nil, err
	}

	go m.Join(ctx)

	return fs, nil
}

// Close implements the notify.Notifier interface.
func (fs *Filesystem) Close() error {
	fs.cancel()
	fs.Destroy()

	return Umount(fs.MountDir)
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

func (fs *Filesystem) addHandle(nID fuseops.InodeID, f *os.File) (id fuseops.HandleID) {
	for {
		fs.seqHandle++

		if fs.seqHandle < 3 {
			fs.seqHandle = 3
		}

		id = fuseops.HandleID(fs.seqHandle)

		if _, ok := fs.handles[id]; !ok {
			fs.handles[id] = HandleInfo{
				InodeID: nID,
				File:    f,
			}
			break
		}
	}

	return id
}

// checkDir checks if provided node describes a directory.
func checkDir(n *node.Node) error {
	if !n.Exist() {
		return fuse.ENOENT
	}

	if !n.Entry.File.Mode.IsDir() {
		return fuse.ENOTDIR
	}

	return nil
}

func (fs *Filesystem) delHandle(id fuseops.HandleID) error {
	fs.mu.Lock()
	f, nID, ok := fs.getHandle(id)
	delete(fs.handles, id)
	fs.mu.Unlock()

	if !ok {
		return nil
	}

	fs.Index.Tree().DoInode(uint64(nID), func(_ node.Guard, n *node.Node) {
		if n == nil {
			return
		}

		n.Entry.Virtual.CountDec()
	})

	return f.Close()
}

func (fs *Filesystem) getHandle(id fuseops.HandleID) (*os.File, fuseops.InodeID, bool) {
	hi, ok := fs.handles[id]
	if !ok {
		return nil, 0, false
	}
	return hi.File, hi.InodeID, true
}

func (fs *Filesystem) commit(rel string, meta index.ChangeMeta) stdcontext.Context {
	return fs.Cache.Commit(index.NewChange(rel, index.PriorityHigh, meta))
}

func (fs *Filesystem) yield(ctx stdcontext.Context, path string, meta index.ChangeMeta) error {
	c := fs.commit(path, meta)

	select {
	case <-c.Done():
		return ignore(c.Err())
	case <-ctx.Done():
		return ignore(ctx.Err())
	}
}

func (fs *Filesystem) attr(entry *node.Entry) fuseops.InodeAttributes {
	mtime := time.Unix(0, entry.File.MTime)
	ctime := time.Unix(0, entry.File.CTime)

	return fuseops.InodeAttributes{
		Size:  uint64(entry.File.Size),
		Nlink: 1, // TODO(rjeczalik): symlink / hardlink implementation
		Mode:  entry.File.Mode,

		Atime:  mtime,
		Mtime:  mtime,
		Ctime:  ctime,
		Crtime: ctime,

		Uid: uint32(fs.user().Uid),
		Gid: uint32(fs.user().Gid),
	}
}

func (fs *Filesystem) newAttr(mode os.FileMode) fuseops.InodeAttributes {
	t := time.Now()

	return fuseops.InodeAttributes{
		Size:   0,
		Nlink:  1,
		Mode:   mode,
		Atime:  t,
		Mtime:  t,
		Ctime:  t,
		Crtime: t,
		Uid:    uint32(fs.user().Uid),
		Gid:    uint32(fs.user().Gid),
	}
}

func (fs *Filesystem) abs(rel string) string {
	return fs.CacheDir + rel
}

func (fs *Filesystem) rel(abs string) string {
	return strings.TrimPrefix(abs, fs.CacheDir)
}

func (fs *Filesystem) move(ctx stdcontext.Context, oldrel, newrel string) error {
	absOld := fs.abs(oldrel)
	absNew := fs.abs(newrel)

	if _, err := os.Stat(absOld); os.IsNotExist(err) {
		if err = fs.yield(ctx, oldrel, index.ChangeMetaRemote|index.ChangeMetaAdd); err != nil {
			return err
		}
	}

	if err := os.MkdirAll(filepath.Dir(absNew), 0755); err != nil {
		return err
	}

	return os.Rename(absOld, absNew)
}

func (fs *Filesystem) unlink(n *node.Node) error {
	if rc := n.Entry.Virtual.CountDec(); rc > 0 {
		n.PromiseUnlink()
		return nil
	}

	return fs.rm(n)
}

func (fs *Filesystem) rm(n *node.Node) error {
	n.PromiseDel()

	path := n.Path()
	if err := os.Remove(fs.abs(path)); os.IsNotExist(err) {
		return nil
	}

	fs.commit(path, index.ChangeMetaLocal|index.ChangeMetaRemove)

	return nil
}

func (fs *Filesystem) open(ctx stdcontext.Context, n *node.Node) (*os.File, fuseops.HandleID, error) {
	f, err := fs.openFile(ctx, n.Path(), n.Entry.File.Mode)
	if err != nil {
		return nil, 0, err
	}

	fs.mu.Lock()
	id := fs.addHandle(fuseops.InodeID(n.Entry.Virtual.Inode), f)
	fs.mu.Unlock()

	n.Entry.Virtual.CountInc()

	return f, id, nil
}

func (fs *Filesystem) openFile(ctx stdcontext.Context, rel string, mode os.FileMode) (*os.File, error) {
	abs := fs.abs(rel)

	f, err := os.OpenFile(abs, os.O_RDWR, mode)
	if os.IsNotExist(err) {
		err = fs.yield(ctx, rel, index.ChangeMetaAdd|index.ChangeMetaRemote)
		if err != nil {
			return nil, err
		}

		f, err = os.OpenFile(abs, os.O_RDWR, mode)
	}

	if os.IsPermission(err) {
		f, err = os.OpenFile(abs, os.O_RDONLY, mode)
	}

	return f, err
}

func (fs *Filesystem) openHandleInfo(id fuseops.HandleID) (*os.File, fuseops.InodeID, error) {
	fs.mu.RLock()
	f, nID, ok := fs.getHandle(id)
	fs.mu.RUnlock()

	if !ok {
		return nil, 0, fuse.ENOENT
	}

	return f, nID, nil
}

func trimRightNull(p []byte) []byte {
	for i := len(p) - 1; i >= 0; i-- {
		if p[i] != 0 {
			break
		}

		p = p[:i]
	}

	return p
}

func direntType(entry *node.Entry) fuseutil.DirentType {
	if entry.File.Mode.IsDir() {
		return fuseutil.DT_Directory
	}
	return fuseutil.DT_File
}
