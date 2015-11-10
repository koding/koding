package klientctlerrors

import "errors"

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
)
