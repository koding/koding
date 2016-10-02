package models

import (
	"fmt"
	"strings"

	mgo "gopkg.in/mgo.v2"
)

// NotFoundError is returned when requested operation on a resource
// cannot be completed due to resource being missing. Most likely
// this kind of errors means the resource was deleted outside
// (shared ownership) and this error is returned to the caller,
// so it recover if possible.
//
// TODO(rjeczalik): the db/mongo helpers should be decorating errors
// instead, so database handling layer is transparent and no
// library specific errors (e.g. mgo.ErrNotFound, pq.Error) are leaked.
type NotFoundError struct {
	Resource string // type / name of resource missing
	Err      error  // underlying error, if any
}

// Error implements the builtin error interface.
func (e *NotFoundError) Error() string {
	return fmt.Sprintf("the %q resource was not found: %s", e.Resource, e.Err)
}

// Underlying gives the error value responsible for failure.
func (e *NotFoundError) Underlying() error {
	return e.Err
}

// ResError is a helper function that decorates the given err with more
// meaningful error value, giving the caller context to recover.
func ResError(err error, resource string) error {
	if err == nil {
		return nil
	}
	if err == mgo.ErrNotFound || strings.Contains(err.Error(), "not found") {
		return &NotFoundError{
			Resource: resource,
			Err:      err,
		}
	}

	return err
}

// IsNotFound gives true when err is of *NotFoundError type and its Resource
// field is equal to one of the given resources.
//
// If no resources are given, the function tests only if err is of
// *NotFoundError type.
func IsNotFound(err error, resources ...string) bool {
	if e, ok := err.(*NotFoundError); ok {
		for _, res := range resources {
			if e.Resource == res {
				return true
			}
		}
	}

	return false
}
