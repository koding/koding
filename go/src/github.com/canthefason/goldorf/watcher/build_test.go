package watcher

import (
	"errors"
	"testing"
)

func TestInterpretError(t *testing.T) {
	testError := errors.New("test error")

	// interpretError just handles the exec.ExitError
	err := interpretError(testError)
	if err != testError {
		t.Error("Expected same error to return")
	}
}
