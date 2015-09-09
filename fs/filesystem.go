package fs

import (
	"log"
	"os"

	"github.com/jacobsa/fuse"
	"github.com/jacobsa/fuse/fuseutil"
	"github.com/koding/fuseklient/config"
	"github.com/koding/fuseklient/transport"
)

// FileSystem implements fuse.FileSystem to let users mount folders on their
// Koding VMs to their local.
type FileSystem struct {
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
}

// NewFileSystemServer is the required initializer for FileSystem.
func NewFileSystem(t transport.Transport, c *config.FuseConfig) *FileSystem {
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

	return &FileSystem{
		Transport:   t,
		RemotePath:  c.RemotePath,
		LocalPath:   c.LocalPath,
		MountConfig: mountConfig,
	}
}

// Mount mounts an specified folder on user VM using Fuse in the specificed
// local path.
func (f *FileSystem) Mount() error {
	server := fuseutil.NewFileSystemServer(f)
	_, err := fuse.Mount(f.LocalPath, server, f.MountConfig)

	return err
}

// Unmount un mounts Fuse mounted folder. Mount exists separate to lifecycle of
// this process and needs to be cleaned up.
func (f *FileSystem) Unmount() error {
	return unmount(f.LocalPath)
}
