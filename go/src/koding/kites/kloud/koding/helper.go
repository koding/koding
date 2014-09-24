package koding

import (
	"koding/kites/kloud/klient"
	"time"
)

type infoFunc func(format string, formatArgs ...interface{})

// GetInfoLogger returns a customized logger with a another prefix. Usually for
// user based logging.
func (p *Provider) GetInfoLogger(prefix string) infoFunc {
	return func(format string, formatArgs ...interface{}) {
		format = "[%s] " + format
		args := []interface{}{prefix}
		args = append(args, formatArgs...)
		p.Log.Info(format, args...)
	}
}

// IsKiteReady returns true if Klient is ready and it can receive a ping.
func (p *Provider) IsKlientReady(querystring string) bool {
	klientRef, err := klient.NewWithTimeout(p.Kite, querystring, time.Minute*2)
	if err != nil {
		p.Log.Warning("Connecting to remote Klient instance err: %s", err)
		return false
	}

	defer klientRef.Close()
	p.Log.Debug("Sending a ping message")
	if err := klientRef.Ping(); err != nil {
		p.Log.Debug("Sending a ping message err:", err)
		return false
	}

	return true
}
