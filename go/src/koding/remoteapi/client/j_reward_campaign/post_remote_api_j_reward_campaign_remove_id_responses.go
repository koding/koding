package j_reward_campaign

// This file was generated by the swagger tool.
// Editing this file might prove futile when you re-run the swagger generate command

import (
	"fmt"
	"io"

	"github.com/go-openapi/runtime"

	strfmt "github.com/go-openapi/strfmt"

	"koding/remoteapi/models"
)

// PostRemoteAPIJRewardCampaignRemoveIDReader is a Reader for the PostRemoteAPIJRewardCampaignRemoveID structure.
type PostRemoteAPIJRewardCampaignRemoveIDReader struct {
	formats strfmt.Registry
}

// ReadResponse reads a server response into the received o.
func (o *PostRemoteAPIJRewardCampaignRemoveIDReader) ReadResponse(response runtime.ClientResponse, consumer runtime.Consumer) (interface{}, error) {
	switch response.Code() {

	case 200:
		result := NewPostRemoteAPIJRewardCampaignRemoveIDOK()
		if err := result.readResponse(response, consumer, o.formats); err != nil {
			return nil, err
		}
		return result, nil

	default:
		return nil, runtime.NewAPIError("unknown error", response, response.Code())
	}
}

// NewPostRemoteAPIJRewardCampaignRemoveIDOK creates a PostRemoteAPIJRewardCampaignRemoveIDOK with default headers values
func NewPostRemoteAPIJRewardCampaignRemoveIDOK() *PostRemoteAPIJRewardCampaignRemoveIDOK {
	return &PostRemoteAPIJRewardCampaignRemoveIDOK{}
}

/*PostRemoteAPIJRewardCampaignRemoveIDOK handles this case with default header values.

OK
*/
type PostRemoteAPIJRewardCampaignRemoveIDOK struct {
	Payload *models.JRewardCampaign
}

func (o *PostRemoteAPIJRewardCampaignRemoveIDOK) Error() string {
	return fmt.Sprintf("[POST /remote.api/JRewardCampaign.remove/{id}][%d] postRemoteApiJRewardCampaignRemoveIdOK  %+v", 200, o.Payload)
}

func (o *PostRemoteAPIJRewardCampaignRemoveIDOK) readResponse(response runtime.ClientResponse, consumer runtime.Consumer, formats strfmt.Registry) error {

	o.Payload = new(models.JRewardCampaign)

	// response payload
	if err := consumer.Consume(response.Body(), o.Payload); err != nil && err != io.EOF {
		return err
	}

	return nil
}