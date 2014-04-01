package models

import (
	"errors"
	"fmt"

	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
)

type Account struct {
	// unique id of the account
	Id int64 `json:"id"`
	// old id of the account, which is coming from mongo
	OldId string `json:"oldId"`
}

func NewAccount() *Account {
	return &Account{}
}

func (a *Account) GetId() int64 {
	return a.Id
}

func (a *Account) TableName() string {
	return "account"
}

func (a *Account) One(selector map[string]interface{}) error {
	return bongo.B.One(a, a, selector)
}

func (a *Account) FetchOrCreate() error {
	if a.OldId == "" {
		return errors.New("old id is not set")
	}

	selector := map[string]interface{}{
		"old_id": a.OldId,
	}

	err := a.One(selector)
	if err == gorm.RecordNotFound {
		if err := a.Create(); err != nil {
			return err
		}
		return nil
	}
	if err != nil {
		return err
	}

	return nil
}

func (a *Account) Create() error {
	if a.OldId == "" {
		return errors.New("old id is not set")
	}
	return bongo.B.Create(a)
}

func (a *Account) FetchChannels(q *Query) ([]Channel, error) {
	cp := NewChannelParticipant()
	// fetch channel ids
	cids, err := cp.FetchParticipatedChannelIds(a)
	if err != nil {
		return nil, err
	}

	// fetch channels by their ids
	c := NewChannel()
	channels, err := c.FetchByIds(cids)
	if err != nil {
		return nil, err
	}

	return channels, nil
}

func (a *Account) Follow(targetId int64) (*ChannelParticipant, error) {
	c, err := a.FetchChannel(Channel_TYPE_FOLLOWERS)
	if err == nil {
		return c.AddParticipant(targetId)
	}

	if err == gorm.RecordNotFound {
		c, err := a.CreateFollowingFeedChannel()
		if err != nil {
			return nil, err
		}
		return c.AddParticipant(targetId)
	}
	return nil, err
}

func (a *Account) Unfollow(targetId int64) error {
	c, err := a.FetchChannel(Channel_TYPE_FOLLOWERS)
	if err != nil {
		fmt.Println(1, err)
		return err
	}
	fmt.Println(2)

	return c.RemoveParticipant(targetId)
}

func (a *Account) FetchFollowerIds() ([]int64, error) {
	followerIds := make([]int64, 0)
	if a.Id == 0 {
		return nil, errors.New(
			"Account id is not set for FetchFollowerChannelIds function ",
		)
	}

	c, err := a.FetchChannel(Channel_TYPE_FOLLOWERS)
	if err != nil {
		return followerIds, err
	}

	participants, err := c.FetchParticipantIds()
	if err != nil {
		return followerIds, err
	}

	return participants, nil
}

func (a *Account) FetchChannel(channelType string) (*Channel, error) {
	if a.Id == 0 {
		return nil, errors.New("Account id is not set")
	}

	c := NewChannel()
	selector := map[string]interface{}{
		"creator_id": a.Id,
		"type":       channelType,
	}

	if err := c.One(selector); err != nil {
		return nil, err
	}

	return c, nil
}

func (a *Account) CreateFollowingFeedChannel() (*Channel, error) {
	if a.Id == 0 {
		return nil, errors.New("Account id is not set")
	}

	c := NewChannel()
	c.CreatorId = a.Id
	c.Name = fmt.Sprintf("%d-FollowingFeedChannel", a.Id)
	c.GroupName = Channel_KODING_NAME
	c.Purpose = "Following Feed for Me"
	c.Type = Channel_TYPE_FOLLOWERS
	if err := c.Create(); err != nil {
		return nil, err
	}

	return c, nil
}

func (a *Account) FetchFollowerChannelIds() ([]int64, error) {

	followerIds, err := a.FetchFollowerIds()
	if err != nil {
		return nil, err
	}

	cp := NewChannelParticipant()
	var channelIds []int64
	err = bongo.B.DB.
		Table(cp.TableName()).
		Where(
		"creator_id IN (?) and type = ?",
		followerIds,
		Channel_TYPE_FOLLOWINGFEED,
	).Find(&channelIds).Error

	if err != nil {
		return nil, err
	}

	return channelIds, nil
}
