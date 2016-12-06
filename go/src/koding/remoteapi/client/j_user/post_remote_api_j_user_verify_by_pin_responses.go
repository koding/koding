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

// PostRemoteAPIJUserVerifyByPinReader is a Reader for the PostRemoteAPIJUserVerifyByPin structure.
type PostRemoteAPIJUserVerifyByPinReader struct {
	formats strfmt.Registry
}

// ReadResponse reads a server response into the received o.
func (o *PostRemoteAPIJUserVerifyByPinReader) ReadResponse(response runtime.ClientResponse, consumer runtime.Consumer) (interface{}, error) {
	switch response.Code() {

	case 200:
		result := NewPostRemoteAPIJUserVerifyByPinOK()
		if err := result.readResponse(response, consumer, o.formats); err != nil {
			return nil, err
		}
		return result, nil

	case 401:
		result := NewPostRemoteAPIJUserVerifyByPinUnauthorized()
		if err := result.readResponse(response, consumer, o.formats); err != nil {
			return nil, err
		}
		return nil, result

	default:
		return nil, runtime.NewAPIError("unknown error", response, response.Code())
	}
}

// NewPostRemoteAPIJUserVerifyByPinOK creates a PostRemoteAPIJUserVerifyByPinOK with default headers values
func NewPostRemoteAPIJUserVerifyByPinOK() *PostRemoteAPIJUserVerifyByPinOK {
	return &PostRemoteAPIJUserVerifyByPinOK{}
}

/*PostRemoteAPIJUserVerifyByPinOK handles this case with default header values.

Request processed succesfully
*/
type PostRemoteAPIJUserVerifyByPinOK struct {
	Payload *models.DefaultResponse
}

func (o *PostRemoteAPIJUserVerifyByPinOK) Error() string {
	return fmt.Sprintf("[POST /remote.api/JUser.verifyByPin][%d] postRemoteApiJUserVerifyByPinOK  %+v", 200, o.Payload)
}

func (o *PostRemoteAPIJUserVerifyByPinOK) readResponse(response runtime.ClientResponse, consumer runtime.Consumer, formats strfmt.Registry) error {

	o.Payload = new(models.DefaultResponse)

	// response payload
	if err := consumer.Consume(response.Body(), o.Payload); err != nil && err != io.EOF {
		return err
	}

	return nil
}

// NewPostRemoteAPIJUserVerifyByPinUnauthorized creates a PostRemoteAPIJUserVerifyByPinUnauthorized with default headers values
func NewPostRemoteAPIJUserVerifyByPinUnauthorized() *PostRemoteAPIJUserVerifyByPinUnauthorized {
	return &PostRemoteAPIJUserVerifyByPinUnauthorized{}
}

/*PostRemoteAPIJUserVerifyByPinUnauthorized handles this case with default header values.

Unauthorized request
*/
type PostRemoteAPIJUserVerifyByPinUnauthorized struct {
	Payload *models.UnauthorizedRequest
}

func (o *PostRemoteAPIJUserVerifyByPinUnauthorized) Error() string {
	return fmt.Sprintf("[POST /remote.api/JUser.verifyByPin][%d] postRemoteApiJUserVerifyByPinUnauthorized  %+v", 401, o.Payload)
}

func (o *PostRemoteAPIJUserVerifyByPinUnauthorized) readResponse(response runtime.ClientResponse, consumer runtime.Consumer, formats strfmt.Registry) error {

	o.Payload = new(models.UnauthorizedRequest)

	// response payload
	if err := consumer.Consume(response.Body(), o.Payload); err != nil && err != io.EOF {
		return err
	}

	return nil
}