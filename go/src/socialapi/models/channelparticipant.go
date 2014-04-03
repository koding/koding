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
	ChannelId int64 `json:"channelId"              sql:"NOT NULL"`

	// Id of the account
	AccountId int64 `json:"accountId"              sql:"NOT NULL"`

	// Status of the participant in the channel
	StatusConstant string `json:"statusConstant"   sql:"NOT NULL;TYPE:VARCHAR(100);"`

	// date of the user's last access to regarding channel
	LastSeenAt time.Time `json:"lastSeenAt"        sql:"NOT NULL"`

	// Creation date of the channel channel participant
	CreatedAt time.Time `json:"createdAt"          sql:"NOT NULL"`

	// Modification date of the channel participant's status
	UpdatedAt time.Time `json:"updatedAt"          sql:"NOT NULL"`
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

func (c *ChannelParticipant) Some(data interface{}, q *bongo.Query) error {
	return bongo.B.Some(c, data, q)
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
		// "status_constant":     ChannelParticipant_STATUS_ACTIVE,
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
	selector := bongo.Partial{
		"account_id": c.AccountId,
		"channel_id": c.ChannelId,
	}
	if err := bongo.B.One(c, c, selector); err != nil {
		return err
	}

	return bongo.B.UpdatePartial(c,
		bongo.Partial{
			"status_constant": ChannelParticipant_STATUS_LEFT,
		},
	)
}

func (c *ChannelParticipant) List() ([]ChannelParticipant, error) {
	var participants []ChannelParticipant

	if c.ChannelId == 0 {
		return participants, errors.New("ChannelId is not set")
	}
	query := &bongo.Query{
		Selector: map[string]interface{}{
			"channel_id":      c.ChannelId,
			"status_constant": ChannelParticipant_STATUS_ACTIVE,
		},
	}

	err := bongo.B.Some(c, &participants, query)
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
