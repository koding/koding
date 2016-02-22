package broker

import "errors"

var (
	ErrProducerNotInitialized   = errors.New("producer is not initialized")
	ErrSubscriberNotInitialized = errors.New("subscriber is not initialized")
	ErrNoHandlerFound           = errors.New("no handler is found")
)
