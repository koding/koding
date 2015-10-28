package util

import (
	"os/exec"
	"strings"
)

// +build linux darwin

// NewPermission instatiates a new Permissions struct with the global
// defaults.
func NewPermissions() *Permissions {
	return &Permissions{
		AdminChecker: isAdmin("id", "-u"),
	}
}

// isAdmin implements an AdminChecker based on the response from the given
// from an id binary on unix systems. It is expected to be zero for a
// root user.
func isAdmin(bin string, args ...string) Checker {
	return func() (bool, error) {
		o, err := exec.Command(bin, args...).CombinedOutput()
		if err != nil {
			return false, err
		}

		if strings.TrimSpace(string(o)) == "0" {
			return true, nil
		}

		return false, nil
	}
}
