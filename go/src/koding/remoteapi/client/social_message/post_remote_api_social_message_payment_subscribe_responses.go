package social_message

// This file was generated by the swagger tool.
// Editing this file might prove futile when you re-run the swagger generate command

import (
	"fmt"
	"io"

	"github.com/go-openapi/runtime"

	strfmt "github.com/go-openapi/strfmt"

	"koding/remoteapi/models"
)

// PostRemoteAPISocialMessagePaymentSubscribeReader is a Reader for the PostRemoteAPISocialMessagePaymentSubscribe structure.
type PostRemoteAPISocialMessagePaymentSubscribeReader struct {
	formats strfmt.Registry
}

// ReadResponse reads a server response into the received o.
func (o *PostRemoteAPISocialMessagePaymentSubscribeReader) ReadResponse(response runtime.ClientResponse, consumer runtime.Consumer) (interface{}, error) {
	switch response.Code() {

	case 200:
		result := NewPostRemoteAPISocialMessagePaymentSubscribeOK()
		if err := result.readResponse(response, consumer, o.formats); err != nil {
			return nil, err
		}
		return result, nil

	case 401:
		result := NewPostRemoteAPISocialMessagePaymentSubscribeUnauthorized()
		if err := result.readResponse(response, consumer, o.formats); err != nil {
			return nil, err
		}
		return nil, result

	default:
		return nil, runtime.NewAPIError("unknown error", response, response.Code())
	}
}

// NewPostRemoteAPISocialMessagePaymentSubscribeOK creates a PostRemoteAPISocialMessagePaymentSubscribeOK with default headers values
func NewPostRemoteAPISocialMessagePaymentSubscribeOK() *PostRemoteAPISocialMessagePaymentSubscribeOK {
	return &PostRemoteAPISocialMessagePaymentSubscribeOK{}
}

/*PostRemoteAPISocialMessagePaymentSubscribeOK handles this case with default header values.

Request processed succesfully
*/
type PostRemoteAPISocialMessagePaymentSubscribeOK struct {
	Payload *models.DefaultResponse
}

func (o *PostRemoteAPISocialMessagePaymentSubscribeOK) Error() string {
	return fmt.Sprintf("[POST /remote.api/SocialMessage.paymentSubscribe][%d] postRemoteApiSocialMessagePaymentSubscribeOK  %+v", 200, o.Payload)
}

func (o *PostRemoteAPISocialMessagePaymentSubscribeOK) readResponse(response runtime.ClientResponse, consumer runtime.Consumer, formats strfmt.Registry) error {

	o.Payload = new(models.DefaultResponse)

	// response payload
	if err := consumer.Consume(response.Body(), o.Payload); err != nil && err != io.EOF {
		return err
	}

	return nil
}

// NewPostRemoteAPISocialMessagePaymentSubscribeUnauthorized creates a PostRemoteAPISocialMessagePaymentSubscribeUnauthorized with default headers values
func NewPostRemoteAPISocialMessagePaymentSubscribeUnauthorized() *PostRemoteAPISocialMessagePaymentSubscribeUnauthorized {
	return &PostRemoteAPISocialMessagePaymentSubscribeUnauthorized{}
}

/*PostRemoteAPISocialMessagePaymentSubscribeUnauthorized handles this case with default header values.

Unauthorized request
*/
type PostRemoteAPISocialMessagePaymentSubscribeUnauthorized struct {
	Payload *models.UnauthorizedRequest
}

func (o *PostRemoteAPISocialMessagePaymentSubscribeUnauthorized) Error() string {
	return fmt.Sprintf("[POST /remote.api/SocialMessage.paymentSubscribe][%d] postRemoteApiSocialMessagePaymentSubscribeUnauthorized  %+v", 401, o.Payload)
}

func (o *PostRemoteAPISocialMessagePaymentSubscribeUnauthorized) readResponse(response runtime.ClientResponse, consumer runtime.Consumer, formats strfmt.Registry) error {

	o.Payload = new(models.UnauthorizedRequest)

	// response payload
	if err := consumer.Consume(response.Body(), o.Payload); err != nil && err != io.EOF {
		return err
	}

	return nil
}