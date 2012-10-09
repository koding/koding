package kite

import (
	"fmt"
)

type UnknownMethodError struct {
	Name string
}

func (err *UnknownMethodError) Error() string {
	return fmt.Sprintf("Method '%v' not known.", err.Name)
}

type ArgumentError struct {
	Expected string
}

func (err *ArgumentError) Error() string {
	return fmt.Sprintf("Invalid argument, %v expected.", err.Expected)
}
