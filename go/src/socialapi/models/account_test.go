package models

import (
	"socialapi/workers/common/tests"
	"strings"
	"testing"

	"github.com/koding/bongo"
	"github.com/koding/runner"
	"gopkg.in/mgo.v2/bson"

	. "github.com/smartystreets/goconvey/convey"
)

func TestAccountNewAccount(t *testing.T) {
	Convey("while testing new account", t, func() {
		Convey("Function call should return account", func() {
			So(NewAccount(), ShouldNotBeNil)
		})
	})
}

func TestAccountGetId(t *testing.T) {
	Convey("while testing get id", t, func() {
		Convey("Initialized struct ", func() {
			Convey("should return given id", func() {
				a := Account{Id: 42}
				So(a.GetId(), ShouldEqual, 42)
			})

			Convey("Uninitialized struct ", func() {
				Convey("should return 0", func() {
					So(NewAccount().GetId(), ShouldEqual, 0)
				})
				So(NewAccount(), ShouldNotBeNil)
			})
		})
	})
}

func TestAccountFetchOrCreate(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {

		Convey("while fetching or creating account", t, func() {
			Convey("it should have old id", func() {
				a := NewAccount()
				err := a.FetchOrCreate()
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, ErrOldIdIsNotSet)
			})

			Convey("it should have error if nick contains guest-", func() {
				a := NewAccount()
				a.OldId = "oldestId"
				a.Nick = "guest-test"
				err := a.FetchOrCreate()
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, ErrGuestsAreNotAllowed)
			})

			Convey("it should not have error if required fields are exist", func() {
				a := NewAccount()
				a.OldId = "oldIdOfAccount"
				a.Nick = "WhatANick"
				err := a.FetchOrCreate()
				So(err, ShouldBeNil)
			})

		})
	})
}

func TestAccountFetchAccountById(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {

		Convey("while fetching an account by id", t, func() {
			Convey("it should not have error while fething", func() {
				// create account
				acc := CreateAccountWithTest()
				So(acc.Create(), ShouldBeNil)

				// fetch the account by id of account
				fa, err := FetchAccountById(acc.Id)
				// error should be nil
				// means that fetching is done successfully
				So(err, ShouldBeNil)
				// account in the db should equal to fetched account
				So(fa.Id, ShouldEqual, acc.Id)
				So(fa.OldId, ShouldEqual, acc.OldId)
				So(fa.Nick, ShouldEqual, acc.Nick)
			})

			Convey("it should have error if record is not found", func() {
				// init account
				a := NewAccount()
				a.Id = 12345
				a.OldId = "oldIdOfAccount"
				a.Nick = "WhatANick"

				// this account id is not exist
				_, err := FetchAccountById(a.Id)
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, bongo.RecordNotFound)

			})
		})
	})
}

func TestAccountByNick(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {

		Convey("while fetching an account by nick", t, func() {
			Convey("it should not have error while fething", func() {
				// create account
				acc := CreateAccountWithTest()
				So(acc.Create(), ShouldBeNil)

				fa := NewAccount()

				// fetch the account by nick of account
				err := fa.ByNick(acc.Nick)
				// error should be nil
				// means that fetching is done successfully
				So(err, ShouldBeNil)
				// account in the db should be equal to fetched account
				So(fa.Id, ShouldEqual, acc.Id)
				So(fa.OldId, ShouldEqual, acc.OldId)
				So(fa.Nick, ShouldEqual, acc.Nick)
			})

			Convey("it should have error if nick is not set", func() {
				fa := NewAccount()
				err := fa.ByNick("")
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, ErrNickIsNotSet)
			})

			Convey("it should have error if record is not found", func() {
				fa := NewAccount()
				err := fa.ByNick("foobarzaa")
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, bongo.RecordNotFound)
			})
		})
	})
}

func TestAccountFetchOldIdsByAccountIds(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {

		Convey("while fetching Old Ids by account ids", t, func() {
			Convey("it should have account id (ids of length) more than zero", func() {
				acc := []int64{}
				foi, err := FetchOldIdsByAccountIds(acc)
				So(err, ShouldBeNil)
				So(foi, ShouldBeEmpty)
			})

			Convey("it should not have error if account is exist in db", func() {
				// create account
				acc := CreateAccountWithTest()
				So(acc.Create(), ShouldBeNil)
				// we created slice to send to FetchOldIdsByAccountIds as argument
				idd := []int64{acc.Id}

				// FetchOldIdsByAccountIds returns as slice
				foi, err := FetchOldIdsByAccountIds(idd)
				So(err, ShouldBeNil)
				// used shouldcontain because foi is a slice
				So(foi, ShouldContain, acc.OldId)

			})

			Convey("it should append successfully", func() {
				acc1 := NewAccount()
				acc1.OldId = bson.NewObjectId().Hex()
				acc1.Nick = bson.NewObjectId().Hex()
				So(acc1.Create(), ShouldBeNil)

				acc2 := NewAccount()
				acc2.OldId = bson.NewObjectId().Hex()
				acc2.Nick = bson.NewObjectId().Hex()
				So(acc2.Create(), ShouldBeNil)

				idd := []int64{acc1.Id, acc2.Id}
				old := []string{acc1.OldId, acc2.OldId}

				foi, err := FetchOldIdsByAccountIds(idd)
				So(err, ShouldBeNil)
				So(foi[1], ShouldEqual, old[1])

			})
		})
	})
}

