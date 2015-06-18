package webhook

import (
	"encoding/json"
	"errors"
	"fmt"
	"socialapi/models"
	"socialapi/workers/common/handler"
	"time"

	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
	"github.com/nu7hatch/gouuid"
)

var (
	ErrIntegrationIdIsNotSet      = errors.New("integration id is not set")
	ErrGroupChannelIdIsNotSet     = errors.New("group channel id is not set")
	ErrChannelIntegrationNotFound = errors.New("channel integration is not found")
	ErrTokenNotSet                = errors.New("token is not set")
)

type ChannelIntegration struct {
	// unique identifier of the channel integration
	Id int64 `json:"id,string"`

	// Description of the channel integration
	Description string `json:"description" sql:"TYPE:TEXT"`

	// Unique token value of the channel integration
	Token string `json:"token" sql:"NOT NULL;TYPE:VARCHAR(20)"`

	// Id of the integration
	IntegrationId int64 `json:"integrationId,string" sql:"NOT NULL;TYPE:BIGINT"`

	// Group name of the integration
	GroupName string `json:"groupName" sql:"NOT NULL;TYPE:VARCHAR(200)"`

	// Id of the channel
	ChannelId int64 `json:"channelId,string" sql:"NOT NULL;TYPE:BIGINT"`

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

	// Options is used for providing optional data
	Options map[string]interface{} `json:"optional" sql:"-"`
}

func NewChannelIntegration() *ChannelIntegration {
	return &ChannelIntegration{}
}

func (i *ChannelIntegration) Create() error {
	if err := i.Validate(); err != nil {
		return err
	}

	token, err := uuid.NewV4()
	if err != nil {
		return err
	}
	i.Token = token.String()

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

func (i *ChannelIntegration) Validate() error {
	if i.GroupName == "" {
		return models.ErrGroupNameIsNotSet
	}

	if i.ChannelId == 0 {
		return models.ErrChannelIsNotSet
	}

	if i.IntegrationId == 0 {
		return ErrIntegrationIdIsNotSet
	}

	if i.CreatorId == 0 {
		return models.ErrCreatorIdIsNotSet
	}

	return nil
}

func (i *ChannelIntegration) RegenerateToken() error {
	var token string
	for {
		ci := NewChannelIntegration()
		t, err := uuid.NewV4()
		if err != nil {
			return err
		}

		token = t.String()
		tokenErr := ci.ByToken(token)
		if tokenErr == ErrChannelIntegrationNotFound {
			break
		}

		if tokenErr != nil {
			return tokenErr
		}
	}

	i.Token = token

	return i.Update()
}

func (i *ChannelIntegration) ByGroupName(groupName string) ([]ChannelIntegration, error) {
	var ints []ChannelIntegration
	if groupName == "" {
		return ints, nil
	}

	query := &bongo.Query{
		Selector: map[string]interface{}{
			"group_name": groupName,
		},
	}

	if err := i.Some(&ints, query); err != nil {
		return nil, err
	}

	return ints, nil
}

type Options map[string]interface{}

func (ci *ChannelIntegration) FetchOptions(cookie, rootPath string) (Options, error) {

	i := NewIntegration()
	if err := i.ById(ci.IntegrationId); err != nil {
		return nil, err
	}

	// fetch optional fields
	sections, err := i.GetSections()
	if err != nil {
		return nil, err
	}

	options := Options{}
	events, err := i.GetEvents()
	if err != ErrSettingNotFound {
		options["events"] = events
	}

	for _, s := range sections {
		if s.Endpoint == "" {
			continue
		}

		request := &handler.Request{
			Type:     "GET",
			Endpoint: fmt.Sprintf("%s%s", rootPath, s.Endpoint),
			Cookie:   cookie,
		}

		resp, err := handler.DoRequest(request)
		if err != nil {
			return nil, err
		}
		if resp.StatusCode != 200 {
			return nil, errors.New(resp.Status)
		}
		defer resp.Body.Close()

		var result interface{}
		err = json.NewDecoder(resp.Body).Decode(&result)
		if err != nil {
			return nil, err
		}

		options[s.Name] = result
	}

	return options, nil
}
