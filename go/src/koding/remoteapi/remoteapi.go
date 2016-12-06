package remoteapi

import (
	"net/http"
	"net/url"

	"koding/api"
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

	// Transport is a caching transport that authorizes each
	// request with clientID.
	Transport *api.Transport
}

func (c *Client) New(session *api.Session) *client.Koding {
	httpClient := &http.Client{
		Transport: c.Transport.NewSingleClient(session),
		Jar:       http.DefaultClient.Jar,
		Timeout:   http.DefaultClient.Timeout,
	}

	if c.Client != nil {
		httpClient.Jar = c.Client.Jar
		httpClient.Timeout = c.Client.Timeout
	}

	return client.New(newRuntime(c.endpoint(), httpClient), strfmt.Default)
}

func (c *Client) endpoint() *url.URL {
	if c.Endpoint != nil {
		return c.Endpoint
	}
	return &url.URL{
		Scheme: "http",
		Host:   "127.0.0.1",
		Path:   "/remote.api",
	}
}

func newRuntime(u *url.URL, c *http.Client) *runtime.Runtime {
	return runtime.NewWithClient(u.Host, u.Path, []string{u.Scheme}, c)
}
