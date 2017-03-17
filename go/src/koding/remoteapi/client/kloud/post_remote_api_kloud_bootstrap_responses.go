package kloud

// This file was generated by the swagger tool.
// Editing this file might prove futile when you re-run the swagger generate command

import (
	"fmt"
	"io"

	"github.com/go-openapi/runtime"

	strfmt "github.com/go-openapi/strfmt"

	"koding/remoteapi/models"
)

// PostRemoteAPIKloudBootstrapReader is a Reader for the PostRemoteAPIKloudBootstrap structure.
type PostRemoteAPIKloudBootstrapReader struct {
	formats strfmt.Registry
}

// ReadResponse reads a server response into the received o.
func (o *PostRemoteAPIKloudBootstrapReader) ReadResponse(response runtime.ClientResponse, consumer runtime.Consumer) (interface{}, error) {
	switch response.Code() {

	case 200:
		result := NewPostRemoteAPIKloudBootstrapOK()
		if err := result.readResponse(response, consumer, o.formats); err != nil {
			return nil, err
		}
		return result, nil

	case 401:
		result := NewPostRemoteAPIKloudBootstrapUnauthorized()
		if err := result.readResponse(response, consumer, o.formats); err != nil {
			return nil, err
		}
		return nil, result

	default:
		return nil, runtime.NewAPIError("unknown error", response, response.Code())
	}
}

// NewPostRemoteAPIKloudBootstrapOK creates a PostRemoteAPIKloudBootstrapOK with default headers values
func NewPostRemoteAPIKloudBootstrapOK() *PostRemoteAPIKloudBootstrapOK {
	return &PostRemoteAPIKloudBootstrapOK{}
}

/*PostRemoteAPIKloudBootstrapOK handles this case with default header values.

Request processed successfully
*/
type PostRemoteAPIKloudBootstrapOK struct {
	Payload *models.DefaultResponse
}

func (o *PostRemoteAPIKloudBootstrapOK) Error() string {
	return fmt.Sprintf("[POST /remote.api/Kloud.bootstrap][%d] postRemoteApiKloudBootstrapOK  %+v", 200, o.Payload)
}

func (o *PostRemoteAPIKloudBootstrapOK) readResponse(response runtime.ClientResponse, consumer runtime.Consumer, formats strfmt.Registry) error {

	o.Payload = new(models.DefaultResponse)

	// response payload
	if err := consumer.Consume(response.Body(), o.Payload); err != nil && err != io.EOF {
		return err
	}

	return nil
}

// NewPostRemoteAPIKloudBootstrapUnauthorized creates a PostRemoteAPIKloudBootstrapUnauthorized with default headers values
func NewPostRemoteAPIKloudBootstrapUnauthorized() *PostRemoteAPIKloudBootstrapUnauthorized {
	return &PostRemoteAPIKloudBootstrapUnauthorized{}
}

/*PostRemoteAPIKloudBootstrapUnauthorized handles this case with default header values.

Unauthorized request
*/
type PostRemoteAPIKloudBootstrapUnauthorized struct {
	Payload *models.UnauthorizedRequest
}

func (o *PostRemoteAPIKloudBootstrapUnauthorized) Error() string {
	return fmt.Sprintf("[POST /remote.api/Kloud.bootstrap][%d] postRemoteApiKloudBootstrapUnauthorized  %+v", 401, o.Payload)
}

func (o *PostRemoteAPIKloudBootstrapUnauthorized) readResponse(response runtime.ClientResponse, consumer runtime.Consumer, formats strfmt.Registry) error {

	o.Payload = new(models.UnauthorizedRequest)

	// response payload
	if err := consumer.Consume(response.Body(), o.Payload); err != nil && err != io.EOF {
		return err
	}

	return nil
}