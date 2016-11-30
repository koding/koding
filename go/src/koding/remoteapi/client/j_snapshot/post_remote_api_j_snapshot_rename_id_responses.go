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

// PostRemoteAPIJSnapshotRenameIDReader is a Reader for the PostRemoteAPIJSnapshotRenameID structure.
type PostRemoteAPIJSnapshotRenameIDReader struct {
	formats strfmt.Registry
}

// ReadResponse reads a server response into the received o.
func (o *PostRemoteAPIJSnapshotRenameIDReader) ReadResponse(response runtime.ClientResponse, consumer runtime.Consumer) (interface{}, error) {
	switch response.Code() {

	case 200:
		result := NewPostRemoteAPIJSnapshotRenameIDOK()
		if err := result.readResponse(response, consumer, o.formats); err != nil {
			return nil, err
		}
		return result, nil

	default:
		return nil, runtime.NewAPIError("unknown error", response, response.Code())
	}
}

// NewPostRemoteAPIJSnapshotRenameIDOK creates a PostRemoteAPIJSnapshotRenameIDOK with default headers values
func NewPostRemoteAPIJSnapshotRenameIDOK() *PostRemoteAPIJSnapshotRenameIDOK {
	return &PostRemoteAPIJSnapshotRenameIDOK{}
}

/*PostRemoteAPIJSnapshotRenameIDOK handles this case with default header values.

OK
*/
type PostRemoteAPIJSnapshotRenameIDOK struct {
	Payload *models.JSnapshot
}

func (o *PostRemoteAPIJSnapshotRenameIDOK) Error() string {
	return fmt.Sprintf("[POST /remote.api/JSnapshot.rename/{id}][%d] postRemoteApiJSnapshotRenameIdOK  %+v", 200, o.Payload)
}

func (o *PostRemoteAPIJSnapshotRenameIDOK) readResponse(response runtime.ClientResponse, consumer runtime.Consumer, formats strfmt.Registry) error {

	o.Payload = new(models.JSnapshot)

	// response payload
	if err := consumer.Consume(response.Body(), o.Payload); err != nil && err != io.EOF {
		return err
	}

	return nil
}