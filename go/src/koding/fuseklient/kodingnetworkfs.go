package fuseklient

import (
	"fmt"
	"net/http"
	"os"
	"path"
	"sync"
	"time"

	"golang.org/x/net/context"
	"golang.org/x/net/trace"

	"koding/fuseklient/transport"

	"github.com/jacobsa/fuse"
	"github.com/jacobsa/fuse/fuseops"
	"github.com/jacobsa/fuse/fuseutil"
)

type FS interface {
	Mount() (*fuse.MountedFileSystem, error)
	Unmount() error
}

var (
	// folderSeparator is the OS specific separator between files and folders.
	folderSeparator = string(os.PathSeparator)
)

// KodingNetworkFS implements `fuse.FileSystem` to let users mount folders on
// their Koding VMs to their local machine.
//
// In general the following rules apply:
//
// * Implemented `fuse.FileSystem` interface method are public, while all
//   others are private.
// * Interface methods return `fuse.ENOENT` if specified entry doesn't exit.
// * Communication with Kernel and maintaining list of live nodes are the only
//   operations that should happen here.
type KodingNetworkFS struct {
	// NotImplementedFileSystem is the default implementation for
	// `fuseutil.FileSystem` interface methods. Any interface methods that are
	// unimplemented return `fuse.ENOSYS` as error. This lets us implement only
	// the required methods while satisifying the interface.
	fuseutil.NotImplementedFileSystem

	// MountPath is path to folder in local to serve as mount point. If this path
	// doesn't exit, it is created. If path exists, its current files and folders
	// are hidden while mounted.
	MountPath string

	// MountConfig is optional config sent to `fuse.Mount`.
	MountConfig *fuse.MountConfig

	Watcher Watcher

	// DiskInfo is the cached result of remote disk info.
	DiskInfo *transport.GetDiskInfoRes

	HandleIDGen *HandleIDGen

	// RWMutex protects the fields below.
	sync.RWMutex

	// liveNodes is (1 indexed) collection of inodes in use by Kernel. The Node
	// at index 1 is the root Node.
	liveNodes map[fuseops.InodeID]Node

	liveHandles map[fuseops.HandleID]Node
}

func New(t transport.Transport, c *Config) (FS, error) {
	ks, err := NewKodingNetworkFS(t, c)
	if err != nil {
		return nil, err
	}

	var fs FS = ks

	if c.Debug {
		// TODO: move this to klient; this tries to start http server for each mount
		go func() {
			fmt.Println("Starting http server for tracing ", http.ListenAndServe(":8888", nil))
		}()

		fs = NewTraceFS(ks)
	}

	return fs, nil
}

