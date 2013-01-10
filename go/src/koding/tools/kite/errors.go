package kite

import (
	"fmt"
)

type ArgumentError struct {
	Expected string
}

func (err *ArgumentError) Error() string {
	return fmt.Sprintf("Invalid argument, %v expected.", err.Expected)
}
