package cli

// Error carries application error along with requested exit code.
type Error struct {
	E        error
	ExitCode int
}

// NewError creates a new CLI error.
func NewError(exit int, err error) *Error {
	return &Error{
		E:        err,
		ExitCode: exit,
	}
}

// Error implements builtin.error interface. It prints underlying error.
func (e *Error) Error() string {
	if e.E != nil {
		return e.E.Error()
	}

	return "unknown"
}

// ExitCodeFromError gets exit code from provided error. If error is nil, the
// exit code will be 0. For errors other than Error type, 1 will be returned.
func ExitCodeFromError(err error) int {
	if err == nil {
		return 0
	}

	if ee, ok := err.(*Error); ok {
		return ee.ExitCode
	}

	return 1
}
