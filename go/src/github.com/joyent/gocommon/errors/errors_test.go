//
// gocommon - Go library to interact with the JoyentCloud
//
//
// Copyright (c) 2013 Joyent Inc.
//
// Written by Daniele Stroppa <daniele.stroppa@joyent.com>
//

package errors_test

import (
	"github.com/joyent/gocommon/errors"
	gc "launchpad.net/gocheck"
	"testing"
)

func Test(t *testing.T) { gc.TestingT(t) }

type ErrorsSuite struct {
}

var _ = gc.Suite(&ErrorsSuite{})

func (s *ErrorsSuite) TestCreateSimpleBadRequestError(c *gc.C) {
	context := "context"
	err := errors.NewBadRequestf(nil, context, "")
	c.Assert(errors.IsBadRequest(err), gc.Equals, true)
	c.Assert(err.Error(), gc.Equals, "Bad Request: context")
}

func (s *ErrorsSuite) TestCreateBadRequestError(c *gc.C) {
	context := "context"
	err := errors.NewBadRequestf(nil, context, "It was bad request: %s", context)
	c.Assert(errors.IsBadRequest(err), gc.Equals, true)
	c.Assert(err.Error(), gc.Equals, "It was bad request: context")
}

func (s *ErrorsSuite) TestCreateSimpleInternalErrorError(c *gc.C) {
	context := "context"
	err := errors.NewInternalErrorf(nil, context, "")
	c.Assert(errors.IsInternalError(err), gc.Equals, true)
	c.Assert(err.Error(), gc.Equals, "Internal Error: context")
}

func (s *ErrorsSuite) TestCreateInternalErrorError(c *gc.C) {
	context := "context"
	err := errors.NewInternalErrorf(nil, context, "It was internal error: %s", context)
	c.Assert(errors.IsInternalError(err), gc.Equals, true)
	c.Assert(err.Error(), gc.Equals, "It was internal error: context")
}

func (s *ErrorsSuite) TestCreateSimpleInvalidArgumentError(c *gc.C) {
	context := "context"
	err := errors.NewInvalidArgumentf(nil, context, "")
	c.Assert(errors.IsInvalidArgument(err), gc.Equals, true)
	c.Assert(err.Error(), gc.Equals, "Invalid Argument: context")
}

func (s *ErrorsSuite) TestCreateInvalidArgumentError(c *gc.C) {
	context := "context"
	err := errors.NewInvalidArgumentf(nil, context, "It was invalid argument: %s", context)
	c.Assert(errors.IsInvalidArgument(err), gc.Equals, true)
	c.Assert(err.Error(), gc.Equals, "It was invalid argument: context")
}

func (s *ErrorsSuite) TestCreateSimpleInvalidCredentialsError(c *gc.C) {
	context := "context"
	err := errors.NewInvalidCredentialsf(nil, context, "")
	c.Assert(errors.IsInvalidCredentials(err), gc.Equals, true)
	c.Assert(err.Error(), gc.Equals, "Invalid Credentials: context")
}

func (s *ErrorsSuite) TestCreateInvalidCredentialsError(c *gc.C) {
	context := "context"
	err := errors.NewInvalidCredentialsf(nil, context, "It was invalid credentials: %s", context)
	c.Assert(errors.IsInvalidCredentials(err), gc.Equals, true)
	c.Assert(err.Error(), gc.Equals, "It was invalid credentials: context")
}

func (s *ErrorsSuite) TestCreateSimpleInvalidHeaderError(c *gc.C) {
	context := "context"
	err := errors.NewInvalidHeaderf(nil, context, "")
	c.Assert(errors.IsInvalidHeader(err), gc.Equals, true)
	c.Assert(err.Error(), gc.Equals, "Invalid Header: context")
}

func (s *ErrorsSuite) TestCreateInvalidHeaderError(c *gc.C) {
	context := "context"
	err := errors.NewInvalidHeaderf(nil, context, "It was invalid header: %s", context)
	c.Assert(errors.IsInvalidHeader(err), gc.Equals, true)
	c.Assert(err.Error(), gc.Equals, "It was invalid header: context")
}

func (s *ErrorsSuite) TestCreateSimpleInvalidVersionError(c *gc.C) {
	context := "context"
	err := errors.NewInvalidVersionf(nil, context, "")
	c.Assert(errors.IsInvalidVersion(err), gc.Equals, true)
	c.Assert(err.Error(), gc.Equals, "Invalid Version: context")
}

func (s *ErrorsSuite) TestCreateInvalidVersionError(c *gc.C) {
	context := "context"
	err := errors.NewInvalidVersionf(nil, context, "It was invalid version: %s", context)
	c.Assert(errors.IsInvalidVersion(err), gc.Equals, true)
	c.Assert(err.Error(), gc.Equals, "It was invalid version: context")
}

func (s *ErrorsSuite) TestCreateSimpleMissingParameterError(c *gc.C) {
	context := "context"
	err := errors.NewMissingParameterf(nil, context, "")
	c.Assert(errors.IsMissingParameter(err), gc.Equals, true)
	c.Assert(err.Error(), gc.Equals, "Missing Parameter: context")
}

func (s *ErrorsSuite) TestCreateMissingParameterError(c *gc.C) {
	context := "context"
	err := errors.NewMissingParameterf(nil, context, "It was missing parameter: %s", context)
	c.Assert(errors.IsMissingParameter(err), gc.Equals, true)
	c.Assert(err.Error(), gc.Equals, "It was missing parameter: context")
}

