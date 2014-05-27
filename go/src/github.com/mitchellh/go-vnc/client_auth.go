package vnc

import (
	"net"
)

// A ClientAuth implements a method of authenticating with a remote server.
type ClientAuth interface {
	// SecurityType returns the byte identifier sent by the server to
	// identify this authentication scheme.
	SecurityType() uint8

	// Handshake is called when the authentication handshake should be
	// performed, as part of the general RFB handshake. (see 7.1.2)
	Handshake(net.Conn) error
}

// ClientAuthNone is the "none" authentication. See 7.1.2
type ClientAuthNone byte

func (*ClientAuthNone) SecurityType() uint8 {
	return 1
}

func (*ClientAuthNone) Handshake(net.Conn) error {
	return nil
}
