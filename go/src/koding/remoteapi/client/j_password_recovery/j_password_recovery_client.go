package j_password_recovery

// This file was generated by the swagger tool.
// Editing this file might prove futile when you re-run the swagger generate command

import (
	"github.com/go-openapi/runtime"

	strfmt "github.com/go-openapi/strfmt"
)

// New creates a new j password recovery API client.
func New(transport runtime.ClientTransport, formats strfmt.Registry) *Client {
	return &Client{transport: transport, formats: formats}
}

/*
Client for j password recovery API
*/
type Client struct {
	transport runtime.ClientTransport
	formats   strfmt.Registry
}

/*
PostRemoteAPIJPasswordRecoveryFetchRegistrationDetails Method JPasswordRecovery.fetchRegistrationDetails
*/
func (a *Client) PostRemoteAPIJPasswordRecoveryFetchRegistrationDetails(params *PostRemoteAPIJPasswordRecoveryFetchRegistrationDetailsParams) (*PostRemoteAPIJPasswordRecoveryFetchRegistrationDetailsOK, error) {
	// TODO: Validate the params before sending
	if params == nil {
		params = NewPostRemoteAPIJPasswordRecoveryFetchRegistrationDetailsParams()
	}

	result, err := a.transport.Submit(&runtime.ClientOperation{
		ID:                 "PostRemoteAPIJPasswordRecoveryFetchRegistrationDetails",
		Method:             "POST",
		PathPattern:        "/remote.api/JPasswordRecovery.fetchRegistrationDetails",
		ProducesMediaTypes: []string{""},
		ConsumesMediaTypes: []string{"application/json"},
		Schemes:            []string{"http", "https"},
		Params:             params,
		Reader:             &PostRemoteAPIJPasswordRecoveryFetchRegistrationDetailsReader{formats: a.formats},
		Context:            params.Context,
	})
	if err != nil {
		return nil, err
	}
	return result.(*PostRemoteAPIJPasswordRecoveryFetchRegistrationDetailsOK), nil

}

/*
PostRemoteAPIJPasswordRecoveryRecoverPassword post remote API j password recovery recover password API
*/
func (a *Client) PostRemoteAPIJPasswordRecoveryRecoverPassword(params *PostRemoteAPIJPasswordRecoveryRecoverPasswordParams) (*PostRemoteAPIJPasswordRecoveryRecoverPasswordOK, error) {
	// TODO: Validate the params before sending
	if params == nil {
		params = NewPostRemoteAPIJPasswordRecoveryRecoverPasswordParams()
	}

	result, err := a.transport.Submit(&runtime.ClientOperation{
		ID:                 "PostRemoteAPIJPasswordRecoveryRecoverPassword",
		Method:             "POST",
		PathPattern:        "/remote.api/JPasswordRecovery.recoverPassword",
		ProducesMediaTypes: []string{""},
		ConsumesMediaTypes: []string{"application/json"},
		Schemes:            []string{"http", "https"},
		Params:             params,
		Reader:             &PostRemoteAPIJPasswordRecoveryRecoverPasswordReader{formats: a.formats},
		Context:            params.Context,
	})
	if err != nil {
		return nil, err
	}
	return result.(*PostRemoteAPIJPasswordRecoveryRecoverPasswordOK), nil

}

/*
PostRemoteAPIJPasswordRecoveryResendVerification post remote API j password recovery resend verification API
*/
func (a *Client) PostRemoteAPIJPasswordRecoveryResendVerification(params *PostRemoteAPIJPasswordRecoveryResendVerificationParams) (*PostRemoteAPIJPasswordRecoveryResendVerificationOK, error) {
	// TODO: Validate the params before sending
	if params == nil {
		params = NewPostRemoteAPIJPasswordRecoveryResendVerificationParams()
	}

	result, err := a.transport.Submit(&runtime.ClientOperation{
		ID:                 "PostRemoteAPIJPasswordRecoveryResendVerification",
		Method:             "POST",
		PathPattern:        "/remote.api/JPasswordRecovery.resendVerification",
		ProducesMediaTypes: []string{""},
		ConsumesMediaTypes: []string{"application/json"},
		Schemes:            []string{"http", "https"},
		Params:             params,
		Reader:             &PostRemoteAPIJPasswordRecoveryResendVerificationReader{formats: a.formats},
		Context:            params.Context,
	})
	if err != nil {
		return nil, err
	}
	return result.(*PostRemoteAPIJPasswordRecoveryResendVerificationOK), nil

}

/*
PostRemoteAPIJPasswordRecoveryResetPassword Method JPasswordRecovery.resetPassword
*/
func (a *Client) PostRemoteAPIJPasswordRecoveryResetPassword(params *PostRemoteAPIJPasswordRecoveryResetPasswordParams) (*PostRemoteAPIJPasswordRecoveryResetPasswordOK, error) {
	// TODO: Validate the params before sending
	if params == nil {
		params = NewPostRemoteAPIJPasswordRecoveryResetPasswordParams()
	}

	result, err := a.transport.Submit(&runtime.ClientOperation{
		ID:                 "PostRemoteAPIJPasswordRecoveryResetPassword",
		Method:             "POST",
		PathPattern:        "/remote.api/JPasswordRecovery.resetPassword",
		ProducesMediaTypes: []string{""},
		ConsumesMediaTypes: []string{"application/json"},
		Schemes:            []string{"http", "https"},
		Params:             params,
		Reader:             &PostRemoteAPIJPasswordRecoveryResetPasswordReader{formats: a.formats},
		Context:            params.Context,
	})
	if err != nil {
		return nil, err
	}
	return result.(*PostRemoteAPIJPasswordRecoveryResetPasswordOK), nil

}

/*
PostRemoteAPIJPasswordRecoveryValidate Method JPasswordRecovery.validate
*/
func (a *Client) PostRemoteAPIJPasswordRecoveryValidate(params *PostRemoteAPIJPasswordRecoveryValidateParams) (*PostRemoteAPIJPasswordRecoveryValidateOK, error) {
	// TODO: Validate the params before sending
	if params == nil {
		params = NewPostRemoteAPIJPasswordRecoveryValidateParams()
	}

	result, err := a.transport.Submit(&runtime.ClientOperation{
		ID:                 "PostRemoteAPIJPasswordRecoveryValidate",
		Method:             "POST",
		PathPattern:        "/remote.api/JPasswordRecovery.validate",
		ProducesMediaTypes: []string{""},
		ConsumesMediaTypes: []string{"application/json"},
		Schemes:            []string{"http", "https"},
		Params:             params,
		Reader:             &PostRemoteAPIJPasswordRecoveryValidateReader{formats: a.formats},
		Context:            params.Context,
	})
	if err != nil {
		return nil, err
	}
	return result.(*PostRemoteAPIJPasswordRecoveryValidateOK), nil

}

// SetTransport changes the transport on the client
func (a *Client) SetTransport(transport runtime.ClientTransport) {
	a.transport = transport
}
