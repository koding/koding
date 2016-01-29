package klientctlerrors

import (
	"errors"
	"strings"

	"github.com/koding/kite"
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

func IsDialFailedErr(err error) bool {
	if err == nil {
		return false
	}

	if kiteErr, ok := err.(*kite.Error); ok && kiteErr.Type == "dialing failed" {
		return true
	}

	return false
}

// IsGetKitesFailure checks if the given error is a getKites error. It does so by
// checking both the kite.Error type, and the message - to be as sure as possible.
func IsGetKitesFailure(err error) bool {
	if err == nil {
		return false
	}

	kiteErr, ok := err.(*kite.Error)
	switch {
	case !ok:
		return false
	case kiteErr.Type != "timeout":
		return false
	case !strings.HasPrefix(err.Error(), `timeout: No response to "getKodingKites"`):
		return false
	default:
		return true
	}
}
