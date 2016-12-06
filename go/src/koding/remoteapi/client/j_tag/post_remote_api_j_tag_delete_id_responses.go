package j_tag

// This file was generated by the swagger tool.
// Editing this file might prove futile when you re-run the swagger generate command

import (
	"fmt"
	"io"

	"github.com/go-openapi/runtime"

	strfmt "github.com/go-openapi/strfmt"

	"koding/remoteapi/models"
)

// PostRemoteAPIJTagDeleteIDReader is a Reader for the PostRemoteAPIJTagDeleteID structure.
type PostRemoteAPIJTagDeleteIDReader struct {
	formats strfmt.Registry
}

// ReadResponse reads a server response into the received o.
func (o *PostRemoteAPIJTagDeleteIDReader) ReadResponse(response runtime.ClientResponse, consumer runtime.Consumer) (interface{}, error) {
	switch response.Code() {

	case 200:
		result := NewPostRemoteAPIJTagDeleteIDOK()
		if err := result.readResponse(response, consumer, o.formats); err != nil {
			return nil, err
		}
		return result, nil

	default:
		return nil, runtime.NewAPIError("unknown error", response, response.Code())
	}
}

// NewPostRemoteAPIJTagDeleteIDOK creates a PostRemoteAPIJTagDeleteIDOK with default headers values
func NewPostRemoteAPIJTagDeleteIDOK() *PostRemoteAPIJTagDeleteIDOK {
	return &PostRemoteAPIJTagDeleteIDOK{}
}

/*PostRemoteAPIJTagDeleteIDOK handles this case with default header values.

OK
*/
type PostRemoteAPIJTagDeleteIDOK struct {
	Payload *models.JTag
}

func (o *PostRemoteAPIJTagDeleteIDOK) Error() string {
	return fmt.Sprintf("[POST /remote.api/JTag.delete/{id}][%d] postRemoteApiJTagDeleteIdOK  %+v", 200, o.Payload)
}

func (o *PostRemoteAPIJTagDeleteIDOK) readResponse(response runtime.ClientResponse, consumer runtime.Consumer, formats strfmt.Registry) error {

	o.Payload = new(models.JTag)

	// response payload
	if err := consumer.Consume(response.Body(), o.Payload); err != nil && err != io.EOF {
		return err
	}

	return nil
}