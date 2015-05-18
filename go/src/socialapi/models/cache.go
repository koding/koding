package models

import (
	"encoding/json"
	"fmt"
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"

	"socialapi/request"
	"strconv"

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
			id:    cache.NewLRU(cacheSize),
		},
		Session: &SessionCache{
			session: cache.NewLRU(cacheSize),
		},
		Channel: &ChannelCache{
			id:        cache.NewLRU(cacheSize),
			groupName: cache.NewLRU(cacheSize),
		},
		Message: &MessageCache{
			id: cache.NewLRU(cacheSize),
		},
	}
}

type StaticCache struct {
	Account *AccountCache
	Session *SessionCache
	Channel *ChannelCache
	Message *MessageCache
}

//////////////// Account Cache ////////////////////
type AccountCache struct {
	oldId cache.Cache
	nick  cache.Cache
	id    cache.Cache
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

func (a *AccountCache) ById(id int64) (*Account, error) {
	data, err := a.id.Get(strconv.FormatInt(id, 10))
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
	if err := account.ById(id); err != nil {
		return nil, err
	}

	if err := a.SetToCache(account); err != nil {
		return nil, err
	}

	return account, nil
}

func (a *AccountCache) ByOldId(oldId string) (*Account, error) {
	data, err := a.oldId.Get(oldId)
	if err != nil && err != cache.ErrNotFound {
		return nil, err
	}

	if err == nil {
		acc, ok := data.(*Account)
		if ok {
			return acc, nil
		}
	}

	acc := NewAccount()
	if err := acc.ByOldId(oldId); err != nil {
		return nil, err
	}

	if err := a.SetToCache(acc); err != nil {
		return nil, err
	}

	return acc, nil
}

func (a *AccountCache) SetToCache(acc *Account) error {
	if err := a.nick.Set(acc.Nick, acc); err != nil {
		return err
	}

	if err := a.oldId.Set(acc.OldId, acc); err != nil {
		return err
	}

	if err := a.id.Set(strconv.FormatInt(acc.Id, 10), acc); err != nil {
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

//////////////// Channel Cache ////////////////////
type ChannelCache struct {
	id        cache.Cache
	groupName cache.Cache
}

func (c *ChannelCache) ById(id int64) (*Channel, error) {
	data, err := c.id.Get(strconv.FormatInt(id, 10))
	if err != nil && err != cache.ErrNotFound {
		return nil, err
	}

	if err == nil {
		ch, ok := data.(*Channel)
		if ok {
			return ch, nil
		}
	}

	ch := NewChannel()
	if err := ch.ById(id); err != nil {
		return nil, err
	}

	if err := c.SetToCache(ch); err != nil {
		return nil, err
	}

	return ch, nil
}

func (c *ChannelCache) ByGroupName(name string) (*Channel, error) {
	data, err := c.groupName.Get(name)
	if err != nil && err != cache.ErrNotFound {
		return nil, err
	}

	if err == nil {
		ch, ok := data.(*Channel)
		if ok {
			return ch, nil
		}
	}

	ch := NewChannel()
	if err := ch.FetchPublicChannel(name); err != nil {
		return nil, err
	}

	if err := c.SetToCache(ch); err != nil {
		return nil, err
	}

	return ch, nil
}

func (c *ChannelCache) SetToCache(ch *Channel) error {

	if err := c.id.Set(strconv.FormatInt(ch.Id, 10), ch); err != nil {
		return err
	}

	if ch.TypeConstant != Channel_TYPE_GROUP {
		return nil
	}

	if err := c.groupName.Set(ch.GroupName, ch); err != nil {
		return err
	}

	return nil
}

//////////////// Message Cache ////////////////////
type MessageCache struct {
	id cache.Cache
}

func (m *MessageCache) ById(id int64) (*ChannelMessage, error) {
	data, err := m.id.Get(strconv.FormatInt(id, 10))
	if err != nil && err != cache.ErrNotFound {
		return nil, err
	}

	if err == nil {
		acc, ok := data.(*ChannelMessage)
		if ok {
			return acc, nil
		}
	}

	message := NewChannelMessage()
	if err := message.ById(id); err != nil {
		return nil, err
	}

	if err := m.SetToCache(message); err != nil {
		return nil, err
	}

	return message, nil
}

func (m *MessageCache) SetToCache(cm *ChannelMessage) error {
	if err := m.id.Set(strconv.FormatInt(cm.Id, 10), cm); err != nil {
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
		acc, err := Cache.Account.ById(id)
		if err != nil {
			return oldIds, err
		}

		oldIds[i] = acc.OldId
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

	Cache.Account.SetToCache(a)
}
