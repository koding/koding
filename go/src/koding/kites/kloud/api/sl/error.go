package sl

import (
	"encoding/json"
	"fmt"
)

// NotFoundError is specialised type of error, which is returned when
// requested resource is not found.
//
// If a filter was used to request the resource, it will be included
// in the error value.
type NotFoundError struct {
	Filter *Filter
}

// Error implements the builtin error interface.
func (err *NotFoundError) Error() string {
	if err.Filter != nil {
		return fmt.Sprintf("no templates found for filter=%+v", err.Filter)
	}
	return "no templates found"
}

// IsNotFound returns true if the error is *NotFoundError.
func IsNotFound(err error) bool {
	_, ok := err.(*NotFoundError)
	return ok
}

// APIError represents and error object response payload.
type APIError struct {
	Message string `json:"error,omitepty"`
	Code    string `json:"code,omitempty"`
}

// Error implements the builtin error interface.
func (err *APIError) Error() string {
	return fmt.Sprintf("Softlayer API error: message=%q, code=%q", err.Message, err.Code)
}

func checkAPIError(p []byte) error {
	var e APIError
	err := json.Unmarshal(p, &e)
	if err == nil && e.Message != "" && e.Code != "" {
		return &e
	}
	return nil
}
