package j_reward_campaign

// This file was generated by the swagger tool.
// Editing this file might prove futile when you re-run the swagger generate command

import (
	"github.com/go-openapi/runtime"

	strfmt "github.com/go-openapi/strfmt"
)

// New creates a new j reward campaign API client.
func New(transport runtime.ClientTransport, formats strfmt.Registry) *Client {
	return &Client{transport: transport, formats: formats}
}

/*
Client for j reward campaign API
*/
type Client struct {
	transport runtime.ClientTransport
	formats   strfmt.Registry
}

/*
PostRemoteAPIJRewardCampaignCreate post remote API j reward campaign create API
*/
func (a *Client) PostRemoteAPIJRewardCampaignCreate(params *PostRemoteAPIJRewardCampaignCreateParams) (*PostRemoteAPIJRewardCampaignCreateOK, error) {
	// TODO: Validate the params before sending
	if params == nil {
		params = NewPostRemoteAPIJRewardCampaignCreateParams()
	}

	result, err := a.transport.Submit(&runtime.ClientOperation{
		ID:                 "PostRemoteAPIJRewardCampaignCreate",
		Method:             "POST",
		PathPattern:        "/remote.api/JRewardCampaign.create",
		ProducesMediaTypes: []string{""},
		ConsumesMediaTypes: []string{"application/json"},
		Schemes:            []string{"http", "https"},
		Params:             params,
		Reader:             &PostRemoteAPIJRewardCampaignCreateReader{formats: a.formats},
		Context:            params.Context,
	})
	if err != nil {
		return nil, err
	}
	return result.(*PostRemoteAPIJRewardCampaignCreateOK), nil

}

/*
PostRemoteAPIJRewardCampaignIsValid post remote API j reward campaign is valid API
*/
func (a *Client) PostRemoteAPIJRewardCampaignIsValid(params *PostRemoteAPIJRewardCampaignIsValidParams) (*PostRemoteAPIJRewardCampaignIsValidOK, error) {
	// TODO: Validate the params before sending
	if params == nil {
		params = NewPostRemoteAPIJRewardCampaignIsValidParams()
	}

	result, err := a.transport.Submit(&runtime.ClientOperation{
		ID:                 "PostRemoteAPIJRewardCampaignIsValid",
		Method:             "POST",
		PathPattern:        "/remote.api/JRewardCampaign.isValid",
		ProducesMediaTypes: []string{""},
		ConsumesMediaTypes: []string{"application/json"},
		Schemes:            []string{"http", "https"},
		Params:             params,
		Reader:             &PostRemoteAPIJRewardCampaignIsValidReader{formats: a.formats},
		Context:            params.Context,
	})
	if err != nil {
		return nil, err
	}
	return result.(*PostRemoteAPIJRewardCampaignIsValidOK), nil

}

/*
PostRemoteAPIJRewardCampaignOne post remote API j reward campaign one API
*/
func (a *Client) PostRemoteAPIJRewardCampaignOne(params *PostRemoteAPIJRewardCampaignOneParams) (*PostRemoteAPIJRewardCampaignOneOK, error) {
	// TODO: Validate the params before sending
	if params == nil {
		params = NewPostRemoteAPIJRewardCampaignOneParams()
	}

	result, err := a.transport.Submit(&runtime.ClientOperation{
		ID:                 "PostRemoteAPIJRewardCampaignOne",
		Method:             "POST",
		PathPattern:        "/remote.api/JRewardCampaign.one",
		ProducesMediaTypes: []string{""},
		ConsumesMediaTypes: []string{"application/json"},
		Schemes:            []string{"http", "https"},
		Params:             params,
		Reader:             &PostRemoteAPIJRewardCampaignOneReader{formats: a.formats},
		Context:            params.Context,
	})
	if err != nil {
		return nil, err
	}
	return result.(*PostRemoteAPIJRewardCampaignOneOK), nil

}

/*
PostRemoteAPIJRewardCampaignRemoveID post remote API j reward campaign remove ID API
*/
func (a *Client) PostRemoteAPIJRewardCampaignRemoveID(params *PostRemoteAPIJRewardCampaignRemoveIDParams) (*PostRemoteAPIJRewardCampaignRemoveIDOK, error) {
	// TODO: Validate the params before sending
	if params == nil {
		params = NewPostRemoteAPIJRewardCampaignRemoveIDParams()
	}

	result, err := a.transport.Submit(&runtime.ClientOperation{
		ID:                 "PostRemoteAPIJRewardCampaignRemoveID",
		Method:             "POST",
		PathPattern:        "/remote.api/JRewardCampaign.remove/{id}",
		ProducesMediaTypes: []string{""},
		ConsumesMediaTypes: []string{"application/json"},
		Schemes:            []string{"http", "https"},
		Params:             params,
		Reader:             &PostRemoteAPIJRewardCampaignRemoveIDReader{formats: a.formats},
		Context:            params.Context,
	})
	if err != nil {
		return nil, err
	}
	return result.(*PostRemoteAPIJRewardCampaignRemoveIDOK), nil

}

/*
PostRemoteAPIJRewardCampaignSome post remote API j reward campaign some API
*/
func (a *Client) PostRemoteAPIJRewardCampaignSome(params *PostRemoteAPIJRewardCampaignSomeParams) (*PostRemoteAPIJRewardCampaignSomeOK, error) {
	// TODO: Validate the params before sending
	if params == nil {
		params = NewPostRemoteAPIJRewardCampaignSomeParams()
	}

	result, err := a.transport.Submit(&runtime.ClientOperation{
		ID:                 "PostRemoteAPIJRewardCampaignSome",
		Method:             "POST",
		PathPattern:        "/remote.api/JRewardCampaign.some",
		ProducesMediaTypes: []string{""},
		ConsumesMediaTypes: []string{"application/json"},
		Schemes:            []string{"http", "https"},
		Params:             params,
		Reader:             &PostRemoteAPIJRewardCampaignSomeReader{formats: a.formats},
		Context:            params.Context,
	})
	if err != nil {
		return nil, err
	}
	return result.(*PostRemoteAPIJRewardCampaignSomeOK), nil

}

/*
PostRemoteAPIJRewardCampaignUpdateID post remote API j reward campaign update ID API
*/
func (a *Client) PostRemoteAPIJRewardCampaignUpdateID(params *PostRemoteAPIJRewardCampaignUpdateIDParams) (*PostRemoteAPIJRewardCampaignUpdateIDOK, error) {
	// TODO: Validate the params before sending
	if params == nil {
		params = NewPostRemoteAPIJRewardCampaignUpdateIDParams()
	}

	result, err := a.transport.Submit(&runtime.ClientOperation{
		ID:                 "PostRemoteAPIJRewardCampaignUpdateID",
		Method:             "POST",
		PathPattern:        "/remote.api/JRewardCampaign.update/{id}",
		ProducesMediaTypes: []string{""},
		ConsumesMediaTypes: []string{"application/json"},
		Schemes:            []string{"http", "https"},
		Params:             params,
		Reader:             &PostRemoteAPIJRewardCampaignUpdateIDReader{formats: a.formats},
		Context:            params.Context,
	})
	if err != nil {
		return nil, err
	}
	return result.(*PostRemoteAPIJRewardCampaignUpdateIDOK), nil

}

// SetTransport changes the transport on the client
func (a *Client) SetTransport(transport runtime.ClientTransport) {
	a.transport = transport
}