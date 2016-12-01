package remoteapi

import (
	"net"
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
	//
	// If nil, http://127.0.0.1/remote.api is going to be used.
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
			Host:         c.Endpoint.Host,
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

	var endpoint *url.URL

	if c.Endpoint == nil {
		endpoint = &url.URL{
			Scheme: "http",
			Host:   "127.0.0.1",
			Path:   "/remote.api",
		}
	} else {
		// NOTE(rjeczalik): optimization - since kloud and remote.api are
		// accessible on local network, use 127.0.0.1 host instead.
		endpoint = copyURL(c.Endpoint)

		if _, port, err := net.SplitHostPort(endpoint.Host); err == nil {
			endpoint.Host = net.JoinHostPort("127.0.0.1", port)
		} else {
			endpoint.Host = "127.0.0.1"
		}

		// Requests will still have "Host: <original host>" header set,
		// just in case the e.g. the c.Endpoint is behind nginx that
		// is configured with host routing.
		httpClient.Transport.(*transport).Host = c.Endpoint.Host
	}

	return client.New(newRuntime(endpoint, httpClient), strfmt.Default)
}

func newRuntime(u *url.URL, c *http.Client) *runtime.Runtime {
	return runtime.NewWithClient(u.Host, u.Path, []string{u.Scheme}, c)
}
