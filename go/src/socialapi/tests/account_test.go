package main

import (
	"koding/db/mongodb/modelhelper"
	"socialapi/models"
	"socialapi/rest"
	"socialapi/workers/common/tests"
	"testing"

	"gopkg.in/mgo.v2/bson"

	"github.com/koding/runner"
	. "github.com/smartystreets/goconvey/convey"
)

var AccountOldId = bson.NewObjectId()
var AccountOldId2 = bson.NewObjectId()
var AccountOldId3 = bson.NewObjectId()
var AccountOldId4 = bson.NewObjectId()
var AccountOldId5 = bson.NewObjectId()

func TestAccountCreation(t *testing.T) {
	Convey("while  creating account", t, func() {
		Convey("First Create User", func() {

			Convey("Should error if you dont pass old id", func() {
				account := models.NewAccount()
				account, err := rest.CreateAccount(account)
				So(err, ShouldNotBeNil)
				So(account, ShouldBeNil)
			})

			Convey("Should not error if you pass old id", func() {
				account := models.NewAccount()
				account.OldId = AccountOldId.Hex()
				account, err := rest.CreateAccount(account)
				So(err, ShouldBeNil)
				So(account, ShouldNotBeNil)
			})

			Convey("Should return same id with same old id", func() {
				// first create account
				account := models.NewAccount()
				account.OldId = AccountOldId.Hex()
				firstAccount, err := rest.CreateAccount(account)
				So(err, ShouldBeNil)
				So(firstAccount, ShouldNotBeNil)

				// then try to create it again
				secondAccount, err := rest.CreateAccount(account)
				So(err, ShouldBeNil)
				So(secondAccount, ShouldNotBeNil)

				So(firstAccount.Id, ShouldEqual, secondAccount.Id)
			})
		})
	})
}

func TestCheckOwnership(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("accounts can own things", t, func() {
			account, _, groupName := models.CreateRandomGroupDataWithChecks()

			ses, err := modelhelper.FetchOrCreateSession(account.Nick, groupName)
			tests.ResultedWithNoErrorCheck(ses, err)

			tedsAccount, err := models.CreateAccountInBothDbsWithNick("ted")
			tests.ResultedWithNoErrorCheck(tedsAccount, err)

			bobsChannel, err := rest.CreateChannelByGroupNameAndType(account.Id, groupName, models.Channel_TYPE_DEFAULT, ses.ClientId)
			So(err, ShouldBeNil)

			Convey("it should say when an account owns a channel", func() {
				isOwner, err := rest.CheckChannelOwnership(account, bobsChannel)
				So(err, ShouldBeNil)
				So(isOwner, ShouldBeTrue)
			})

			Convey("it should say when an account doesn't own a channel", func() {
				isOwner, err := rest.CheckChannelOwnership(tedsAccount, bobsChannel)
				So(err, ShouldBeNil)
				So(isOwner, ShouldBeFalse)
			})
		})
	})
}

func TestAccountGroupChannels(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("While fetching account activity count in profile page", t, func() {
			account, _, groupName := models.CreateRandomGroupDataWithChecks()

			ses, err := modelhelper.FetchOrCreateSession(account.Nick, groupName)
			So(err, ShouldBeNil)
			So(ses, ShouldNotBeNil)

			channel, err := rest.CreateChannelByGroupNameAndType(account.Id, groupName, models.Channel_TYPE_DEFAULT, ses.ClientId)
			So(err, ShouldBeNil)
			So(channel, ShouldNotBeNil)

			cc, err := rest.FetchAccountChannels(ses.ClientId)
			So(err, ShouldBeNil)
			ccs := []models.ChannelContainer(*cc)
			So(len(ccs), ShouldEqual, 2)
		})
	})
}
