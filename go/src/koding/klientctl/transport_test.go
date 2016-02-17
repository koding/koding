package main

import (
	"testing"

	"github.com/koding/kite/dnode"
	. "github.com/smartystreets/goconvey/convey"
)

// fakeTransport implements Transport interface and is to be used in tests.
type fakeTransport struct {
	TripResponses map[string]interface{}
}

func (f *fakeTransport) Tell(methodName string, reqs ...interface{}) (*dnode.Partial, error) {
	return nil, nil
}

func TestTransport(t *testing.T) {
	Convey("fakeTransport", t, func() {
		Convey("It should implement Transport", func() {
			var _ Transport = (*fakeTransport)(nil)
		})
	})
}
