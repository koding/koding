package main

import "testing"

func TestGuessTunnelServerAddr(t *testing.T) {
	cases := []struct {
		username    string
		tunnelURL   string
		registerURL string
		want        string
	}{{ // i=0
		"rafal",
		"",
		"http://example1.rafal.tunnel.dev.koding.io:8081/klient/kite",
		"tunnel.dev.koding.io:8081",
	}}
	for i, cas := range cases {
		got := guessTunnelServerAddr(cas.username, cas.tunnelURL, cas.registerURL)
		if got != cas.want {
			t.Errorf("%d: wanted %q, got %q", i, cas.want, got)
		}
	}
}
