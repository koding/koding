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
	ModifiedAt time.Time
}

const (
	ACTIVE int = iota
	LEFT
	REQUEST_PENDING
)

func NewChannelParticipant() *ChannelParticipant {
	now := time.Now().UTC()
	return &ChannelParticipant{
		ChannelId:  1,
		AccountId:  1,
		Status:     ACTIVE,
		LastSeenAt: now,
		CreatedAt:  now,
		ModifiedAt: now,
	}
}

func (c *ChannelParticipant) Create() error {
	now := time.Now().UTC()
	// created at shouldnt be updated
	c.LastSeenAt = now
	c.CreatedAt = now
	c.ModifiedAt = now
	return c.Save()
}

func (c *ChannelParticipant) Update() error {
	if c.Id == 0 {
		return errors.New("ChannelParticipant id is not set")
	}

	now := time.Now().UTC()
	c.LastSeenAt = now
	c.ModifiedAt = now

	return c.Save()
}

func (c *ChannelParticipant) Save() error {
	if err := db.DB.Save(c).Error; err != nil {
		return err
	}
	return nil
}

func (c *ChannelParticipant) Delete() error {
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
