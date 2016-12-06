package o_auth

// This file was generated by the swagger tool.
// Editing this file might prove futile when you re-run the swagger generate command

import (
	"github.com/go-openapi/runtime"

	strfmt "github.com/go-openapi/strfmt"
)

// New creates a new o auth API client.
func New(transport runtime.ClientTransport, formats strfmt.Registry) *Client {
	return &Client{transport: transport, formats: formats}
}

/*
Client for o auth API
*/
type Client struct {
	transport runtime.ClientTransport
	formats   strfmt.Registry
}

/*
PostRemoteAPIOAuthGetURL post remote API o auth get URL API
*/
func (a *Client) PostRemoteAPIOAuthGetURL(params *PostRemoteAPIOAuthGetURLParams) (*PostRemoteAPIOAuthGetURLOK, error) {
	// TODO: Validate the params before sending
	if params == nil {
		params = NewPostRemoteAPIOAuthGetURLParams()
	}

	result, err := a.transport.Submit(&runtime.ClientOperation{
		ID:                 "PostRemoteAPIOAuthGetURL",
		Method:             "POST",
		PathPattern:        "/remote.api/OAuth.getUrl",
		ProducesMediaTypes: []string{""},
		ConsumesMediaTypes: []string{"application/json"},
		Schemes:            []string{"http", "https"},
		Params:             params,
		Reader:             &PostRemoteAPIOAuthGetURLReader{formats: a.formats},
		Context:            params.Context,
	})
	if err != nil {
		return nil, err
	}
	return result.(*PostRemoteAPIOAuthGetURLOK), nil

}

// SetTransport changes the transport on the client
func (a *Client) SetTransport(transport runtime.ClientTransport) {
	a.transport = transport
}