package tigertonic

import (
	"errors"
	"testing"
)

func TestNamedHTTPEquivError(t *testing.T) {
	var err error = OK{testNamedError("foo")}
	if "foo" != errorName(err, "error") {
		t.Fatal(errorName(err, "error"))
	}
}

func TestUnnamedError(t *testing.T) {
	var err error = errors.New("foo")
	if "error" != errorName(err, "error") {
		t.Fatal(errorName(err, "error"))
	}
}

func TestUnnamedHTTPEquivError(t *testing.T) {
	var err error = OK{errors.New("foo")}
	if "tigertonic.OK" != errorName(err, "error") {
		t.Fatal(errorName(err, "error"))
	}
}

func TestUnnamedSnakeCaseHTTPEquivError(t *testing.T) {
	SnakeCaseHTTPEquivErrors = true
	defer func() { SnakeCaseHTTPEquivErrors = false }()
	var err error = OK{errors.New("foo")}
	if "ok" != errorName(err, "error") {
		t.Fatal(errorName(err, "error"))
	}
}
