package streamtunnel

const (
	// control messages
	ctHandshakeRequest  = "controlHandshake"
	ctHandshakeResponse = "controlOk"

	TunnelPath = "/_tunnelPath_/"

	// Custom Tunnel specific header
	XKTunnelIdentifier = "X-KTunnel-Identifier"
)

var Connected = "200 Connected to Tunnel"

type ClientMsg struct {
	Action string `json:"action"`
}

type ServerMsg struct {
	Protocol   string `json:"action"`
	TunnelID   string `json:"tunnelID"`
	Identifier string `json:"idenfitifer"`
	Host       string `json:"host"`
}
