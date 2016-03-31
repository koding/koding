// Package govalidator provides validation functions
package govalidator

import (
	"fmt"
	"math"
	"regexp"
	"strings"
	"time"
	"unicode/utf8"
)

var (
	// ERR_MSG_X_MUST_BE_OF_TYPE_Y = `%s must be of type %s`

	// ERR_MSG_X_IS_MISSING_AND_REQUIRED  = `%s is missing and required`
	// ERR_MSG_MUST_BE_OF_TYPE_X          = `must be of type %s`
	// ERR_MSG_ARRAY_ITEMS_MUST_BE_UNIQUE = `array items must be unique`

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

	// ErrMsgNumberMustBeLowerOrEqual   = `must be lower than or equal to %s`
	// ErrMsgNumberMustBeGreatorOrEqual = `must be greater than or equal to %f`

	// ERR_MSG_NUMBER_MUST_VALIDATE_ALLOF = `must validate all the schemas (allOf)`
	// ERR_MSG_NUMBER_MUST_VALIDATE_ONEOF = `must validate one and only one schema (oneOf)`
	// ERR_MSG_NUMBER_MUST_VALIDATE_ANYOF = `must validate at least one schema (anyOf)`
	// ERR_MSG_NUMBER_MUST_VALIDATE_NOT   = `must not validate the schema (not)`

	// ERR_MSG_ARRAY_MIN_ITEMS = `array must have at least %d items`
	// ERR_MSG_ARRAY_MAX_ITEMS = `array must have at the most %d items`

	// ERR_MSG_ARRAY_MIN_PROPERTIES = `must have at least %d properties`
	// ERR_MSG_ARRAY_MAX_PROPERTIES = `must have at the most %d properties`

	// ERR_MSG_HAS_DEPENDENCY_ON = `has a dependency on %s`

	// ERR_MSG_ARRAY_NO_ADDITIONAL_ITEM = `no additional item allowed on array`

	// ERR_MSG_ADDITIONAL_PROPERTY_NOT_ALLOWED = `additional property "%s" is not allowed`
	// ERR_MSG_INVALID_PATTERN_PROPERTY        = `property "%s" does not match pattern %s`
)

// Validator provides an interface for validation contract
type Validator interface {
	Validate() error
}

type f func() error

// Validate validates the pre-built function
func (f f) Validate() error {
	return f()
}

// MinLength createas a validator for checking if the string has the required
// min length
func MinLength(data string, length int) Validator {
	return f(func() error {
		if utf8.RuneCount([]byte(data)) < length {
			return fmt.Errorf(ErrMsgStringLengthMustBeGreaterOrEqual, length)
		}

		return nil
	})
}

// MaxLength createas a validator for checking if the string has the required
// max length
func MaxLength(data string, length int) Validator {
	return f(func() error {
		if utf8.RuneCount([]byte(data)) > length {
			return fmt.Errorf(ErrMsgStringLengthMustBeLowerOrEqual, length)
		}

		return nil
	})
}

// Pattern validates the given string with the given regex
func Pattern(data string, pattern string) Validator {
	return f(func() error {
		// TODO add caching for compile?
		regex, err := regexp.Compile(pattern)
		if err != nil {
			return err
		}

		if !regex.MatchString(data) {
			return fmt.Errorf(ErrMsgDoesNotMatchPattern, pattern)
		}

		return nil
	})
}

// OneOf creates a validator to check if the given value is one of the element
// of given string slice
func OneOf(data string, enums []string) Validator {
	return f(func() error {
		for _, val := range enums {
			if val == data {
				return nil
			}
		}

		return fmt.Errorf(ErrMsgMustMatchOneEnumValues, strings.Join(enums, ","))
	})
}

// Min creates a validator to check if the given value is greater than the given
// value
func Min(data float64, min float64) Validator {
	return f(func() error {
		if data < min {
			return fmt.Errorf(ErrMsgNumberMustBeGreater, min)
		}

		return nil
	})
}

// Max creates a validator to check if the given value is lower than the given
// value
func Max(data float64, max float64) Validator {
	return f(func() error {
		if data > max {
			return fmt.Errorf(ErrMsgNumberMustBeLower, max)
		}

		return nil
	})
}

// MultipleOf creates a validator to check if the check value is multiple of the
// given value
func MultipleOf(data float64, multipleOf float64) Validator {
	return f(func() error {
		if math.Mod(data, multipleOf) != 0 {
			return fmt.Errorf(ErrMsgMultipleOf, multipleOf)
		}

		return nil
	})
}

// Date creates a validator to check if the given date is not zero date
func Date(data time.Time) Validator {
	return f(func() error {
		if data.IsZero() {
			return fmt.Errorf(ErrMsgDate)
		}

		return nil
	})
}

// NewMulti creates a multi validator, it stops the execution with the first error if error happens while validating
func NewMulti(v ...Validator) Validator {
	return f(func() error {
		for _, vv := range v {
			if err := vv.Validate(); err != nil {
				return err
			}
		}

		return nil
	})
}