// NewKodingNetworkFS is the required initializer for KodingNetworkFS.
func NewKodingNetworkFS(t transport.Transport, c *Config) (*KodingNetworkFS, error) {
	// create mount point if it doesn't exist
	if err := os.MkdirAll(c.Path, 0755); err != nil {
		return nil, err
	}

	mountConfig := &fuse.MountConfig{
		// FSName is name of mount; required to be non empty or `umount` command
		// will require root to unmount the folder.
		FSName: c.MountName,

		// VolumeName is the name of the folder shown in applications like Finder
		// in OSX.
		VolumeName: path.Base(c.Path),

		// DisableWritebackCaching disables write cache in Kernel. Without this if
		// a file changes in the user VM, when user checks local, file will not have
		// changed even if change is propagated via Transport. In general we want
		// to cache entries, contents etc. in this process vs using Kernel cache,
		// this lets us listen to changes using Transport and invalidate the cache.
		//
		// See https://goo.gl/y6R75k.
		DisableWritebackCaching: true,

		// EnableVnodeCaching is OSX only option to enable caching of entries. This
		// needs to turned off since as in DisableWritebackCaching scenario above,
		// a file can change in user VM.
		//
		// See https://goo.gl/Db7T6Q.
		EnableVnodeCaching: false,
	}

	// setup fuse library logging
	// TODO: this is here just for legacy reasons
	//mountConfig.ErrorLogger = log.New(os.Stderr, "", 0)
	//mountConfig.DebugLogger = log.New(os.Stdout, "", 0)

	localUser, localGroup := getLocalUserInfo()

	// create root entry
	rootEntry := NewRootEntry(t, c.Path)
	rootEntry.Name = "/"
	rootEntry.Path = "/"
	rootEntry.Uid = localUser
	rootEntry.Gid = localGroup

	// TODO: what size to set for directories
	rootEntry.Attrs = fuseops.InodeAttributes{
		Uid: localUser, Gid: localGroup, Mode: 0700 | os.ModeDir, Size: 10,
	}

	// create root directory
	rootDir := NewDir(rootEntry, NewIDGen())
	watcher := NewFindWatcher(t, rootEntry.Path)

	// update entries for root directory
	if err := rootDir.Expire(); err != nil {
		return nil, err
	}

	// update info about root directory
	if err := rootDir.UpdateAttrsFromRemote(); err != nil {
		return nil, err
	}

	// watch for changes on remote optionally
	if !c.NoWatch {
		go WatchForRemoteChanges(rootDir, watcher)
	}

	// don't prefetch folder/file metadata optionally
	if !c.NoPrefetchMeta {
		// remove entries fetched above or it'll have double entries
		rootDir.Reset()

		if err := NewDirInitializer(t, rootDir).Initialize(); err != nil {
			return nil, err
		}
	}

	// save root directory
	liveNodes := map[fuseops.InodeID]Node{fuseops.RootInodeID: rootDir}
	liveHandles := map[fuseops.HandleID]Node{}

	res, err := t.GetDiskInfo(rootDir.Name)
	if err != nil {
		return nil, err
	}

	return &KodingNetworkFS{
		MountPath:   c.Path,
		MountConfig: mountConfig,
		RWMutex:     sync.RWMutex{},
		Watcher:     watcher,
		DiskInfo:    res,
		HandleIDGen: NewHandleIDGen(),
		liveNodes:   liveNodes,
		liveHandles: liveHandles,
	}, nil
}

// Mount mounts an specified folder on user VM using Fuse in the specificed
// local path.
func (k *KodingNetworkFS) Mount() (*fuse.MountedFileSystem, error) {
	server := fuseutil.NewFileSystemServer(k)
	return fuse.Mount(k.MountPath, server, k.MountConfig)
}

// Unmount un mounts Fuse mounted folder. Mount exists separate to lifecycle of
// this process and needs to be cleaned up.
func (k *KodingNetworkFS) Unmount() error {
	// watcher can be nil if Config.NoWatch was set to true
	//if k.Watcher != nil {
	//  k.Watcher.Close()
	//}

	return Unmount(k.MountPath)
}

// GetInodeAttributes set attributes for a specified Node.
//
// Required for fuse.FileSystem.
func (k *KodingNetworkFS) GetInodeAttributes(ctx context.Context, op *fuseops.GetInodeAttributesOp) error {
	entry, err := k.getEntry(ctx, op.Inode)
	if err != nil {
		return err
	}

	op.Attributes = entry.GetAttrs()

	return nil
}

// LookUpInode finds entry in context of specific parent directory and sets
// its attributes. It assumes parent directory has already been seen.
//
// Required for fuse.FileSystem.
func (k *KodingNetworkFS) LookUpInode(ctx context.Context, op *fuseops.LookUpInodeOp) error {
	dir, err := k.getDir(ctx, op.Parent)
	if err != nil {
		return err
	}

	entry, err := dir.FindEntry(op.Name)
	if err != nil {
		return err
	}

	k.setEntry(entry.GetID(), entry)

	op.Entry.Child = entry.GetID()
	op.Entry.Attributes = entry.GetAttrs()

	return nil
}

///// Directory Operations

// OpenDir opens a directory, ie. indicates operations are to be done on this
// directory.
//
// Required for fuse.FileSystem.
func (k *KodingNetworkFS) OpenDir(ctx context.Context, op *fuseops.OpenDirOp) error {
	_, err := k.getDir(ctx, op.Inode)
	return err
}

