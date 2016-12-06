package j_invitation

// This file was generated by the swagger tool.
// Editing this file might prove futile when you re-run the swagger generate command

import (
	"time"

	"golang.org/x/net/context"

	"github.com/go-openapi/errors"
	"github.com/go-openapi/runtime"
	cr "github.com/go-openapi/runtime/client"

	strfmt "github.com/go-openapi/strfmt"

	"koding/remoteapi/models"
)

// NewPostRemoteAPIJInvitationByCodeParams creates a new PostRemoteAPIJInvitationByCodeParams object
// with the default values initialized.
func NewPostRemoteAPIJInvitationByCodeParams() *PostRemoteAPIJInvitationByCodeParams {
	var ()
	return &PostRemoteAPIJInvitationByCodeParams{

		timeout: cr.DefaultTimeout,
	}
}

// NewPostRemoteAPIJInvitationByCodeParamsWithTimeout creates a new PostRemoteAPIJInvitationByCodeParams object
// with the default values initialized, and the ability to set a timeout on a request
func NewPostRemoteAPIJInvitationByCodeParamsWithTimeout(timeout time.Duration) *PostRemoteAPIJInvitationByCodeParams {
	var ()
	return &PostRemoteAPIJInvitationByCodeParams{

		timeout: timeout,
	}
}

// NewPostRemoteAPIJInvitationByCodeParamsWithContext creates a new PostRemoteAPIJInvitationByCodeParams object
// with the default values initialized, and the ability to set a context for a request
func NewPostRemoteAPIJInvitationByCodeParamsWithContext(ctx context.Context) *PostRemoteAPIJInvitationByCodeParams {
	var ()
	return &PostRemoteAPIJInvitationByCodeParams{

		Context: ctx,
	}
}

/*PostRemoteAPIJInvitationByCodeParams contains all the parameters to send to the API endpoint
for the post remote API j invitation by code operation typically these are written to a http.Request
*/
type PostRemoteAPIJInvitationByCodeParams struct {

	/*Body
	  body of the request

	*/
	Body *models.DefaultSelector

	timeout time.Duration
	Context context.Context
}

// WithTimeout adds the timeout to the post remote API j invitation by code params
func (o *PostRemoteAPIJInvitationByCodeParams) WithTimeout(timeout time.Duration) *PostRemoteAPIJInvitationByCodeParams {
	o.SetTimeout(timeout)
	return o
}

// SetTimeout adds the timeout to the post remote API j invitation by code params
func (o *PostRemoteAPIJInvitationByCodeParams) SetTimeout(timeout time.Duration) {
	o.timeout = timeout
}

// WithContext adds the context to the post remote API j invitation by code params
func (o *PostRemoteAPIJInvitationByCodeParams) WithContext(ctx context.Context) *PostRemoteAPIJInvitationByCodeParams {
	o.SetContext(ctx)
	return o
}

// SetContext adds the context to the post remote API j invitation by code params
func (o *PostRemoteAPIJInvitationByCodeParams) SetContext(ctx context.Context) {
	o.Context = ctx
}

// WithBody adds the body to the post remote API j invitation by code params
func (o *PostRemoteAPIJInvitationByCodeParams) WithBody(body *models.DefaultSelector) *PostRemoteAPIJInvitationByCodeParams {
	o.SetBody(body)
	return o
}

// SetBody adds the body to the post remote API j invitation by code params
func (o *PostRemoteAPIJInvitationByCodeParams) SetBody(body *models.DefaultSelector) {
	o.Body = body
}

// WriteToRequest writes these params to a swagger request
func (o *PostRemoteAPIJInvitationByCodeParams) WriteToRequest(r runtime.ClientRequest, reg strfmt.Registry) error {

	r.SetTimeout(o.timeout)
	var res []error

	if o.Body == nil {
		o.Body = new(models.DefaultSelector)
	}

	if err := r.SetBodyParam(o.Body); err != nil {
		return err
	}

	if len(res) > 0 {
		return errors.CompositeValidationError(res...)
	}
	return nil
}