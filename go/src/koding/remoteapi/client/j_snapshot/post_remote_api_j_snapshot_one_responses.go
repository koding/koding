package j_snapshot

// This file was generated by the swagger tool.
// Editing this file might prove futile when you re-run the swagger generate command

import (
	"fmt"
	"io"

	"github.com/go-openapi/runtime"

	strfmt "github.com/go-openapi/strfmt"

	"koding/remoteapi/models"
)

// PostRemoteAPIJSnapshotOneReader is a Reader for the PostRemoteAPIJSnapshotOne structure.
type PostRemoteAPIJSnapshotOneReader struct {
	formats strfmt.Registry
}

// ReadResponse reads a server response into the received o.
func (o *PostRemoteAPIJSnapshotOneReader) ReadResponse(response runtime.ClientResponse, consumer runtime.Consumer) (interface{}, error) {
	switch response.Code() {

	case 200:
		result := NewPostRemoteAPIJSnapshotOneOK()
		if err := result.readResponse(response, consumer, o.formats); err != nil {
			return nil, err
		}
		return result, nil

	case 401:
		result := NewPostRemoteAPIJSnapshotOneUnauthorized()
		if err := result.readResponse(response, consumer, o.formats); err != nil {
			return nil, err
		}
		return nil, result

	default:
		return nil, runtime.NewAPIError("unknown error", response, response.Code())
	}
}

// NewPostRemoteAPIJSnapshotOneOK creates a PostRemoteAPIJSnapshotOneOK with default headers values
func NewPostRemoteAPIJSnapshotOneOK() *PostRemoteAPIJSnapshotOneOK {
	return &PostRemoteAPIJSnapshotOneOK{}
}

/*PostRemoteAPIJSnapshotOneOK handles this case with default header values.

Request processed succesfully
*/
type PostRemoteAPIJSnapshotOneOK struct {
	Payload *models.DefaultResponse
}

func (o *PostRemoteAPIJSnapshotOneOK) Error() string {
	return fmt.Sprintf("[POST /remote.api/JSnapshot.one][%d] postRemoteApiJSnapshotOneOK  %+v", 200, o.Payload)
}

func (o *PostRemoteAPIJSnapshotOneOK) readResponse(response runtime.ClientResponse, consumer runtime.Consumer, formats strfmt.Registry) error {

	o.Payload = new(models.DefaultResponse)

	// response payload
	if err := consumer.Consume(response.Body(), o.Payload); err != nil && err != io.EOF {
		return err
	}

	return nil
}

// NewPostRemoteAPIJSnapshotOneUnauthorized creates a PostRemoteAPIJSnapshotOneUnauthorized with default headers values
func NewPostRemoteAPIJSnapshotOneUnauthorized() *PostRemoteAPIJSnapshotOneUnauthorized {
	return &PostRemoteAPIJSnapshotOneUnauthorized{}
}

/*PostRemoteAPIJSnapshotOneUnauthorized handles this case with default header values.

Unauthorized request
*/
type PostRemoteAPIJSnapshotOneUnauthorized struct {
	Payload *models.UnauthorizedRequest
}

func (o *PostRemoteAPIJSnapshotOneUnauthorized) Error() string {
	return fmt.Sprintf("[POST /remote.api/JSnapshot.one][%d] postRemoteApiJSnapshotOneUnauthorized  %+v", 401, o.Payload)
}

func (o *PostRemoteAPIJSnapshotOneUnauthorized) readResponse(response runtime.ClientResponse, consumer runtime.Consumer, formats strfmt.Registry) error {

	o.Payload = new(models.UnauthorizedRequest)

	// response payload
	if err := consumer.Consume(response.Body(), o.Payload); err != nil && err != io.EOF {
		return err
	}

	return nil
}
