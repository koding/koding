package main

import (
	"testing"

	"github.com/koding/kite/dnode"
	. "github.com/smartystreets/goconvey/convey"
)

// fakeTransport implements Transport interface and is to be used in tests.
type fakeTransport struct {
	TripResponses map[string]*dnode.Partial
	TripErrors    map[string]error
}

func newFakeTransport() *fakeTransport {
	return &fakeTransport{
		TripResponses: map[string]*dnode.Partial{},
		TripErrors:    map[string]error{},
	}
}

func (f *fakeTransport) Tell(methodName string, reqs ...interface{}) (res *dnode.Partial, err error) {
	if f.TripErrors != nil {
		err, _ = f.TripErrors[methodName]
	}

	if f.TripResponses != nil {
		res, _ = f.TripResponses[methodName]
	}

	return res, err
}

func TestTransport(t *testing.T) {
	Convey("fakeTransport", t, func() {
		Convey("It should implement Transport", func() {
			var _ Transport = (*fakeTransport)(nil)
		})
	})
}