func (s *ErrorsSuite) TestCreateSimpleNotAuthorizedError(c *gc.C) {
	context := "context"
	err := errors.NewNotAuthorizedf(nil, context, "")
	c.Assert(errors.IsNotAuthorized(err), gc.Equals, true)
	c.Assert(err.Error(), gc.Equals, "Not Authorized: context")
}

func (s *ErrorsSuite) TestCreateNotAuthorizedError(c *gc.C) {
	context := "context"
	err := errors.NewNotAuthorizedf(nil, context, "It was not authorized: %s", context)
	c.Assert(errors.IsNotAuthorized(err), gc.Equals, true)
	c.Assert(err.Error(), gc.Equals, "It was not authorized: context")
}

func (s *ErrorsSuite) TestCreateSimpleRequestThrottledError(c *gc.C) {
	context := "context"
	err := errors.NewRequestThrottledf(nil, context, "")
	c.Assert(errors.IsRequestThrottled(err), gc.Equals, true)
	c.Assert(err.Error(), gc.Equals, "Request Throttled: context")
}

func (s *ErrorsSuite) TestCreateRequestThrottledError(c *gc.C) {
	context := "context"
	err := errors.NewRequestThrottledf(nil, context, "It was request throttled: %s", context)
	c.Assert(errors.IsRequestThrottled(err), gc.Equals, true)
	c.Assert(err.Error(), gc.Equals, "It was request throttled: context")
}

func (s *ErrorsSuite) TestCreateSimpleRequestTooLargeError(c *gc.C) {
	context := "context"
	err := errors.NewRequestTooLargef(nil, context, "")
	c.Assert(errors.IsRequestTooLarge(err), gc.Equals, true)
	c.Assert(err.Error(), gc.Equals, "Request Too Large: context")
}

func (s *ErrorsSuite) TestCreateRequestTooLargeError(c *gc.C) {
	context := "context"
	err := errors.NewRequestTooLargef(nil, context, "It was request too large: %s", context)
	c.Assert(errors.IsRequestTooLarge(err), gc.Equals, true)
	c.Assert(err.Error(), gc.Equals, "It was request too large: context")
}

func (s *ErrorsSuite) TestCreateSimpleRequestMovedError(c *gc.C) {
	context := "context"
	err := errors.NewRequestMovedf(nil, context, "")
	c.Assert(errors.IsRequestMoved(err), gc.Equals, true)
	c.Assert(err.Error(), gc.Equals, "Request Moved: context")
}

func (s *ErrorsSuite) TestCreateRequestMovedError(c *gc.C) {
	context := "context"
	err := errors.NewRequestMovedf(nil, context, "It was request moved: %s", context)
	c.Assert(errors.IsRequestMoved(err), gc.Equals, true)
	c.Assert(err.Error(), gc.Equals, "It was request moved: context")
}

func (s *ErrorsSuite) TestCreateSimpleResourceNotFoundError(c *gc.C) {
	context := "context"
	err := errors.NewResourceNotFoundf(nil, context, "")
	c.Assert(errors.IsResourceNotFound(err), gc.Equals, true)
	c.Assert(err.Error(), gc.Equals, "Resource Not Found: context")
}

func (s *ErrorsSuite) TestCreateResourceNotFoundError(c *gc.C) {
	context := "context"
	err := errors.NewResourceNotFoundf(nil, context, "It was resource not found: %s", context)
	c.Assert(errors.IsResourceNotFound(err), gc.Equals, true)
	c.Assert(err.Error(), gc.Equals, "It was resource not found: context")
}

func (s *ErrorsSuite) TestCreateSimpleUnknownErrorError(c *gc.C) {
	context := "context"
	err := errors.NewUnknownErrorf(nil, context, "")
	c.Assert(errors.IsUnknownError(err), gc.Equals, true)
	c.Assert(err.Error(), gc.Equals, "Unknown Error: context")
}

func (s *ErrorsSuite) TestCreateUnknownErrorError(c *gc.C) {
	context := "context"
	err := errors.NewUnknownErrorf(nil, context, "It was unknown error: %s", context)
	c.Assert(errors.IsUnknownError(err), gc.Equals, true)
	c.Assert(err.Error(), gc.Equals, "It was unknown error: context")
}

func (s *ErrorsSuite) TestErrorCause(c *gc.C) {
	rootCause := errors.NewResourceNotFoundf(nil, "some value", "")
	// Construct a new error, based on a resource not found root cause.
	err := errors.Newf(rootCause, "an error occurred")
	c.Assert(err.Cause(), gc.Equals, rootCause)
	// Check the other error attributes.
	c.Assert(err.Error(), gc.Equals, "an error occurred\ncaused by: Resource Not Found: some value")
}

func (s *ErrorsSuite) TestErrorIsType(c *gc.C) {
	rootCause := errors.NewBadRequestf(nil, "some value", "")
	// Construct a new error, based on a bad request root cause.
	err := errors.Newf(rootCause, "an error occurred")
	// Check that the error is not falsely identified as something it is not.
	c.Assert(errors.IsNotAuthorized(err), gc.Equals, false)
	// Check that the error is correctly identified as a not found error.
	c.Assert(errors.IsBadRequest(err), gc.Equals, true)
}
