package models

import (
	"fmt"
	"socialapi/config"
	"socialapi/workers/common/runner"
	"socialapi/workers/helper"
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"

	"github.com/koding/redis"
)

func initialize(t *testing.T) *redis.RedisSession {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("Could not initialize runner: %s", err)
	}

	return helper.MustInitRedisConn(r.Conf)
}

func TestPrepareCacheKey(t *testing.T) {
	initialize(t)
	Convey("it should be able to prepare cache key", t, func() {
		t := NewToken()
		t.AccountId = 3
		key := t.prepareKey()
		env := config.MustGet().Environment
		So(key, ShouldEqual, fmt.Sprintf("%s:realtime:account-3", env))
	})
}

func TestTokenPersist(t *testing.T) {
	redisConn := initialize(t)
	Convey("While saving a token to redis", t, func() {
		t := NewToken()
		t.AccountId = 3
		Convey("it should return error when token is not set", func() {
			err := t.save()
			So(err, ShouldEqual, ErrTokenNotSet)
		})
		Convey("it should be able to save it", func() {
			t.Token = "1234"
			err := t.save()
			So(err, ShouldBeNil)

			value, err := redisConn.Get(t.prepareKey())
			So(err, ShouldBeNil)
			So(value, ShouldEqual, t.Token)
		})

		Reset(func() {
			_, err := redisConn.Del(t.prepareKey())
			So(err, ShouldBeNil)
		})
	})

}

func TestTokenCreate(t *testing.T) {
	redisConn := initialize(t)
	Convey("While creating a new token", t, func() {
		t := NewToken()
		t.AccountId = 3
		token, err := t.create()
		So(err, ShouldBeNil)
		So(token, ShouldNotBeNil)
		So(token.AccountId, ShouldEqual, 3)
		So(token.Token, ShouldNotEqual, "")
		So(token.Expires.Equal(time.Now().Add(TTL).Round(time.Second)), ShouldBeTrue)

		Reset(func() {
			_, err := redisConn.Del(t.prepareKey())
			So(err, ShouldBeNil)
		})
	})
}

func TestTokenGet(t *testing.T) {
	redisConn := initialize(t)
	Convey("while fetching the new token", t, func() {
		t := NewToken()
		t.AccountId = 3
		Convey("it should return error when token does not exist", func() {
			_, err := t.get()
			So(err, ShouldEqual, ErrNotFound)
		})
		Convey("it should return token if it exists", func() {
			_, err := t.create()
			So(err, ShouldBeNil)

			token, err := t.get()
			So(err, ShouldBeNil)
			So(token.Token, ShouldNotEqual, "")
			So(token.AccountId, ShouldEqual, t.AccountId)
			So(token.Expires.Equal(time.Now().Add(TTL).Round(time.Second)), ShouldBeTrue)
		})

		Reset(func() {
			_, err := redisConn.Del(t.prepareKey())
			So(err, ShouldBeNil)
		})
	})
}

func TestTokenGetOrCreate(t *testing.T) {
	redisConn := initialize(t)
	Convey("when get or create token is called", t, func() {
		t := NewToken()
		Convey("it should return error when account id is not set", func() {
			_, err := t.GetOrCreate()
			So(err, ShouldEqual, ErrAccountIdNotSet)
		})
		Convey("it should return a token when account id is set", func() {
			t.AccountId = 3
			token, err := t.GetOrCreate()
			So(err, ShouldBeNil)
			So(token.AccountId, ShouldEqual, t.AccountId)
			So(token.Token, ShouldNotEqual, "")
			So(token.Expires.After(time.Now()), ShouldBeTrue)
		})

		Reset(func() {
			_, err := redisConn.Del(t.prepareKey())
			So(err, ShouldBeNil)
		})
	})
}

func TestTokenAuthenticate(t *testing.T) {
	redisConn := initialize(t)
	Convey("when authenticate is called", t, func() {
		t := NewToken()
		Convey("it should return error when token or account id is not set", func() {
			err := t.Authenticate()
			So(err, ShouldEqual, ErrAccountIdNotSet)
			t.AccountId = 3
			err = t.Authenticate()
			So(err, ShouldEqual, ErrTokenNotSet)
		})
		Convey("it should return error if token does not exist", func() {
			t.AccountId = 3
			t.Token = "1234"
			err := t.Authenticate()
			So(err, ShouldEqual, ErrNotFound)
		})

		Convey("it should authenticate if it matches with existing token", func() {
			t.AccountId = 3
			token, err := t.create()
			So(err, ShouldBeNil)

			t.Token = "1234"
			err = t.Authenticate()
			So(err, ShouldEqual, ErrInvalidToken)

			t.Token = token.Token
			err = t.Authenticate()
			So(err, ShouldBeNil)
		})
		Reset(func() {
			_, err := redisConn.Del(t.prepareKey())
			So(err, ShouldBeNil)
		})
	})
}
