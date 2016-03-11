package app

import (
	"errors"
	"net/url"
	"strconv"
	"time"

	"koding/kites/common"
	"koding/kites/tunnelproxy"
)

func (k *Klient) register(addr string, useTunnel bool) error {
	scheme := "http"
	if k.kite.TLSConfig != nil {
		scheme = "https"
	}

	registerURL := &url.URL{
		Scheme: scheme,
		Host:   addr,
		Path:   "/kite",
	}

	if useTunnel {
		host, err := k.setupTunnel()
		if err != nil {
			k.log.Error("Couldn't setup tunnel connection: %s", err)
		} else {
			registerURL.Host = host
			registerURL.Path = "/klient/kite"
			k.log.Info("Tunnel address: %s", host)
		}
	} else if k.config.RegisterURL != "" {
		u, err := url.Parse(k.config.RegisterURL)
		if err != nil {
			k.log.Fatal("Couldn't parse register url: %s", err)
		}

		registerURL = u
	}

	if registerURL == nil {
		return errors.New("register url is nil")
	}

	// replace kontrolURL if's being overidden
	if k.config.KontrolURL != "" {
		k.kite.Config.KontrolURL = k.config.KontrolURL
	}

	k.log.Info("Register to kontrol '%s' via the URL value: '%s'",
		k.kite.Config.KontrolURL, registerURL)

	k.kite.RegisterHTTPForever(registerURL)
	return nil
}

func (k *Klient) setupTunnel() (string, error) {
	opts := &tunnelproxy.ClientOptions{
		TunnelName:    k.config.TunnelName,
		TunnelKiteURL: k.config.TunnelKiteURL,
		Debug:         k.config.Debug,
		Config:        k.kite.Config,
		Log:           common.NewLogger("tunnelclient", k.config.Debug),
		Timeout:       5 * time.Minute,
	}

	if k.config.Port != 0 {
		opts.LocalAddr = "127.0.0.1:" + strconv.Itoa(k.config.Port)
	}

	return k.tunnelclient.Start(opts)
}
