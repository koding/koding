package fuse

import (
	stdcontext "context"
	"errors"
	"log"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"syscall"
	"time"

	"koding/kites/config"
	"koding/klient/fs"
	"koding/klient/machine/index"
	"koding/klient/machine/mount/notify"

	"github.com/jacobsa/fuse"
	origfuse "github.com/jacobsa/fuse"
	"github.com/jacobsa/fuse/fuseops"
	"github.com/jacobsa/fuse/fuseutil"
	"golang.org/x/net/context"
)

// TODO(rjeczalik): add promise update ops, so attrs updates are served
// right away, without waiting for index update.

// TODO(rjeczalik): symlink support: add index.Entry.Nlink field and
// add support for in Unlink, ForgotInode and CreateSymlink methods.

// Builder provides a default notify.Builder for the FUSE filesystem.
var Builder notify.Builder = builder{}

type builder struct{}

func block(path string) *fs.DiskInfo {
	stfs := syscall.Statfs_t{}

	if err := syscall.Statfs(path, &stfs); err != nil {
		return nil
	}

	di := &fs.DiskInfo{
		BlockSize:   uint32(stfs.Bsize),
		BlocksTotal: stfs.Blocks,
		BlocksFree:  stfs.Bfree,
		IOSize:      stfs.Iosize,
	}

	di.BlocksUsed = di.BlocksTotal - di.BlocksFree

	return di
}

// Build implements the notify.Builder interface.
func (builder) Build(opts *notify.BuildOpts) (notify.Notifier, error) {
	o := &Opts{
		Index:    opts.Index,
		Cache:    opts.Cache,
		CacheDir: opts.CacheDir,
		Mount:    filepath.Base(opts.Mount.Path),
		MountDir: opts.Mount.Path,
		// intentionally separate env to not enable fuse logging
		// for regular kd debug
		Debug: os.Getenv("KD_MOUNT_DEBUG") == "1",
	}

	// TODO(ppknap) get disk info from client.
	if o.Disk == nil {
		o.Disk = block(opts.CacheDir)
	}

	if err := o.Valid(); err != nil {
		return nil, err
	}

	return NewFilesystem(o)
}

// Opts configures FUSE filesystem.
type Opts struct {
	Index    *index.Index // metadata index
	Disk     *fs.DiskInfo // filesystem information
	Cache    notify.Cache // used to request cache updates
	CacheDir string       // path of the cache directory of the mount; must end with a dangling /
	Mount    string       // name of the mount
	MountDir string       // path of the mount directory
	User     *config.User // owner of the mount; if nil, config.CurrentUser is used
	Debug    bool         // turns on fuse debug logging
}

