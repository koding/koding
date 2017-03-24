package config

import (
	"koding/httputil"

	"github.com/koding/kite/config"
)

// Disabling compression due to errors like:
//
//   readloop err: websocket: close 1002 (protocol error): unexpected reserved bits 0x40
//

func init() {
	// sockjs.WebSocketUpgrader.EnableCompression = true
}

// ReadKiteConfig reads new kite config by reading kite
// key from /etc/kite/kite.key and environment variables.
//
// It sets up also server and client connections for
// use with koding kites.
func ReadKiteConfig(debug bool) (*config.Config, error) {
	cfg, err := config.Get()
	if err != nil {
		return nil, err
	}

	// cfg.Websocket.EnableCompression = true
	cfg.Client = httputil.Client(debug)
	cfg.XHR = httputil.ClientXHR(debug)
	cfg.Transport = config.XHRPolling

	return cfg, nil
}

// NewKiteConfig gives new default kite config, setting up
// server and client connections for use with koding kites.
func NewKiteConfig(debug bool) *config.Config {
	cfg := config.New()

	// cfg.Websocket.EnableCompression = true
	cfg.Client = httputil.Client(debug)
	cfg.XHR = httputil.ClientXHR(debug)
	cfg.Transport = config.XHRPolling

	return cfg
}
