package models

import (
	"encoding/json"
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"

	"socialapi/request"

	"github.com/koding/cache"
)

var Cache *StaticCache

var cacheSize = 10000

// later, this can be lazily init, after database connection established
func init() {
	Cache = &StaticCache{
		Account: &AccountCache{
			oldId: cache.NewLRU(cacheSize),
			nick:  cache.NewLRU(cacheSize),
		},
		Session: &SessionCache{
			session: cache.NewLRU(cacheSize),
		},
	}
}

type StaticCache struct {
	Account *AccountCache
	Session *SessionCache
}

//////////////// Account Cache ////////////////////
type AccountCache struct {
	oldId cache.Cache
	nick  cache.Cache
}

func (a *AccountCache) ByNick(nick string) (*Account, error) {
	data, err := a.nick.Get(nick)
	if err != nil && err != cache.ErrNotFound {
		return nil, err
	}

	if err == nil {
		acc, ok := data.(*Account)
		if ok {
			return acc, nil
		}
	}

	account := NewAccount()
	if err := account.ByNick(nick); err != nil {
		return nil, err
	}

	if err := a.SetToCache(account); err != nil {
		return nil, err
	}

	return account, nil
}

func (a *AccountCache) SetToCache(acc *Account) error {
	if err := a.nick.Set(acc.Nick, acc); err != nil {
		return err
	}

	if err := a.oldId.Set(acc.OldId, acc); err != nil {
		return err
	}
	return nil
}

//////////////// Session Cache ////////////////////
type SessionCache struct {
	session cache.Cache
}

func (s *SessionCache) ById(id string) (*mongomodels.Session, error) {
	data, err := s.session.Get(id)
	if err != nil && err != cache.ErrNotFound {
		return nil, err
	}

	if err == nil {
		ses, ok := data.(*mongomodels.Session)
		if ok {
			return ses, nil
		}
	}

	session, err := modelhelper.GetSession(id)
	if err != nil {
		return nil, err
	}

	if err := s.SetToCache(session); err != nil {
		return nil, err
	}

	return session, nil
}

func (s *SessionCache) SetToCache(ses *mongomodels.Session) error {
	if err := s.session.Set(ses.ClientId, ses); err != nil {
		return err
	}

	return nil
}

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
