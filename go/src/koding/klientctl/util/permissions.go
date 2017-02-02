package util

import "os/exec"

// binRunner exists mainly to allow mocking of the bin execution, to deal
// with testing subtle binary differences between hosts.
type binRunner func(string, ...string) ([]byte, error)

// defaultBinRunner uses exec's CombinedOutput to execute the given
// executable path and args.
func defaultBinRunner(bin string, args ...string) ([]byte, error) {
	return exec.Command(bin, args...).CombinedOutput()
}

// Permissions is a struct containing tools for testing and/or verifying
// the current users permissions in a mockable fashion.
type Permissions struct {
	binRunner binRunner
}

// NewPermission instatiates a new Permissions struct with the global
// defaults.
func NewPermissions() *Permissions {
	return &Permissions{
		binRunner: defaultBinRunner,
	}
}

// IsAdmin checks whether or not the current user has admin privileges.
//
// On Darwin and Linux, this checks if the `id` process is
func (p *Permissions) IsAdmin() (bool, error) {
	return p.isAdmin()
}
