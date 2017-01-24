package stack

import (
	"fmt"
	"strconv"

	"github.com/koding/kite"
)

// Error is used to differentiate expected stack errors
// from the unexpected ones. If kloud kite method handler
// return non-nil error of *stack.Error type, the error
// is going to be logged.
type Error struct {
	Err error
}

// Error implements the builtin error interface.
func (e *Error) Error() string {
	return e.Err.Error()
}

type EventerError struct {
	Msg string
}

func NewEventerError(err error) *EventerError {
	if e, ok := err.(*EventerError); ok {
		return e
	}

	return &EventerError{
		Msg: err.Error(),
	}
}

func (e *EventerError) Error() string {
	return e.Msg
}

const (
	ErrMachineInitialized        = 100
	ErrMachineNotInitialized     = 101
	ErrMachineUnknownState       = 102
	ErrMachineIsBuilding         = 103
	ErrMachineIdMissing          = 104
	ErrMachineTerminating        = 105
	ErrMachineNotFound           = 106
	ErrMachineIsLocked           = 107
	ErrSnapshotIdMissing         = 108
	ErrTerraformContextIsMissing = 109

	ErrEventNotFound    = 200
	ErrEventIdMissing   = 201
	ErrEventTypeMissing = 202
	ErrEventArgsEmpty   = 203

	ErrBadState               = 400
	ErrProviderNotFound       = 401
	ErrNoKiteConnection       = 402
	ErrNoArguments            = 403
	ErrBadResponse            = 404
	ErrProviderAvailable      = 405
	ErrProviderNotImplemented = 406
	ErrBuilderNotImplemented  = 407
	ErrProviderIsMissing      = 408
	ErrStaterNotImplemented   = 409
	ErrProviderIsWrong        = 410
	ErrProviderIsDisabled     = 411
	ErrMachineNotImplemented  = 412
	ErrStackNotImplemented    = 413
	ErrCredentialIsMissing    = 414
	ErrBadRequest             = 415
	ErrNotAuthorized          = 416
	ErrInternalServer         = 417

	ErrTeamSubIsNotActive = 420

	ErrUserNotConfirmed = 500
)

var kloudErrors = map[int]string{
	// Machine errors
	ErrMachineIdMissing:          "Machine id is missing.",
	ErrMachineInitialized:        "Machine is already initialized and prepared.",
	ErrMachineNotInitialized:     "Machine is not initialized.",
	ErrMachineUnknownState:       "Machine is in unknown state. Please contact support.",
	ErrMachineIsBuilding:         "Machine is being build. Hold on.",
	ErrMachineTerminating:        "Machine is terminated.",
	ErrMachineNotFound:           "Machine is not found",
	ErrMachineIsLocked:           "Machine is locked by someone else",
	ErrSnapshotIdMissing:         "Snapshot id is missing.",
	ErrTerraformContextIsMissing: "Terraform context file is missing.",

	// Event errors
	ErrEventIdMissing:   "Event id is missing.",
	ErrEventTypeMissing: "Event type is missing.",
	ErrEventNotFound:    "Event not found.",
	ErrEventArgsEmpty:   "Event arguments is empty, expecting an array.",

	// Generic errors
	ErrBadState:               "Bad state.",
	ErrProviderNotFound:       "Provider is not found",
	ErrNoKiteConnection:       "Couldn't connect to remote klient kite",
	ErrNoArguments:            "No arguments are passed.",
	ErrBadResponse:            "Provider has a bad response.",
	ErrProviderAvailable:      "Provider is already available",
	ErrProviderNotImplemented: "Provider doesn't implement the given interface",
	ErrBuilderNotImplemented:  "Provider doesn't implement the builder interface",
	ErrStaterNotImplemented:   "Provider doesn't implement the stater interface",
	ErrMachineNotImplemented:  "Provider doesn't implement the machine interface",
	ErrStackNotImplemented:    "Provider doesn't implement the stack interface",
	ErrProviderIsMissing:      "Provider argument is missing.",
	ErrProviderIsWrong:        "Provider doesn't match the internal name",
	ErrProviderIsDisabled:     "Provider is disabled",
	ErrCredentialIsMissing:    "Credential is missing",
	ErrBadRequest:             "Bad request",
	ErrNotAuthorized:          "Not Authorized",
	ErrInternalServer:         "Internal server error",

	// Team errors
	ErrTeamSubIsNotActive: "Team subscription is no longer active",

	// User errors
	ErrUserNotConfirmed: "User account is not confirmed",
}

func NewErrorMessage(errMsg string) *kite.Error {
	return &kite.Error{
		Type:    "kloudError",
		Message: errMsg + " (error code: 900)",
		CodeVal: "900",
	}
}

func NewError(errorCode int) *kite.Error {
	errMsg, ok := kloudErrors[errorCode]
	if !ok {
		panic(fmt.Sprintf("no message is defined for error code %d", errorCode))
	}

	code := strconv.Itoa(errorCode)

	return &kite.Error{
		Type:    "kloudError",
		Message: errMsg + " (error code: " + code + ")",
		CodeVal: code,
	}
}