func TestAccountCreateFollowingFeedChannel(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {

		Convey("while creating feed channel", t, func() {
			Convey("it should have account id", func() {
				// create account
				acc := NewAccount()

				_, err := acc.CreateFollowingFeedChannel()
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, ErrAccountIdIsNotSet)
			})

			Convey("it should have creator id as account id", func() {
				// create account
				acc := CreateAccountWithTest()
				So(acc.Create(), ShouldBeNil)

				cff, err := acc.CreateFollowingFeedChannel()
				So(err, ShouldBeNil)
				So(cff.CreatorId, ShouldEqual, acc.Id)
			})

			Convey("it should have channel name as required", func() {
				// create account
				acc := NewAccount()
				acc.OldId = bson.NewObjectId().Hex()
				acc.Nick = bson.NewObjectId().Hex()
				So(acc.Create(), ShouldBeNil)

				cff, err := acc.CreateFollowingFeedChannel()
				So(err, ShouldBeNil)
				So(strings.HasSuffix(cff.Name, "-FollowingFeedChannel"), ShouldBeTrue)
			})

			Convey("it should have group name as Channel_KODING_NAME", func() {
				// create account
				acc := CreateAccountWithTest()
				So(acc.Create(), ShouldBeNil)

				cff, err := acc.CreateFollowingFeedChannel()
				So(err, ShouldBeNil)
				So(cff.GroupName, ShouldEqual, Channel_KODING_NAME)
			})

			Convey("it should have purpose as Following Feed for me", func() {
				// create account
				acc := CreateAccountWithTest()
				So(acc.Create(), ShouldBeNil)

				cff, err := acc.CreateFollowingFeedChannel()
				So(err, ShouldBeNil)
				So(cff.Purpose, ShouldEqual, "Following Feed for Me")
			})

			Convey("it should have type constant as Channel_TYPE_FOLLOWERS", func() {
				// create account
				acc := CreateAccountWithTest()
				So(acc.Create(), ShouldBeNil)

				cff, err := acc.CreateFollowingFeedChannel()
				So(err, ShouldBeNil)
				So(cff.TypeConstant, ShouldEqual, Channel_TYPE_FOLLOWERS)
			})
		})
	})
}

func TestAccountFetchChannel(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {

		Convey("while fetching channel", t, func() {
			Convey("it should have account id", func() {
				acc := NewAccount()

				_, err := acc.FetchChannel("ChannelType")
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, ErrAccountIdIsNotSet)
			})

			Convey("it should have error if channel is not exist", func() {
				acc := NewAccount()
				acc.Id = 35135

				_, err := acc.FetchChannel(Channel_TYPE_GROUP)
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, bongo.RecordNotFound)
			})

			Convey("it should not have error if channel type is exist", func() {
				acc := CreateAccountWithTest()
				c := CreateTypedChannelWithTest(acc.Id, Channel_TYPE_TOPIC)

				cha, err := acc.FetchChannel(Channel_TYPE_TOPIC)
				So(err, ShouldBeNil)
				So(cha.TypeConstant, ShouldEqual, c.TypeConstant)
			})
		})
	})
}

func TestAccountsByNick(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {

		Convey("while fetching account ids by nicknames", t, func() {
			Convey("it should not fetch any accounts when nicknames are empty", func() {
				nicknames := make([]string, 0)

				accounts, err := FetchAccountsByNicks(nicknames)
				So(err, ShouldBeNil)
				So(len(accounts), ShouldEqual, 0)
			})

			Convey("it should fetch accounts by nicknames", func() {
				acc1 := CreateAccountWithTest()
				acc2 := CreateAccountWithTest()
				nicknames := make([]string, 0)
				nicknames = append(nicknames, acc1.Nick, acc2.Nick)
				accounts, err := FetchAccountsByNicks(nicknames)
				So(err, ShouldBeNil)
				So(accounts, ShouldNotBeNil)
				So(len(accounts), ShouldEqual, 2)
			})
		})
	})
}
