package klientctlerrors

import (
	"errors"
	"strings"
)

// Error types, used when needing to return new instances with
// custom error messages. Example:
//
//		type ErrCustomError struct { Msg string }
//		func (e ErrCustomError) Error() string { return e.Msg }

// Error instances, used when we only care about matching the error
// itself. Functions should try to not mix and match returning types
// vs instances, to avoid awkaward check implementation.

var (
	ErrUserCancelled = errors.New("User cancelled operation.")
	ErrExistingMount = errors.New("There's already a mount on that folder.")

	fuseExistingMountErr = "Reading init op: EOF"
)

// IsExistingMountErr return true if err is due there existing a previous
// mount in the same folder.
func IsExistingMountErr(err error) bool {
	if err == nil {
		return false
	}

	// since err is sent over network, == doesnt work
	if err.Error() == ErrExistingMount.Error() {
		return true
	}

	// fuse doesnt have errs to compare against
	if strings.Contains(err.Error(), fuseExistingMountErr) {
		return true
	}

	return false
}
