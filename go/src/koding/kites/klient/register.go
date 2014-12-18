package main

import (
	"errors"
	"fmt"
	"io/ioutil"
	"net"
	"net/http"
	"net/url"
	"strconv"

	"github.com/koding/kite"
)

const publicEcho = "http://echoip.com"

func register(k *kite.Kite) error {
	ip, err := publicIP()
	if err != nil {
		return err
	}

	scheme := "http"
	if k.TLSConfig != nil {
		scheme = "https"
	}

	registerURL := &url.URL{
		Scheme: scheme,
		Host:   ip.String() + ":" + strconv.Itoa(k.Config.Port),
		Path:   "/kite",
	}

	if *flagRegisterURL != "" {
		u, err := url.Parse(*flagRegisterURL)
		if err != nil {
			k.Log.Fatal("Couldn't parse register url: %s", err)
		}

		registerURL = u
	}

	if registerURL == nil {
		errors.New("register url is nil")
	}

	k.Log.Info("Going to register over HTTP to kontrol with URL: %s", registerURL)
	return k.RegisterForever(registerURL)
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
