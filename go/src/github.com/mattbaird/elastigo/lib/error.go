package elastigo

import (
	"fmt"
)

// 404 Response.
var RecordNotFound = errorf("record not found")

type elastigoError struct {
	s string
}

func errorf(s string, args ...interface{}) elastigoError {
	return elastigoError{s: fmt.Sprintf(s, args...)}
}

func (err elastigoError) Error() string {
	return err.s
}
