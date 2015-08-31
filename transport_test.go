package main

import "testing"

type fakeTransport struct{}

func (f *fakeTransport) Trip(methodName string, req interface{}, resp interface{}) error {
	return nil
}

func TestTransportImplements(t *testing.T) {
	var (
		_ Transport = (*fakeTransport)(nil)
		_ Transport = (*KlientTransport)(nil)
	)
}
