package models

import (
	"errors"
	"fmt"
	"socialapi/db"
	"time"
)

type ChannelParticipant struct {
	// unique identifier of the channel
	Id int64

	// Id of the channel
	ChannelId int64

	// Id of the account
	AccountId int64

	// Status of the participant in the channel
	Status int

	// date of the user's last access to regarding channel
	LastSeenAt time.Time

	// Creation date of the channel channel participant
	CreatedAt time.Time

	// Modification date of the channel participant's status
	UpdatedAt time.Time
}

const (
	ACTIVE int = iota
	LEFT
	REQUEST_PENDING
)

func NewChannelParticipant() *ChannelParticipant {
	return &ChannelParticipant{}
}

func (c *ChannelParticipant) BeforeSave() {
	c.LastSeenAt = time.Now().UTC()
}

func (c *ChannelParticipant) BeforeUpdate() {
	c.LastSeenAt = time.Now().UTC()
}

func (c *ChannelParticipant) Create() error {
	return c.Save()
}

func (c *ChannelParticipant) Update() error {
	if c.Id == 0 {
		return errors.New("ChannelParticipant id is not set")
	}

	return c.Save()
}

func (c *ChannelParticipant) Save() error {
	if err := Save(c); err != nil {
		return err
	}

	return nil
}

func (c *ChannelParticipant) Fetch() error {
	if c.AccountId == 0 {
		return errors.New("AccountId is not set")
	}

	if c.ChannelId == 0 {
		return errors.New("ChannelId is not set")
	}

	cp := NewChannelParticipant()
	err := db.DB.
		Where("account_id = ? and channel_id = ?", c.AccountId, c.ChannelId).
		Find(&cp).Error

	if err != nil {
		return err
	}

	// override channel participant
	c = cp
	return nil
}

func (c *ChannelParticipant) Delete() error {
	if err := c.Fetch(); err != nil {
		return err
	}
	c.Status = LEFT
	return c.Update()
}

func (c *ChannelParticipant) List() ([]ChannelParticipant, error) {
	var participants []ChannelParticipant

	if c.ChannelId == 0 {
		return participants, errors.New("ChannelId is not set")
	}

	// change this usage to a better one
	// we shouldnt use table name directly
	err := db.DB.Order("created_at desc").Table("channel_participant").Where(
		map[string]interface{}{
			"channel_id": c.ChannelId,
			"status":     ACTIVE,
		},
	).Find(&participants).Error

	fmt.Println(participants)
	return participants, err
}
