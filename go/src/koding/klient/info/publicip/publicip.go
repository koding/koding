package publicip

import (
	"bytes"
	"errors"
	"fmt"
	"io/ioutil"
	"net"
	"net/http"
	"net/url"
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
	"http://ifconfig.co",
}

var testSites = []string{
	// Definitely in future - koding.com/-/testip
	"http://rjk.io/test",
	"http://ifconfig.co/test",
}

var defaultClient = &http.Client{
	Transport: &http.Transport{
		Proxy: http.ProxyFromEnvironment,
		ResponseHeaderTimeout: 15 * time.Second,
		Dial: (&net.Dialer{
			Timeout: 5 * time.Second,
		}).Dial,
		TLSHandshakeTimeout: 5 * time.Second,
	},
	Timeout: 15 * time.Second,
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

func isReachable(addr, service string) (bool, error) {
	resp, err := defaultClient.Get(service + "/" + url.QueryEscape(addr))
	if err != nil {
		return false, err
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusGone {
		return false, nil
	}

	if resp.StatusCode/100 == 2 {
		return true, nil
	}

	return false, fmt.Errorf("error status: %s (%d)", resp.Status, resp.StatusCode)
}

type testServer struct {
	serving  chan struct{}
	closed   chan struct{}
	listener net.Listener
}

func newTestServer(addr string) (*testServer, error) {
	l, err := net.Listen("tcp", addr)
	if err != nil {
		return nil, err
	}

	t := &testServer{
		serving:  make(chan struct{}),
		closed:   make(chan struct{}),
		listener: l,
	}

	go t.serve()
	<-t.serving

	return t, nil
}

func (t *testServer) handler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(204)
}

func (t *testServer) serve() {
	close(t.serving)
	defer close(t.closed)

	http.Serve(t.listener, http.HandlerFunc(t.handler))
}

func (t *testServer) Close() error {
	t.listener.Close()
	<-t.closed
	return nil
}

// IsReachableRetry test whether the given address is reachable from the internet or not.
//
// When a public IP address is behind NAT it's often not reachable from the
// outside.
//
// When it returns non-nil error, the test has failed and we're unable
// to say the ip is reachable or not.
func IsReachableRetry(addr string, maxRetries int, retryPause time.Duration, log kite.Logger) (bool, error) {
	if maxRetries <= 0 {
		return false, errors.New("IsReachableRetry: retry number must be larger than 0")
	}

	_, port, err := net.SplitHostPort(addr)
	if err != nil {
		return false, err
	}

	t, err := newTestServer(net.JoinHostPort("0.0.0.0", port))
	if err != nil {
		return false, err
	}
	defer t.Close()

	var ok bool
	for i := 0; i < maxRetries; i++ {
		service := testSites[i%len(testSites)]

		ok, err = isReachable(addr, service)
		if err == nil {
			return ok, nil
		}

		if log != nil {
			log.Warning("retrying test of %q address reachability; delay=%s, err=%s", addr, retryPause, err)
		}

		if retryPause > 0 {
			time.Sleep(retryPause)
		}
	}

	return false, err
}