// ReadDir reads entries in a specific directory.
//
// Required for fuse.FileSystem.
func (k *KodingNetworkFS) ReadDir(ctx context.Context, op *fuseops.ReadDirOp) error {
	dir, err := k.getDir(ctx, op.Inode)
	if err != nil {
		return err
	}

	entries, err := dir.ReadEntries(op.Offset)
	if err != nil {
		return err
	}

	var bytesRead int
	for _, e := range entries {
		c := fuseutil.WriteDirent(op.Dst[bytesRead:], e)
		if c == 0 {
			break
		}

		bytesRead += c
	}

	op.BytesRead = bytesRead

	return nil
}

// MkDir creates new directory inside specified parent directory. It returns
// `fuse.EEXIST` if a file or directory already exists with specified name.
//
// Note: `mkdir` command checks if directory exists before calling this method,
// so you won't see the error from here if you're using `mkdir`.
//
// Required for fuse.FileSystem.
func (k *KodingNetworkFS) MkDir(ctx context.Context, op *fuseops.MkDirOp) error {
	dir, err := k.getDir(ctx, op.Parent)
	if err != nil {
		return err
	}

	if _, err := dir.FindEntry(op.Name); err != fuse.ENOENT {
		return fuse.EEXIST
	}

	newDir, err := dir.CreateEntryDir(op.Name, op.Mode)
	if err != nil {
		return err
	}

	k.setEntry(newDir.GetID(), newDir)

	op.Entry.Child = newDir.GetID()
	op.Entry.Attributes = newDir.GetAttrs()

	return nil
}

// Rename changes a file or directory from old name and parent to new name and
// parent.
//
// Note if a new name already exists, we still go ahead and rename it. While
// the old and new entries are the same, we throw out the old one and create
// new entry for it.
//
// Required for fuse.FileSystem.
func (k *KodingNetworkFS) Rename(ctx context.Context, op *fuseops.RenameOp) error {
	dir, err := k.getDir(ctx, op.OldParent)
	if err != nil {
		return err
	}

	oldEntry, err := dir.FindEntry(op.OldName)
	if err != nil {
		return err
	}

	newDir, err := k.getDir(ctx, op.NewParent)
	if err != nil {
		return err
	}

	newEntry, err := dir.MoveEntry(op.OldName, op.NewName, newDir)
	if err != nil {
		return err
	}

	// delete old entry from live nodes
	k.deleteEntry(oldEntry.GetID())

	// save new entry to live nodes
	k.setEntry(newEntry.GetID(), newEntry)

	if r, ok := trace.FromContext(ctx); ok {
		r.LazyPrintf("moved from %s", oldEntry.ToString())
		r.LazyPrintf("moved to %s", newEntry.ToString())
	}

	return nil
}

// RmDir deletes a directory from remote and list of live nodes.
//
// Note: `rm -r` calls Unlink method on each directory entry.
//
// Required for fuse.FileSystem.
func (k *KodingNetworkFS) RmDir(ctx context.Context, op *fuseops.RmDirOp) error {
	dir, err := k.getDir(ctx, op.Parent)
	if err != nil {
		return err
	}

	entry, err := dir.RemoveEntry(op.Name)
	if err != nil {
		return err
	}

	k.deleteEntry(entry.GetID())

	return nil
}

///// File Operations

// OpenFile opens a File, ie. indicates operations are to be done on this file.
//
// Required for fuse.FileSystem.
func (k *KodingNetworkFS) OpenFile(ctx context.Context, op *fuseops.OpenFileOp) error {
	file, err := k.getFile(ctx, op.Inode)
	if err != nil {
		return err
	}

	file.Open()

	handleID := k.setEntryByHandle(file)
	op.Handle = handleID

	// KeepPageCache tells Kernel to cache this file contents or not. Say an user
	// opens a file on their local and then changes that same file on the VM, by
	// setting this to be false, the user can close and open the file to see the
	// changes. See https://goo.gl/vjhjFY.
	op.KeepPageCache = false

	return nil
}

// ReadFile reads contents of a specified file starting from specified offset.
// It returns `io.EIO` if specified offset is larger than the length of contents
// of the file.
//
// Required for fuse.FileSystem.
func (k *KodingNetworkFS) ReadFile(ctx context.Context, op *fuseops.ReadFileOp) error {
	file, err := k.getFile(ctx, op.Inode)
	if err != nil {
		return err
	}

	bytes, err := file.ReadAt(op.Offset)
	if err != nil {
		return err
	}

	op.BytesRead = copy(op.Dst, bytes)

	return nil
}

