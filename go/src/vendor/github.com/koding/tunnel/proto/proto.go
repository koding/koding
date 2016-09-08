// Package proto defines tunnel client server communication protocol.
package proto

const (
	// ControlPath is http.Handler url path for control connection.
	ControlPath = "/_controlPath/"

	// ClientIdentifierHeader is header carrying information about tunnel identifier.
	ClientIdentifierHeader = "X-KTunnel-Identifier"

	// control messages

	// Connected is message sent by server to client when control connection was established.
	Connected = "200 Connected to Tunnel"
	// HandshakeRequest is hello message sent by client to server.
	HandshakeRequest = "controlHandshake"
	// HandshakeResponse is response to HandshakeRequest sent by server to client.
	HandshakeResponse = "controlOk"
)
