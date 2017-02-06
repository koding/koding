package client

import (
	"context"

	"koding/klient/machine/index"
)

// Client describes the operations that can be made on remote machine.
type Client interface {
	// CurrentUser returns remote machine current username.
	CurrentUser() (string, error)

	// SSHAddKeys adds SSH public keys to user's authorized_keys file.
	SSHAddKeys(string, ...string) error

	// MountHeadIndex returns the number and the overall size of files in a
	// given remote directory.
	MountHeadIndex(string) (string, int, int64, error)

	// MountGetIndex returns an index that describes the current state of remote
	// directory.
	MountGetIndex(string) (*index.Index, error)

	// DiskBlocks gets basic information about volume pointed by provided path.
	DiskBlocks(string) (uint64, uint64, uint64, uint64, error)

	// Context returns client's Context.
	Context() context.Context
}
