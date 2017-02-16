package publicip

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"net"
	"net/http"
	"time"

	"koding/httputil"
	konfig "koding/klient/config"
)

// StatusError describes a HTTP response error.
type StatusError struct {
	StatusCode int
}

// Error implements the built-in error interface.
func (e *StatusError) Error() string {
	return http.StatusText(e.StatusCode)
}

// PublicIP returns an IP that is supposed to be public.
func PublicIP() (net.IP, error) {
	return DefaultClient.PublicIP()
}

// IsReachable returns nil error when the given addr
// is reachable from the internet.
func IsReachable(addr string) error {
	return DefaultClient.IsReachable(addr)
}

var fallback director

// DefaultClient defines default behavior for IP fetching and testing.
var DefaultClient = &Client{
	Client: httputil.NewClient(&httputil.ClientConfig{
		DialTimeout:           10 * time.Second,
		RoundTripTimeout:      10 * time.Second,
		TLSHandshakeTimeout:   10 * time.Second,
		ResponseHeaderTimeout: 10 * time.Second,
	}),
	MaxRetries:          3,
	Backoff:             fallback.Backoff,
	ShouldRetry:         fallback.ShouldRetry,
	EndpointPublicIP:    fallback.EndpointPublicIP,
	EndpointIsReachable: fallback.EndpointIsReachable,
}

type director struct {
	fallback bool
}

func (d *director) Backoff(int) time.Duration {
	return 100 * time.Millisecond
}

func (d *director) EndpointPublicIP() string {
	if d.fallback {
		return "http://echoip.net"
	}

	return konfig.Konfig.Endpoints.IP.Public.String()
}

func (d *director) EndpointIsReachable(port string) string {
	return konfig.Konfig.Endpoints.IPCheck.Public.String() + "/" + port
}

func (d *director) ShouldRetry(err error) bool {
	switch e := err.(type) {
	case net.Error:
		return e.Temporary() || e.Timeout()
	case *StatusError:
		// 504 Gateway Timeout it returned by nginx when client's
		// IP address is not reachable.
		switch e.StatusCode {
		case http.StatusNotFound:
			d.fallback = true // TODO(rjeczalik): remove after nginx changes are deployed to prod

			return true
		case http.StatusRequestTimeout, http.StatusInternalServerError:
			return true
		}
	}

	return false
}

// Client is used to fetch public IP of the host or test whether the IP
// is reachable from the internet.
type Client struct {
	Client     *http.Client // HTTP client to use
	MaxRetries int          // retry failed requests

	Backoff             func(retry int) time.Duration // cool down between retries
	EndpointPublicIP    func() (url string)
	EndpointIsReachable func(port string) (url string)
	ShouldRetry         func(error) bool
}

// PublicIP returns an IP that is supposed to be public.
func (c *Client) PublicIP() (ip net.IP, err error) {
	for i := 0; i < c.MaxRetries; i++ {
		if ip, err = c.publicIP(); err == nil {
			return ip, nil
		}

		if !c.ShouldRetry(err) {
			return nil, err
		}

		time.Sleep(c.Backoff(i))
	}

	return nil, err
}

func (c *Client) publicIP() (net.IP, error) {
	resp, err := c.Client.Get(c.EndpointPublicIP())
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if err := checkStatusError(resp); err != nil {
		return nil, err
	}

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

// IsReachableRetry test whether the given address is reachable from the internet or not.
//
// When a public IP address is behind NAT it's often not reachable from the
// outside.
//
// When it returns non-nil error, the the addr is not reachable from the internet.
func (c *Client) IsReachable(addr string) error {
	ip, port, err := net.SplitHostPort(addr)
	if err != nil {
		return err
	}

	t, err := newTestServer(net.JoinHostPort("0.0.0.0", port))
	if err != nil {
		return err
	}
	defer t.Close()

	for i := 0; i < c.MaxRetries; i++ {
		if err = c.isReachable(ip, port); err == nil {
			return nil
		}

		if !c.ShouldRetry(err) {
			return err
		}

		time.Sleep(c.Backoff(i))
	}

	return err
}

func (c *Client) isReachable(ip, port string) error {
	req, err := http.NewRequest("GET", c.EndpointIsReachable(port), nil)
	if err != nil {
		return err
	}

	req.Header.Set("X-Real-IP", ip)
	resp, err := c.Client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	// addr is reachable when it replied with 2xx HTTP status code
	if err := checkStatusError(resp); err != nil {
		return err
	}

	return nil
}

func checkStatusError(resp *http.Response) error {
	switch resp.StatusCode {
	case http.StatusOK, http.StatusNoContent:
		return nil
	default:
		return &StatusError{
			StatusCode: resp.StatusCode,
		}
	}
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

	// TODO(rjeczalik): move discovertest.Listener to some common place
	// and use it here instead.
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
