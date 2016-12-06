package j_group

// This file was generated by the swagger tool.
// Editing this file might prove futile when you re-run the swagger generate command

import (
	"fmt"
	"io"

	"github.com/go-openapi/runtime"

	strfmt "github.com/go-openapi/strfmt"

	"koding/remoteapi/models"
)

// PostRemoteAPIJGroupFetchAPITokensIDReader is a Reader for the PostRemoteAPIJGroupFetchAPITokensID structure.
type PostRemoteAPIJGroupFetchAPITokensIDReader struct {
	formats strfmt.Registry
}

// ReadResponse reads a server response into the received o.
func (o *PostRemoteAPIJGroupFetchAPITokensIDReader) ReadResponse(response runtime.ClientResponse, consumer runtime.Consumer) (interface{}, error) {
	switch response.Code() {

	case 200:
		result := NewPostRemoteAPIJGroupFetchAPITokensIDOK()
		if err := result.readResponse(response, consumer, o.formats); err != nil {
			return nil, err
		}
		return result, nil

	default:
		return nil, runtime.NewAPIError("unknown error", response, response.Code())
	}
}

// NewPostRemoteAPIJGroupFetchAPITokensIDOK creates a PostRemoteAPIJGroupFetchAPITokensIDOK with default headers values
func NewPostRemoteAPIJGroupFetchAPITokensIDOK() *PostRemoteAPIJGroupFetchAPITokensIDOK {
	return &PostRemoteAPIJGroupFetchAPITokensIDOK{}
}

/*PostRemoteAPIJGroupFetchAPITokensIDOK handles this case with default header values.

OK
*/
type PostRemoteAPIJGroupFetchAPITokensIDOK struct {
	Payload *models.JGroup
}

func (o *PostRemoteAPIJGroupFetchAPITokensIDOK) Error() string {
	return fmt.Sprintf("[POST /remote.api/JGroup.fetchApiTokens/{id}][%d] postRemoteApiJGroupFetchApiTokensIdOK  %+v", 200, o.Payload)
}

func (o *PostRemoteAPIJGroupFetchAPITokensIDOK) readResponse(response runtime.ClientResponse, consumer runtime.Consumer, formats strfmt.Registry) error {

	o.Payload = new(models.JGroup)

	// response payload
	if err := consumer.Consume(response.Body(), o.Payload); err != nil && err != io.EOF {
		return err
	}

	return nil
}