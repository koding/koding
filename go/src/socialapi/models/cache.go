package models

import (
	"encoding/json"
	"socialapi/request"
)

func BuildChannelMessageContainer(id int64, query *request.Query) (*ChannelMessageContainer, error) {
	cm := NewChannelMessage()
	cm.Id = id
	if err := cm.ById(cm.Id); err != nil {
		return nil, err
	}

	cmc := NewChannelMessageContainer()
	cmc.PopulateWith(cm).SetGenerics(query)
	if cmc.Err != nil {
		return nil, cmc.Err
	}

	return cmc, nil
}

func CacheForChannelMessage(id int64) (string, error) {
	query := request.NewQuery().SetDefaults()
	// no need to add IsInteracted data into cache
	query.AddIsInteracted = false
	cmc, err := BuildChannelMessageContainer(id, query)
	d, err := json.Marshal(cmc)
	if err != nil {
		return "", err
	}

	return string(d), err
}

func BuildChannelContainer(id int64, query *request.Query) (*ChannelContainer, error) {
	c := NewChannel()
	c.Id = id
	if err := c.ById(c.Id); err != nil {
		return nil, err
	}

	cc := NewChannelContainer()
	cc.PopulateWith(*c, query.AccountId)

	return cc, cc.Err
}

func CacheForChannel(id int64) (string, error) {
	query := request.NewQuery().SetDefaults()
	cc, err := BuildChannelContainer(id, query)
	d, err := json.Marshal(cc)
	if err != nil {
		return "", err
	}

	return string(d), nil
}
