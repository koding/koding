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

// NewPostRemoteAPIJMachineSetLabelIDParams creates a new PostRemoteAPIJMachineSetLabelIDParams object
// with the default values initialized.
func NewPostRemoteAPIJMachineSetLabelIDParams() *PostRemoteAPIJMachineSetLabelIDParams {
	var ()
	return &PostRemoteAPIJMachineSetLabelIDParams{

		timeout: cr.DefaultTimeout,
	}
}

// NewPostRemoteAPIJMachineSetLabelIDParamsWithTimeout creates a new PostRemoteAPIJMachineSetLabelIDParams object
// with the default values initialized, and the ability to set a timeout on a request
func NewPostRemoteAPIJMachineSetLabelIDParamsWithTimeout(timeout time.Duration) *PostRemoteAPIJMachineSetLabelIDParams {
	var ()
	return &PostRemoteAPIJMachineSetLabelIDParams{

		timeout: timeout,
	}
}

// NewPostRemoteAPIJMachineSetLabelIDParamsWithContext creates a new PostRemoteAPIJMachineSetLabelIDParams object
// with the default values initialized, and the ability to set a context for a request
func NewPostRemoteAPIJMachineSetLabelIDParamsWithContext(ctx context.Context) *PostRemoteAPIJMachineSetLabelIDParams {
	var ()
	return &PostRemoteAPIJMachineSetLabelIDParams{

		Context: ctx,
	}
}

/*PostRemoteAPIJMachineSetLabelIDParams contains all the parameters to send to the API endpoint
for the post remote API j machine set label ID operation typically these are written to a http.Request
*/
type PostRemoteAPIJMachineSetLabelIDParams struct {

	/*ID
	  Mongo ID of target instance

	*/
	ID string

	timeout time.Duration
	Context context.Context
}

// WithTimeout adds the timeout to the post remote API j machine set label ID params
func (o *PostRemoteAPIJMachineSetLabelIDParams) WithTimeout(timeout time.Duration) *PostRemoteAPIJMachineSetLabelIDParams {
	o.SetTimeout(timeout)
	return o
}

// SetTimeout adds the timeout to the post remote API j machine set label ID params
func (o *PostRemoteAPIJMachineSetLabelIDParams) SetTimeout(timeout time.Duration) {
	o.timeout = timeout
}

// WithContext adds the context to the post remote API j machine set label ID params
func (o *PostRemoteAPIJMachineSetLabelIDParams) WithContext(ctx context.Context) *PostRemoteAPIJMachineSetLabelIDParams {
	o.SetContext(ctx)
	return o
}

// SetContext adds the context to the post remote API j machine set label ID params
func (o *PostRemoteAPIJMachineSetLabelIDParams) SetContext(ctx context.Context) {
	o.Context = ctx
}

// WithID adds the id to the post remote API j machine set label ID params
func (o *PostRemoteAPIJMachineSetLabelIDParams) WithID(id string) *PostRemoteAPIJMachineSetLabelIDParams {
	o.SetID(id)
	return o
}

// SetID adds the id to the post remote API j machine set label ID params
func (o *PostRemoteAPIJMachineSetLabelIDParams) SetID(id string) {
	o.ID = id
}

// WriteToRequest writes these params to a swagger request
func (o *PostRemoteAPIJMachineSetLabelIDParams) WriteToRequest(r runtime.ClientRequest, reg strfmt.Registry) error {

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