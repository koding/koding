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

// PostRemoteAPISocialChannelFetchParticipantsReader is a Reader for the PostRemoteAPISocialChannelFetchParticipants structure.
type PostRemoteAPISocialChannelFetchParticipantsReader struct {
	formats strfmt.Registry
}

// ReadResponse reads a server response into the received o.
func (o *PostRemoteAPISocialChannelFetchParticipantsReader) ReadResponse(response runtime.ClientResponse, consumer runtime.Consumer) (interface{}, error) {
	switch response.Code() {

	case 200:
		result := NewPostRemoteAPISocialChannelFetchParticipantsOK()
		if err := result.readResponse(response, consumer, o.formats); err != nil {
			return nil, err
		}
		return result, nil

	case 401:
		result := NewPostRemoteAPISocialChannelFetchParticipantsUnauthorized()
		if err := result.readResponse(response, consumer, o.formats); err != nil {
			return nil, err
		}
		return nil, result

	default:
		return nil, runtime.NewAPIError("unknown error", response, response.Code())
	}
}

// NewPostRemoteAPISocialChannelFetchParticipantsOK creates a PostRemoteAPISocialChannelFetchParticipantsOK with default headers values
func NewPostRemoteAPISocialChannelFetchParticipantsOK() *PostRemoteAPISocialChannelFetchParticipantsOK {
	return &PostRemoteAPISocialChannelFetchParticipantsOK{}
}

/*PostRemoteAPISocialChannelFetchParticipantsOK handles this case with default header values.

Request processed succesfully
*/
type PostRemoteAPISocialChannelFetchParticipantsOK struct {
	Payload *models.DefaultResponse
}

func (o *PostRemoteAPISocialChannelFetchParticipantsOK) Error() string {
	return fmt.Sprintf("[POST /remote.api/SocialChannel.fetchParticipants][%d] postRemoteApiSocialChannelFetchParticipantsOK  %+v", 200, o.Payload)
}

func (o *PostRemoteAPISocialChannelFetchParticipantsOK) readResponse(response runtime.ClientResponse, consumer runtime.Consumer, formats strfmt.Registry) error {

	o.Payload = new(models.DefaultResponse)

	// response payload
	if err := consumer.Consume(response.Body(), o.Payload); err != nil && err != io.EOF {
		return err
	}

	return nil
}

// NewPostRemoteAPISocialChannelFetchParticipantsUnauthorized creates a PostRemoteAPISocialChannelFetchParticipantsUnauthorized with default headers values
func NewPostRemoteAPISocialChannelFetchParticipantsUnauthorized() *PostRemoteAPISocialChannelFetchParticipantsUnauthorized {
	return &PostRemoteAPISocialChannelFetchParticipantsUnauthorized{}
}

/*PostRemoteAPISocialChannelFetchParticipantsUnauthorized handles this case with default header values.

Unauthorized request
*/
type PostRemoteAPISocialChannelFetchParticipantsUnauthorized struct {
	Payload *models.UnauthorizedRequest
}

func (o *PostRemoteAPISocialChannelFetchParticipantsUnauthorized) Error() string {
	return fmt.Sprintf("[POST /remote.api/SocialChannel.fetchParticipants][%d] postRemoteApiSocialChannelFetchParticipantsUnauthorized  %+v", 401, o.Payload)
}

func (o *PostRemoteAPISocialChannelFetchParticipantsUnauthorized) readResponse(response runtime.ClientResponse, consumer runtime.Consumer, formats strfmt.Registry) error {

	o.Payload = new(models.UnauthorizedRequest)

	// response payload
	if err := consumer.Consume(response.Body(), o.Payload); err != nil && err != io.EOF {
		return err
	}

	return nil
}