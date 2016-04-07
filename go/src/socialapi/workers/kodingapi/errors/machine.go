package errs

import "errors"

var (
	ErrMachineIDNotSet       = errors.New("Machine.ID not set")
	ErrMachineOwnerNotSet    = errors.New("Machine.Owner not set")
	ErrMachineStateNotSet    = errors.New("Machine.State not set")
	ErrMachineUsernameNotSet = errors.New("Machine.Username not set")
)
