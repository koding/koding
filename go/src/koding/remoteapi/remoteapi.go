package remoteapi

import (
	"net/http"
	"net/url"

	"koding/remoteapi/client"

	runtime "github.com/go-openapi/runtime/client"
	"github.com/go-openapi/strfmt"
)

//go:generate swagger generate client -f ../../../../website/swagger.json

// Client is a REST client used to interact with remote.api.
//
// It creates new client object per client, so it requires
// authorisation (obtaining jSession.clientId) happens
// externally.
//
// TODO(rjeczalik): Add admin mode for remote.api for it's possible
// for kloud to use one persistant session to interact with
// remote.api on behalf of the users. See discussion #9667.
type Client struct {
	// Endpoint is URL of remote.api endpoint.
	// Required.
	Endpoint *url.URL

	// Client is an underlying HTTP client used for
	// communication with remote.api server.
	//
	// If nil, http.DefaultClient is used instead.
	Client *http.Client
}

func (c *Client) New(clientID string) *client.Koding {
	httpClient := &http.Client{
		Transport: &transport{
			RoundTripper: http.DefaultTransport,
			ClientID:     clientID,
		},
		Jar:     http.DefaultClient.Jar,
		Timeout: http.DefaultClient.Timeout,
	}

	if c.Client != nil {
		httpClient.Transport.(*transport).RoundTripper = c.Client.Transport
		httpClient.Jar = c.Client.Jar
		httpClient.Timeout = c.Client.Timeout
	}

	return client.New(newRuntime(c.Endpoint, httpClient), strfmt.Default)
}

func newRuntime(u *url.URL, c *http.Client) *runtime.Runtime {
	return runtime.NewWithClient(u.Host, u.Path, []string{u.Scheme}, c)
}

// transport is a signing transport that
// authorizes each request with jSession.clientId.
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
