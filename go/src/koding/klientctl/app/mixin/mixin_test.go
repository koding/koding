package mixin_test

import (
	"testing"

	"koding/klientctl/app/mixin"

	"github.com/kr/pretty"
)

// TestStub is a dummy test which is here because of go test, so it does
// not skip executing this package due to no tests.
//
// The purpose of executing TestStub is to ensure no public variable
// panics during initialization.
func TestStub(*testing.T) { pretty.Println(mixin.App) }
