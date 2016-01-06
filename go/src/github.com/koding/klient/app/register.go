package app

import (
	"errors"
	"net/url"
	"strconv"

	"github.com/koding/klient/info/publicip"
)

func (k *Klient) register() error {
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
