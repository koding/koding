package kloud

import (
	"fmt"
	"strconv"

	"github.com/koding/kite"
)

const (
	ErrAlreadyInitialized  = 101
	ErrNotInitialized      = 102
	ErrUnknownState        = 103
	ErrBuilding            = 104
	ErrMachineIdMissing    = 107
	ErrProviderNotFound    = 108
	ErrNoKiteConnection    = 109
	ErrMachineTerminating  = 110
	ErrMachinePendingEvent = 111
	ErrNoArguments         = 112
	ErrMachineNotFound     = 113

	ErrEventNotFound    = 201
	ErrEventIdMissing   = 202
	ErrEventTypeMissing = 203
	ErrEventArgsEmpty   = 204

	ErrSignUsernameEmpty   = 301
	ErrSignKontrolURLEmpty = 302
	ErrSignPrivateKeyEmpty = 303
	ErrSignPublicKeyEmpty  = 304
	ErrSignGenerateToken   = 305

	ErrBadState = 401
)

var errors = map[int]string{
	ErrAlreadyInitialized:  "Machine is already initialized and prepared.",
	ErrNotInitialized:      "Machine is not initialized.",
	ErrUnknownState:        "Machine is in unknown state. Please contact support.",
	ErrBuilding:            "Machine is being build. Hold on.",
	ErrMachineIdMissing:    "Machine id is missing.",
	ErrProviderNotFound:    "Provider is not found",
	ErrNoKiteConnection:    "Couldn't connect to remote klient kite",
	ErrMachineTerminating:  "Machine is terminated.",
	ErrMachinePendingEvent: "MachineId has a pending event going on",
	ErrNoArguments:         "No arguments are passed.",
	ErrMachineNotFound:     "Machine is not found",

	// Generic errors
	ErrBadState: "Bad state.",

	// Event errors
	ErrEventIdMissing:   "Event id is missing.",
	ErrEventTypeMissing: "Event type is missing.",
	ErrEventNotFound:    "Event not found.",
	ErrEventArgsEmpty:   "Event arguments is empty, expecting an array.",

	// Signer errors
	ErrSignUsernameEmpty:   "Username is empty",
	ErrSignKontrolURLEmpty: "Kontrol URL is empty",
	ErrSignPrivateKeyEmpty: "Private key is empty",
	ErrSignPublicKeyEmpty:  "Public key is empty",
	ErrSignGenerateToken:   "Cannot generate token",
}

func NewErrorMessage(errMsg string) *kite.Error {
	return &kite.Error{
		Type:    "kloudError",
		Message: errMsg + " (error code: 900)",
		CodeVal: "900",
	}
}

func NewError(errorCode int) *kite.Error {
	errMsg, ok := errors[errorCode]
	if !ok {
		panic(fmt.Sprintf("no message is defined for error code %s", errorCode))
	}

	code := strconv.Itoa(errorCode)

	return &kite.Error{
		Type:    "kloudError",
		Message: errMsg + " (error code: " + code + ")",
		CodeVal: code,
	}
}
