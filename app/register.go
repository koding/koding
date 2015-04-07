package app

import (
	"errors"
	"fmt"
	"io/ioutil"
	"net"
	"net/http"
	"net/url"
	"strconv"
)

const publicEcho = "http://echoip.com"

func (k *Klient) register() error {
	ip, err := publicIP()
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

	k.log.Info("Register to kontrol '%s' via the URL value: '%s'", k.kite.Config.KontrolURL, registerURL)
	k.kite.RegisterHTTPForever(registerURL)
	return nil
}

// publicIP returns an IP that is supposed to be Public.
func publicIP() (net.IP, error) {
	resp, err := http.Get(publicEcho)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	out, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	n := net.ParseIP(string(out))
	if n == nil {
		return nil, fmt.Errorf("cannot parse ip %s", string(out))
	}

	return n, nil
}
