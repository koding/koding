package main

import (
	"koding/db/mongodb/modelhelper"
	"math/rand"
	"socialapi/config"
	"socialapi/models"
	"socialapi/request"
	"socialapi/rest"
	"testing"

	"github.com/koding/runner"
	"labix.org/v2/mgo/bson"

	. "github.com/smartystreets/goconvey/convey"
)

func TestGroupChannel(t *testing.T) {

	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	Convey("while  testing pinned activity channel", t, func() {
		groupName := models.RandomGroupName()

		account, err := models.CreateAccountInBothDbs()
		So(err, ShouldBeNil)

		ses, err := models.FetchOrCreateSession(account.Nick, groupName)
		So(err, ShouldBeNil)
		So(ses, ShouldNotBeNil)

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
			})
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

		Convey("normal user should not be able to update it", func() {
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

			ses, err := models.FetchOrCreateSession(anotherAccount.Nick, groupName)
			So(err, ShouldBeNil)
			So(ses, ShouldNotBeNil)

			_, err = rest.UpdateChannel(channel1, ses.ClientId)
			So(err, ShouldNotBeNil)
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
}
