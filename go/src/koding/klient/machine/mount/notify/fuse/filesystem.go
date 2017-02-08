package fuse

import (
	stdcontext "context"
	"os"
	"path/filepath"
	"sort"
	"sync"
	"sync/atomic"
	"time"

	"koding/kites/config"
	"koding/klient/fs"
	"koding/klient/machine/index"
	"koding/klient/machine/mount/notify"

	"github.com/jacobsa/fuse"
	"github.com/jacobsa/fuse/fuseops"
	"github.com/jacobsa/fuse/fuseutil"
	"golang.org/x/net/context"
)

// TODO(rjeczalik): TTL for items on pending list; if a lot inodes were
// allocated but none were looked up, pending list will grow indefinitely.
// Prune pending list after the remote index was updated.

// Builder provides a default notify.Builder for the FUSE filesystem.
var Builder notify.Builder = builder{}

type builder struct{}

// Build implements the notify.Builder interface.
func (builder) Build(opts *notify.BuildOpts) (notify.Notifier, error) {
	o := &Opts{
		Local:    opts.LocalIdx,
		Remote:   opts.RemoteIdx,
		Cache:    opts.Cache,
		CacheDir: opts.CacheDir,
		Mount:    filepath.Base(opts.Mount.Path),
		MountDir: opts.Mount.Path,
	}

	return NewFilesystem(o)
}

// Opts configures FUSE filesystem.
type Opts struct {
	Local    *index.Index // local metadata index (needed?)
	Remote   *index.Index // remote metadata index
	Disk     *fs.DiskInfo // remote filesystem informartion
	Cache    notify.Cache // used to request cache updates
	CacheDir string       // path of the cache directory of the mount
	Mount    string       // name of the mount
	MountDir string       // path of the mount directory
	User     *config.User // owner of the mount; if nil, config.CurrentUser is used
}

func (opts *Opts) user() *config.User {
	if opts.User != nil {
		return opts.User
	}
	return config.CurrentUser
}

// Filesystem implements fuseutil.FileSystem.
//
// List operations are backend by remote index.
// Write and read operations are backed by cache,
// which is populated lazily by notify.Cache.
type Filesystem struct {
	// NotImplementedFileSystem provides stubs for the following methods:
	//
	//   - MkNode
	//   - CreateSymlink
	//   - ReleaseDirHandle
	//   - FlushFile
	//   - ForgetInode
	//   - ReadSymlink
	//
	fuseutil.NotImplementedFileSystem
	Opts

	mu        sync.RWMutex
	seq       uint64
	inodes    map[fuseops.InodeID]string
	seqHandle uint64
	handles   map[fuseops.HandleID]*os.File

	// pending list is used to temporarily cache new inodes,
	// created by MkDir, MkFile etc. methods until the Inode
	// is looked up for the first time. There's no guarantee
	// what will happen first - index get updated or the Inode
	// looked up.
	pending map[string]fuseops.InodeID
}

var _ fuseutil.FileSystem = (*Filesystem)(nil)

// NewFilesystem creates new Filesystem value.
func NewFilesystem(opts *Opts) (*Filesystem, error) {
	if err := os.MkdirAll(opts.MountDir, 0755); err != nil {
		return nil, err
	}

	fs := &Filesystem{
		Opts: *opts,
		seq:  uint64(fuseops.RootInodeID),
		inodes: map[fuseops.InodeID]string{
			fuseops.RootInodeID: "",
		},
		seqHandle: uint64(fuseops.RootInodeID),
		handles:   make(map[fuseops.HandleID]*os.File),
		pending:   make(map[string]fuseops.InodeID),
	}

	return fs, nil
}

// Close implements the notify.Notifier interface.
func (fs *Filesystem) Close() {
	fs.Destroy()
}

func (fs *Filesystem) config() *fuse.MountConfig {
	return &fuse.MountConfig{
		FSName:                  fs.Mount,
		VolumeName:              filepath.Base(fs.MountDir),
		DisableWritebackCaching: true,
		EnableVnodeCaching:      false,
		Options:                 map[string]string{"allow_other": ""},
	}
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
	if id = fuseops.InodeID(atomic.LoadUint64(&entry.Aux)); id != 0 {
		return id
	}

	path := filepath.Join(dir, base)

	fs.mu.Lock()
	// Slow path.
	//
	// Firstly see pending list to check if entry was recently created.
	// If yes,associate the InodeID with index' node.
	// If not, create new InodeID only if it was not written in the
	// meantime.
	var ok bool
	if id, ok = fs.pending[path]; ok {
		atomic.StoreUint64(&entry.Aux, uint64(id))
		delete(fs.pending, path)
	} else if id = fuseops.InodeID(atomic.LoadUint64(&entry.Aux)); id == 0 {
		id = fs.add(path)
		atomic.StoreUint64(&entry.Aux, uint64(id))
	}
	fs.mu.Unlock()

	return id
}

