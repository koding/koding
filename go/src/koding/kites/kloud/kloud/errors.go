package kloud

import "errors"

var (
	ErrAlreadyInitialized = errors.New("Machine is already initialized and prepared.")
	ErrNotInitialized     = errors.New("Machine is not initialized.")
	ErrUnknownState       = errors.New("Machine is in unknown state. Please contact support.")
	ErrBuilding           = errors.New("Machine is being build. Hold on...")
)
