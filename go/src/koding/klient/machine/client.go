package machine

// Client describes the operations that can be made on remote machine.
type Client interface {
	// CurrentUser returns remote machine current username.
	CurrentUser() (string, error)

	// SSHAddKeys adds SSH public keys to user's authorized_keys file.
	SSHAddKeys(string, ...string) error
}
