// A series of error related functions and errors.
package klientctlerrors

import (
	"errors"
	"strings"

	"koding/klient/kiteerrortypes"

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

// IsMachineNotValidYetErr checks if the given error is machine not valid yet.
func IsMachineNotValidYetErr(err error) bool {
	if err == nil {
		return false
	}

	kiteErr, ok := err.(*kite.Error)
	if ok && kiteErr.Type == kiteerrortypes.MachineNotValidYet {
		return true
	}

	return false
}

// IsListReconnectingErr checks if the message is either the SessionNotEstablished
// sendErr or the getKites error. Two errors that, during getKites from kontrol,
// mean we are in the process of reconnecting to kontrol.
//
// This function explicitly refers to List reconnecting, because other things
// reconnecting will respond differently. Eg, a Remote reconnecting has no involvement
// with GetKites failures, etc.
func IsListReconnectingErr(err error) bool {
	return IsSessionNotEstablishedFailure(err) || IsGetKitesFailure(err)
}

// IsSessionNotEstablishedFailure checks if the given error is the Kite XHR Transport
// error of Session Not Established.
// It does so by checking both the kite.Error type, and the message - to be as sure
// as possible.
func IsSessionNotEstablishedFailure(err error) bool {
	return isKiteOfTypeOrPrefixErr(
		err, "sendError",
		`can't send, session is not established yet`,
	)
}

// IsGetKitesFailure checks if the given error is a getKites error. It does so by
// checking both the kite.Error type, and the message - to be as sure as possible.
//
// Note that this is explicitly checking GetKodingKites, as that is the only method
// remote.list and kd list uses.
func IsGetKitesFailure(err error) bool {
	return isKiteOfTypeOrPrefixErr(
		err, "timeout",
		`No response to "getKodingKites"`,
	)
}

func IsMachineActionLockedErr(err error) bool {
	return IsKiteOfTypeErr(err, kiteerrortypes.MachineActionIsLocked)
}

func IsRemotePathNotExistErr(err error) bool {
	return IsKiteOfTypeErr(err, kiteerrortypes.RemotePathDoesNotExist)
}

func IsProcessError(err error) bool {
	return IsKiteOfTypeErr(err, kiteerrortypes.ProcessError)
}

func IsKiteOfTypeErr(err error, t string) bool {
	if err == nil {
		return false
	}

	kiteErr, ok := err.(*kite.Error)
	switch {
	case !ok:
		return false
	case kiteErr.Type != t:
		return false
	default:
		return true
	}
}

func isKiteOfTypeOrPrefixErr(err error, t, p string) bool {
	if err == nil {
		return false
	}

	kiteErr, ok := err.(*kite.Error)
	switch {
	case !ok:
		return false
	case kiteErr.Type != t:
		return false
	case !strings.HasPrefix(kiteErr.Message, p):
		return false
	default:
		return true
	}
}
