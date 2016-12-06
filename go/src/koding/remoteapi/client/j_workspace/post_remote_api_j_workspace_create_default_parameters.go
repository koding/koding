package j_workspace

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

// NewPostRemoteAPIJWorkspaceCreateDefaultParams creates a new PostRemoteAPIJWorkspaceCreateDefaultParams object
// with the default values initialized.
func NewPostRemoteAPIJWorkspaceCreateDefaultParams() *PostRemoteAPIJWorkspaceCreateDefaultParams {
	var ()
	return &PostRemoteAPIJWorkspaceCreateDefaultParams{

		timeout: cr.DefaultTimeout,
	}
}

// NewPostRemoteAPIJWorkspaceCreateDefaultParamsWithTimeout creates a new PostRemoteAPIJWorkspaceCreateDefaultParams object
// with the default values initialized, and the ability to set a timeout on a request
func NewPostRemoteAPIJWorkspaceCreateDefaultParamsWithTimeout(timeout time.Duration) *PostRemoteAPIJWorkspaceCreateDefaultParams {
	var ()
	return &PostRemoteAPIJWorkspaceCreateDefaultParams{

		timeout: timeout,
	}
}

// NewPostRemoteAPIJWorkspaceCreateDefaultParamsWithContext creates a new PostRemoteAPIJWorkspaceCreateDefaultParams object
// with the default values initialized, and the ability to set a context for a request
func NewPostRemoteAPIJWorkspaceCreateDefaultParamsWithContext(ctx context.Context) *PostRemoteAPIJWorkspaceCreateDefaultParams {
	var ()
	return &PostRemoteAPIJWorkspaceCreateDefaultParams{

		Context: ctx,
	}
}

/*PostRemoteAPIJWorkspaceCreateDefaultParams contains all the parameters to send to the API endpoint
for the post remote API j workspace create default operation typically these are written to a http.Request
*/
type PostRemoteAPIJWorkspaceCreateDefaultParams struct {

	/*Body
	  body of the request

	*/
	Body *models.DefaultSelector

	timeout time.Duration
	Context context.Context
}

// WithTimeout adds the timeout to the post remote API j workspace create default params
func (o *PostRemoteAPIJWorkspaceCreateDefaultParams) WithTimeout(timeout time.Duration) *PostRemoteAPIJWorkspaceCreateDefaultParams {
	o.SetTimeout(timeout)
	return o
}

// SetTimeout adds the timeout to the post remote API j workspace create default params
func (o *PostRemoteAPIJWorkspaceCreateDefaultParams) SetTimeout(timeout time.Duration) {
	o.timeout = timeout
}

// WithContext adds the context to the post remote API j workspace create default params
func (o *PostRemoteAPIJWorkspaceCreateDefaultParams) WithContext(ctx context.Context) *PostRemoteAPIJWorkspaceCreateDefaultParams {
	o.SetContext(ctx)
	return o
}

// SetContext adds the context to the post remote API j workspace create default params
func (o *PostRemoteAPIJWorkspaceCreateDefaultParams) SetContext(ctx context.Context) {
	o.Context = ctx
}

// WithBody adds the body to the post remote API j workspace create default params
func (o *PostRemoteAPIJWorkspaceCreateDefaultParams) WithBody(body *models.DefaultSelector) *PostRemoteAPIJWorkspaceCreateDefaultParams {
	o.SetBody(body)
	return o
}

// SetBody adds the body to the post remote API j workspace create default params
func (o *PostRemoteAPIJWorkspaceCreateDefaultParams) SetBody(body *models.DefaultSelector) {
	o.Body = body
}

// WriteToRequest writes these params to a swagger request
func (o *PostRemoteAPIJWorkspaceCreateDefaultParams) WriteToRequest(r runtime.ClientRequest, reg strfmt.Registry) error {

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