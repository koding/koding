package webhook

import (
	"errors"
	"socialapi/models"
	"time"

	"github.com/koding/bongo"
)

var (
	ErrIntegrationIdIsNotSet   = errors.New("integration id is not set")
	ErrGroupChannelIdIsNotSet  = errors.New("group channel id is not set")
	ErrTeamIntegrationNotFound = errors.New("team integration is not found")
)

type TeamIntegration struct {
	// unique identifier of the teamintegration
	Id int64 `json:"id,string"`

	// Custom Name of the teamintegration bot
	BotName string `json:"botName" sql:"TYPE:VARCHAR(200)"`

	// Custom icon path of the
	BotIconPath string `json:"botIconPath" sql:"TYPE:VARCHAR(200)"`

	// Description of the teamintegration
	Description string `json:"description" sql:"TYPE:TEXT"`

	// Unique token value of the teamintegration
	Token string `json:"token" sql:"NOT NULL;TYPE:VARCHAR(20)"`

	// Id of the integration
	IntegrationId int64 `json:"integrationId" sql:"NOT NULL;TYPE:BIGINT"`

	// Id of the channel
	GroupChannelId int64 `json:"groupChannelId" sql:"NOT NULL;TYPE:BIGINT"`

	// Id of the creator
	CreatorId int64 `json:"creatorId" sql:"NOT NULL;TYPE:BIGINT"`

	// Flag to enable/disable a teamintegration
	IsDisabled bool `json:"isDisabled" sql:"NOT NULL;TYPE:BOOLEAN"`

	// Creation date of the integration
	CreatedAt time.Time `json:"createdAt" sql:"NOT NULL"`

	// Modification date of the integration
	UpdatedAt time.Time `json:"updatedAt" sql:"NOT NULL"`

	// Deletion date of the integration
	DeletedAt time.Time `json:"deletedAt" sql:"NOT NULL"`
}

func NewTeamIntegration() *TeamIntegration {
	return &TeamIntegration{}
}

func (i *TeamIntegration) Create() error {
	if err := i.validate(); err != nil {
		return err
	}

	i.Token = models.RandomName()

	return bongo.B.Create(i)
}

func (i *TeamIntegration) ByToken(token string) error {
	query := &bongo.Query{
		Selector: map[string]interface{}{
			"token": token,
		},
	}

	err := i.One(query)
	if err == bongo.RecordNotFound {
		return ErrTeamIntegrationNotFound
	}

	if err != nil {
		return err
	}

	return nil
}

func (i *TeamIntegration) validate() error {
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
