package app

import (
	"errors"
	"net/url"
	"strconv"

	"koding/kites/tunnelproxy"
	"koding/klient/info/publicip"
)

func (k *Klient) register(useTunnel bool) error {
	ip, err := publicip.PublicIP()
	if err != nil {
		return err
	}

	scheme := "http"
	if k.kite.TLSConfig != nil {
		scheme = "https"
	}

	registerURL := &url.URL{
		Scheme: scheme,
		Host:   ip.String() + ":" + strconv.Itoa(k.config.Port),
		Path:   "/kite",
	}

	if k.config.RegisterURL != "" {
		u, err := url.Parse(k.config.RegisterURL)
		if err != nil {
			k.log.Fatal("Couldn't parse register url: %s", err)
		}

		registerURL = u
	} else if useTunnel {
		host, err := k.setupTunnel()
		if err != nil {
			k.log.Error("Couldn't setup tunnel connection: %s", err)
		} else {
			registerURL.Host = host
		}
	}

	if registerURL == nil {
		errors.New("register url is nil")
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
		ServerAddr: k.config.TunnelServerAddr,
		LocalAddr:  k.config.TunnelLocalAddr,
		Debug:      k.config.Debug,
		Config:     k.kite.Config,
		NoTLS:      k.kite.TLSConfig == nil,
	}

	if opts.LocalAddr == "" && k.config.Port != 0 {
		opts.LocalAddr = "127.0.0.1:" + strconv.Itoa(k.config.Port)
	}

	return k.tunnelclient.Start(opts)
}
