package amazon

import (
	"fmt"

	"github.com/aws/aws-sdk-go/aws"
)

// LogFunc describes a single logging.Logger function.
type LogFunc func(format string, args ...interface{})

// Logger is an aws.Logger adapter for our logging.Logger interface.
type Logger struct {
	fn func(string, ...interface{})
}

// NewLogger gives new aws.Logger for the given logging function.
func NewLogger(fn LogFunc) Logger {
	return Logger{fn: fn}
}

// Log implements the aws.Logger interface.
func (l Logger) Log(args ...interface{}) {
	l.fn("%s", fmt.Sprint(args))
}

var _ aws.Logger = Logger{}
