package compute_provider

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

// NewPostRemoteAPIComputeProviderFetchUsageParams creates a new PostRemoteAPIComputeProviderFetchUsageParams object
// with the default values initialized.
func NewPostRemoteAPIComputeProviderFetchUsageParams() *PostRemoteAPIComputeProviderFetchUsageParams {
	var ()
	return &PostRemoteAPIComputeProviderFetchUsageParams{

		timeout: cr.DefaultTimeout,
	}
}

// NewPostRemoteAPIComputeProviderFetchUsageParamsWithTimeout creates a new PostRemoteAPIComputeProviderFetchUsageParams object
// with the default values initialized, and the ability to set a timeout on a request
func NewPostRemoteAPIComputeProviderFetchUsageParamsWithTimeout(timeout time.Duration) *PostRemoteAPIComputeProviderFetchUsageParams {
	var ()
	return &PostRemoteAPIComputeProviderFetchUsageParams{

		timeout: timeout,
	}
}

// NewPostRemoteAPIComputeProviderFetchUsageParamsWithContext creates a new PostRemoteAPIComputeProviderFetchUsageParams object
// with the default values initialized, and the ability to set a context for a request
func NewPostRemoteAPIComputeProviderFetchUsageParamsWithContext(ctx context.Context) *PostRemoteAPIComputeProviderFetchUsageParams {
	var ()
	return &PostRemoteAPIComputeProviderFetchUsageParams{

		Context: ctx,
	}
}

/*PostRemoteAPIComputeProviderFetchUsageParams contains all the parameters to send to the API endpoint
for the post remote API compute provider fetch usage operation typically these are written to a http.Request
*/
type PostRemoteAPIComputeProviderFetchUsageParams struct {

	/*Body
	  body of the request

	*/
	Body *models.DefaultSelector

	timeout time.Duration
	Context context.Context
}

// WithTimeout adds the timeout to the post remote API compute provider fetch usage params
func (o *PostRemoteAPIComputeProviderFetchUsageParams) WithTimeout(timeout time.Duration) *PostRemoteAPIComputeProviderFetchUsageParams {
	o.SetTimeout(timeout)
	return o
}

// SetTimeout adds the timeout to the post remote API compute provider fetch usage params
func (o *PostRemoteAPIComputeProviderFetchUsageParams) SetTimeout(timeout time.Duration) {
	o.timeout = timeout
}

// WithContext adds the context to the post remote API compute provider fetch usage params
func (o *PostRemoteAPIComputeProviderFetchUsageParams) WithContext(ctx context.Context) *PostRemoteAPIComputeProviderFetchUsageParams {
	o.SetContext(ctx)
	return o
}

// SetContext adds the context to the post remote API compute provider fetch usage params
func (o *PostRemoteAPIComputeProviderFetchUsageParams) SetContext(ctx context.Context) {
	o.Context = ctx
}

// WithBody adds the body to the post remote API compute provider fetch usage params
func (o *PostRemoteAPIComputeProviderFetchUsageParams) WithBody(body *models.DefaultSelector) *PostRemoteAPIComputeProviderFetchUsageParams {
	o.SetBody(body)
	return o
}

// SetBody adds the body to the post remote API compute provider fetch usage params
func (o *PostRemoteAPIComputeProviderFetchUsageParams) SetBody(body *models.DefaultSelector) {
	o.Body = body
}

// WriteToRequest writes these params to a swagger request
func (o *PostRemoteAPIComputeProviderFetchUsageParams) WriteToRequest(r runtime.ClientRequest, reg strfmt.Registry) error {

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
