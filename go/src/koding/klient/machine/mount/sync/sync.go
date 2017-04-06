package sync

import (
	"fmt"
	"io"

	"koding/klient/machine/client"
	"koding/klient/machine/index"
)

// DynamicSSHFunc locates the remote host which ssh should connect to.
type DynamicSSHFunc func() (host string, port int, err error)

// IndexSyncFunc is a function that must be called by syncer immediately after
// synchronization process. It is used to update index.
type IndexSyncFunc func(*index.Change)

// BuildOpts represents the context that can be used by external syncers to
// build their own type. Built syncer should update the index after syncing and
// manage received events.
type BuildOpts struct {
	RemoteDir string // absolute path to synced remote directory.
	CacheDir  string // absolute path to locally cached files.

	ClientFunc    client.DynamicClientFunc // factory for dynamic clients.
	SSHFunc       DynamicSSHFunc           // dynamic getter for machine SSH address.
	IndexSyncFunc IndexSyncFunc            // callback used to update index.
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
	// Event returns base event which is going to be synchronized.
	Event() *Event

	// Exec starts synchronization of stored syncing job. It should update
	// indexes and clean up synced Event.
	Exec() error

	// Debug returns debug information about the execer.
	Debug() string

	// fmt.Stringer defines human readable information about the event.
	fmt.Stringer
}

// Syncer is an interface which must be implemented by external syncer.
type Syncer interface {
	// ExecStream is a method that wraps received event with custom
	// synchronization logic.
	ExecStream(<-chan *Event) <-chan Execer

	// Close cleans up syncer resources.
	io.Closer
}
