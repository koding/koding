package sl

import (
	"encoding/json"
	"fmt"
)

// NotFoundError is specialised type of error, which is returned when
// requested resource is not found.
type NotFoundError struct {
	Resource string // resource type that was requested
	Err      error  // underlying reason that caused the error
}

func newNotFoundError(res string, err error) error {
	return &NotFoundError{
		Resource: res,
		Err:      err,
	}
}

// Error implements the builtin error interface.
func (err *NotFoundError) Error() string {
	return fmt.Sprintf("%s not found: %s", err.Resource, err.Err)
}

// IsNotFound returns true if the error is *NotFoundError.
func IsNotFound(err error) bool {
	if err == nil {
		return false
	}
	if err.Error() == "not found" {
		return true
	}
	_, ok := err.(*NotFoundError)
	return ok
}

// Error represents and error object response payload.
type Error struct {
	Message string `json:"error,omitepty"`
	Code    string `json:"code,omitempty"`
}

// Error implements the builtin error interface.
func (err *Error) Error() string {
	return fmt.Sprintf("Softlayer API error: message=%q, code=%q", err.Message, err.Code)
}

func checkError(p []byte) error {
	var e Error
	err := json.Unmarshal(p, &e)
	if err == nil && e.Message != "" && e.Code != "" {
		return &e
	}
	return nil
}
