package utils

import (
	"net"
	"strings"
	"time"
)

// Given a string of the form "host", "host:port", or "[ipv6::address]:port",
// return true if the string includes a port.
func HasPort(s string) bool { return strings.LastIndex(s, ":") > strings.LastIndex(s, "]") }

// Given a string of the form "host", "port", returns "host:port"
func AddPort(host, port string) string {
	if ok := HasPort(host); ok {
		return host
	}

	return host + ":" + port
}

// Check if a server is alive or not
func CheckServer(host string) error {
	c, err := net.DialTimeout("tcp", host, time.Second*10)
	if err != nil {
		return err
	}
	c.Close()
	return nil
}

func CheckScheme(url string) string {
	if !strings.HasPrefix(url, "http://") && !strings.HasPrefix(url, "https://") {
		url = "http://" + url
	}
	return url
}
