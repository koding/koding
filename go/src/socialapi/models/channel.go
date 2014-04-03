package models

import (
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
)

type Channel struct {
	// unique identifier of the channel
	Id int64 `json:"id"`

	// Name of the channel
	Name string `json:"name"                   sql:"NOT NULL;TYPE:VARCHAR(200);"`

	// Creator of the channel
	CreatorId int64 `json:"creatorId"          sql:"NOT NULL"`

	// Name of the group which channel is belong to
	GroupName string `json:"groupName"         sql:"NOT NULL;TYPE:VARCHAR(200);"`

	// Purpose of the channel
	Purpose string `json:"purpose"`

	// Secret key of the channel for event propagation purposes
	// we can put this key into another table?
	SecretKey string `json:"secretKey"`

	// Type of the channel
	TypeConstant string `json:"typeConstant"   sql:"NOT NULL"`

	// Privacy constant of the channel
	Privacy string `json:"privacy"             sql:"NOT NULL"`

	// Creation date of the channel
	CreatedAt time.Time `json:"createdAt"      sql:"NOT NULL"`

	// Modification date of the channel
	UpdatedAt time.Time `json:"updatedAt"      sql:"NOT NULL"`
}

// to-do check for allowed channels
const (
	// TYPES
	Channel_TYPE_GROUP         = "group"
	Channel_TYPE_TOPIC         = "topic"
	Channel_TYPE_FOLLOWINGFEED = "followingfeed"
	Channel_TYPE_FOLLOWERS     = "followers"
	Channel_TYPE_CHAT          = "chat"
	// Privacy
	Channel_TYPE_PUBLIC  = "public"
	Channel_TYPE_PRIVATE = "private"
	// Koding Group Name
	Channel_KODING_NAME = "koding"
)

func NewChannel() *Channel {
	return &Channel{
		Name:      "koding",
		CreatorId: 123,
		GroupName: Channel_KODING_NAME,
		Purpose:   "string",
		SecretKey: "string",
		Type:      Channel_TYPE_GROUP,
		Privacy:   Channel_TYPE_PRIVATE,
	}
}

func (c *Channel) BeforeCreate() {
	c.CreatedAt = time.Now()
	c.UpdatedAt = time.Now()
}

func (c *Channel) BeforeUpdate() {
	c.UpdatedAt = time.Now()
}

func (c *Channel) GetId() int64 {
	return c.Id
}

func (c *Channel) TableName() string {
	return "channel"
}

func (c *Channel) Fetch() error {
	return bongo.B.Fetch(c)
}

func (c *Channel) AfterCreate() {
	bongo.B.AfterCreate(c)
}

func (c *Channel) AfterUpdate() {
	bongo.B.AfterUpdate(c)
}

func (c *Channel) AfterDelete() {
	bongo.B.AfterDelete(c)
}

func (c *Channel) Update() error {
	if c.Name == "" || c.GroupName == "" {
		return fmt.Errorf("Validation failed %s - %s", c.Name, c.GroupName)
	}

	return bongo.B.Update(c)
}

func (c *Channel) Create() error {
	if c.Name == "" || c.GroupName == "" || c.TypeConstant == "" {
		return fmt.Errorf("Validation failed %s - %s", c.Name, c.GroupName)
	}

	// golang returns -1 if item not in the string
	if strings.Index(c.Name, " ") > -1 {
		return fmt.Errorf("Channel name %q has empty space in it", c.Name)
	}

	selector := map[string]interface{}{
		"name":       c.Name,
		"group_name": c.GroupName,
	}

	// if err is nil
	// it means we already have that channel
	err := c.One(selector)
	if err == nil {
		return fmt.Errorf("Channel %s is already created before for %s group", c.Name, c.GroupName)
	}

	if err != gorm.RecordNotFound {
		return err
	}

	return bongo.B.Create(c)
}

func (c *Channel) Delete() error {
	return bongo.B.Delete(c)
}

func (c *Channel) One(selector map[string]interface{}) error {
	return bongo.B.One(c, c, selector)
}

func (c *Channel) FetchByIds(ids []int64) ([]Channel, error) {
	var channels []Channel

	if len(ids) == 0 {
		return channels, nil
	}

	if err := bongo.B.FetchByIds(c, &channels, ids); err != nil {
		return nil, err
	}
	return channels, nil
}

func (c *Channel) AddParticipant(participantId int64) (*ChannelParticipant, error) {
	if c.Id == 0 {
		return nil, errors.New("Channel Id is not set")
	}

	cp := NewChannelParticipant()
	cp.ChannelId = c.Id
	cp.AccountId = participantId

	err := cp.FetchParticipant()
	if err != nil && err != gorm.RecordNotFound {
		return nil, err
	}

	// if we have this record in DB
	if cp.Id != 0 {
		// if status is not active
		if cp.Status == ChannelParticipant_STATUS_ACTIVE {
			return nil, errors.New(fmt.Sprintf("Account %s is already a participant of channel %s", cp.AccountId, cp.ChannelId))
		}
		cp.Status = ChannelParticipant_STATUS_ACTIVE
		if err := cp.Update(); err != nil {
			return nil, err
		}
		return cp, nil
	}

	cp.Status = ChannelParticipant_STATUS_ACTIVE

	if err := cp.Create(); err != nil {
		return nil, err
	}

	return cp, nil
}

func (c *Channel) RemoveParticipant(participantId int64) error {
	if c.Id == 0 {
		return errors.New("Channel Id is not set")
	}

	cp := NewChannelParticipant()
	cp.ChannelId = c.Id
	cp.AccountId = participantId

	err := cp.FetchParticipant()
	// if user is not in this channel, do nothing
	if err == gorm.RecordNotFound {
		return nil
	}

	if err != nil {
		return err
	}

	if cp.Status == ChannelParticipant_STATUS_LEFT {
		return nil
	}

	cp.Status = ChannelParticipant_STATUS_LEFT
	if err := cp.Update(); err != nil {
		return err
	}

	return nil
}

func (c *Channel) FetchParticipantIds() ([]int64, error) {
	var participantIds []int64

	if c.Id == 0 {
		return participantIds, errors.New("Channel Id is not set")
	}

	query := &bongo.Query{
		Selector: map[string]interface{}{
			"channel_id": c.Id,
			"status":     ChannelParticipant_STATUS_ACTIVE,
		},
		Pluck: "account_id",
	}

	cp := NewChannelParticipant()
	err := cp.Some(&participantIds, query)
	if err != nil {
		return nil, err
	}

	return participantIds, nil
}

func (c *Channel) AddMessage(messageId int64) (*ChannelMessageList, error) {
	if c.Id == 0 {
		return nil, errors.New("Channel Id is not set")
	}

	cml := NewChannelMessageList()
	cml.ChannelId = c.Id
	cml.MessageId = messageId

	if err := cml.Create(); err != nil {
		return nil, err
	}

	return cml, nil
}

func (c *Channel) List(q *Query) ([]Channel, error) {

	var channels []Channel

	query := &bongo.Query{
		Selector: map[string]interface{}{
			"group_name": q.GroupName,
		},
	}

	err := bongo.B.Some(c, &channels, query)
	if err != nil {
		return nil, err
	}

	return channels, nil
}
