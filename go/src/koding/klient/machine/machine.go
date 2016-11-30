package machine

import "errors"

var (
	// ErrMachineNotFound indicates that provided machine cannot be found.
	ErrMachineNotFound = errors.New("machine not found")
)

// IsMachineNotFound is a helper function that checks if provided error
// describes missing machine.
func IsMachineNotFound(err error) bool {
	return err == ErrMachineNotFound
}

// ID is a unique identifier of the machine.
type ID string
