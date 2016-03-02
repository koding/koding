package userdata

type Value struct {
	Username string
	Hostname string
	Groups   []string
	SSHKeys  []string
	KiteKey  string

	// URL of the latest version of the Klient package.
	LatestKlientURL string

	// Register URL of the klient
	RegisterURL string

	// Kontrol URL of the klient to be registered.
	KontrolURL string

	// TunnelName - name of the registered tunnel.
	TunnelName string

	// TunnelKiteURL address of the tunnel server kite to register.
	TunnelKiteURL string
}
