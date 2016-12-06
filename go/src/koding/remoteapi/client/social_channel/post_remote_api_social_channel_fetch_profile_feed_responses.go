package social_channel

// This file was generated by the swagger tool.
// Editing this file might prove futile when you re-run the swagger generate command

import (
	"fmt"
	"io"

	"github.com/go-openapi/runtime"

	strfmt "github.com/go-openapi/strfmt"

	"koding/remoteapi/models"
)

// PostRemoteAPISocialChannelFetchProfileFeedReader is a Reader for the PostRemoteAPISocialChannelFetchProfileFeed structure.
type PostRemoteAPISocialChannelFetchProfileFeedReader struct {
	formats strfmt.Registry
}

// ReadResponse reads a server response into the received o.
func (o *PostRemoteAPISocialChannelFetchProfileFeedReader) ReadResponse(response runtime.ClientResponse, consumer runtime.Consumer) (interface{}, error) {
	switch response.Code() {

	case 200:
		result := NewPostRemoteAPISocialChannelFetchProfileFeedOK()
		if err := result.readResponse(response, consumer, o.formats); err != nil {
			return nil, err
		}
		return result, nil

	case 401:
		result := NewPostRemoteAPISocialChannelFetchProfileFeedUnauthorized()
		if err := result.readResponse(response, consumer, o.formats); err != nil {
			return nil, err
		}
		return nil, result

	default:
		return nil, runtime.NewAPIError("unknown error", response, response.Code())
	}
}

// NewPostRemoteAPISocialChannelFetchProfileFeedOK creates a PostRemoteAPISocialChannelFetchProfileFeedOK with default headers values
func NewPostRemoteAPISocialChannelFetchProfileFeedOK() *PostRemoteAPISocialChannelFetchProfileFeedOK {
	return &PostRemoteAPISocialChannelFetchProfileFeedOK{}
}

/*PostRemoteAPISocialChannelFetchProfileFeedOK handles this case with default header values.

Request processed succesfully
*/
type PostRemoteAPISocialChannelFetchProfileFeedOK struct {
	Payload *models.DefaultResponse
}

func (o *PostRemoteAPISocialChannelFetchProfileFeedOK) Error() string {
	return fmt.Sprintf("[POST /remote.api/SocialChannel.fetchProfileFeed][%d] postRemoteApiSocialChannelFetchProfileFeedOK  %+v", 200, o.Payload)
}

func (o *PostRemoteAPISocialChannelFetchProfileFeedOK) readResponse(response runtime.ClientResponse, consumer runtime.Consumer, formats strfmt.Registry) error {

	o.Payload = new(models.DefaultResponse)

	// response payload
	if err := consumer.Consume(response.Body(), o.Payload); err != nil && err != io.EOF {
		return err
	}

	return nil
}

// NewPostRemoteAPISocialChannelFetchProfileFeedUnauthorized creates a PostRemoteAPISocialChannelFetchProfileFeedUnauthorized with default headers values
func NewPostRemoteAPISocialChannelFetchProfileFeedUnauthorized() *PostRemoteAPISocialChannelFetchProfileFeedUnauthorized {
	return &PostRemoteAPISocialChannelFetchProfileFeedUnauthorized{}
}

/*PostRemoteAPISocialChannelFetchProfileFeedUnauthorized handles this case with default header values.

Unauthorized request
*/
type PostRemoteAPISocialChannelFetchProfileFeedUnauthorized struct {
	Payload *models.UnauthorizedRequest
}

func (o *PostRemoteAPISocialChannelFetchProfileFeedUnauthorized) Error() string {
	return fmt.Sprintf("[POST /remote.api/SocialChannel.fetchProfileFeed][%d] postRemoteApiSocialChannelFetchProfileFeedUnauthorized  %+v", 401, o.Payload)
}

func (o *PostRemoteAPISocialChannelFetchProfileFeedUnauthorized) readResponse(response runtime.ClientResponse, consumer runtime.Consumer, formats strfmt.Registry) error {

	o.Payload = new(models.UnauthorizedRequest)

	// response payload
	if err := consumer.Consume(response.Body(), o.Payload); err != nil && err != io.EOF {
		return err
	}

	return nil
}