func (fs *Filesystem) mkInodeID(path string) (id fuseops.InodeID) {
	fs.mu.Lock()
	id = fs.add(path)
	fs.pending[path] = id
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

	nd, ok := fs.Remote.Lookup(path)
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
	f, ok := fs.handles[id]
	delete(fs.handles, id)
	fs.mu.Unlock()

	if ok {
		return f.Close()
	}

	return nil
}

func (fs *Filesystem) yield(ctx stdcontext.Context, path string, meta index.ChangeMeta) error {
	c := fs.Cache.Commit(index.NewChange(path, meta))

	select {
	case <-c.Done():
		return ignore(c.Err())
	case <-ctx.Done():
		return ignore(ctx.Err())
	}
}

func (fs *Filesystem) attr(entry *index.Entry) fuseops.InodeAttributes {
	mtime := time.Unix(0, entry.MTime)
	ctime := time.Unix(0, entry.CTime)

	return fuseops.InodeAttributes{
		Size:   uint64(entry.Size),
		Mode:   entry.Mode,
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

func (fs *Filesystem) mkdir(path string, mode os.FileMode) error {
	return os.MkdirAll(fs.path(path), mode)
}

func (fs *Filesystem) touch(ctx stdcontext.Context, path string, mode os.FileMode) error {
	path = fs.path(path)

	dir := filepath.Dir(path)

	if _, err := os.Stat(dir); os.IsNotExist(err) {
		// Best-effort attempt of synchronizing the destination directory,
		// it may not exist on remote.
		_ = fs.yield(ctx, dir, index.ChangeMetaRemote|index.ChangeMetaAdd)
	}

	f, err := os.Create(path)
	if os.IsExist(err) {
		return nil
	}
	if err != nil {
		return err
	}

	_ = f.Chmod(mode)

	return f.Close()
}

func (fs *Filesystem) move(ctx stdcontext.Context, oldpath, newpath string) error {
	if _, err := os.Stat(oldpath); os.IsNotExist(err) {
		if err = fs.yield(ctx, oldpath, index.ChangeMetaRemote|index.ChangeMetaAdd); err != nil {
			return err
		}
	}

	newDir := filepath.Dir(newpath)

	if _, err := os.Stat(newDir); os.IsNotExist(err) {
		// Best-effort attempt of synchronizing the destination directory,
		// it may not exist on remote.
		_ = fs.yield(ctx, newDir, index.ChangeMetaRemote|index.ChangeMetaAdd)
	}

	return os.Rename(fs.path(oldpath), fs.path(newpath))
}

func (fs *Filesystem) rm(nd *index.Node, path string) error {
	atomic.StoreUint64(&nd.Entry.Aux, 0)

	err := os.Remove(fs.path(path))
	if os.IsNotExist(err) {
		return nil
	}
	return err
}

func (fs *Filesystem) readdir(nd *index.Node, path string, off fuseops.DirOffset) ([]*fuseutil.Dirent, error) {
	names := make([]string, 0, len(nd.Sub))

	for name := range nd.Sub {
		names = append(names, name)
	}

	sort.Strings(names)

	if off > fuseops.DirOffset(len(names)) {
		return nil, fuse.EIO
	}

	dirent := make([]*fuseutil.Dirent, 0, len(names)-int(off))

	for i, name := range names {
		sub := nd.Sub[name]

		dirent = append(dirent, &fuseutil.Dirent{
			Offset: off + fuseops.DirOffset(i),
			Inode:  fs.lookupInodeID(path, name, sub.Entry),
			Name:   name,
			Type:   direntType(sub.Entry),
		})
	}

	return dirent, nil
}

func (fs *Filesystem) open(ctx stdcontext.Context, path string) (*os.File, fuseops.HandleID, error) {
	f, err := fs.openFile(ctx, path)
	if err != nil {
		return nil, 0, err
	}

	fs.mu.Lock()
	id := fs.addHandle(f)
	fs.mu.Unlock()

	return f, id, nil
}

func (fs *Filesystem) openFile(ctx stdcontext.Context, path string) (*os.File, error) {
	flag := os.O_RDWR
	path = fs.path(path)

	f, err := os.OpenFile(path, flag, 0755)
	if os.IsNotExist(err) {
		err = fs.yield(ctx, path, index.ChangeMetaAdd|index.ChangeMetaRemote)
		if err != nil {
			return nil, err
		}

		f, err = os.OpenFile(path, flag, 0755)
	}

	return f, err
}

func (fs *Filesystem) openInode(ctx stdcontext.Context, id fuseops.InodeID) (*os.File, fuseops.HandleID, error) {
	_, path, err := fs.getFile(id)
	if err != nil {
		return nil, 0, err
	}

	return fs.open(ctx, path)
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

func direntType(entry *index.Entry) fuseutil.DirentType {
	if isdir(entry) {
		return fuseutil.DT_Directory
	}
	return fuseutil.DT_File
}

func isdir(entry *index.Entry) bool {
	return entry.Mode&os.ModeDir == os.ModeDir
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
