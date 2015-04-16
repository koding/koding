package webhook

import (
	"errors"
	"socialapi/models"
	"time"

	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
)

var (
	ErrIntegrationIdIsNotSet      = errors.New("integration id is not set")
	ErrGroupChannelIdIsNotSet     = errors.New("group channel id is not set")
	ErrChannelIntegrationNotFound = errors.New("channel integration is not found")
)

type ChannelIntegration struct {
	// unique identifier of the channel integration
	Id int64 `json:"id,string"`

	// Description of the channel integration
	Description string `json:"description" sql:"TYPE:TEXT"`

	// Unique token value of the channel integration
	Token string `json:"token" sql:"NOT NULL;TYPE:VARCHAR(20)"`

	// Id of the integration
	IntegrationId int64 `json:"integrationId" sql:"NOT NULL;TYPE:BIGINT"`

	// Group name of the integration
	GroupName string `json:"groupName" sql:"NOT NULL;TYPE:VARCHAR(200)"`

	// Id of the channel
	ChannelId int64 `json:"groupChannelId" sql:"NOT NULL;TYPE:BIGINT"`

	// Id of the creator
	CreatorId int64 `json:"creatorId" sql:"NOT NULL;TYPE:BIGINT"`

	// Flag to enable/disable a channel integration
	IsDisabled bool `json:"isDisabled" sql:"NOT NULL;TYPE:BOOLEAN"`

	// Settings field used for storing custom bot name, icon path and various
	// other data
	Settings gorm.Hstore `json:"settings"`

	// Creation date of the integration
	CreatedAt time.Time `json:"createdAt" sql:"NOT NULL"`

	// Modification date of the integration
	UpdatedAt time.Time `json:"updatedAt" sql:"NOT NULL"`

	// Deletion date of the integration
	DeletedAt time.Time `json:"deletedAt" sql:"NOT NULL"`
}

func NewChannelIntegration() *ChannelIntegration {
	return &ChannelIntegration{}
}

func (i *ChannelIntegration) Create() error {
	if err := i.validate(); err != nil {
		return err
	}

	i.Token = models.RandomName()

	return bongo.B.Create(i)
}

func (i *ChannelIntegration) ByToken(token string) error {
	query := &bongo.Query{
		Selector: map[string]interface{}{
			"token": token,
		},
	}

	err := i.One(query)
	if err == bongo.RecordNotFound {
		return ErrChannelIntegrationNotFound
	}

	if err != nil {
		return err
	}

	return nil
}

func (i *ChannelIntegration) validate() error {
	if i.GroupChannelId == 0 {
		return ErrGroupChannelIdIsNotSet
	}

	if i.IntegrationId == 0 {
		return ErrIntegrationIdIsNotSet
	}

	if i.CreatorId == 0 {
		return models.ErrCreatorIdIsNotSet
	}

	return nil
}
