package j_reward

// This file was generated by the swagger tool.
// Editing this file might prove futile when you re-run the swagger generate command

import (
	"fmt"
	"io"

	"github.com/go-openapi/runtime"

	strfmt "github.com/go-openapi/strfmt"

	"koding/remoteapi/models"
)

// PostRemoteAPIJRewardAddCustomRewardReader is a Reader for the PostRemoteAPIJRewardAddCustomReward structure.
type PostRemoteAPIJRewardAddCustomRewardReader struct {
	formats strfmt.Registry
}

// ReadResponse reads a server response into the received o.
func (o *PostRemoteAPIJRewardAddCustomRewardReader) ReadResponse(response runtime.ClientResponse, consumer runtime.Consumer) (interface{}, error) {
	switch response.Code() {

	case 200:
		result := NewPostRemoteAPIJRewardAddCustomRewardOK()
		if err := result.readResponse(response, consumer, o.formats); err != nil {
			return nil, err
		}
		return result, nil

	case 401:
		result := NewPostRemoteAPIJRewardAddCustomRewardUnauthorized()
		if err := result.readResponse(response, consumer, o.formats); err != nil {
			return nil, err
		}
		return nil, result

	default:
		return nil, runtime.NewAPIError("unknown error", response, response.Code())
	}
}

// NewPostRemoteAPIJRewardAddCustomRewardOK creates a PostRemoteAPIJRewardAddCustomRewardOK with default headers values
func NewPostRemoteAPIJRewardAddCustomRewardOK() *PostRemoteAPIJRewardAddCustomRewardOK {
	return &PostRemoteAPIJRewardAddCustomRewardOK{}
}

/*PostRemoteAPIJRewardAddCustomRewardOK handles this case with default header values.

Request processed succesfully
*/
type PostRemoteAPIJRewardAddCustomRewardOK struct {
	Payload *models.DefaultResponse
}

func (o *PostRemoteAPIJRewardAddCustomRewardOK) Error() string {
	return fmt.Sprintf("[POST /remote.api/JReward.addCustomReward][%d] postRemoteApiJRewardAddCustomRewardOK  %+v", 200, o.Payload)
}

func (o *PostRemoteAPIJRewardAddCustomRewardOK) readResponse(response runtime.ClientResponse, consumer runtime.Consumer, formats strfmt.Registry) error {

	o.Payload = new(models.DefaultResponse)

	// response payload
	if err := consumer.Consume(response.Body(), o.Payload); err != nil && err != io.EOF {
		return err
	}

	return nil
}

// NewPostRemoteAPIJRewardAddCustomRewardUnauthorized creates a PostRemoteAPIJRewardAddCustomRewardUnauthorized with default headers values
func NewPostRemoteAPIJRewardAddCustomRewardUnauthorized() *PostRemoteAPIJRewardAddCustomRewardUnauthorized {
	return &PostRemoteAPIJRewardAddCustomRewardUnauthorized{}
}

/*PostRemoteAPIJRewardAddCustomRewardUnauthorized handles this case with default header values.

Unauthorized request
*/
type PostRemoteAPIJRewardAddCustomRewardUnauthorized struct {
	Payload *models.UnauthorizedRequest
}

func (o *PostRemoteAPIJRewardAddCustomRewardUnauthorized) Error() string {
	return fmt.Sprintf("[POST /remote.api/JReward.addCustomReward][%d] postRemoteApiJRewardAddCustomRewardUnauthorized  %+v", 401, o.Payload)
}

func (o *PostRemoteAPIJRewardAddCustomRewardUnauthorized) readResponse(response runtime.ClientResponse, consumer runtime.Consumer, formats strfmt.Registry) error {

	o.Payload = new(models.UnauthorizedRequest)

	// response payload
	if err := consumer.Consume(response.Body(), o.Payload); err != nil && err != io.EOF {
		return err
	}

	return nil
}