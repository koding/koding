package main

import (
	"koding/db/mongodb/modelhelper"
	"math/rand"
	"socialapi/models"
	"socialapi/request"
	"socialapi/rest"
	"socialapi/workers/common/tests"
	"testing"

	"github.com/koding/runner"
	"gopkg.in/mgo.v2/bson"

	. "github.com/smartystreets/goconvey/convey"
)

func TestGroupChannel(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("while  testing pinned activity channel", t, func() {
			groupName := models.RandomGroupName()

			account, err := models.CreateAccountInBothDbs()
			So(err, ShouldBeNil)

			ses, err := modelhelper.FetchOrCreateSession(account.Nick, groupName)
			So(err, ShouldBeNil)
			So(ses, ShouldNotBeNil)

			models.CreateTypedGroupedChannelWithTest(
				account.Id,
				models.Channel_TYPE_GROUP,
				groupName,
			)

			Convey("channel should be there", func() {
				channel1, err := rest.CreateChannelByGroupNameAndType(
					account.Id,
					groupName,
					models.Channel_TYPE_GROUP,
					ses.ClientId,
				)
				So(err, ShouldBeNil)
				So(channel1, ShouldNotBeNil)

				channel2, err := rest.CreateChannelByGroupNameAndType(
					account.Id,
					groupName,
					models.Channel_TYPE_GROUP,
					ses.ClientId,
				)
				So(err, ShouldBeNil)
				So(channel2, ShouldNotBeNil)
			})

			Convey("group channel should be shown before announcement", func() {
				account, err := models.CreateAccountInBothDbs()
				So(err, ShouldBeNil)

				ses, err := modelhelper.FetchOrCreateSession(account.Nick, groupName)
				So(err, ShouldBeNil)
				So(ses, ShouldNotBeNil)

				_, err = rest.CreateChannelByGroupNameAndType(
					account.Id,
					groupName,
					models.Channel_TYPE_GROUP,
					ses.ClientId,
				)
				So(err, ShouldBeNil)

				_, err = rest.CreateChannelByGroupNameAndType(
					account.Id,
					groupName,
					models.Channel_TYPE_ANNOUNCEMENT,
					ses.ClientId,
				)
				So(err, ShouldBeNil)
				channels, err := rest.FetchChannelsByQuery(account.Id, &request.Query{
					GroupName: groupName,
					Type:      models.Channel_TYPE_GROUP,
				},
					ses.ClientId,
				)
				So(err, ShouldBeNil)
				So(len(channels), ShouldEqual, 2)
				So(channels[0].TypeConstant, ShouldEqual, models.Channel_TYPE_GROUP)
				So(channels[1].TypeConstant, ShouldEqual, models.Channel_TYPE_ANNOUNCEMENT)

			})

			Convey("owner should be able to update it", func() {
				channel1, err := rest.CreateChannelByGroupNameAndType(
					account.Id,
					groupName,
					models.Channel_TYPE_GROUP,
					ses.ClientId,
				)
				So(err, ShouldBeNil)
				So(channel1, ShouldNotBeNil)
				// fetching channel returns creator id
				_, err = rest.UpdateChannel(channel1, ses.ClientId)
				So(err, ShouldBeNil)
			})

			Convey("owner should only be able to update name and purpose of the channel", nil)

			Convey("normal user should be able to update it if and only if user is creator or participant", func() {
				channel1, err := rest.CreateChannelByGroupNameAndType(
					account.Id,
					groupName,
					models.Channel_TYPE_GROUP,
					ses.ClientId,
				)
				So(err, ShouldBeNil)
				So(channel1, ShouldNotBeNil)

				anotherAccount := models.NewAccount()
				anotherAccount.OldId = bson.NewObjectId().Hex()
				anotherAccount, err = rest.CreateAccount(anotherAccount)

				So(err, ShouldBeNil)
				So(account, ShouldNotBeNil)

				ses, err := modelhelper.FetchOrCreateSession(anotherAccount.Nick, groupName)
				So(err, ShouldBeNil)
				So(ses, ShouldNotBeNil)

				_, err = rest.UpdateChannel(channel1, ses.ClientId)
				So(err, ShouldBeNil)
			})

			Convey("owner cant delete it", func() {
				channel1, err := rest.CreateChannelByGroupNameAndType(
					account.Id,
					groupName,
					models.Channel_TYPE_GROUP,
					ses.ClientId,
				)
				So(err, ShouldBeNil)
				So(channel1, ShouldNotBeNil)

				err = rest.DeleteChannel(account.Id, channel1.Id)
				So(err, ShouldNotBeNil)
			})

			Convey("normal user cant delete it", func() {
				channel1, err := rest.CreateChannelByGroupNameAndType(
					account.Id,
					groupName,
					models.Channel_TYPE_GROUP,
					ses.ClientId,
				)
				So(err, ShouldBeNil)
				So(channel1, ShouldNotBeNil)

				err = rest.DeleteChannel(rand.Int63(), channel1.Id)
				So(err, ShouldNotBeNil)
			})

			Convey("member can post status update", nil)

			Convey("non-member can not post status update", nil)
		})
	})
}

func TestGroupChannelFirstCreation(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("While creating the new group channel for the first time", t, func() {
			Convey("user should be able to create group channel", func() {
				acc, err := models.CreateAccountInBothDbs()
				So(err, ShouldBeNil)

				groupName := models.RandomGroupName()
				ses, err := modelhelper.FetchOrCreateSession(acc.Nick, groupName)
				So(err, ShouldBeNil)
				So(ses, ShouldNotBeNil)

				channel, err := rest.CreateChannelByGroupNameAndType(
					acc.Id,
					groupName,
					models.Channel_TYPE_GROUP,
					ses.ClientId,
				)

				So(err, ShouldBeNil)
				So(channel.GroupName, ShouldEqual, groupName)
			})
		})
	})
}
