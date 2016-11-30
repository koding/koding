package j_proxy_restriction

// This file was generated by the swagger tool.
// Editing this file might prove futile when you re-run the swagger generate command

import (
	"fmt"
	"io"

	"github.com/go-openapi/runtime"

	strfmt "github.com/go-openapi/strfmt"

	"koding/remoteapi/models"
)

// PostRemoteAPIJProxyRestrictionSomeReader is a Reader for the PostRemoteAPIJProxyRestrictionSome structure.
type PostRemoteAPIJProxyRestrictionSomeReader struct {
	formats strfmt.Registry
}

// ReadResponse reads a server response into the received o.
func (o *PostRemoteAPIJProxyRestrictionSomeReader) ReadResponse(response runtime.ClientResponse, consumer runtime.Consumer) (interface{}, error) {
	switch response.Code() {

	case 200:
		result := NewPostRemoteAPIJProxyRestrictionSomeOK()
		if err := result.readResponse(response, consumer, o.formats); err != nil {
			return nil, err
		}
		return result, nil

	case 401:
		result := NewPostRemoteAPIJProxyRestrictionSomeUnauthorized()
		if err := result.readResponse(response, consumer, o.formats); err != nil {
			return nil, err
		}
		return nil, result

	default:
		return nil, runtime.NewAPIError("unknown error", response, response.Code())
	}
}

// NewPostRemoteAPIJProxyRestrictionSomeOK creates a PostRemoteAPIJProxyRestrictionSomeOK with default headers values
func NewPostRemoteAPIJProxyRestrictionSomeOK() *PostRemoteAPIJProxyRestrictionSomeOK {
	return &PostRemoteAPIJProxyRestrictionSomeOK{}
}

/*PostRemoteAPIJProxyRestrictionSomeOK handles this case with default header values.

Request processed succesfully
*/
type PostRemoteAPIJProxyRestrictionSomeOK struct {
	Payload *models.DefaultResponse
}

func (o *PostRemoteAPIJProxyRestrictionSomeOK) Error() string {
	return fmt.Sprintf("[POST /remote.api/JProxyRestriction.some][%d] postRemoteApiJProxyRestrictionSomeOK  %+v", 200, o.Payload)
}

func (o *PostRemoteAPIJProxyRestrictionSomeOK) readResponse(response runtime.ClientResponse, consumer runtime.Consumer, formats strfmt.Registry) error {

	o.Payload = new(models.DefaultResponse)

	// response payload
	if err := consumer.Consume(response.Body(), o.Payload); err != nil && err != io.EOF {
		return err
	}

	return nil
}

// NewPostRemoteAPIJProxyRestrictionSomeUnauthorized creates a PostRemoteAPIJProxyRestrictionSomeUnauthorized with default headers values
func NewPostRemoteAPIJProxyRestrictionSomeUnauthorized() *PostRemoteAPIJProxyRestrictionSomeUnauthorized {
	return &PostRemoteAPIJProxyRestrictionSomeUnauthorized{}
}

/*PostRemoteAPIJProxyRestrictionSomeUnauthorized handles this case with default header values.

Unauthorized request
*/
type PostRemoteAPIJProxyRestrictionSomeUnauthorized struct {
	Payload *models.UnauthorizedRequest
}

func (o *PostRemoteAPIJProxyRestrictionSomeUnauthorized) Error() string {
	return fmt.Sprintf("[POST /remote.api/JProxyRestriction.some][%d] postRemoteApiJProxyRestrictionSomeUnauthorized  %+v", 401, o.Payload)
}

func (o *PostRemoteAPIJProxyRestrictionSomeUnauthorized) readResponse(response runtime.ClientResponse, consumer runtime.Consumer, formats strfmt.Registry) error {

	o.Payload = new(models.UnauthorizedRequest)

	// response payload
	if err := consumer.Consume(response.Body(), o.Payload); err != nil && err != io.EOF {
		return err
	}

	return nil
}
