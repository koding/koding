package stripe

import "errors"

var (
	ErrStripePlanAlreadyExists = errors.New(`{"type":"invalid_request_error","message":"Plan already exists."}`)
)
