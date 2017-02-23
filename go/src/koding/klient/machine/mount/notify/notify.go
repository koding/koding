package notify

import (
	"context"
	"io"

	"koding/klient/fs"
	"koding/klient/machine/index"
	"koding/klient/machine/mount"
)

// DiskInfo retrieves information about remote directory volume.
type DiskInfo func() (fs.DiskInfo, error)

// BuildOpts represents the context that can be used by external notifiers to
// build their own type.
type BuildOpts struct {
	MountID mount.ID    // identifier of synced mount.
	Mount   mount.Mount // single mount with absolute paths.

	Cache    Cache  // index file system change consumer.
	CacheDir string // absolute path to locally cached files.

	DiskInfo DiskInfo // remote directory volume info.

	Index *index.Index // known state of managed index.
}

// Builder represents a factory method which external notifiers must implement
// in order to create their instances.
type Builder interface {
	// Build uses provided build options to create Notifier instance.
	Build(opts *BuildOpts) (Notifier, error)
}

// Notifier is an interface which must be implemented by external notifiers.
type Notifier interface {
	// Close cleans up notifier resources, if any.
	io.Closer
}

// Cache represents external synchronization devices that can apply provided
// change to both underlying file system and its indexes.
type Cache interface {
	// Commit notifies syncers about observed file system change. Resulted
	// context will be canceled if the change was applied or dropped.
	Commit(*index.Change) context.Context
}
