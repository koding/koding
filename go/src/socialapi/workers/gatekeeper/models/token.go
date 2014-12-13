package models

import (
	"fmt"
	"socialapi/config"
	"socialapi/workers/helper"
	"time"

	"github.com/koding/redis"
	"github.com/nu7hatch/gouuid"
)

const (
	CachePrefix = "realtime"
)

var (
	ErrAccountIdNotSet = fmt.Errorf("account old id is not set")
	ErrTokenNotSet     = fmt.Errorf("token is not set")
	ErrNotFound        = fmt.Errorf("not found")
	ErrInvalidToken    = fmt.Errorf("invalid token")
	// TODO configurable
	TTL = 24 * time.Hour
)

type Token struct {
	AccountId int64
	Token     string
	Expires   time.Time
}

func NewToken() *Token {
	return &Token{}
}

// Authenticate checks if token is valid for the given account
func (t *Token) Authenticate() error {
	if t.AccountId == 0 {
		return ErrAccountIdNotSet
	}
	if t.Token == "" {
		return ErrTokenNotSet
	}

	token, err := t.get()
	if err != nil {
		return err
	}

	if token.Token != t.Token {
		return ErrInvalidToken
	}

	return nil
}

// GetOrCreate gets token of the given account, and creates if it
// does not exist
func (t *Token) GetOrCreate() (*Token, error) {
	if t.AccountId == 0 {
		return nil, ErrAccountIdNotSet
	}

	token, err := t.get()
	if err == nil {
		return token, nil
	}

	if err != ErrNotFound {
		return nil, err
	}

	return t.create()
}

func (t *Token) get() (*Token, error) {
	redisConn := helper.MustGetRedisConn()
	uuid4, err := redisConn.Get(t.prepareKey())
	if err == redis.ErrNil {
		return nil, ErrNotFound
	}

	if err != nil {
		return nil, err
	}

	ttl, err := redisConn.TTL(t.prepareKey())
	if err != nil {
		return nil, err
	}
	expires := time.Now().Round(time.Second).Add(ttl)

	token := NewToken()
	token.AccountId = t.AccountId
	token.Token = uuid4
	token.Expires = expires

	return token, nil
}

// Create creates a token with a random uuid and constant TTL
func (t *Token) create() (*Token, error) {
	uuid4, err := t.generateUUID()
	if err != nil {
		return nil, err
	}

	token := NewToken()
	token.Token = uuid4
	token.AccountId = t.AccountId

	if err := token.save(); err != nil {
		return nil, err
	}
	expires := time.Now().Round(time.Second).Add(TTL)
	token.Expires = expires

	return token, nil
}

// generateUUID creates a version 4 random uuid
func (t *Token) generateUUID() (string, error) {
	uuid4, err := uuid.NewV4()
	if err != nil {
		return "", err
	}

	return uuid4.String(), nil
}

// save creates the token with default TTL value
func (t *Token) save() error {
	if t.Token == "" {
		return ErrTokenNotSet
	}

	redisConn := helper.MustGetRedisConn()
	key := t.prepareKey()

	return redisConn.Setex(key, TTL, t.Token)
}

func (t *Token) prepareKey() string {
	return fmt.Sprintf("%s:%s:account-%d",
		config.MustGet().Environment,
		CachePrefix,
		t.AccountId,
	)
}
