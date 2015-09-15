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
	liveNodes map[fuseops.InodeID]*Node
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

	rootNode := NewNode(t, idGen)
	rootNode.Name = path.Base(c.RemotePath)
	rootNode.RemotePath = c.RemotePath
	rootNode.LocalPath = c.LocalPath
	rootNode.EntryType = fuseutil.DT_Directory

	// TODO: get uid and gid for current process and use that
	rootNode.Attrs = fuseops.InodeAttributes{
		Uid: 501, Gid: 20, Mode: 0700 | os.ModeDir, Size: 10,
	}

	return &KodingNetworkFS{
		MountConfig: mountConfig,
		MountPath:   c.LocalPath,
		RWMutex:     sync.RWMutex{},
		liveNodes:   map[fuseops.InodeID]*Node{fuseops.RootInodeID: rootNode},
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

	node, ok := k.liveNodes[op.Inode]
	if !ok {
		return fuse.ENOENT
	}

	op.Attributes = node.Attrs

	return nil
}

// LookUpInode finds node in context of specific parent Node and sets
// attributes. It assumes parnet node has already been seen, if not it returns
// `fuse.ENOENT`.
//
// TODO: Check if this is called once for each parent in case of nested lookups.
//
// Required by Fuse.
func (k *KodingNetworkFS) LookUpInode(ctx context.Context, op *fuseops.LookUpInodeOp) error {
	// defer debug(time.Now(), "ParentID=%d Name=%s", op.Parent, op.Name)

	parent, ok := k.liveNodes[op.Parent]
	if !ok {
		return fuse.ENOENT
	}

	child, err := parent.FindChild(op.Name)
	if err != nil {
		if err == ErrNodeNotFound {
			return fuse.ENOENT
		}

		return err
	}

	k.liveNodes[child.ID] = child

	op.Entry.Child = child.ID
	op.Entry.Attributes = child.Attrs

	return err
}

///// Directory Operations

// TODO: I've no clue what this does or if it's even required.
//
// Required by Fuse.
func (k *KodingNetworkFS) OpenDir(ctx context.Context, op *fuseops.OpenDirOp) error {
	defer debug(time.Now(), "ID=%d, HandleID=%d", op.Inode, op.Handle)

	if _, err := k.getNode(op.Inode); err != nil {
		return fuse.ENOENT
	}

	return nil
}

