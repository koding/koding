package models

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"strconv"
	"time"

	"github.com/koding/cache"
)

var (
	channelCache     map[int64]*Channel
	accountCache     map[int64]*Account
	oldAccountCache  map[string]int64
	secretNamesCache cache.Cache
)

func init() {
	// those are not thread safe!!!!
	channelCache = make(map[int64]*Channel)
	accountCache = make(map[int64]*Account)
	oldAccountCache = make(map[string]int64)
	secretNamesCache = cache.NewMemoryWithTTL(time.Second * 10)
}

/////////// Channel

func ChannelsByIds(ids []int64) ([]*Channel, error) {
	channels := make([]*Channel, len(ids))
	if len(channels) == 0 {
		return channels, nil
	}

	for i, id := range ids {
		channel, err := Cache.Channel.ById(id)
		if err != nil {
			return channels, err
		}
		channels[i] = channel
	}

	return channels, nil
}

///// Account

func FetchAccountOldIdByIdFromCache(id int64) (string, error) {
	if a, ok := accountCache[id]; ok && a != nil {
		return a.OldId, nil
	}

	account, err := ResetAccountCache(id)
	if err != nil {
		return "", err
	}

	return account.OldId, nil
}

func ResetAccountCache(id int64) (*Account, error) {
	account, err := FetchAccountById(id)
	if err != nil {
		return nil, err
	}

	SetAccountToCache(account)

	return account, nil
}

func FetchAccountOldsIdByIdsFromCache(ids []int64) ([]string, error) {
	oldIds := make([]string, len(ids))
	if len(oldIds) == 0 {
		return oldIds, nil
	}

	for i, id := range ids {
		oldId, err := FetchAccountOldIdByIdFromCache(id)
		if err != nil {
			return oldIds, err
		}
		oldIds[i] = oldId
	}

	return oldIds, nil
}

func SetAccountToCache(a *Account) {
	if a == nil {
		return
	}

	if a.Id == 0 {
		fmt.Println("account id is empty")
		return
	}

	accountCache[a.Id] = a
}

func AccountIdByOldId(oldId, nick string) (int64, error) {
	if id, ok := oldAccountCache[oldId]; ok {
		return id, nil
	}

	a := NewAccount()
	a.OldId = oldId
	a.Nick = nick
	if err := a.FetchOrCreate(); err != nil {
		return 0, err
	}

	oldAccountCache[oldId] = a.Id

	return a.Id, nil
}

func FetchAccountIdByOldId(oldId string) int64 {
	id, ok := oldAccountCache[oldId]
	if !ok {
		return 0
	}

	return id
}

////// SecretNames /////

func SecretNamesByChannelId(channelId int64) ([]string, error) {
	key := strconv.FormatInt(channelId, 10)
	data, err := secretNamesCache.Get(key)
	if err == nil {
		if d, ok := data.([]string); ok {
			return d, nil
		}
	}

	c, err := Cache.Channel.ById(channelId)
	if err != nil {
		return nil, err
	}

	name := fmt.Sprintf(
		"socialapi-group-%s-type-%s-name-%s",
		c.GroupName,
		c.TypeConstant,
		c.Name,
	)

	names, err := modelhelper.FetchFlattenedSecretName(name)
	if err != nil {
		return nil, err
	}

	// set obtained data to cache
	secretNamesCache.Set(key, names)
	return names, nil
}
