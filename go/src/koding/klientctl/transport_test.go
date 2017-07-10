package main

import (
	"koding/klient/remote/req"

	"github.com/koding/kite/dnode"
)

// fakeTransport implements Transport interface and is to be used in tests.
type fakeTransport struct {
	TripResponses map[string]*dnode.Partial
	TripErrors    map[string]error
}

var _ Transport = (*fakeTransport)(nil)

func newFakeTransport() *fakeTransport {
	return &fakeTransport{
		TripResponses: map[string]*dnode.Partial{},
		TripErrors:    map[string]error{},
	}
}

func (f *fakeTransport) Tell(methodName string, reqs ...interface{}) (res *dnode.Partial, err error) {
	return f.TripResponses[methodName], f.TripErrors[methodName]
}

// fakeKlient implements the unnamed (SSHKey).Klient interface.
type fakeKlient struct {
	Transport

	RemoteUsername string
}

func (k *fakeKlient) RemoteCurrentUsername(req.CurrentUsernameOptions) (string, error) {
	return k.RemoteUsername, nil
}
