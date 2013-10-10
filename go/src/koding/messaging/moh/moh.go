// Package moh provides mechanisms for messaging over HTTP connection.
// While Requester and Replier talk via HTTP synchronously,
// Subscriber and Publisher talk via Websocket protocol asynchronously.
package moh

// MessageHandler is the type of the function that Replier and Subscriber
// use to process the messages they receive.
// It is very generic function as it takes []byte and return []byte
// so you have to do the work of encoding/decoding
// if you want to send and receive anything other than bytes.
type MessageHandler func([]byte) []byte
