package integration

import (
	"testing"

	"github.com/koding/integration/services"
	"github.com/koding/logging"
)

var testRootPath = "http://lvh.me:8090"

func TestValidate(t *testing.T) {

	l := logging.NewLogger("test")
	h := NewHandler(l, &services.Services{})

	err := h.validate("", "")
	if err != ErrTokenNotSet {
		t.Errorf("expected '%s' error, but got '%s'", ErrTokenNotSet, err)
	}

	err = h.validate("", "tokentome")
	if err != ErrNameNotSet {
		t.Errorf("expected '%s' errors, but got '%s'", ErrNameNotSet, err)
	}
}
