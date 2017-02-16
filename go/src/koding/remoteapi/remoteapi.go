package remoteapi

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"time"

	"koding/api"
	"koding/remoteapi/client"
	"koding/remoteapi/models"

	runtime "github.com/go-openapi/runtime/client"
	"github.com/go-openapi/strfmt"
	"github.com/koding/kite"
)

// Unmarshal unmarshals resp.Data into v.
//
// If resp.Error is non-nil, non-nil error is returned instead.
func Unmarshal(resp *models.DefaultResponse, v interface{}) error {
	if resp.Error != nil {
		if err, ok := resp.Error.(map[string]interface{}); ok {
			msg, _ := err["message"].(string)
			typ, _ := err["name"].(string)

			if msg != "" && typ != "" {
				return &kite.Error{
					Type:    typ,
					Message: msg,
				}
			}
		}

		return fmt.Errorf("%v", resp.Error)
	}

	if v == nil {
		return nil
	}

	p, err := jsonMarshal(resp.Data)
	if err != nil {
		return err
	}

	return json.Unmarshal(p, v)
}

//go:generate swagger generate client -f ../../../../website/swagger.json

// Client is a REST client used to interact with remote.api.
//
// It creates new client object per client, so it requires
// authorisation (obtaining jSession.clientId) happens
// externally.
//
// TODO(rjeczalik): Add admin mode for remote.api for it's possible
// for kloud to use one persistent session to interact with
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

func (c *Client) New(user *api.User) *client.Koding {
	httpClient := &http.Client{
		Transport: c.Transport.NewSingleUser(user),
		Jar:       http.DefaultClient.Jar,
		Timeout:   http.DefaultClient.Timeout,
	}

	if c.Client != nil {
		httpClient.Jar = c.Client.Jar
		httpClient.Timeout = c.Client.Timeout
	}

	return client.New(newRuntime(c.endpoint(), httpClient), strfmt.Default)
}

func (c *Client) Timeout() time.Duration {
	if c.Client != nil && c.Client.Timeout != 0 {
		return c.Client.Timeout
	}
	return 30 * time.Second
}

func (c *Client) endpoint() *url.URL {
	if c.Endpoint != nil {
		return c.Endpoint
	}
	return &url.URL{
		Scheme: "http",
		Host:   "127.0.0.1",
		Path:   "/",
	}
}

func newRuntime(u *url.URL, c *http.Client) *runtime.Runtime {
	return runtime.NewWithClient(u.Host, u.Path, []string{u.Scheme}, c)
}

func jsonMarshal(v interface{}) ([]byte, error) {
	var buf bytes.Buffer

	enc := json.NewEncoder(&buf)
	enc.SetEscapeHTML(false)

	if err := enc.Encode(v); err != nil {
		return nil, err
	}

	return buf.Bytes(), nil
}
