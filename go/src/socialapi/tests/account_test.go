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
			account, groupChannel, groupName := models.CreateRandomGroupDataWithChecks()

			ses, err := modelhelper.FetchOrCreateSession(account.Nick, groupName)
			tests.ResultedWithNoErrorCheck(ses, err)

			tedsAccount, err := models.CreateAccountInBothDbsWithNick("ted")
			tests.ResultedWithNoErrorCheck(tedsAccount, err)

			bobsPost, err := rest.CreatePost(groupChannel.Id, ses.ClientId)
			tests.ResultedWithNoErrorCheck(bobsPost, err)

			Convey("it should say when an account owns a post", func() {
				isOwner, err := rest.CheckPostOwnership(account, bobsPost)
				So(err, ShouldBeNil)
				So(isOwner, ShouldBeTrue)
			})

			Convey("it should say when an account doesn't own a post", func() {
				isOwner, err := rest.CheckPostOwnership(tedsAccount, bobsPost)
				So(err, ShouldBeNil)
				So(isOwner, ShouldBeFalse)
			})

			bobsChannel, err := rest.CreateChannelByGroupNameAndType(account.Id, groupName, models.Channel_TYPE_TOPIC, ses.ClientId)
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

func TestAccountFetchProfile(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("while fetching account activities in profile page", t, func() {
			account, _, groupName := models.CreateRandomGroupDataWithChecks()

			ses, err := modelhelper.FetchOrCreateSession(account.Nick, groupName)
			So(err, ShouldBeNil)
			So(ses, ShouldNotBeNil)

			// create channel
			channel, err := rest.CreateChannelByGroupNameAndType(account.Id, groupName, models.Channel_TYPE_GROUP, ses.ClientId)
			So(err, ShouldBeNil)
			So(channel, ShouldNotBeNil)

			// create message
			post, err := rest.CreatePost(channel.Id, ses.ClientId)
			So(err, ShouldBeNil)
			So(post, ShouldNotBeNil)

			Convey("it should list latest posts when there is no time interval in query", func() {
				cmc, err := rest.FetchAccountActivities(account.Id, ses.ClientId)
				So(err, ShouldBeNil)
				So(len(cmc), ShouldEqual, 1)
				So(cmc[0].Message.Body, ShouldEqual, post.Body)
			})
		})
	})
}

func TestAccountProfilePostCount(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("While fetching account activity count in profile page", t, func() {
			account, _, groupName := models.CreateRandomGroupDataWithChecks()

			ses, err := modelhelper.FetchOrCreateSession(account.Nick, groupName)
			So(err, ShouldBeNil)
			So(ses, ShouldNotBeNil)

			// create channel
			channel, err := rest.CreateChannelByGroupNameAndType(account.Id, groupName, models.Channel_TYPE_GROUP, ses.ClientId)
			So(err, ShouldBeNil)
			So(channel, ShouldNotBeNil)

			// create message
			post, err := rest.CreatePost(channel.Id, ses.ClientId)
			So(err, ShouldBeNil)
			So(post, ShouldNotBeNil)

			Convey("it should fetch all post count when they are not troll", func() {
				cr, err := rest.FetchAccountActivityCount(account.Id, ses.ClientId)
				So(err, ShouldBeNil)
				So(cr, ShouldNotBeNil)
				So(cr.TotalCount, ShouldEqual, 1)

				post, err := rest.CreatePost(channel.Id, ses.ClientId)
				So(err, ShouldBeNil)
				So(post, ShouldNotBeNil)

				cr, err = rest.FetchAccountActivityCount(account.Id, ses.ClientId)
				So(err, ShouldBeNil)
				So(cr, ShouldNotBeNil)
				So(cr.TotalCount, ShouldEqual, 2)
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

			channel, err := rest.CreateChannelByGroupNameAndType(account.Id, groupName, models.Channel_TYPE_TOPIC, ses.ClientId)
			So(err, ShouldBeNil)
			So(channel, ShouldNotBeNil)

			cc, err := rest.FetchAccountChannels(ses.ClientId)
			So(err, ShouldBeNil)
			ccs := []models.ChannelContainer(*cc)
			So(len(ccs), ShouldEqual, 2)
		})
	})
}
