package kite

import (
	"reflect"
)

type KiteError interface {
	error
	Code() string
}

func NewKiteErr(err error) KiteError {
	return &BaseError{
		Message: err.Error(),
		CodeErr: "ErrBaseError",
	}
}

type ErrorObject struct {
	Name    string `json:"name"`
	Message string `json:"message"`
	Code    string `json:"code"`
}

func CreateErrorObject(err KiteError) *ErrorObject {
	return &ErrorObject{Name: reflect.TypeOf(err).Elem().Name(), Message: err.Error(), Code: err.Code()}
}

type InternalKiteError struct{}

func (err *InternalKiteError) Error() string {
	return "An internal error occurred in the Kite."
}

func (i *InternalKiteError) Code() string {
	return "ErrInternalKite"
}

type UnknownMethodError struct {
	Method string
}

func (err *UnknownMethodError) Error() string {
	return "Method '" + err.Method + "' not known."
}

func (err *UnknownMethodError) Code() string {
	return "ErrUnknownMethod"
}

type ArgumentError struct {
	Expected string
}

func (err *ArgumentError) Error() string {
	return "Invalid argument, " + err.Expected + " expected."
}

func (a *ArgumentError) Code() string {
	return "ErrArgument"
}

type PermissionError struct{}

func (err *PermissionError) Error() string {
	return "Permission denied."
}

func (err *PermissionError) Code() string {
	return "ErrPermissionDenied"
}

type WrongChannelError struct{}

func (err *WrongChannelError) Error() string {
	return "Wrong channel."
}

func (err *WrongChannelError) Code() string {
	return "ErrWrongChannel"
}

type BaseError struct {
	Message string
	CodeErr string
}

func (err *BaseError) Error() string {
	return err.Message
}

func (err *BaseError) Code() string {
	return err.CodeErr
}