// Valid implements the stack.Validator interface.
func (o *Opts) Valid() error {
	const sep = string(os.PathSeparator)

	if o.Index == nil {
		return errors.New("index is nil")
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
	return nil
}

func (opts *Opts) user() *config.User {
	if opts.User != nil {
		return opts.User
	}
	return config.CurrentUser
}

type dir struct {
	files  []string
	offset int
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
	Opts

	cancel func()

	mu        sync.RWMutex
	seq       uint64
	inodes    map[fuseops.InodeID]string
	seqHandle uint64
	handles   map[fuseops.HandleID]*os.File
}

var _ fuseutil.FileSystem = (*Filesystem)(nil)

// NewFilesystem creates new Filesystem value.
func NewFilesystem(opts *Opts) (*Filesystem, error) {
	if err := os.MkdirAll(opts.MountDir, 0755); err != nil {
		return nil, err
	}

	ctx, cancel := context.WithCancel(context.Background())

	fs := &Filesystem{
		Opts:   *opts,
		cancel: cancel,
		seq:    uint64(fuseops.RootInodeID),
		inodes: map[fuseops.InodeID]string{
			fuseops.RootInodeID: "",
		},
		seqHandle: uint64(3),
		handles:   make(map[fuseops.HandleID]*os.File),
	}

	// Best-effort attempt of unmounting already existing mount.
	_ = Umount(fs.MountDir)

	m, err := origfuse.Mount(opts.MountDir, fuseutil.NewFileSystemServer(fs), fs.Config())
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

func (fs *Filesystem) DebugString() string {
	return fs.Index.DebugString()
}

func (fs *Filesystem) add(path string) (id fuseops.InodeID) {
	for {
		fs.seq++

		if fs.seq <= fuseops.RootInodeID {
			fs.seq = fuseops.RootInodeID + 1
		}

		id = fuseops.InodeID(fs.seq)

		if _, ok := fs.inodes[id]; !ok {
			fs.inodes[id] = path
			break
		}
	}

	return id
}

func (fs *Filesystem) addHandle(f *os.File) (id fuseops.HandleID) {
	for {
		fs.seqHandle++

		if fs.seqHandle < 3 {
			fs.seqHandle = 3
		}

		id = fuseops.HandleID(fs.seqHandle)

		if _, ok := fs.handles[id]; !ok {
			fs.handles[id] = f
			break
		}
	}

	return id
}

func (fs *Filesystem) lookupInodeID(dir, base string, entry *index.Entry) (id fuseops.InodeID) {
	// Fast path - check if InodeID was already associated with index node.
	if id = fuseops.InodeID(entry.Inode()); id != 0 {
		return id
	}

	path := filepath.Join(dir, base)

	fs.mu.Lock()
	id = fs.add(path)
	entry.SetInode(uint64(id))
	fs.mu.Unlock()

	return id
}

func (fs *Filesystem) get(id fuseops.InodeID) (*index.Node, string, bool) {
	fs.mu.RLock()
	path, ok := fs.inodes[id]
	fs.mu.RUnlock()

	if !ok {
		return nil, "", false
	}

	nd, ok := fs.Index.Lookup(path)
	if !ok {
		return nil, "", false
	}

	return nd, path, true
}

func (fs *Filesystem) getDir(id fuseops.InodeID) (*index.Node, string, error) {
	nd, path, ok := fs.get(id)
	if !ok {
		return nil, "", fuse.ENOENT
	}

	if !isdir(nd.Entry) {
		return nil, "", fuse.EIO
	}

	return nd, path, nil
}

func (fs *Filesystem) getFile(id fuseops.InodeID) (*index.Node, string, error) {
	nd, path, ok := fs.get(id)
	if !ok {
		return nil, "", fuse.ENOENT
	}

	if isdir(nd.Entry) {
		return nil, "", fuse.EIO
	}

	return nd, path, nil
}

func (fs *Filesystem) del(id fuseops.InodeID) {
	fs.mu.Lock()
	delete(fs.inodes, id)
	fs.mu.Unlock()
}

func (fs *Filesystem) delHandle(id fuseops.HandleID) error {
	fs.mu.Lock()
	f, nd, ok := fs.getHandle(id)
	delete(fs.handles, id)
	fs.mu.Unlock()

	if !ok {
		return nil
	}

	nd.Entry.DecRefCount()

	return f.Close()
}

func (fs *Filesystem) getHandle(id fuseops.HandleID) (*os.File, *index.Node, bool) {
	f, ok := fs.handles[id]
	if !ok {
		return nil, nil, false
	}

	path := f.Name()

	if strings.HasPrefix(path, fs.CacheDir) {
		path = path[len(fs.CacheDir):]
	}

	nd, ok := fs.Index.Lookup(path)
	if !ok || nd.Deleted() {
		return nil, nil, false
	}

	return f, nd, true
}

func (fs *Filesystem) commit(path string, meta index.ChangeMeta) stdcontext.Context {
	return fs.Cache.Commit(index.NewChange(path, meta))
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

func (fs *Filesystem) attr(entry *index.Entry) fuseops.InodeAttributes {
	mtime := time.Unix(0, entry.MTime())
	ctime := time.Unix(0, entry.CTime())

	return fuseops.InodeAttributes{
		Size:   uint64(entry.Size()),
		Nlink:  1, // TODO(rjeczalik): symlink / hardlink implementation
		Mode:   entry.Mode(),
		Atime:  mtime,
		Mtime:  mtime,
		Ctime:  ctime,
		Crtime: ctime,
		Uid:    uint32(fs.user().Uid),
		Gid:    uint32(fs.user().Gid),
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

func (fs *Filesystem) path(loc string) string {
	return filepath.Join(fs.CacheDir, loc)
}

func (fs *Filesystem) mkdir(path string, mode os.FileMode) (id fuseops.InodeID, err error) {
	if err = os.MkdirAll(fs.path(path), mode); err != nil {
		return 0, err
	}

	entry := index.NewEntry(0, mode|os.ModeDir)
	entry.IncRefCount()

	fs.mu.Lock()
	id = fs.add(path)
	fs.mu.Unlock()

	entry.SetInode(uint64(id))

	fs.Index.PromiseAdd(path, entry)

	return id, nil
}

func (fs *Filesystem) mkfile(path string, mode os.FileMode) (id fuseops.InodeID, h fuseops.HandleID, err error) {
	absPath := fs.path(path)

	if err := os.MkdirAll(filepath.Dir(absPath), 0755); err != nil {
		return 0, 0, err
	}

	f, err := os.Create(absPath)
	if err != nil {
		return 0, 0, err
	}

	_ = f.Chmod(mode)

	entry := index.NewEntry(0, mode)
	entry.IncRefCount()

	fs.mu.Lock()
	id = fs.add(path)
	h = fs.addHandle(f)
	fs.mu.Unlock()

	entry.SetInode(uint64(id))

	fs.Index.PromiseAdd(path, entry)

	return id, h, nil
}

func (fs *Filesystem) move(ctx stdcontext.Context, oldpath, newpath string) error {
	absOld := fs.path(oldpath)
	absNew := fs.path(newpath)

	if _, err := os.Stat(absOld); os.IsNotExist(err) {
		if err = fs.yield(ctx, oldpath, index.ChangeMetaRemote|index.ChangeMetaAdd); err != nil {
			return err
		}
	}

	if err := os.MkdirAll(filepath.Dir(absNew), 0755); err != nil {
		return err
	}

	return os.Rename(fs.path(oldpath), fs.path(newpath))
}

func (fs *Filesystem) unlink(ctx stdcontext.Context, nd *index.Node, path string) error {
	fs.Index.PromiseUnlink(path, nd)

	if n := nd.Entry.DecRefCount(); n > 0 {
		return nil
	}

	return fs.rm(ctx, nd, path)
}

func (fs *Filesystem) rm(ctx stdcontext.Context, nd *index.Node, path string) error {
	fs.Index.PromiseDel(path, nd)
	nd.Entry.SetInode(0)

	path = fs.path(path)

	if err := os.Remove(path); os.IsNotExist(err) {
		return nil
	}

	fs.commit(path, index.ChangeMetaLocal|index.ChangeMetaRemove)

	return nil
}

func (fs *Filesystem) update(ctx stdcontext.Context, f *os.File, nd *index.Node) error {
	err := f.Sync()

	_ = updateSize(f, nd)

	fs.commit(f.Name(), index.ChangeMetaLocal|index.ChangeMetaUpdate)

	return err
}

func (fs *Filesystem) open(ctx stdcontext.Context, nd *index.Node, path string) (*os.File, fuseops.HandleID, error) {
	f, err := fs.openFile(ctx, path, nd.Entry.Mode())
	if err != nil {
		return nil, 0, err
	}

	fs.mu.Lock()
	id := fs.addHandle(f)
	fs.mu.Unlock()

	nd.Entry.IncRefCount()

	return f, id, nil
}

func (fs *Filesystem) openFile(ctx stdcontext.Context, path string, mode os.FileMode) (*os.File, error) {
	path = fs.path(path)

	f, err := os.OpenFile(path, os.O_RDWR, mode)
	if os.IsNotExist(err) {
		err = fs.yield(ctx, path, index.ChangeMetaAdd|index.ChangeMetaRemote)
		if err != nil {
			return nil, err
		}

		f, err = os.OpenFile(path, os.O_RDWR, mode)
	}

	if os.IsPermission(err) {
		f, err = os.OpenFile(path, os.O_RDONLY, mode)
	}

	return f, err
}

func (fs *Filesystem) openInode(ctx stdcontext.Context, id fuseops.InodeID) (*os.File, fuseops.HandleID, error) {
	nd, path, err := fs.getFile(id)
	if err != nil {
		return nil, 0, err
	}

	return fs.open(ctx, nd, path)
}

func (fs *Filesystem) openHandle(id fuseops.HandleID) (*os.File, error) {
	fs.mu.RLock()
	f, ok := fs.handles[id]
	fs.mu.RUnlock()

	if !ok {
		return nil, fuse.ENOENT
	}

	return f, nil
}

func (fs *Filesystem) openHandleNode(id fuseops.HandleID) (*os.File, *index.Node, error) {
	fs.mu.RLock()
	f, nd, ok := fs.getHandle(id)
	fs.mu.RUnlock()

	if !ok {
		return nil, nil, fuse.ENOENT
	}

	return f, nd, nil
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

func updateSize(f *os.File, nd *index.Node) error {
	fi, err := f.Stat()
	if err != nil {
		return err
	}

	nd.Entry.SetSize(fi.Size())

	return nil
}

func direntType(entry *index.Entry) fuseutil.DirentType {
	if isdir(entry) {
		return fuseutil.DT_Directory
	}
	return fuseutil.DT_File
}

func isdir(entry *index.Entry) bool {
	return entry.Mode()&os.ModeDir == os.ModeDir
}

func nonil(err ...error) error {
	for _, e := range err {
		if e != nil {
			return e
		}
	}
	return nil
}

// ignore filters out context.Canceled errors.
func ignore(err error) error {
	switch err {
	case context.Canceled, stdcontext.Canceled:
		return nil
	default:
		return err
	}
}
