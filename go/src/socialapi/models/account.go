package models

import (
	"errors"
	"fmt"
	"socialapi/request"

	"github.com/koding/bongo"
)

type Account struct {
	// unique id of the account
	Id int64 `json:"id,string"`

	// old id of the account, which is originally
	// perisisted in mongo
	// mongo ids has 24 char
	OldId string `json:"oldId"      sql:"NOT NULL;UNIQUE;TYPE:VARCHAR(24);"`

	// IsTroll
	IsTroll bool `json:"isTroll"`

	// unique account nicknames
	Nick string `json:"nick"        sql:"NOT NULL;UNIQUE;TYPE:VARCHAR(25);"`
}

func (a *Account) FetchOrCreate() error {
	if a.OldId == "" {
		return errors.New("old id is not set")
	}

	selector := map[string]interface{}{
		"old_id": a.OldId,
	}

	err := a.One(bongo.NewQS(selector))
	// if we dont get any error
	// it means we found the record in our db
	if err == nil {
		return nil
	}

	// first check if the err is not found err
	if err == bongo.RecordNotFound {
		if a.Nick == "" {
			return errors.New("nick is not set")
		}

		if err := a.Create(); err != nil {
			return err
		}
		return nil
	}

	return err
}

func (a *Account) FetchChannels(q *request.Query) ([]Channel, error) {
	cp := NewChannelParticipant()
	// fetch channel ids
	cids, err := cp.FetchParticipatedChannelIds(a, q)
	if err != nil {
		return nil, err
	}

	// fetch channels by their ids
	channels, err := NewChannel().FetchByIds(cids)
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

	if err == bongo.RecordNotFound {
		c, err := a.CreateFollowingFeedChannel()
		if err != nil {
			return nil, err
		}
		return c.AddParticipant(targetId)
	}

	return nil, err
}

func (a *Account) Unfollow(targetId int64) (*Account, error) {
	c, err := a.FetchChannel(Channel_TYPE_FOLLOWERS)
	if err != nil {
		return nil, err
	}

	return a, c.RemoveParticipant(targetId)
}

func (a *Account) FetchFollowerIds(q *request.Query) ([]int64, error) {
	followerIds := make([]int64, 0)
	if a.Id == 0 {
		return nil, errors.New(
			"account id is not set for FetchFollowerChannelIds function ",
		)
	}

	c, err := a.FetchChannel(Channel_TYPE_FOLLOWERS)
	if err != nil {
		return followerIds, err
	}

	participants, err := c.FetchParticipantIds(q)
	if err != nil {
		return followerIds, err
	}

	return participants, nil
}

func (a *Account) FetchChannel(channelType string) (*Channel, error) {
	if a.Id == 0 {
		return nil, errors.New("account id is not set")
	}

	c := NewChannel()
	selector := map[string]interface{}{
		"creator_id":    a.Id,
		"type_constant": channelType,
	}

	if err := c.One(bongo.NewQS(selector)); err != nil {
		return nil, err
	}

	return c, nil
}

func (a *Account) MarkAsTroll() error {
	if a.Id == 0 {
		return errors.New("account id is not set")
	}

	if err := a.ById(a.Id); err != nil {
		return err
	}

	// do not try to mark twice
	if a.IsTroll {
		return fmt.Errorf("account is already a troll %d", a.Id)
	}

	a.IsTroll = true
	if err := a.Update(); err != nil {
		return err
	}

	if err := bongo.B.PublishEvent("marked_as_troll", a); err != nil {
		return err
	}

	return nil
}

func (a *Account) UnMarkAsTroll() error {
	if a.Id == 0 {
		return errors.New("account id is not set")
	}

	if err := a.ById(a.Id); err != nil {
		return err
	}

	// do not try to un-mark twice
	if !a.IsTroll {
		return fmt.Errorf("account is not a troll %d", a.Id)
	}

	a.IsTroll = false
	if err := a.Update(); err != nil {
		return err
	}

	if err := bongo.B.PublishEvent("unmarked_as_troll", a); err != nil {
		return err
	}

	return nil
}

func (a *Account) CreateFollowingFeedChannel() (*Channel, error) {
	if a.Id == 0 {
		return nil, errors.New("account id is not set")
	}

	c := NewChannel()
	c.CreatorId = a.Id
	c.Name = fmt.Sprintf("%d-FollowingFeedChannel", a.Id)
	c.GroupName = Channel_KODING_NAME
	c.Purpose = "Following Feed for Me"
	c.TypeConstant = Channel_TYPE_FOLLOWERS
	if err := c.Create(); err != nil {
		return nil, err
	}

	return c, nil
}

func (a *Account) FetchFollowerChannelIds(q *request.Query) ([]int64, error) {

	followerIds, err := a.FetchFollowerIds(q)
	if err != nil {
		return nil, err
	}

	cp := NewChannelParticipant()
	var channelIds []int64
	res := bongo.B.DB.
		Table(cp.TableName()).
		Where(
		"creator_id IN (?) and type_constant = ?",
		followerIds,
		Channel_TYPE_FOLLOWINGFEED,
	).Find(&channelIds)

	if err := bongo.CheckErr(res); err != nil {
		return nil, err
	}

	return channelIds, nil
}

func FetchAccountById(accountId int64) (*Account, error) {
	a := NewAccount()
	if err := a.ById(accountId); err != nil {
		return nil, err
	}

	return a, nil
}

func FetchOldIdsByAccountIds(accountIds []int64) ([]string, error) {
	oldIds := make([]string, 0)

	if len(accountIds) == 0 {
		return oldIds, nil
	}

	var accounts []Account
	account := Account{}

	err := bongo.B.FetchByIds(account, &accounts, accountIds)
	if err != nil {
		return oldIds, nil
	}

	for _, account := range accounts {
		oldIds = append(oldIds, account.OldId)
	}

	return oldIds, nil
}
