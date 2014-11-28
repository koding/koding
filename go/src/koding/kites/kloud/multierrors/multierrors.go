// package multierrors is a convenient helper package to return multipl errors
// in type error
package multierrors

import "fmt"

type Errors []error

func (e Errors) Add(err error) {
	e = append(e, err)
}

func (e Errors) Len() int {
	return len(e)
}

func (e Errors) Error() string {
	errorMsg := fmt.Sprintf("[%d errors] ", len(e))
	for i, err := range e {
		if err != nil {
			errorMsg += fmt.Sprintf("[%d] %s", i, err.Error())
		}
	}

	return errorMsg
}
