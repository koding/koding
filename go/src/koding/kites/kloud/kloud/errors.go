package kloud

import (
	"fmt"
	"strconv"
)

const (
	ErrAlreadyInitialized = 1
	ErrNotInitialized     = 2
	ErrUnknownState       = 3
	ErrBuilding           = 4
	ErrEventIdMissing     = 5
	ErrEventTypeMissing   = 6
	ErrMachineIdMissing   = 7
	ErrProviderNotFound   = 8
	ErrNoKiteConnection   = 9

	ErrSignUsernameEmpty   = 10
	ErrSignKontrolURLEmpty = 11
	ErrSignPrivateKeyEmpty = 12
	ErrSignPublicKeyEmpty  = 13
	ErrSignGenerateToken   = 14
)

var errors = map[int]string{
	ErrAlreadyInitialized: "Machine is already initialized and prepared.",
	ErrNotInitialized:     "Machine is not initialized.",
	ErrUnknownState:       "Machine is in unknown state. Please contact support.",
	ErrBuilding:           "Machine is being build. Hold on.",
	ErrEventIdMissing:     "Event id is missing.",
	ErrEventTypeMissing:   "Event type is missing.",
	ErrMachineIdMissing:   "Machine id is missing.",
	ErrProviderNotFound:   "Provider is not found",
	ErrNoKiteConnection:   "Couldn't connect to remote klient kite",

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
