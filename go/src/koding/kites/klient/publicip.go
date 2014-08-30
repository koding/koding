package main

import (
	"fmt"
	"io/ioutil"
	"net"
	"net/http"
	"net/url"
	"strconv"

	"github.com/koding/kite"
)

const publicEcho = "http://echoip.com"

func getRegisterURL(k *kite.Kite) (*url.URL, error) {
	ip, err := publicIP()
	if err != nil {
		return nil, err
	}

	scheme := "http"
	if k.TLSConfig != nil {
		scheme = "https"
	}

	return &url.URL{
		Scheme: scheme,
		Host:   ip.String() + ":" + strconv.Itoa(k.Config.Port),
		Path:   "/kite",
	}, nil
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
