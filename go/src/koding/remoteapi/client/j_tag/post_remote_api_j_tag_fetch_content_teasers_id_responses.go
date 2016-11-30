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

// PostRemoteAPIJTagFetchContentTeasersIDReader is a Reader for the PostRemoteAPIJTagFetchContentTeasersID structure.
type PostRemoteAPIJTagFetchContentTeasersIDReader struct {
	formats strfmt.Registry
}

// ReadResponse reads a server response into the received o.
func (o *PostRemoteAPIJTagFetchContentTeasersIDReader) ReadResponse(response runtime.ClientResponse, consumer runtime.Consumer) (interface{}, error) {
	switch response.Code() {

	case 200:
		result := NewPostRemoteAPIJTagFetchContentTeasersIDOK()
		if err := result.readResponse(response, consumer, o.formats); err != nil {
			return nil, err
		}
		return result, nil

	default:
		return nil, runtime.NewAPIError("unknown error", response, response.Code())
	}
}

// NewPostRemoteAPIJTagFetchContentTeasersIDOK creates a PostRemoteAPIJTagFetchContentTeasersIDOK with default headers values
func NewPostRemoteAPIJTagFetchContentTeasersIDOK() *PostRemoteAPIJTagFetchContentTeasersIDOK {
	return &PostRemoteAPIJTagFetchContentTeasersIDOK{}
}

/*PostRemoteAPIJTagFetchContentTeasersIDOK handles this case with default header values.

OK
*/
type PostRemoteAPIJTagFetchContentTeasersIDOK struct {
	Payload *models.JTag
}

func (o *PostRemoteAPIJTagFetchContentTeasersIDOK) Error() string {
	return fmt.Sprintf("[POST /remote.api/JTag.fetchContentTeasers/{id}][%d] postRemoteApiJTagFetchContentTeasersIdOK  %+v", 200, o.Payload)
}

func (o *PostRemoteAPIJTagFetchContentTeasersIDOK) readResponse(response runtime.ClientResponse, consumer runtime.Consumer, formats strfmt.Registry) error {

	o.Payload = new(models.JTag)

	// response payload
	if err := consumer.Consume(response.Body(), o.Payload); err != nil && err != io.EOF {
		return err
	}

	return nil
}