// WriteFile write specified contents to specified file at specified offset.
//
// Required for fuse.FileSystem.
func (k *KodingNetworkFS) WriteFile(ctx context.Context, op *fuseops.WriteFileOp) error {
	file, err := k.getFile(ctx, op.Inode)
	if err != nil {
		return err
	}

	if err := file.WriteAt(op.Data, op.Offset); err != nil {
		return err
	}

	k.entryChanged(file)

	return nil
}

// CreateFile creates an empty file with specified name and mode. It returns an
// error if specified parent directory doesn't exist. but not if file already
// exists.
//
// Required for fuse.FileSystem.
func (k *KodingNetworkFS) CreateFile(ctx context.Context, op *fuseops.CreateFileOp) error {
	dir, err := k.getDir(ctx, op.Parent)
	if err != nil {
		return err
	}

	file, err := dir.CreateEntryFile(op.Name, op.Mode)
	if err != nil {
		return err
	}

	// tell Kernel about file
	op.Entry.Child = file.GetID()
	op.Entry.Attributes = file.GetAttrs()

	// save file to list of live nodes
	k.setEntry(file.GetID(), file)

	return nil
}

// SetInodeAttributes sets specified attributes to file or directory.
//
// Required for fuse.FileSystem.
func (k *KodingNetworkFS) SetInodeAttributes(ctx context.Context, op *fuseops.SetInodeAttributesOp) error {
	entry, err := k.getEntry(ctx, op.Inode)
	if err != nil {
		return err
	}

	attrs := entry.GetAttrs()

	///// optionally update attributes

	if op.Mode != nil {
		attrs.Mode = *op.Mode
	}

	if op.Atime != nil {
		attrs.Atime = *op.Atime
	}

	///// optionally update attributes only if entry is a file

	_, isFile := entry.(*File)

	if isFile && op.Mtime != nil {
		attrs.Mtime = *op.Mtime
	}

	if isFile && op.Size != nil {
		attrs.Size = *op.Size

		// if new size is 0 and entry is a file, truncate the file
		if *op.Size == 0 {
			if file, ok := entry.(*File); ok {
				file.WriteAt([]byte{}, 0)

				if err := file.Flush(); err != nil {
					return err
				}
			}
		}
	}

	entry.SetAttrs(attrs)
	op.Attributes = attrs

	return nil
}

// FlushFile saves file contents from local to remote.
//
// Required for fuse.FileSystem.
func (k *KodingNetworkFS) FlushFile(ctx context.Context, op *fuseops.FlushFileOp) error {
	file, err := k.getFile(ctx, op.Inode)
	if err != nil {
		return err
	}

	if r, ok := trace.FromContext(ctx); ok {
		r.LazyPrintf("flushing file=%s sized=%d", file.Name, len(file.Content))
	}

	return file.Flush()
}

// SyncFile sends file contents from local to remote.
//
// Required for fuse.FileSystem.
func (k *KodingNetworkFS) SyncFile(ctx context.Context, op *fuseops.SyncFileOp) error {
	file, err := k.getFile(ctx, op.Inode)
	if err != nil {
		return err
	}

	if r, ok := trace.FromContext(ctx); ok {
		r.LazyPrintf("syncing file=%s sized=%d", file.Name, len(file.Content))
	}

	return file.Sync()
}

// Unlink removes entry from specified parent directory.
//
// Required for fuse.FileSystem.
func (k *KodingNetworkFS) Unlink(ctx context.Context, op *fuseops.UnlinkOp) error {
	dir, err := k.getDir(ctx, op.Parent)
	if err != nil {
		return err
	}

	entry, err := dir.RemoveEntry(op.Name)
	if err != nil {
		return err
	}

	if r, ok := trace.FromContext(ctx); ok {
		r.LazyPrintf("removed %s", entry.ToString())
	}

	k.deleteEntry(entry.GetID())

	return nil
}

// StatFS sets filesystem metadata.
//
// Required for fuse.FileSystem.
func (k *KodingNetworkFS) StatFS(ctx context.Context, op *fuseops.StatFSOp) error {
	ds := k.DiskInfo

	op.BlockSize = ds.BlockSize
	op.Blocks = ds.BlocksTotal
	op.BlocksFree = ds.BlocksFree
	op.BlocksAvailable = op.BlocksFree

	return nil
}

