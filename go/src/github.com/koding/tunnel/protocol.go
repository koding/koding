package tunnel

var Connected = "200 Connected to Tunnel"

const (
	// control messages
	ctHandshakeRequest  = "controlHandshake"
	ctHandshakeResponse = "controlOk"

	ControlPath = "/_controlPath/"

	// Custom Tunnel specific header
	XKTunnelIdentifier = "X-KTunnel-Identifier"
)

type Action int

const (
	RequestClientSession Action = iota + 1
)

type TransportProtocol int

const (
	HTTPTransport TransportProtocol = iota + 1
)

type ControlMsg struct {
	Action    Action            `json:"action"`
	Protocol  TransportProtocol `json:"transportProtocol"`
	LocalPort string            `json:"localPort"`
}
