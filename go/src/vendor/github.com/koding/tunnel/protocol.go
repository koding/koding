package tunnel

const (
	connected = "200 Connected to Tunnel"

	// control messages
	ctHandshakeRequest  = "controlHandshake"
	ctHandshakeResponse = "controlOk"

	// http.Handler path for control connection
	controlPath = "/_controlPath/"

	// Custom Tunnel specific header
	xKTunnelIdentifier = "X-KTunnel-Identifier"
)

type action int

const (
	requestClientSession action = iota + 1
)

type transportProtocol int

const (
	httpTransport transportProtocol = iota + 1
	tcpTransport
	wsTransport
)

type controlMsg struct {
	Action    action            `json:"action"`
	Protocol  transportProtocol `json:"transportProtocol"`
	LocalPort int               `json:"localPort"`
}
