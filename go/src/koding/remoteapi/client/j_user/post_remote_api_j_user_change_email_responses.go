package j_user

// This file was generated by the swagger tool.
// Editing this file might prove futile when you re-run the swagger generate command

import (
	"fmt"
	"io"

	"github.com/go-openapi/runtime"

	strfmt "github.com/go-openapi/strfmt"

	"koding/remoteapi/models"
)

// PostRemoteAPIJUserChangeEmailReader is a Reader for the PostRemoteAPIJUserChangeEmail structure.
type PostRemoteAPIJUserChangeEmailReader struct {
	formats strfmt.Registry
}

// ReadResponse reads a server response into the received o.
func (o *PostRemoteAPIJUserChangeEmailReader) ReadResponse(response runtime.ClientResponse, consumer runtime.Consumer) (interface{}, error) {
	switch response.Code() {

	case 200:
		result := NewPostRemoteAPIJUserChangeEmailOK()
		if err := result.readResponse(response, consumer, o.formats); err != nil {
			return nil, err
		}
		return result, nil

	case 401:
		result := NewPostRemoteAPIJUserChangeEmailUnauthorized()
		if err := result.readResponse(response, consumer, o.formats); err != nil {
			return nil, err
		}
		return nil, result

	default:
		return nil, runtime.NewAPIError("unknown error", response, response.Code())
	}
}

// NewPostRemoteAPIJUserChangeEmailOK creates a PostRemoteAPIJUserChangeEmailOK with default headers values
func NewPostRemoteAPIJUserChangeEmailOK() *PostRemoteAPIJUserChangeEmailOK {
	return &PostRemoteAPIJUserChangeEmailOK{}
}

/*PostRemoteAPIJUserChangeEmailOK handles this case with default header values.

Request processed succesfully
*/
type PostRemoteAPIJUserChangeEmailOK struct {
	Payload *models.DefaultResponse
}

func (o *PostRemoteAPIJUserChangeEmailOK) Error() string {
	return fmt.Sprintf("[POST /remote.api/JUser.changeEmail][%d] postRemoteApiJUserChangeEmailOK  %+v", 200, o.Payload)
}

func (o *PostRemoteAPIJUserChangeEmailOK) readResponse(response runtime.ClientResponse, consumer runtime.Consumer, formats strfmt.Registry) error {

	o.Payload = new(models.DefaultResponse)

	// response payload
	if err := consumer.Consume(response.Body(), o.Payload); err != nil && err != io.EOF {
		return err
	}

	return nil
}

// NewPostRemoteAPIJUserChangeEmailUnauthorized creates a PostRemoteAPIJUserChangeEmailUnauthorized with default headers values
func NewPostRemoteAPIJUserChangeEmailUnauthorized() *PostRemoteAPIJUserChangeEmailUnauthorized {
	return &PostRemoteAPIJUserChangeEmailUnauthorized{}
}

/*PostRemoteAPIJUserChangeEmailUnauthorized handles this case with default header values.

Unauthorized request
*/
type PostRemoteAPIJUserChangeEmailUnauthorized struct {
	Payload *models.UnauthorizedRequest
}

func (o *PostRemoteAPIJUserChangeEmailUnauthorized) Error() string {
	return fmt.Sprintf("[POST /remote.api/JUser.changeEmail][%d] postRemoteApiJUserChangeEmailUnauthorized  %+v", 401, o.Payload)
}

func (o *PostRemoteAPIJUserChangeEmailUnauthorized) readResponse(response runtime.ClientResponse, consumer runtime.Consumer, formats strfmt.Registry) error {

	o.Payload = new(models.UnauthorizedRequest)

	// response payload
	if err := consumer.Consume(response.Body(), o.Payload); err != nil && err != io.EOF {
		return err
	}

	return nil
}