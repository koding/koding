// Package multierrors is a convenient helper package to return multiple errors
// in type error
package multierrors

import "fmt"

type Errors struct {
	errs []error
}

func New() *Errors {
	return &Errors{
		errs: make([]error, 0),
	}
}

func (e *Errors) Add(err error) {
	if err != nil {
		e.errs = append(e.errs, err)
	}
}

func (e *Errors) Len() int {
	return len(e.errs)
}

func (e *Errors) Error() string {
	errorMsg := fmt.Sprintf("[%d errors] ", len(e.errs))
	for _, err := range e.errs {
		errorMsg += fmt.Sprintf("[%s]", err.Error())
	}

	return errorMsg
}