// ReleaseFileHandle releases file handle. It does not return errors even if it
// fails since this op doesn't affect anything.
//
// Required for fuse.FileSystem.
func (k *KodingNetworkFS) ReleaseFileHandle(ctx context.Context, op *fuseops.ReleaseFileHandleOp) error {
	file, err := k.getFileByHandle(ctx, op.Handle)
	if err != nil {
		return nil
	}

	if err := file.Reset(); err != nil {
		return nil
	}

	k.deleteEntryByHandle(op.Handle)

	return nil
}

///// Helpers

// getDir gets directory entry with specified id from list of live nodes. It
// returns `fuse.EIO` if the entry is not a directory.
func (k *KodingNetworkFS) getDir(ctx context.Context, id fuseops.InodeID) (*Dir, error) {
	entry, err := k.getEntry(ctx, id)
	if err != nil {
		return nil, err
	}

	if entry.GetType() != fuseutil.DT_Directory {
		return nil, fuse.EIO
	}

	return entry.(*Dir), nil
}

// getDir gets file entry with specified id from list of live nodes. It returns
// `fuse.EIO` if the entry is not a file.
func (k *KodingNetworkFS) getFile(ctx context.Context, id fuseops.InodeID) (*File, error) {
	entry, err := k.getEntry(ctx, id)
	if err != nil {
		return nil, err
	}

	if entry.GetType() != fuseutil.DT_File {
		return nil, fuse.EIO
	}

	return entry.(*File), nil
}

// getEntry gets an entry with specified id from list of live nodes.
func (k *KodingNetworkFS) getEntry(ctx context.Context, id fuseops.InodeID) (Node, error) {
	k.RLock()
	defer k.RUnlock()

	entry, ok := k.liveNodes[id]
	if !ok {
		return nil, fuse.ENOENT
	}

	if r, ok := trace.FromContext(ctx); ok {
		r.LazyPrintf(entry.ToString())
	}

	return entry, nil
}

// setEntry sets entry to list of live nodes map with id as key.
func (k *KodingNetworkFS) setEntry(id fuseops.InodeID, entry Node) {
	k.Lock()
	k.liveNodes[id] = entry
	k.Unlock()
}

// deleteEntry removes entry with specified id from list of live nodes.
func (k *KodingNetworkFS) deleteEntry(id fuseops.InodeID) {
	k.Lock()
	delete(k.liveNodes, id)
	k.Unlock()
}

func (k *KodingNetworkFS) entryChanged(e Node) {
	file, ok := e.(*File)
	if ok {
		k.Watcher.AddTimedIgnore(file.Path, 1*time.Minute)
	}
}

func (k *KodingNetworkFS) setEntryByHandle(entry Node) fuseops.HandleID {
	k.Lock()
	defer k.Unlock()

	handleID := k.HandleIDGen.Next()
	k.liveHandles[handleID] = entry

	return handleID
}

func (k *KodingNetworkFS) deleteEntryByHandle(handleId fuseops.HandleID) {
	k.Lock()
	delete(k.liveHandles, handleId)
	k.Unlock()
}

func (k *KodingNetworkFS) getDirByHandle(ctx context.Context, id fuseops.HandleID) (*Dir, error) {
	node, err := k.getByHandle(ctx, id)
	if err != nil {
		return nil, err
	}

	dir, ok := node.(*Dir)
	if !ok {
		return nil, fuse.ENOENT
	}

	return dir, nil
}

func (k *KodingNetworkFS) getFileByHandle(ctx context.Context, id fuseops.HandleID) (*File, error) {
	node, err := k.getByHandle(ctx, id)
	if err != nil {
		return nil, err
	}

	file, ok := node.(*File)
	if !ok {
		return nil, fuse.ENOENT
	}

	return file, nil
}

func (k *KodingNetworkFS) getByHandle(ctx context.Context, id fuseops.HandleID) (Node, error) {
	k.RLock()
	defer k.RUnlock()

	entry, ok := k.liveHandles[id]
	if !ok {
		return nil, fuse.ENOENT
	}

	return entry, nil
}
