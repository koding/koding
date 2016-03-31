[![GoDoc](https://godoc.org/github.com/cihangir/govalidator?status.svg)](https://godoc.org/github.com/cihangir/govalidator)
[![Build Status](https://travis-ci.org/cihangir/govalidator.svg)](https://travis-ci.org/cihangir/govalidator)

# govalidator
--
    import "github.com/cihangir/govalidator"


## Usage

```go
var (

	// ErrMsgStringLengthMustBeGreaterOrEqual holds the error message format
	ErrMsgStringLengthMustBeGreaterOrEqual = `string length must be greater or equal to %d`

	// ErrMsgStringLengthMustBeLowerOrEqual holds the error message format
	ErrMsgStringLengthMustBeLowerOrEqual = `string length must be lower or equal to %d`

	// ErrMsgDoesNotMatchPattern holds the error message format
	ErrMsgDoesNotMatchPattern = `does not match pattern '%s'`

	// ErrMsgMustMatchOneEnumValues holds the error message format
	ErrMsgMustMatchOneEnumValues = `must match one of the enum values [%s]`

	// ErrMsgNumberMustBeGreater holds the error message format
	ErrMsgNumberMustBeGreater = `must be greater than %f`

	// ErrMsgNumberMustBeLower holds the error message format
	ErrMsgNumberMustBeLower = `must be lower than %f`

	// ErrMsgMultipleOf holds the error message format
	ErrMsgMultipleOf = `must be a multiple of %f`

	// ErrMsgDate holds the error message format
	ErrMsgDate = `date should not be zero`
)
```

#### type Validator

```go
type Validator interface {
	Validate() error
}
```

Validator provides an interface for validation contract

#### func  Date

```go
func Date(data time.Time) Validator
```
Date creates a validator to check if the given date is not zero date

#### func  Max

```go
func Max(data float64, max float64) Validator
```
Max creates a validator to check if the given value is lower than the given
value

#### func  MaxLength

```go
func MaxLength(data string, length int) Validator
```
MaxLength createas a validator for checking if the string has the required max
length

#### func  Min

```go
func Min(data float64, min float64) Validator
```
Min creates a validator to check if the given value is greater than the given
value

#### func  MinLength

```go
func MinLength(data string, length int) Validator
```
MinLength createas a validator for checking if the string has the required min
length

#### func  MultipleOf

```go
func MultipleOf(data float64, multipleOf float64) Validator
```
MultipleOf creates a validator to check if the check value is multiple of the
given value

#### func  NewMulti

```go
func NewMulti(v ...Validator) Validator
```
NewMulti creates a multi validator, it stops the execution with the first error
if error happens while validating

#### func  OneOf

```go
func OneOf(data string, enums []string) Validator
```
OneOf creates a validator to check if the given value is one of the element of
given string slice

#### func  Pattern

```go
func Pattern(data string, pattern string) Validator
```
Pattern validates the given string with the given regex
