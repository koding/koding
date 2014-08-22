package models

import (
	"socialapi/workers/common/runner"
	"testing"

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
			a := NewAccount()
			a.OldId = "oldIdOfAccount"
			a.Nick = "WhatANick"

			// this account id is not exist
			_, err := FetchAccountById(12345)
			So(err, ShouldNotBeNil)

		})

	})
}
