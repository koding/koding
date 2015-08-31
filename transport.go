package main

import "github.com/koding/kite"

// Transport defines communication between this package and user VM.
type Transport interface {
	Trip(string, interface{}, interface{}) error
}

// KlientTransport is a Transport using Klient on user VM.
type KlientTransport struct {
	client *kite.Client
}

// Trip is a generic method for communication. It accepts `req` to pass args
// to Klient and `resp` to store unmarshalled response from Klient.
func (k *KlientTransport) Trip(methodName string, req interface{}, resp interface{}) error {
	return nil
}
