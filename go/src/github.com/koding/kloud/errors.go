package kloud

import (
	"fmt"
	"strconv"

	"github.com/koding/kite"
)

const (
	ErrMachineInitialized    = 100
	ErrMachineNotInitialized = 101
	ErrMachineUnknownState   = 102
	ErrMachineIsBuilding     = 103
	ErrMachineIdMissing      = 104
	ErrMachineTerminating    = 105
	ErrMachineNotFound       = 106
	ErrMachinePendingEvent   = 107

	ErrEventNotFound    = 200
	ErrEventIdMissing   = 201
	ErrEventTypeMissing = 202
	ErrEventArgsEmpty   = 203

	ErrSignUsernameEmpty   = 300
	ErrSignKontrolURLEmpty = 301
	ErrSignPrivateKeyEmpty = 302
	ErrSignPublicKeyEmpty  = 303
	ErrSignGenerateToken   = 304

	ErrBadState          = 400
	ErrProviderNotFound  = 401
	ErrNoKiteConnection  = 402
	ErrNoArguments       = 403
	ErrBadResponse       = 404
	ErrProviderAvailable = 405
)

var errors = map[int]string{
	// Machine errors
	ErrMachineInitialized:    "Machine is already initialized and prepared.",
	ErrMachineNotInitialized: "Machine is not initialized.",
	ErrMachineUnknownState:   "Machine is in unknown state. Please contact support.",
	ErrMachineIsBuilding:     "Machine is being build. Hold on.",
	ErrMachineIdMissing:      "Machine id is missing.",
	ErrMachineTerminating:    "Machine is terminated.",
	ErrMachineNotFound:       "Machine is not found",
	ErrMachinePendingEvent:   "Machine has a pending event going on",

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

	// Generic errors
	ErrBadState:          "Bad state.",
	ErrProviderNotFound:  "Provider is not found",
	ErrNoKiteConnection:  "Couldn't connect to remote klient kite",
	ErrNoArguments:       "No arguments are passed.",
	ErrBadResponse:       "Provider has a bad response.",
	ErrProviderAvailable: "Provider is already available",
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
