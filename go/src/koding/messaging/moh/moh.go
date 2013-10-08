// Package moh provides mechanisms for messaging over HTTP connection.
// While Requester and Replier talk via HTTP synchronously,
// Subscriber and Publisher talk via Websocket protocol asynchronously.
package moh

type Handler func([]byte) []byte
