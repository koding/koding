package govalidator

import (
	"fmt"
	"path/filepath"
	"runtime"
	"testing"
	"time"
)

// assert fails the test if the condition is false.
func assert(t *testing.T, condition bool, msg string, v ...interface{}) {
	if !condition {
		_, file, line, _ := runtime.Caller(1)
		fmt.Printf("\033[31m%s:%d: "+msg+"\033[39m\n\n", append([]interface{}{filepath.Base(file), line}, v...)...)
		t.FailNow()
	}
}

func TestMinLengthFail(t *testing.T) {
	assert(t, MinLength("", 0).Validate() == nil, "empty string should pass with min length 0")
}

func TestMinLengthPass(t *testing.T) {
	assert(t, MinLength("", 1).Validate() != nil, "empty string should fail with min length 1")
}

func TestMaxLengthPassForEmptyString(t *testing.T) {
	assert(t, MaxLength("", 0).Validate() == nil, "empty string should pass with max length 0")
}

func TestMaxLengthPass(t *testing.T) {
	assert(t, MaxLength("", 1).Validate() == nil, "empty string should pass with max length 1")
}

func TestMaxLengthFail(t *testing.T) {
	assert(t, MaxLength("test", 1).Validate() != nil, "2 char string should fail with max length 1")
}

func TestInvalidPattern(t *testing.T) {
	assert(t, Pattern("--", "\\").Validate() != nil, "invalid regex should fail with pattern validator")
}

func TestPatternFail(t *testing.T) {
	assert(t, Pattern("--", "az").Validate() != nil, "regex should fail with non-matching input")
}

func TestPatternPass(t *testing.T) {
	assert(t, Pattern("--", "-").Validate() == nil, "regex should pass with matching input")
}

func TestOneOfFail(t *testing.T) {
	assert(t, OneOf("foo", []string{"bar", "zaa"}).Validate() != nil, "OneOf should fail with non-existing element")
}

func TestOneOfPass(t *testing.T) {
	assert(t, OneOf("foo", []string{"bar", "foo"}).Validate() == nil, "OneOf should pass with matching element")
}

func TestMinFail(t *testing.T) {
	assert(t, Min(2, 3).Validate() != nil, "Min should fail bigger input")
}

func TestMinPassWithSame(t *testing.T) {
	assert(t, Min(2, 2).Validate() == nil, "Min should pass with same input")
}

func TestMinPass(t *testing.T) {
	assert(t, Min(2, 1).Validate() == nil, "Min should fail smaller input")
}

func TestMaxFail(t *testing.T) {
	assert(t, Max(2, 1).Validate() != nil, "Max should fail smaller input")
}

func TestMaxPassWithSame(t *testing.T) {
	assert(t, Max(2, 2).Validate() == nil, "Max should pass with same input")
}

func TestMaxPass(t *testing.T) {
	assert(t, Max(2, 3).Validate() == nil, "Max should fail bigger input")
}

func TestMultipleOfFail(t *testing.T) {
	assert(t, MultipleOf(3, 2).Validate() != nil, "MultipleOf should fail")
}

func TestMultipleOfPassWithSame(t *testing.T) {
	assert(t, MultipleOf(2, 2).Validate() == nil, "MultipleOf should pass with same input")
}

func TestMultipleOfPass(t *testing.T) {
	assert(t, MultipleOf(4, 2).Validate() == nil, "MultipleOf should pass ")
}

func TestDateFail(t *testing.T) {
	assert(t, Date(time.Time{}).Validate() != nil, "Zero Date should fail")
}

func TestDatePass(t *testing.T) {
	assert(t, Date(time.Now()).Validate() == nil, "Date should pass")
}

func TestNewMultiFail(t *testing.T) {
	assert(t, NewMulti(Date(time.Time{})).Validate() != nil, "NewMulti should fail")
}

func TestNewMultiPass(t *testing.T) {
	assert(t, NewMulti(Date(time.Now())).Validate() == nil, "NewMulti should pass")
}
