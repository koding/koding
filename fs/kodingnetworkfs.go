package fs

import (
	"log"
	"os"
	"path"
	"sync"
	"time"

	"golang.org/x/net/context"

	"github.com/jacobsa/fuse"
	"github.com/jacobsa/fuse/fuseops"
	"github.com/jacobsa/fuse/fuseutil"
	"github.com/koding/fuseklient/config"
	"github.com/koding/fuseklient/transport"
	"github.com/koding/fuseklient/unmount"
)

// TODO: what's a good default error to return when things go wrong, ie
// network errors when talking to user VM?
var ErrDefault = fuse.EIO

// KodingNetworkFS implements `fuse.FileSystem` to let users mount folders on
// their Koding VMs to their local machine.
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

	// Ctx is the context used in joining filesystem.
	// TODO: I'm not sure what to do with this yet, saving it for future.
	Ctx context.Context

	// RWMutex protects the fields below.
	sync.RWMutex

	// liveNodes is (1 indexed) collection of inodes in use by Kernel. The Node
	// at index 1 is the root Node.
	liveNodes map[fuseops.InodeID]Node
}

// NewKodingNetworkFS is the required initializer for KodingNetworkFS.
func NewKodingNetworkFS(t transport.Transport, c *config.FuseConfig) *KodingNetworkFS {
	mountConfig := &fuse.MountConfig{
		FSName: c.MountName,

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

	if c.FuseDebug {
		mountConfig.DebugLogger = log.New(os.Stdout, "", 0)
	}

	if c.Debug {
		DebugEnabled = true
	}

	idGen := NewNodeIDGen()

	rootInode := NewRootInode(t, c.RemotePath, c.LocalPath)
	rootInode.Name = path.Base(c.RemotePath)
	rootInode.RemotePath = c.RemotePath
	rootInode.LocalPath = c.LocalPath

	// TODO: get uid and gid for current process and use that
	rootInode.Attrs = fuseops.InodeAttributes{
		Uid: 501, Gid: 20, Mode: 0700 | os.ModeDir, Size: 10,
	}

	rootDir := NewDir(rootInode, idGen)
	err := rootDir.updateEntriesFromRemote()
	if err != nil {
		panic(err.Error())
	}

	return &KodingNetworkFS{
		MountConfig: mountConfig,
		MountPath:   c.LocalPath,
		RWMutex:     sync.RWMutex{},
		liveNodes:   map[fuseops.InodeID]Node{fuseops.RootInodeID: rootDir},
	}
}

// Mount mounts an specified folder on user VM using Fuse in the specificed
// local path.
func (k *KodingNetworkFS) Mount() (*fuse.MountedFileSystem, error) {
	server := fuseutil.NewFileSystemServer(k)
	return fuse.Mount(k.MountPath, server, k.MountConfig)
}

// Join mounts and blocks till user VM is unmounted.
func (k *KodingNetworkFS) Join() error {
	mountedFS, err := k.Mount()
	if err != nil {
		return err
	}

	// TODO: what context to use?
	k.Ctx = context.TODO()

	return mountedFS.Join(k.Ctx)
}

// Unmount un mounts Fuse mounted folder. Mount exists separate to lifecycle of
// this process and needs to be cleaned up.
func (k *KodingNetworkFS) Unmount() error {
	return unmount.Unmount(k.MountPath)
}

// GetInodeAttributesOp set attributes for a specified Node. It returns
// `fuse.ENOENT` if node doesn't exist in internal map.
//
// Required by Fuse.
func (k *KodingNetworkFS) GetInodeAttributes(ctx context.Context, op *fuseops.GetInodeAttributesOp) error {
	// defer debug(time.Now(), "ID=%d", op.Inode)

	node, err := k.getNode(op.Inode)
	if err != nil {
		return fuse.ENOENT
	}

	op.Attributes = node.GetAttrs()

	return nil
}

// LookUpInode finds node in context of specific parent Node and sets
// attributes. It assumes parent node has already been seen, if not it returns
// `fuse.ENOENT`.
//
// TODO: Check if this is called once for each parent in case of nested lookups.
//
// Required by Fuse.
func (k *KodingNetworkFS) LookUpInode(ctx context.Context, op *fuseops.LookUpInodeOp) error {
	defer debug(time.Now(), "ParentID=%d Name=%s", op.Parent, op.Name)

	dir, err := k.getDirNode(op.Parent)
	if err != nil {
		return err
	}

	entry, err := dir.FindEntry(op.Name)
	if err != nil {
		return err
	}

	k.setNode(entry.GetID(), entry)

	op.Entry.Child = entry.GetID()
	op.Entry.Attributes = entry.GetAttrs()

	return nil
}

///// Directory Operations

// TODO: I've no clue what this does or if it's even required.
//
// Required by Fuse.
func (k *KodingNetworkFS) OpenDir(ctx context.Context, op *fuseops.OpenDirOp) error {
	defer debug(time.Now(), "ID=%d, HandleID=%d", op.Inode, op.Handle)

	if _, err := k.getDirNode(op.Inode); err != nil {
		return err
	}

	return nil
}

// ReadDir reads entries in a specific directory Node. It returns `fuse.ENOENT`
// if directory Node doesn't exist.
//
// Required by Fuse.
func (k *KodingNetworkFS) ReadDir(ctx context.Context, op *fuseops.ReadDirOp) error {
	defer debug(time.Now(), "ID=%d Offset=%d", op.Inode, op.Offset)

	dir, err := k.getDirNode(op.Inode)
	if err != nil {
		return fuse.ENOENT
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

// Mkdir creates new directory inside specified parent directory. It returns
// `fuse.EEXIST` if the parent directory doesn't exist.
//
// Required by Fuse.
func (k *KodingNetworkFS) MkDir(ctx context.Context, op *fuseops.MkDirOp) error {
	defer debug(time.Now(), "ParentID=%d Name=%s", op.Parent, op.Name)

	dir, err := k.getDirNode(op.Parent)
	if err != nil {
		return fuse.ENOENT
	}

	if _, err := dir.FindEntry(op.Name); err != fuse.ENOENT {
		return fuse.EEXIST
	}

	newDir, err := dir.CreateEntryDir(op.Name, op.Mode)
	if err != nil {
		return err
	}

	k.setNode(newDir.GetID(), newDir)

	op.Entry.Child = newDir.GetID()
	op.Entry.Attributes = newDir.GetAttrs()

	return nil
}

func (k *KodingNetworkFS) Rename(ctx context.Context, op *fuseops.RenameOp) error {
	defer debug(time.Now(), "Old=%v,%s New=%v,%s", op.OldParent, op.OldName, op.NewParent, op.NewName)

	dir, err := k.getDirNode(op.OldParent)
	if err != nil {
		return err
	}

	newDir, err := k.getDirNode(op.NewParent)
	if err != nil {
		return err
	}

	return dir.MoveEntry(op.OldName, op.NewName, newDir)
}

func (k *KodingNetworkFS) RmDir(ctx context.Context, op *fuseops.RmDirOp) error {
	dir, err := k.getDirNode(op.Parent)
	if err != nil {
		return err
	}

	entry, err := dir.RemoveEntry(op.Name)
	if err != nil {
		return err
	}

	k.deleteNode(entry.GetID())

	return err
}

///// File Operations

// OpenFile opens a File, ie. indicates operations are to be done on this file.
// It returns `fuse.ENOENT` if file doesn't exist.
//
// Required by Fuse.
func (k *KodingNetworkFS) OpenFile(ctx context.Context, op *fuseops.OpenFileOp) error {
	defer debug(time.Now(), "ID=%v", op.Inode)

	file, err := k.getFileNode(op.Inode)
	if err != nil {
		return fuse.ENOENT
	}

	file.Open()

	// KeepPageCache tells Kernel to cache this file contents or not. Say an user
	// opens a file on their local and then changes that same file on the VM, by
	// setting this to be false, the user can close and open the file to see the
	// changes. See https://goo.gl/vjhjFY.
	op.KeepPageCache = false

	return nil
}

// ReadFile reads contents of a specified file.
//
// Required by Fuse.
func (k *KodingNetworkFS) ReadFile(ctx context.Context, op *fuseops.ReadFileOp) error {
	defer debug(time.Now(), "ID=%v Offset=%v", op.Inode, op.Offset)

	file, err := k.getFileNode(op.Inode)
	if err != nil {
		return err
	}

	bytes, err := file.ReadAt(op.Offset)
	if err != nil {
		return err
	}

	op.BytesRead = copy(op.Dst[op.Offset:], bytes)

	return nil
}

func (k *KodingNetworkFS) WriteFile(ctx context.Context, op *fuseops.WriteFileOp) error {
	defer debug(time.Now(), "ID=%v DataLen=%v Offset=%v", op.Inode, len(op.Data), op.Offset)

	file, err := k.getFileNode(op.Inode)
	if err != nil {
		return err
	}

	file.WriteAt(op.Data, op.Offset)

	return nil
}

func (k *KodingNetworkFS) CreateFile(ctx context.Context, op *fuseops.CreateFileOp) error {
	defer debug(time.Now(), "Parent=%v Name=%s Mode=%s", op.Parent, op.Name, op.Mode)

	dir, err := k.getDirNode(op.Parent)
	if err != nil {
		return err
	}

	file, err := dir.CreateEntryFile(op.Name, op.Mode)
	if err != nil {
		return err
	}

	k.setNode(file.GetID(), file)

	op.Entry.Child = file.GetID()
	op.Entry.Attributes = file.GetAttrs()

	return nil
}

func (k *KodingNetworkFS) SetInodeAttributes(ctx context.Context, op *fuseops.SetInodeAttributesOp) error {
	defer debug(time.Now(), "ID=%v", op.Inode)

	node, err := k.getNode(op.Inode)
	if err != nil {
		return err
	}

	attrs := node.GetAttrs()

	if op.Mode != nil {
		attrs.Mode = *op.Mode
	}

	if op.Atime != nil {
		attrs.Atime = *op.Atime
	}

	if op.Mtime != nil {
		attrs.Mtime = *op.Mtime
	}

	if op.Size != nil {
		attrs.Size = *op.Size

		if *op.Size == 0 {
			if file, ok := node.(*File); ok {
				file.WriteAt([]byte{}, 0)
			}
		}
	}

	node.SetAttrs(attrs)
	op.Attributes = attrs

	return nil
}

func (k *KodingNetworkFS) FlushFile(ctx context.Context, op *fuseops.FlushFileOp) error {
	defer debug(time.Now(), "ID=%v", op.Inode)

	file, err := k.getFileNode(op.Inode)
	if err != nil {
		return err
	}

	return file.Flush()
}

func (k *KodingNetworkFS) SyncFile(ctx context.Context, op *fuseops.SyncFileOp) error {
	defer debug(time.Now(), "ID=%v", op.Inode)

	file, err := k.getFileNode(op.Inode)
	if err != nil {
		return err
	}

	return file.Sync()
}

func (k *KodingNetworkFS) Unlink(ctx context.Context, op *fuseops.UnlinkOp) error {
	defer debug(time.Now(), "Parent=%v Name=%s", op.Parent, op.Name)

	dir, err := k.getDirNode(op.Parent)
	if err != nil {
		return err
	}

	entry, err := dir.RemoveEntry(op.Name)
	if err != nil {
		return err
	}

	k.deleteNode(entry.GetID())

	return nil
}

// ///// Helpers

func (k *KodingNetworkFS) getDirNode(id fuseops.InodeID) (*Dir, error) {
	node, err := k.getNode(id)
	if err != nil {
		return nil, err
	}

	if node.GetType() != fuseutil.DT_Directory {
		return nil, fuse.EIO
	}

	return node.(*Dir), nil
}

func (k *KodingNetworkFS) getFileNode(id fuseops.InodeID) (*File, error) {
	node, err := k.getNode(id)
	if err != nil {
		return nil, err
	}

	if node.GetType() != fuseutil.DT_File {
		return nil, fuse.EIO
	}

	return node.(*File), nil
}

// getNode gets Node from KodingNetworkFS#EntriesList.
func (k *KodingNetworkFS) getNode(id fuseops.InodeID) (Node, error) {
	node, ok := k.liveNodes[id]
	if !ok {
		return nil, fuse.ENOENT
	}

	return node, nil
}

func (k *KodingNetworkFS) setNode(id fuseops.InodeID, entry Node) {
	k.liveNodes[id] = entry
}

func (k *KodingNetworkFS) deleteNode(id fuseops.InodeID) {
	delete(k.liveNodes, id)
}
