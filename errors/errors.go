package errs

import "errors"

// Error types, used when we need meaningful data returned *with*
// the error.

// Error instances, used when we only care about matching the error
// itself. Functions should try to not mix and match returning types
// vs instances, to avoid awkaward check implementation.

var (
	ErrUserCancelled = errors.New("User cancelled operation")
)
