package stackplan

import (
	"errors"
	"koding/db/models"

	"github.com/koding/logging"
)

// DetachOptions groups parameters for stack detach operation.
type DetachOptions struct {
	Stack *models.ComputeStack
	Log   logging.Logger
}

// Valid implements the kloud.Validator interface.
func (opts *DetachOptions) Valid() error {
	if opts == nil {
		return errors.New("invalid nil options")
	}

	if opts.Stack == nil {
		return errors.New("invalid nil stack")
	}

	return nil
}

// DestroyOptions groups parameters for stack destroy operation.
type DestroyOptions struct {
	Stack *models.ComputeStack
	Log   logging.Logger
}

// Valid implements the kloud.Validator interface.
func (opts *DestroyOptions) Valid() error {
	if opts == nil {
		return errors.New("invalid nil options")
	}

	if opts.Stack == nil {
		return errors.New("invalid nil stack")
	}

	return nil
}

// Database describes an interface for stack's database operations.
//
// TODO(rjeczalik): move updateMachines from {aws,vagrant}/stackplan.go here
// and merge them to single, generic Update(*UpdateOptions) method.
type Database interface {
	// Detach detaches user from the stack. The operation is performed
	// prior to stack reinit - it allows the stack to be concurrently
	// deleted while enabling user to start building new stack.
	Detach(*DetachOptions) error

	// Destroy removes the stack completely.
	Destroy(*DestroyOptions) error
}

// DatabaseBuilder is a decorator for Builder and Database values.
//
// Both are required to be non-nil.
type DatabaseBuilder struct {
	Database
	*Builder
}

// Detach detaches the stack built by the underlying Builder.
//
// Prior to calling Detach, the Builder is required to have
// the stack successfully built with the BuildStack method.
//
// Otherwise the behavior of the method is unspecified.
func (db *DatabaseBuilder) Detach() error {
	opts := &DetachOptions{
		Stack: db.Builder.Stack.Stack,
		Log:   db.log().New(db.Builder.Stack.Stack.Id.Hex()),
	}

	return db.Database.Detach(opts)
}

// Destroy destroys the stack built by the underlying Builder.
//
// Prior to calling Destroy, the Builder is required to have
// the stack successfully built with the BuildStack method.
//
// Otherwise the behavior of the method is unspecified.
func (db *DatabaseBuilder) Destroy() error {
	opts := &DestroyOptions{
		Stack: db.Builder.Stack.Stack,
		Log:   db.log().New(db.Builder.Stack.Stack.Id.Hex()),
	}

	return db.Database.Destroy(opts)
}

func (db *DatabaseBuilder) log() logging.Logger {
	if db.Builder.Log != nil {
		return db.Builder.Log
	}

	return defaultLog
}
