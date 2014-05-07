package main

import (
	"errors"
	"fmt"
	"io/ioutil"
	"net"
	"net/http"
)

type localhost struct{}

func (l *localhost) LocalIP() (net.IP, error) {
	tt, err := net.Interfaces()
	if err != nil {
		return nil, err
	}

	for _, t := range tt {
		aa, err := t.Addrs()
		if err != nil {
			return nil, err
		}
		for _, a := range aa {
			ipnet, ok := a.(*net.IPNet)
			if !ok {
				continue
			}
			v4 := ipnet.IP.To4()

			if v4 == nil || v4[0] == 127 { // loopback address
				continue
			}
			return v4, nil
		}
	}

	return nil, errors.New("cannot find local IP address")
}

func (l *localhost) PublicIp() (net.IP, error) {
	resp, err := http.Get("http://echoip.com")
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
