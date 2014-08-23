package models

import (
	"socialapi/workers/common/runner"
	"testing"

	"github.com/koding/bongo"
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
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

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
}

func TestAccountFetchAccountById(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("while fetching an account by id", t, func() {
		Convey("it should not have error while fething", func() {
			// create account
			acc := createAccountWithTest()
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
}

func TestAccountFetchOldIdsByAccountIds(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("while fetching Old Ids by account ids", t, func() {
		Convey("it should have account id (ids of length) more than zero", func() {
			acc := []int64{}
			foi, err := FetchOldIdsByAccountIds(acc)
			So(err, ShouldBeNil)
			So(foi, ShouldBeEmpty)
		})

		Convey("it should not have error if account is exist in db", func() {
			// create account
			acc := createAccountWithTest()
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
			acc1.Id = 1
			acc1.OldId = "11"
			acc1.Nick = "acc1"
			So(acc1.Create(), ShouldBeNil)

			acc2 := NewAccount()
			acc2.Id = 2
			acc2.OldId = "22"
			acc2.Nick = "acc2"
			So(acc2.Create(), ShouldBeNil)

			idd := []int64{acc1.Id, acc2.Id}
			old := []string{acc1.OldId, acc2.OldId}

			foi, err := FetchOldIdsByAccountIds(idd)
			So(err, ShouldBeNil)
			So(foi[1], ShouldEqual, old[1])

		})

	})
}

func TestAccountCreateFollowingFeedChannel(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

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
			acc := createAccountWithTest()
			So(acc.Create(), ShouldBeNil)

			cff, err := acc.CreateFollowingFeedChannel()
			So(err, ShouldBeNil)
			So(cff.CreatorId, ShouldEqual, acc.Id)
		})

		Convey("it should have channel name as required", func() {
			// create account
			acc := NewAccount()
			acc.Id = 1
			acc.OldId = "11"
			acc.Nick = "acc1"
			So(acc.Create(), ShouldBeNil)

			cff, err := acc.CreateFollowingFeedChannel()
			So(err, ShouldBeNil)
			So(cff.Name, ShouldEqual, "1-FollowingFeedChannel")
		})

		Convey("it should have group name as Channel_KODING_NAME", func() {
			// create account
			acc := createAccountWithTest()
			So(acc.Create(), ShouldBeNil)

			cff, err := acc.CreateFollowingFeedChannel()
			So(err, ShouldBeNil)
			So(cff.GroupName, ShouldEqual, Channel_KODING_NAME)
		})

		Convey("it should have purpose as Following Feed for me", func() {
			// create account
			acc := createAccountWithTest()
			So(acc.Create(), ShouldBeNil)

			cff, err := acc.CreateFollowingFeedChannel()
			So(err, ShouldBeNil)
			So(cff.Purpose, ShouldEqual, "Following Feed for Me")
		})

		Convey("it should have type constant as Channel_TYPE_FOLLOWERS", func() {
			// create account
			acc := createAccountWithTest()
			So(acc.Create(), ShouldBeNil)

			cff, err := acc.CreateFollowingFeedChannel()
			So(err, ShouldBeNil)
			So(cff.TypeConstant, ShouldEqual, Channel_TYPE_FOLLOWERS)
		})

	})
}
