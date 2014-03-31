package models

import (
	"errors"
	"time"

	"github.com/koding/bongo"
)

// todo Scope function for this struct
// in order not to fetch passive accounts
type ChannelParticipant struct {
	// unique identifier of the channel
	Id int64 `json:"id"`

	// Id of the channel
	ChannelId int64 `json:"channelId"`

	// Id of the account
	AccountId int64 `json:"accountId"`

	// Status of the participant in the channel
	Status string `json:"status"`

	// date of the user's last access to regarding channel
	LastSeenAt time.Time `json:"lastSeenAt"`

	// Creation date of the channel channel participant
	CreatedAt time.Time `json:"createdAt"`

	// Modification date of the channel participant's status
	UpdatedAt time.Time `json:"updatedAt"`
}

// here is why i did this not-so-good constants
// https://code.google.com/p/go/issues/detail?id=359
const (
	ChannelParticipant_STATUS_ACTIVE          = "active"
	ChannelParticipant_STATUS_LEFT            = "left"
	ChannelParticipant_STATUS_REQUEST_PENDING = "requestPending"
)

func NewChannelParticipant() *ChannelParticipant {
	return &ChannelParticipant{}
}

func (c *ChannelParticipant) GetId() int64 {
	return c.Id
}

func (c *ChannelParticipant) TableName() string {
	return "channel_participant"
}

func (c *ChannelParticipant) Self() bongo.Modellable {
	return c
}

func (c *ChannelParticipant) BeforeSave() {
	c.LastSeenAt = time.Now().UTC()
}

func (c *ChannelParticipant) BeforeUpdate() {
	c.LastSeenAt = time.Now().UTC()
}

func (c *ChannelParticipant) Create() error {
	return bongo.B.Create(c)
}

func (c *ChannelParticipant) Update() error {
	return bongo.B.Update(c)
}

func (c *ChannelParticipant) Some(data interface{}, rest ...map[string]interface{}) error {
	return bongo.B.Some(c, data, rest...)
}

func (c *ChannelParticipant) FetchParticipant() error {
	if c.ChannelId == 0 {
		return errors.New("ChannelId is not set")
	}

	if c.AccountId == 0 {
		return errors.New("AccountId is not set")
	}

	selector := map[string]interface{}{
		"channel_id": c.ChannelId,
		"account_id": c.AccountId,
		// "status":     ChannelParticipant_STATUS_ACTIVE,
	}

	err := bongo.B.One(c, c, selector)
	if err != nil {
		return err
	}

	return nil
}

func (c *ChannelParticipant) FetchUnreadCount() (int, error) {
	cml := NewChannelMessageList()
	return cml.UnreadCount(c)
}

func (c *ChannelParticipant) Delete() error {
	return bongo.B.UpdatePartial(c,
		bongo.Partial{
			"account_id": c.AccountId,
			"channel_id": c.ChannelId,
		},
		bongo.Partial{
			"status": ChannelParticipant_STATUS_LEFT,
		},
	)
}

func (c *ChannelParticipant) List() ([]ChannelParticipant, error) {
	var participants []ChannelParticipant

	if c.ChannelId == 0 {
		return participants, errors.New("ChannelId is not set")
	}

	selector := map[string]interface{}{
		"channel_id": c.ChannelId,
		"status":     ChannelParticipant_STATUS_ACTIVE,
	}

	err := bongo.B.Some(c, &participants, selector)
	if err != nil {
		return nil, err
	}

	return participants, nil
}

func (c *ChannelParticipant) FetchParticipatedChannelIds(a *Account) ([]int64, error) {

	if a.Id == 0 {
		return nil, errors.New("Account.Id is not set")
	}

	var channelIds []int64

	if err := bongo.B.DB.Table(c.TableName()).
		Order("created_at desc").
		Where("account_id = ?", a.Id).
		Pluck("channel_id", &channelIds).
		Error; err != nil {
		return nil, err
	}

	return channelIds, nil
}
