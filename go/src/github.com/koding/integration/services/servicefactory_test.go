package services

import (
	"testing"
)

func TestServiceFactory(t *testing.T) {
	sf := NewServiceFactory()
	_, err := sf.Create("heleley", &ServiceConfig{})
	if err != ErrServiceNotFound {
		t.Errorf("expected '%s', but got '%v'", ErrServiceNotFound, err)
	}

	sf = NewServiceFactory()
	_, err = sf.Create("iterable", &ServiceConfig{})
	if err != nil {
		t.Errorf("unexpected error: '%s'", err)
	}
}
