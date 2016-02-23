package publicip

import (
	"bytes"
	"errors"
	"fmt"
	"io/ioutil"
	"net"
	"net/http"
	"time"

	"github.com/koding/kite"
)

// The sites that PublicIP() uses to get the public IP from.
//
// Note that the site must return *only* the IP characters.
var echoSites = []string{
	// In the future, maybe koding.com/-/echoip first?
	"http://echoip.com",
	"http://api.ipify.org",
	"http://ipinfo.io/ip",
}

var defaultClient = &http.Client{
	Timeout: 5 * time.Second,
}

// PublicIP returns an IP that is supposed to be Public.
func PublicIP() (net.IP, error) {
	return publicIP(echoSites[0])
}

// publicIP requests a URL and returns a netIP for the response.
func publicIP(host string) (net.IP, error) {
	resp, err := defaultClient.Get(host)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	out, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	n := net.ParseIP(string(bytes.TrimSpace(out)))
	if n == nil {
		return nil, fmt.Errorf("cannot parse ip %s", string(out))
	}

	return n, nil
}

// PublicIPRetry fetches the public IP, retrying as many times as requested.
// An *optional* logger is provided, to log retry progress.
func PublicIPRetry(maxRetries int, retryPause time.Duration, log kite.Logger) (net.IP, error) {
	return publicIPRetry(echoSites, maxRetries, retryPause, log)
}

func publicIPRetry(hosts []string, maxRetries int, retryPause time.Duration, log kite.Logger) (net.IP, error) {
	if maxRetries <= 0 {
		return nil, errors.New("PublicIPRetry: maxRetries must be larger than 0")
	}

	var (
		ip  net.IP
		err error
	)

	for i := 0; i < maxRetries; i++ {
		host := hosts[i%len(hosts)]
		ip, err = publicIP(host)

		// If there's no error, we successfully got the IP.
		if err == nil {
			return ip, nil
		}

		if log != nil {
			log.Warning(
				"Retrying fetch of PublicIP due to error. delay:%s, err:%s",
				retryPause, err,
			)
		}

		if retryPause > 0 {
			// Pause before retrying.
			time.Sleep(retryPause)
		}
	}

	return nil, err
}
