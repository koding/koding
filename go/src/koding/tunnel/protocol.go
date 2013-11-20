package tunnel

const ControlPath = "/_controlPath_/"
const TunnelPath = "/_tunnelPath_/"

var Connected = "200 Connected to KD Tunnel"

type ClientMsg struct {
	Action string `json:"action"`
}

type ServerMsg struct {
	Action string `json:"action"`
}
