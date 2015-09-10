package fs

import (
	"log"
	"os"
	"sync"

	"golang.org/x/net/context"

	"github.com/jacobsa/fuse"
	"github.com/jacobsa/fuse/fuseops"
	"github.com/jacobsa/fuse/fuseutil"
	"github.com/koding/fuseklient/config"
	"github.com/koding/fuseklient/transport"
)

// KodingNetworkFS, ie Koding Network File System, implements `fuse.FileSystem` to let
// users mount folders on their VMs to their local.
type KodingNetworkFS struct {
	// Transport is two way communication layer with user VM.
	transport.Transport

	// NotImplementedFileSystem is the default implementation for
	// `fuseutil.FileSystem` interface methods. Any interface methods that are
	// unimplemented return `fuse.ENOSYS` as error. This lets us implement only
	// the required methods while satisifying the interface.
	fuseutil.NotImplementedFileSystem

	// RemotePath is path to folder in user VM to be mounted locally. This path
	// has to exist on user VM or it returns with an error.
	RemotePath string

	// LocalPath is path to folder in local to serve as mount point. If this path
	// doesn't exit, it is created. If path exists, its current files and folders
	// are hidden while mounted.
	LocalPath string

	// MountConfig is optional config sent to `fuse.Mount`.
	MountConfig *fuse.MountConfig

	// Ctx is the context used in joining filesystem.
	Ctx context.Context

	// RWMutex protects the fields below.
	sync.RWMutex

	// liveNodes is collection of inodes in use by Kernel.
	liveNodes map[fuseops.InodeID]*Node
}

// NewKNFS is the required initializer for KodingNetworkFS.
func NewKNFS(t transport.Transport, c *config.FuseConfig) *KodingNetworkFS {
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

	if c.Debug {
		mountConfig.ErrorLogger = log.New(os.Stderr, "fk: ", log.Lshortfile)
		mountConfig.DebugLogger = log.New(os.Stdout, "fk_debug: ", log.Lshortfile)
	}

	nodes := map[fuseops.InodeID]*Node{
		fuseops.RootInodeID: &Node{
			Attrs: fuseops.InodeAttributes{Mode: 0700 | os.ModeDir},
		},
	}

	return &KodingNetworkFS{
		Transport:   t,
		RemotePath:  c.RemotePath,
		LocalPath:   c.LocalPath,
		MountConfig: mountConfig,
		RWMutex:     sync.RWMutex{},
		liveNodes:   nodes,
	}
}

// Mount mounts an specified folder on user VM using Fuse in the specificed
// local path.
func (k *KodingNetworkFS) Mount() (*fuse.MountedFileSystem, error) {
	server := fuseutil.NewFileSystemServer(k)
	return fuse.Mount(k.LocalPath, server, k.MountConfig)
}

// Join mounts and blocks till it's unmounted.
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
	return unmount(k.LocalPath)
}

// GetInodeAttributesOp returns list attributes of a specified Inode. It
// returns `fuse.ENOENT` if inode doesn't exist in internal map.
//
// Required by Fuse.
func (k *KodingNetworkFS) GetInodeAttributes(ctx context.Context, op *fuseops.GetInodeAttributesOp) error {
	k.RLock()
	node, ok := k.liveNodes[op.Inode]
	k.RUnlock()

	if !ok {
		return fuse.ENOENT
	}

	op.Attributes = node.Attrs

	return nil
}

func (k *KodingNetworkFS) OpenDir(ctx context.Context, op *fuseops.OpenDirOp) error {
	return nil
}
