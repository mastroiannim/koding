package social_channel

// This file was generated by the swagger tool.
// Editing this file might prove futile when you re-run the swagger generate command

import (
	"net/http"
	"time"

	"golang.org/x/net/context"

	"github.com/go-openapi/errors"
	"github.com/go-openapi/runtime"
	cr "github.com/go-openapi/runtime/client"

	strfmt "github.com/go-openapi/strfmt"

	"koding/remoteapi/models"
)

// NewSocialChannelFetchChannelsParams creates a new SocialChannelFetchChannelsParams object
// with the default values initialized.
func NewSocialChannelFetchChannelsParams() *SocialChannelFetchChannelsParams {
	var ()
	return &SocialChannelFetchChannelsParams{

		timeout: cr.DefaultTimeout,
	}
}

// NewSocialChannelFetchChannelsParamsWithTimeout creates a new SocialChannelFetchChannelsParams object
// with the default values initialized, and the ability to set a timeout on a request
func NewSocialChannelFetchChannelsParamsWithTimeout(timeout time.Duration) *SocialChannelFetchChannelsParams {
	var ()
	return &SocialChannelFetchChannelsParams{

		timeout: timeout,
	}
}

// NewSocialChannelFetchChannelsParamsWithContext creates a new SocialChannelFetchChannelsParams object
// with the default values initialized, and the ability to set a context for a request
func NewSocialChannelFetchChannelsParamsWithContext(ctx context.Context) *SocialChannelFetchChannelsParams {
	var ()
	return &SocialChannelFetchChannelsParams{

		Context: ctx,
	}
}

/*SocialChannelFetchChannelsParams contains all the parameters to send to the API endpoint
for the social channel fetch channels operation typically these are written to a http.Request
*/
type SocialChannelFetchChannelsParams struct {

	/*Body
	  body of the request

	*/
	Body models.DefaultSelector

	timeout    time.Duration
	Context    context.Context
	HTTPClient *http.Client
}

// WithTimeout adds the timeout to the social channel fetch channels params
func (o *SocialChannelFetchChannelsParams) WithTimeout(timeout time.Duration) *SocialChannelFetchChannelsParams {
	o.SetTimeout(timeout)
	return o
}

// SetTimeout adds the timeout to the social channel fetch channels params
func (o *SocialChannelFetchChannelsParams) SetTimeout(timeout time.Duration) {
	o.timeout = timeout
}

// WithContext adds the context to the social channel fetch channels params
func (o *SocialChannelFetchChannelsParams) WithContext(ctx context.Context) *SocialChannelFetchChannelsParams {
	o.SetContext(ctx)
	return o
}

// SetContext adds the context to the social channel fetch channels params
func (o *SocialChannelFetchChannelsParams) SetContext(ctx context.Context) {
	o.Context = ctx
}

// WithBody adds the body to the social channel fetch channels params
func (o *SocialChannelFetchChannelsParams) WithBody(body models.DefaultSelector) *SocialChannelFetchChannelsParams {
	o.SetBody(body)
	return o
}

// SetBody adds the body to the social channel fetch channels params
func (o *SocialChannelFetchChannelsParams) SetBody(body models.DefaultSelector) {
	o.Body = body
}

// WriteToRequest writes these params to a swagger request
func (o *SocialChannelFetchChannelsParams) WriteToRequest(r runtime.ClientRequest, reg strfmt.Registry) error {

	r.SetTimeout(o.timeout)
	var res []error

	if err := r.SetBodyParam(o.Body); err != nil {
		return err
	}

	if len(res) > 0 {
		return errors.CompositeValidationError(res...)
	}
	return nil
}
