package util

import "strings"

// +build linux darwin

// isAdmin implements IsAdmin based on the response from the given
// from an id binary on unix systems. It is expected to be zero for a
// root user.
func (p *Permissions) isAdmin() (bool, error) {
	o, err := p.binRunner("id", "-u")
	if err != nil {
		return false, err
	}

	if strings.TrimSpace(string(o)) == "0" {
		return true, nil
	}

	return false, nil
}
