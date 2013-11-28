package tunnel

const ControlPath = "/_controlPath_/"
const TunnelPath = "/_tunnelPath_/"

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
