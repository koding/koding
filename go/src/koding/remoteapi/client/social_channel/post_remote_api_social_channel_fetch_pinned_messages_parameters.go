package social_channel

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

// NewPostRemoteAPISocialChannelFetchPinnedMessagesParams creates a new PostRemoteAPISocialChannelFetchPinnedMessagesParams object
// with the default values initialized.
func NewPostRemoteAPISocialChannelFetchPinnedMessagesParams() *PostRemoteAPISocialChannelFetchPinnedMessagesParams {
	var ()
	return &PostRemoteAPISocialChannelFetchPinnedMessagesParams{

		timeout: cr.DefaultTimeout,
	}
}

// NewPostRemoteAPISocialChannelFetchPinnedMessagesParamsWithTimeout creates a new PostRemoteAPISocialChannelFetchPinnedMessagesParams object
// with the default values initialized, and the ability to set a timeout on a request
func NewPostRemoteAPISocialChannelFetchPinnedMessagesParamsWithTimeout(timeout time.Duration) *PostRemoteAPISocialChannelFetchPinnedMessagesParams {
	var ()
	return &PostRemoteAPISocialChannelFetchPinnedMessagesParams{

		timeout: timeout,
	}
}

// NewPostRemoteAPISocialChannelFetchPinnedMessagesParamsWithContext creates a new PostRemoteAPISocialChannelFetchPinnedMessagesParams object
// with the default values initialized, and the ability to set a context for a request
func NewPostRemoteAPISocialChannelFetchPinnedMessagesParamsWithContext(ctx context.Context) *PostRemoteAPISocialChannelFetchPinnedMessagesParams {
	var ()
	return &PostRemoteAPISocialChannelFetchPinnedMessagesParams{

		Context: ctx,
	}
}

/*PostRemoteAPISocialChannelFetchPinnedMessagesParams contains all the parameters to send to the API endpoint
for the post remote API social channel fetch pinned messages operation typically these are written to a http.Request
*/
type PostRemoteAPISocialChannelFetchPinnedMessagesParams struct {

	/*Body
	  body of the request

	*/
	Body *models.DefaultSelector

	timeout time.Duration
	Context context.Context
}

// WithTimeout adds the timeout to the post remote API social channel fetch pinned messages params
func (o *PostRemoteAPISocialChannelFetchPinnedMessagesParams) WithTimeout(timeout time.Duration) *PostRemoteAPISocialChannelFetchPinnedMessagesParams {
	o.SetTimeout(timeout)
	return o
}

// SetTimeout adds the timeout to the post remote API social channel fetch pinned messages params
func (o *PostRemoteAPISocialChannelFetchPinnedMessagesParams) SetTimeout(timeout time.Duration) {
	o.timeout = timeout
}

// WithContext adds the context to the post remote API social channel fetch pinned messages params
func (o *PostRemoteAPISocialChannelFetchPinnedMessagesParams) WithContext(ctx context.Context) *PostRemoteAPISocialChannelFetchPinnedMessagesParams {
	o.SetContext(ctx)
	return o
}

// SetContext adds the context to the post remote API social channel fetch pinned messages params
func (o *PostRemoteAPISocialChannelFetchPinnedMessagesParams) SetContext(ctx context.Context) {
	o.Context = ctx
}

// WithBody adds the body to the post remote API social channel fetch pinned messages params
func (o *PostRemoteAPISocialChannelFetchPinnedMessagesParams) WithBody(body *models.DefaultSelector) *PostRemoteAPISocialChannelFetchPinnedMessagesParams {
	o.SetBody(body)
	return o
}

// SetBody adds the body to the post remote API social channel fetch pinned messages params
func (o *PostRemoteAPISocialChannelFetchPinnedMessagesParams) SetBody(body *models.DefaultSelector) {
	o.Body = body
}

// WriteToRequest writes these params to a swagger request
func (o *PostRemoteAPISocialChannelFetchPinnedMessagesParams) WriteToRequest(r runtime.ClientRequest, reg strfmt.Registry) error {

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
