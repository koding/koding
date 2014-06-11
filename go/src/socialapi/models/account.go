package models

import (
	"errors"
	"fmt"

	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
)

type Account struct {
	// unique id of the account
	Id int64 `json:"id,string"`

	// old id of the account, which is originally
	// perisisted in mongo
	// mongo ids has 24 char
	OldId string `json:"oldId"      sql:"NOT NULL;UNIQUE;TYPE:VARCHAR(24);"`

	// unique account nicknames
	Nick string `json:"nick"        sql:"NOT NULL;UNIQUE;TYPE:VARCHAR(25);`
}

func NewAccount() *Account {
	return &Account{}
}

func (a Account) GetId() int64 {
	return a.Id
}

func (a Account) TableName() string {
	return "api.account"
}

func (a *Account) One(q *bongo.Query) error {
	return bongo.B.One(a, a, q)
}

func (a *Account) ById(id int64) error {
	return bongo.B.ById(a, id)
}

func (a *Account) FetchOrCreate() error {
	if a.OldId == "" {
		return errors.New("old id is not set")
	}

	if a.Nick == "" {
		return errors.New("nick is not set")
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
	if err == gorm.RecordNotFound {
		if err := a.Create(); err != nil {
			return err
		}
		return nil
	}

	return err
}

func (a *Account) Create() error {
	if a.OldId == "" {
		return errors.New("old id is not set")
	}

	return bongo.B.Create(a)
}

func (a *Account) Some(data interface{}, q *bongo.Query) error {
	return bongo.B.Some(a, data, q)
}

func (a *Account) FetchChannels(q *Query) ([]Channel, error) {
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

	if err == gorm.RecordNotFound {
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
		"creator_id":    a.Id,
		"type_constant": channelType,
	}

	if err := c.One(bongo.NewQS(selector)); err != nil {
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
	c.TypeConstant = Channel_TYPE_FOLLOWERS
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

func FetchOldIdByAccountId(accountId int64) (string, error) {

	a := NewAccount()
	var data []string
	q := &bongo.Query{
		Selector: map[string]interface{}{
			"id": accountId,
		},
		Pluck:      "old_id",
		Pagination: *bongo.NewPagination(1, 0),
	}
	err := a.Some(&data, q)
	if err != nil {
		return "", err
	}

	if len(data) == 0 {
		return "", nil
	}

	return data[0], nil
}

func FetchOldIdsByAccountIds(accountIds []int64) ([]string, error) {
	var oldIds []string
	if len(accountIds) == 0 {
		return make([]string, 0), nil
	}

	res := bongo.B.DB.
		Table(Account{}.TableName()).
		Where("id IN (?)", accountIds).
		Pluck("old_id", &oldIds)

	if err := bongo.CheckErr(res); err != nil {
		return nil, err
	}

	if len(oldIds) == 0 {
		return make([]string, 0), nil
	}

	return oldIds, nil
}
