package j_location

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

// NewPostRemoteAPIJLocationOneParams creates a new PostRemoteAPIJLocationOneParams object
// with the default values initialized.
func NewPostRemoteAPIJLocationOneParams() *PostRemoteAPIJLocationOneParams {
	var ()
	return &PostRemoteAPIJLocationOneParams{

		timeout: cr.DefaultTimeout,
	}
}

// NewPostRemoteAPIJLocationOneParamsWithTimeout creates a new PostRemoteAPIJLocationOneParams object
// with the default values initialized, and the ability to set a timeout on a request
func NewPostRemoteAPIJLocationOneParamsWithTimeout(timeout time.Duration) *PostRemoteAPIJLocationOneParams {
	var ()
	return &PostRemoteAPIJLocationOneParams{

		timeout: timeout,
	}
}

// NewPostRemoteAPIJLocationOneParamsWithContext creates a new PostRemoteAPIJLocationOneParams object
// with the default values initialized, and the ability to set a context for a request
func NewPostRemoteAPIJLocationOneParamsWithContext(ctx context.Context) *PostRemoteAPIJLocationOneParams {
	var ()
	return &PostRemoteAPIJLocationOneParams{

		Context: ctx,
	}
}

/*PostRemoteAPIJLocationOneParams contains all the parameters to send to the API endpoint
for the post remote API j location one operation typically these are written to a http.Request
*/
type PostRemoteAPIJLocationOneParams struct {

	/*Body
	  body of the request

	*/
	Body *models.DefaultSelector

	timeout time.Duration
	Context context.Context
}

// WithTimeout adds the timeout to the post remote API j location one params
func (o *PostRemoteAPIJLocationOneParams) WithTimeout(timeout time.Duration) *PostRemoteAPIJLocationOneParams {
	o.SetTimeout(timeout)
	return o
}

// SetTimeout adds the timeout to the post remote API j location one params
func (o *PostRemoteAPIJLocationOneParams) SetTimeout(timeout time.Duration) {
	o.timeout = timeout
}

// WithContext adds the context to the post remote API j location one params
func (o *PostRemoteAPIJLocationOneParams) WithContext(ctx context.Context) *PostRemoteAPIJLocationOneParams {
	o.SetContext(ctx)
	return o
}

// SetContext adds the context to the post remote API j location one params
func (o *PostRemoteAPIJLocationOneParams) SetContext(ctx context.Context) {
	o.Context = ctx
}

// WithBody adds the body to the post remote API j location one params
func (o *PostRemoteAPIJLocationOneParams) WithBody(body *models.DefaultSelector) *PostRemoteAPIJLocationOneParams {
	o.SetBody(body)
	return o
}

// SetBody adds the body to the post remote API j location one params
func (o *PostRemoteAPIJLocationOneParams) SetBody(body *models.DefaultSelector) {
	o.Body = body
}

// WriteToRequest writes these params to a swagger request
func (o *PostRemoteAPIJLocationOneParams) WriteToRequest(r runtime.ClientRequest, reg strfmt.Registry) error {

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