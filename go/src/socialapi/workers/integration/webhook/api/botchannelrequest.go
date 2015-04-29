package api

import (
	"socialapi/models"

	"github.com/koding/bongo"
)

type BotChannelRequest struct {
	GroupName string `json:"groupName"`
	Username  string `json:"username"`
}

func (b *BotChannelRequest) validate() error {
	if b.GroupName == "" {
		return ErrGroupNotSet
	}

	if b.Username == "" {
		return ErrUsernameNotSet
	}

	return nil
}

func (b *BotChannelRequest) verifyAccount() (*models.Account, error) {

	// fetch account id
	acc, err := models.Cache.Account.ByNick(b.Username)
	if err == bongo.RecordNotFound {
		return nil, ErrAccountNotFound
	}

	if err != nil {
		return nil, err
	}

	return acc, nil
}

func (b *BotChannelRequest) verifyGroup() (*models.Channel, error) {
	c, err := models.Cache.Channel.ByGroupName(b.GroupName)
	if err == bongo.RecordNotFound {
		return nil, ErrGroupNotFound
	}

	if err != nil {
		return nil, err
	}

	return c, nil
}
