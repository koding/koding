package j_machine

// This file was generated by the swagger tool.
// Editing this file might prove futile when you re-run the swagger generate command

import (
	"time"

	"golang.org/x/net/context"

	"github.com/go-openapi/errors"
	"github.com/go-openapi/runtime"
	cr "github.com/go-openapi/runtime/client"

	strfmt "github.com/go-openapi/strfmt"
)

// NewPostRemoteAPIJMachineApproveIDParams creates a new PostRemoteAPIJMachineApproveIDParams object
// with the default values initialized.
func NewPostRemoteAPIJMachineApproveIDParams() *PostRemoteAPIJMachineApproveIDParams {
	var ()
	return &PostRemoteAPIJMachineApproveIDParams{

		timeout: cr.DefaultTimeout,
	}
}

// NewPostRemoteAPIJMachineApproveIDParamsWithTimeout creates a new PostRemoteAPIJMachineApproveIDParams object
// with the default values initialized, and the ability to set a timeout on a request
func NewPostRemoteAPIJMachineApproveIDParamsWithTimeout(timeout time.Duration) *PostRemoteAPIJMachineApproveIDParams {
	var ()
	return &PostRemoteAPIJMachineApproveIDParams{

		timeout: timeout,
	}
}

// NewPostRemoteAPIJMachineApproveIDParamsWithContext creates a new PostRemoteAPIJMachineApproveIDParams object
// with the default values initialized, and the ability to set a context for a request
func NewPostRemoteAPIJMachineApproveIDParamsWithContext(ctx context.Context) *PostRemoteAPIJMachineApproveIDParams {
	var ()
	return &PostRemoteAPIJMachineApproveIDParams{

		Context: ctx,
	}
}

/*PostRemoteAPIJMachineApproveIDParams contains all the parameters to send to the API endpoint
for the post remote API j machine approve ID operation typically these are written to a http.Request
*/
type PostRemoteAPIJMachineApproveIDParams struct {

	/*ID
	  Mongo ID of target instance

	*/
	ID string

	timeout time.Duration
	Context context.Context
}

// WithTimeout adds the timeout to the post remote API j machine approve ID params
func (o *PostRemoteAPIJMachineApproveIDParams) WithTimeout(timeout time.Duration) *PostRemoteAPIJMachineApproveIDParams {
	o.SetTimeout(timeout)
	return o
}

// SetTimeout adds the timeout to the post remote API j machine approve ID params
func (o *PostRemoteAPIJMachineApproveIDParams) SetTimeout(timeout time.Duration) {
	o.timeout = timeout
}

// WithContext adds the context to the post remote API j machine approve ID params
func (o *PostRemoteAPIJMachineApproveIDParams) WithContext(ctx context.Context) *PostRemoteAPIJMachineApproveIDParams {
	o.SetContext(ctx)
	return o
}

// SetContext adds the context to the post remote API j machine approve ID params
func (o *PostRemoteAPIJMachineApproveIDParams) SetContext(ctx context.Context) {
	o.Context = ctx
}

// WithID adds the id to the post remote API j machine approve ID params
func (o *PostRemoteAPIJMachineApproveIDParams) WithID(id string) *PostRemoteAPIJMachineApproveIDParams {
	o.SetID(id)
	return o
}

// SetID adds the id to the post remote API j machine approve ID params
func (o *PostRemoteAPIJMachineApproveIDParams) SetID(id string) {
	o.ID = id
}

// WriteToRequest writes these params to a swagger request
func (o *PostRemoteAPIJMachineApproveIDParams) WriteToRequest(r runtime.ClientRequest, reg strfmt.Registry) error {

	r.SetTimeout(o.timeout)
	var res []error

	// path param id
	if err := r.SetPathParam("id", o.ID); err != nil {
		return err
	}

	if len(res) > 0 {
		return errors.CompositeValidationError(res...)
	}
	return nil
}