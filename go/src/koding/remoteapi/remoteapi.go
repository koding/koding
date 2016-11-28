package remoteapi

import (
	"net/http"
	"net/url"

	"koding/remoteapi/client"

	runtime "github.com/go-openapi/runtime/client"
	"github.com/go-openapi/strfmt"
)

//go:generate swagger generate client -f ../../../../website/swagger.json

type Client struct {
	Endpoint *url.URL
	Client   *http.Client
}

func (c *Client) New(clientID string) *client.Koding {
	httpClient := &http.Client{
		Transport: &transport{
			RoundTripper: c.Client.Transport,
			ClientID:     clientID,
		},
		Jar:     c.Client.Jar,
		Timeout: c.Client.Timeout,
	}

	return client.New(newRuntime(c.Endpoint, httpClient), strfmt.Default)
}

func newRuntime(u *url.URL, c *http.Client) *runtime.Runtime {
	return runtime.NewWithClient(u.Host, u.Path, []string{u.Scheme}, c)
}

type transport struct {
	http.RoundTripper
	ClientID string
}

type httpTransport interface {
	http.RoundTripper
	httpRequestCanceler
	httpIdleConnectionsCloser
}

type httpRequestCanceler interface {
	CancelRequest(*http.Request)
}

type httpIdleConnectionsCloser interface {
	CloseIdleConnections()
}

var _ httpTransport = (*transport)(nil)

func (t *transport) RoundTrip(req *http.Request) (*http.Response, error) {
	reqCopy := copyRequest(req) // per RoundTripper contract
	reqCopy.Header.Set("Authorization", "Bearer "+t.ClientID)
	return t.RoundTripper.RoundTrip(reqCopy)
}

func (t *transport) CancelRequest(req *http.Request) {
	if rc, ok := t.RoundTripper.(httpRequestCanceler); ok {
		rc.CancelRequest(req)
	}
}

func (t *transport) CloseIdleConnections() {
	if icl, ok := t.RoundTripper.(httpIdleConnectionsCloser); ok {
		icl.CloseIdleConnections()
	}
}

func copyRequest(req *http.Request) *http.Request {
	req2 := new(http.Request)
	*req2 = *req
	req2.URL = new(url.URL)
	*req2.URL = *req.URL
	req2.Header = make(http.Header, len(req.Header))
	for k, s := range req.Header {
		req2.Header[k] = append([]string(nil), s...)
	}
	return req2
}
