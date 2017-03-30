package client

import (
	"context"

	"koding/klient/machine/index"
	"koding/klient/os"
)

// Client describes the operations that can be made on remote machine.
type Client interface {
	// CurrentUser returns remote machine current username.
	CurrentUser() (string, error)

	// Abs returns absolute representation of given path.
	Abs(string) (string, bool, bool, error)

	// SSHAddKeys adds SSH public keys to user's authorized_keys file.
	SSHAddKeys(string, ...string) error

	// MountHeadIndex returns the number and the overall size of files in a
	// given remote directory.
	MountHeadIndex(string) (string, int, int64, error)

	// MountGetIndex returns an index that describes the current state of remote
	// directory.
	MountGetIndex(string) (*index.Index, error)

	// Exec runs a command on a remote machine.
	Exec(*os.ExecRequest) (*os.ExecResponse, error)

	// Kill terminates previously started command on a remote machine.
	Kill(*os.KillRequest) (*os.KillResponse, error)

	// Context returns client's Context.
	Context() context.Context
}
