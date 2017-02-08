package notify

import (
	"context"

	"koding/klient/machine/index"
	"koding/klient/machine/mount"
)

// BuildOpts represents the context that can be used by external notifiers to
// build their own type. Built notifier should only read from provided indexes
// and, if changes occur, commit observed changes using Cache interface.
type BuildOpts struct {
	MountID mount.ID    // identifier of synced mount.
	Mount   mount.Mount // single mount with absolute paths.

	Cache    Cache  // index file system change consumer.
	CacheDir string // absolute path to locally cached files.

	RemoteIdx *index.Index // known state of remote index.
	LocalIdx  *index.Index // known state of local index.
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
	Close()
}

// Cache represents external synchronization devices that can apply provided
// change to both underlying file system and its indexes.
type Cache interface {
	// Commit notifies syncers about observed file system change. Resulted
	// context will be canceled if the change was applied or dropped.
	Commit(*index.Change) context.Context
}
