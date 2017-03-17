package models

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/request"
	"strings"

	"github.com/hashicorp/go-multierror"
	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
	mgo "gopkg.in/mgo.v2"
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

	// ShareLocation is a setting for users on socialapi
	Settings gorm.Hstore `json:"settings"`

	// Token is used for authentication purposes, this data should not be shared
	// with other clients/accounts
	Token string `json:"-"`
}

func ValidateAccount(a *Account) error {
	if a.OldId == "" {
		return ErrOldIdIsNotSet
	}

	if strings.Contains(a.Nick, "guest-") {
		return ErrGuestsAreNotAllowed
	}
	return nil
}

func (a *Account) IsShareLocationEnabled() bool {
	if a.Settings == nil {
		return false
	}
	shareLocation, ok := a.Settings["shareLocation"]
	if !ok || shareLocation == nil {
		return false
	}

	return *shareLocation == "true"
}

// Tests are done.
func (a *Account) FetchOrCreate() error {
	if err := ValidateAccount(a); err != nil {
		return err
	}

	selector := map[string]interface{}{
		"old_id": a.OldId,
	}

	err := a.One(bongo.NewQS(selector))
	// first check if the err is not found err
	if err != bongo.RecordNotFound {
		return err
	}

	if a.Nick == "" {
		return ErrNickIsNotSet
	}

	// if we got here it means we have an obsolete account in the db, remove it.
	if err := a.ByNick(a.Nick); err != bongo.RecordNotFound {
		if err := a.DeleteIfNotInMongo(); err != nil {
			return err
		}
	}

	return a.Create()
}

func (a *Account) FetchChannels(q *request.Query) ([]Channel, error) {
	cp := NewChannelParticipant()
	// fetch channel ids
	cids, err := cp.FetchParticipatedTypedChannelIds(a, q)
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

// TO-DO
// Control functions and remove ?
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

// TO-DO
// Control functions and remove ?
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
		return nil, ErrAccountIdIsNotSet
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

// FetchChannel fetchs the channel of the account
//
// Channel_TYPE_GROUP as parameter returns error , in the tests!!!!
// TO-DO, other types dont return error
//
// Tests are done
func (a *Account) FetchChannel(channelType string) (*Channel, error) {
	if a.Id == 0 {
		return nil, ErrAccountIdIsNotSet
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

// Tests are done.
func (a *Account) ByNick(nick string) error {
	if nick == "" {
		return ErrNickIsNotSet
	}

	selector := map[string]interface{}{
		"nick": nick,
	}

	return a.One(bongo.NewQS(selector))
}

func (a *Account) ByOldId(oldId string) error {
	if oldId == "" {
		return ErrOldIdIsNotSet
	}

	selector := map[string]interface{}{
		"old_id": oldId,
	}

	return a.One(bongo.NewQS(selector))
}

// Tests are done.
func (a *Account) CreateFollowingFeedChannel() (*Channel, error) {
	if a.Id == 0 {
		return nil, ErrAccountIdIsNotSet
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
		Table(cp.BongoName()).
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

// FetchAccountById gives all information about account by id of account
//
// Tests are done.
func FetchAccountById(accountId int64) (*Account, error) {
	a := NewAccount()
	if err := a.ById(accountId); err != nil {
		return nil, err
	}

	return a, nil
}

// FetchOldIdsByAccountIds takes slice as parameter
//
// Tests are done
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

	for _, acc := range accounts {
		// The append built-in function appends elements to the end of a slice
		oldIds = append(oldIds, acc.OldId)
	}

	return oldIds, nil
}

func FetchAccountsByNicks(nicks []string) ([]Account, error) {
	var accounts []Account

	if len(nicks) == 0 {
		return accounts, nil
	}

	a := NewAccount()
	res := bongo.B.DB.
		Table(a.BongoName()).
		Where("nick in (?)", nicks).Find(&accounts)

	if err := bongo.CheckErr(res); err != nil {
		return nil, err
	}

	return accounts, nil
}

//
//
// USE BELOW FUNCTION TO DELETE ACCOUNT FROM POSTGRE THAT NON-EXISTING ACCOUNTS INSIDE MONGODB
//
//

func (a *Account) DeleteIfNotInMongo() error {
	if a.OldId == "" {
		return ErrOldIdIsNotSet
	}

	_, err := modelhelper.GetAccountById(a.OldId)
	if err != mgo.ErrNotFound {
		return err
	}

	query := fmt.Sprintf("DELETE FROM %s WHERE account_id = ?", NewChannelParticipant().BongoName())
	if err := bongo.B.DB.Exec(query, a.Id).Error; err != nil {
		return err
	}

	query = fmt.Sprintf("DELETE FROM %s WHERE creator_id = ?", NewChannel().BongoName())
	if err := bongo.B.DB.Exec(query, a.Id).Error; err != nil {
		return err
	}

	return a.Delete()
}

// FetchAccountsWithBongoOffset fetches the accounts with bongo
func FetchAccountsWithBongoOffset(limit, offset int) ([]Account, error) {
	acc := &Account{}
	var accounts []Account
	query := &bongo.Query{
		Pagination: *bongo.NewPagination(limit, offset),
	}
	if err := acc.Some(&accounts, query); err != nil {
		return nil, err
	}

	return accounts, nil
}

// DeleteDiffedDBAccounts
func DeleteDiffedDBAccounts() error {
	var errs *multierror.Error

	limit := 100
	offset := 0
	for {
		counter := 0
		accs, err := FetchAccountsWithBongoOffset(limit, offset)
		if err != nil {
			errs = multierror.Append(errs, err)
		}
		for _, acc := range accs {
			// don't remove 'bot' or 'admin' accounts
			if acc.Nick == "bot" || acc.Nick == "admin" {
				continue
			}

			if err := acc.DeleteIfNotInMongo(); err != nil {
				errs = multierror.Append(errs, err)
				counter++
			}
		}

		// we increase offset number
		// if delete all fetched accounts we should not increase offset
		// if we increase offset, some data will be skiped without checking
		// scenario;
		// fetch with; limit:100 offset: 0 && delete all fetched accounts
		// after this if we fetch with limit:100 offset:100
		// some data will be skipped (the data that limit:100 offset:0).
		offset += limit - counter

		// This check provide us to break the loop if there is no data left
		// that need to be processed
		// fetch tolerance is limit/2, is accounts count is less than limited number then break.
		if len(accs) < (limit / 2) {
			break
		}
	}

	return errs.ErrorOrNil()

}
