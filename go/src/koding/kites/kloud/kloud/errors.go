package kloud

import (
	"fmt"
	"strconv"
)

const (
	ErrAlreadyInitialized = 101
	ErrNotInitialized     = 102
	ErrUnknownState       = 103
	ErrBuilding           = 104
	ErrMachineIdMissing   = 107
	ErrProviderNotFound   = 108
	ErrNoKiteConnection   = 109
	ErrMachineTerminating = 110

	ErrEventNotFound    = 201
	ErrEventIdMissing   = 202
	ErrEventTypeMissing = 203

	ErrSignUsernameEmpty   = 301
	ErrSignKontrolURLEmpty = 302
	ErrSignPrivateKeyEmpty = 303
	ErrSignPublicKeyEmpty  = 304
	ErrSignGenerateToken   = 305
)

var errors = map[int]string{
	ErrAlreadyInitialized: "Machine is already initialized and prepared.",
	ErrNotInitialized:     "Machine is not initialized.",
	ErrUnknownState:       "Machine is in unknown state. Please contact support.",
	ErrBuilding:           "Machine is being build. Hold on.",
	ErrMachineIdMissing:   "Machine id is missing.",
	ErrProviderNotFound:   "Provider is not found",
	ErrNoKiteConnection:   "Couldn't connect to remote klient kite",
	ErrMachineTerminating: "Machine is terminated.",

	// Event errors
	ErrEventIdMissing:   "Event id is missing.",
	ErrEventTypeMissing: "Event type is missing.",
	ErrEventNotFound:    "Event not found.",

	// Signer errors
	ErrSignUsernameEmpty:   "Username is empty",
	ErrSignKontrolURLEmpty: "Kontrol URL is empty",
	ErrSignPrivateKeyEmpty: "Private key is empty",
	ErrSignPublicKeyEmpty:  "Public key is empty",
	ErrSignGenerateToken:   "Cannot generate token",
}

type Error struct {
	Message string `json:"message"`
	Code    int    `json:"code"`
}

func (e Error) Error() string {
	return e.Message + " (error code: " + strconv.Itoa(e.Code) + ")"
}

func NewError(errorCode int) *Error {
	errMsg, ok := errors[errorCode]
	if !ok {
		panic(fmt.Sprintf("no message is defined for error code %s", errorCode))
	}

	return &Error{
		Message: errMsg,
		Code:    errorCode,
	}
}
