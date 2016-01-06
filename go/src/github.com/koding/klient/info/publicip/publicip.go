package publicip

import (
	"fmt"
	"io/ioutil"
	"net"
	"net/http"
)

// The site PublicIP() uses to get the public IP from.
const publicEcho string = "http://echoip.com"

// PublicIP returns an IP that is supposed to be Public.
func PublicIP() (net.IP, error) {
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
