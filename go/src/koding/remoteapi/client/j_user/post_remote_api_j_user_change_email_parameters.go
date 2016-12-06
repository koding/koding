package j_user

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

// NewPostRemoteAPIJUserChangeEmailParams creates a new PostRemoteAPIJUserChangeEmailParams object
// with the default values initialized.
func NewPostRemoteAPIJUserChangeEmailParams() *PostRemoteAPIJUserChangeEmailParams {
	var ()
	return &PostRemoteAPIJUserChangeEmailParams{

		timeout: cr.DefaultTimeout,
	}
}

// NewPostRemoteAPIJUserChangeEmailParamsWithTimeout creates a new PostRemoteAPIJUserChangeEmailParams object
// with the default values initialized, and the ability to set a timeout on a request
func NewPostRemoteAPIJUserChangeEmailParamsWithTimeout(timeout time.Duration) *PostRemoteAPIJUserChangeEmailParams {
	var ()
	return &PostRemoteAPIJUserChangeEmailParams{

		timeout: timeout,
	}
}

// NewPostRemoteAPIJUserChangeEmailParamsWithContext creates a new PostRemoteAPIJUserChangeEmailParams object
// with the default values initialized, and the ability to set a context for a request
func NewPostRemoteAPIJUserChangeEmailParamsWithContext(ctx context.Context) *PostRemoteAPIJUserChangeEmailParams {
	var ()
	return &PostRemoteAPIJUserChangeEmailParams{

		Context: ctx,
	}
}

/*PostRemoteAPIJUserChangeEmailParams contains all the parameters to send to the API endpoint
for the post remote API j user change email operation typically these are written to a http.Request
*/
type PostRemoteAPIJUserChangeEmailParams struct {

	/*Body
	  body of the request

	*/
	Body *models.DefaultSelector

	timeout time.Duration
	Context context.Context
}

// WithTimeout adds the timeout to the post remote API j user change email params
func (o *PostRemoteAPIJUserChangeEmailParams) WithTimeout(timeout time.Duration) *PostRemoteAPIJUserChangeEmailParams {
	o.SetTimeout(timeout)
	return o
}

// SetTimeout adds the timeout to the post remote API j user change email params
func (o *PostRemoteAPIJUserChangeEmailParams) SetTimeout(timeout time.Duration) {
	o.timeout = timeout
}

// WithContext adds the context to the post remote API j user change email params
func (o *PostRemoteAPIJUserChangeEmailParams) WithContext(ctx context.Context) *PostRemoteAPIJUserChangeEmailParams {
	o.SetContext(ctx)
	return o
}

// SetContext adds the context to the post remote API j user change email params
func (o *PostRemoteAPIJUserChangeEmailParams) SetContext(ctx context.Context) {
	o.Context = ctx
}

// WithBody adds the body to the post remote API j user change email params
func (o *PostRemoteAPIJUserChangeEmailParams) WithBody(body *models.DefaultSelector) *PostRemoteAPIJUserChangeEmailParams {
	o.SetBody(body)
	return o
}

// SetBody adds the body to the post remote API j user change email params
func (o *PostRemoteAPIJUserChangeEmailParams) SetBody(body *models.DefaultSelector) {
	o.Body = body
}

// WriteToRequest writes these params to a swagger request
func (o *PostRemoteAPIJUserChangeEmailParams) WriteToRequest(r runtime.ClientRequest, reg strfmt.Registry) error {

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