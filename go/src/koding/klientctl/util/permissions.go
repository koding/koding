package util

import "errors"

// Checker is a generic boolean checking signature
type Checker func() (bool, error)

// Permissions is a struct containing tools for testing and/or verifying
// the current users permissions in a mockable fashion.
type Permissions struct {
	AdminChecker Checker
}

// IsAdmin checks whether or not the current user has admin privelages.
//
// On Darwin and Linux, this checks if the `id` process is
func (p *Permissions) IsAdmin() (bool, error) {
	if p.AdminChecker == nil {
		return false, errors.New("adminChecker is required for IsAdmin() functionality")
	}

	return p.AdminChecker()
}
