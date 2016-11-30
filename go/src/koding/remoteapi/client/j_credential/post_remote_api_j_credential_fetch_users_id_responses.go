package j_credential

// This file was generated by the swagger tool.
// Editing this file might prove futile when you re-run the swagger generate command

import (
	"fmt"
	"io"

	"github.com/go-openapi/runtime"

	strfmt "github.com/go-openapi/strfmt"

	"koding/remoteapi/models"
)

// PostRemoteAPIJCredentialFetchUsersIDReader is a Reader for the PostRemoteAPIJCredentialFetchUsersID structure.
type PostRemoteAPIJCredentialFetchUsersIDReader struct {
	formats strfmt.Registry
}

// ReadResponse reads a server response into the received o.
func (o *PostRemoteAPIJCredentialFetchUsersIDReader) ReadResponse(response runtime.ClientResponse, consumer runtime.Consumer) (interface{}, error) {
	switch response.Code() {

	case 200:
		result := NewPostRemoteAPIJCredentialFetchUsersIDOK()
		if err := result.readResponse(response, consumer, o.formats); err != nil {
			return nil, err
		}
		return result, nil

	default:
		return nil, runtime.NewAPIError("unknown error", response, response.Code())
	}
}

// NewPostRemoteAPIJCredentialFetchUsersIDOK creates a PostRemoteAPIJCredentialFetchUsersIDOK with default headers values
func NewPostRemoteAPIJCredentialFetchUsersIDOK() *PostRemoteAPIJCredentialFetchUsersIDOK {
	return &PostRemoteAPIJCredentialFetchUsersIDOK{}
}

/*PostRemoteAPIJCredentialFetchUsersIDOK handles this case with default header values.

OK
*/
type PostRemoteAPIJCredentialFetchUsersIDOK struct {
	Payload *models.JCredential
}

func (o *PostRemoteAPIJCredentialFetchUsersIDOK) Error() string {
	return fmt.Sprintf("[POST /remote.api/JCredential.fetchUsers/{id}][%d] postRemoteApiJCredentialFetchUsersIdOK  %+v", 200, o.Payload)
}

func (o *PostRemoteAPIJCredentialFetchUsersIDOK) readResponse(response runtime.ClientResponse, consumer runtime.Consumer, formats strfmt.Registry) error {

	o.Payload = new(models.JCredential)

	// response payload
	if err := consumer.Consume(response.Body(), o.Payload); err != nil && err != io.EOF {
		return err
	}

	return nil
}