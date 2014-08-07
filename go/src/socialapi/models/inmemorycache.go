package models

import "fmt"

var (
	channelCache        map[int64]*Channel
	channelMessageCache map[int64]*ChannelMessage
	accountCache        map[int64]*Account
	oldAccountCache     map[string]int64
)

func init() {
	// those are not thread safe!!!!
	channelCache = make(map[int64]*Channel)
	channelMessageCache = make(map[int64]*ChannelMessage)
	accountCache = make(map[int64]*Account)
	oldAccountCache = make(map[string]int64)
}

/////////// ChannelMessage

func ChannelMessageById(id int64) (*ChannelMessage, error) {
	if channelMessage, ok := channelMessageCache[id]; ok {
		return channelMessage, nil
	}

	// todo add caching here
	c := NewChannelMessage()
	if err := c.ById(id); err != nil {
		return nil, err
	}

	// add channel to cache
	channelMessageCache[c.Id] = c

	return c, nil
}

/////////// Channel

// todo fix!!
// this will fail when a channel marked as troll
func ChannelById(id int64) (*Channel, error) {
	if channel, ok := channelCache[id]; ok {
		return channel, nil
	}

	// todo add caching here
	c := NewChannel()
	if err := c.ById(id); err != nil {
		return nil, err
	}

	// add channel to cache
	channelCache[c.Id] = c

	return c, nil
}

func ChannelsByIds(ids []int64) ([]*Channel, error) {
	channels := make([]*Channel, len(ids))
	if len(channels) == 0 {
		return channels, nil
	}

	for i, id := range ids {
		channel, err := ChannelById(id)
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

func FetchAccountFromCache(id int64) (*Account, error) {
	if a, ok := accountCache[id]; ok && a != nil {
		return a, nil
	}

	return ResetAccountCache(id)
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
