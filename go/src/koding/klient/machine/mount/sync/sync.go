package sync

import "koding/klient/machine/index"

// BuildOpts represents a context that can be used by external syncers to build
// their own type. Built syncer should update indexes after syncing and manage
// received events.
type BuildOpts struct {
	RemoteIdx *index.Index // known state of remote index.
	LocalIdx  *index.Index // known state of local index.
}

// Builder represents a factory method which external syncers must implement in
// order to create their instances.
type Builder interface {
	// Build uses provided build options to create Syncer instance.
	Build(opts *BuildOpts) (Syncer, error)
}

// Execer represents an interface which must be implemented by sync event
// produced by external syncer.
type Execer interface {
	// Exec starts synchronization of stored syncing job. It should update
	// indexes and clean up synced Event.
	Exec() error
}

// Syncer is an interface which must be implemented by external syncer.
type Syncer interface {
	// ExecStream is a method that wraps received event with custom
	// synchronization logic.
	ExecStream(<-chan *Event) <-chan Execer

	// Close cleans up syncer resources.
	Close()
}