// ReadDir reads entries in a specific directory Node. It returns `fuse.ENOENT`
// if directory Node doesn't exist.
//
// Required by Fuse.
func (k *KodingNetworkFS) ReadDir(ctx context.Context, op *fuseops.ReadDirOp) error {
	defer debug(time.Now(), "ID=%d Offset=%d", op.Inode, op.Offset)

	node, err := k.getNode(op.Inode)
	if err != nil {
		return fuse.ENOENT
	}

	entries, err := node.ReadDir()
	if err != nil {
		return err
	}

	if op.Offset > fuseops.DirOffset(len(entries)) {
		return fuse.EIO
	}

	var bytesRead int

	entries = entries[op.Offset:]
	for _, ent := range entries {
		c := fuseutil.WriteDirent(op.Dst[bytesRead:], ent)
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

	parent, err := k.getNode(op.Parent)
	if err != nil {
		return fuse.ENOENT
	}

	if _, err := parent.FindChild(op.Name); err != ErrNodeNotFound {
		return fuse.EEXIST
	}

	newFolder, err := parent.Mkdir(op.Name, op.Mode)
	if err != nil {
		return err
	}

	k.liveNodes[newFolder.ID] = newFolder

	op.Entry.Child = newFolder.ID
	op.Entry.Attributes = newFolder.Attrs

	return nil
}

func (k *KodingNetworkFS) Rename(ctx context.Context, op *fuseops.RenameOp) error {
	defer debug(time.Now(), "Old=%v,%s New=%v,%s", op.OldParent, op.OldName, op.NewParent, op.NewName)

	parent, err := k.getNode(op.OldParent)
	if err != nil {
		return fuse.ENOENT
	}

	return parent.Rename(op.OldName, op.NewName)
}

///// File Operations

// OpenFile opens a File, ie. indicates operations are to be done on this file.
// It returns `fuse.ENOENT` if file doesn't exist.
//
// Required by Fuse.
func (k *KodingNetworkFS) OpenFile(ctx context.Context, op *fuseops.OpenFileOp) error {
	defer debug(time.Now(), "ID=%v", op.Inode)

	_, err := k.getNode(op.Inode)
	if err != nil {
		return fuse.ENOENT
	}

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
	defer debug(time.Now(), "ID=%v Offset=%s", op.Inode, op.Offset)

	fileNode, err := k.getNode(op.Inode)
	if err != nil {
		return fuse.ENOENT
	}

	op.BytesRead, err = fileNode.ReadAt(op.Dst, op.Offset)

	return err
}

func (k *KodingNetworkFS) WriteFile(ctx context.Context, op *fuseops.WriteFileOp) error {
	defer debug(time.Now(), "ID=%v DataLen=%v Offset=%v", op.Inode, len(op.Data), op.Offset)

	fileNode, err := k.getNode(op.Inode)
	if err != nil {
		return fuse.ENOENT
	}

	_, err = fileNode.WriteAt(op.Data, op.Offset)

	return err
}

func (k *KodingNetworkFS) CreateFile(ctx context.Context, op *fuseops.CreateFileOp) error {
	defer debug(time.Now(), "Parent=%v Name=%s Mode=%s", op.Parent, op.Name, op.Mode)

	dirNode, err := k.getNode(op.Parent)
	if err != nil {
		return fuse.ENOENT
	}

	if _, err := dirNode.FindChild(op.Name); err != ErrNodeNotFound {
		return fuse.EEXIST
	}

	fileNode, err := k.initializeChildNode(dirNode, op.Name)
	if err != nil {
		return err
	}

	fileNode.EntryType = fuseutil.DT_File
	fileNode.Attrs.Mode = op.Mode

	if err := fileNode.CreateFile(); err != nil {
		return ErrDefault
	}

	op.Entry.Child = fileNode.ID
	op.Entry.Attributes = fileNode.Attrs

	return nil
}

func (k *KodingNetworkFS) SetInodeAttributes(ctx context.Context, op *fuseops.SetInodeAttributesOp) error {
	defer debug(time.Now(), "ID=%v", op.Inode)

	node, err := k.getNode(op.Inode)
	if err != nil {
		return fuse.ENOENT
	}

	if op.Mode != nil {
		node.Attrs.Mode = *op.Mode
	}

	if op.Atime != nil {
		node.Attrs.Atime = *op.Atime
	}

	if op.Mtime != nil {
		node.Attrs.Mtime = *op.Mtime
	}

	if op.Size != nil {
		node.Attrs.Size = *op.Size

		if *op.Size == 0 {
			_, err := node.WriteAt([]byte{}, 0)
			return err
		}
	}

	op.Attributes = node.Attrs

	return nil
}

func (k *KodingNetworkFS) FlushFile(ctx context.Context, op *fuseops.FlushFileOp) error {
	defer debug(time.Now(), "ID=%v", op.Inode)

	fileNode, err := k.getNode(op.Inode)
	if err != nil {
		return fuse.ENOENT
	}

	err = fileNode.Flush()
	return err
}

func (k *KodingNetworkFS) SyncFile(ctx context.Context, op *fuseops.SyncFileOp) error {
	defer debug(time.Now(), "ID=%v", op.Inode)

	fileNode, err := k.getNode(op.Inode)
	if err != nil {
		return fuse.ENOENT
	}

	err = fileNode.Flush()
	return err
}

func (k *KodingNetworkFS) Unlink(ctx context.Context, op *fuseops.UnlinkOp) error {
	defer debug(time.Now(), "Parent=%v Name=%s", op.Parent, op.Name)

	parentDir, err := k.getNode(op.Parent)
	if err != nil {
		return fuse.ENOENT
	}

	child, err := parentDir.FindChild(op.Name)
	if err != nil {
		if err == ErrNodeNotFound {
			return fuse.ENOENT
		}

		return err
	}

	if err = child.Delete(); err != nil {
		return err
	}

	delete(k.liveNodes, child.ID)

	return nil
}

///// Helpers

// getNode gets Node from KodingNetworkFS#EntriesList.
func (k *KodingNetworkFS) getNode(nodeId fuseops.InodeID) (*Node, error) {
	node, ok := k.liveNodes[nodeId]
	if !ok {
		return nil, ErrNodeNotFound
	}

	return node, nil
}

// initializeChildNode creates new Node in context of parent and adds it to
// KodingNetworkFS#liveNodes.
func (k *KodingNetworkFS) initializeChildNode(p *Node, name string) (*Node, error) {
	nextID := p.NodeIDGen.Next()
	c := p.InitializeChildNode(name, nextID)

	k.liveNodes[c.ID] = c

	return c, nil
}
