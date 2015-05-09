package realtime

import (
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/models"
	"socialapi/rest"
	"testing"

	"github.com/koding/runner"

	"labix.org/v2/mgo/bson"

	. "github.com/smartystreets/goconvey/convey"
)

func TestAddRemoveChannelParticipant(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	controller := &Controller{}
	Convey("While testing add/remove channel participants", t, func() {
		pe := &models.ParticipantEvent{}

		groupName := models.RandomGroupName()

		account := models.NewAccount()
		account.OldId = bson.NewObjectId().Hex()
		account, err := rest.CreateAccount(account)
		So(err, ShouldBeNil)

		// fetch admin's session
		ses, err := models.FetchOrCreateSession(account.Nick, groupName)
		So(err, ShouldBeNil)
		So(ses, ShouldNotBeNil)

		Convey("When user follows/unfollows a topic, they must be notified", func() {
			topicChannel, err := rest.CreateChannelByGroupNameAndType(
				account.Id,
				groupName,
				models.Channel_TYPE_TOPIC,
				ses.ClientId,
			)
			So(err, ShouldBeNil)
			So(topicChannel, ShouldNotBeNil)
			pe.Id = topicChannel.Id
			cp := &models.ChannelParticipant{}
			cp.AccountId = account.Id

			pe.Participants = []*models.ChannelParticipant{cp}

			participants, err := controller.fetchNotifiedParticipantIds(topicChannel, pe, AddedToChannelEventName)
			So(err, ShouldBeNil)
			So(len(participants), ShouldEqual, 1)
			So(participants[0], ShouldEqual, account.Id)

			participants, err = controller.fetchNotifiedParticipantIds(topicChannel, pe, RemovedFromChannelEventName)
			So(err, ShouldBeNil)
			So(len(participants), ShouldEqual, 1)
			So(participants[0], ShouldEqual, account.Id)
		})

		Convey("When user joins a topic, only participant user must be notified", func() {
			privateChannel, err := rest.CreateChannelByGroupNameAndType(
				account.Id,
				groupName,
				models.Channel_TYPE_PRIVATE_MESSAGE,
				ses.ClientId,
			)
			So(err, ShouldBeNil)
			So(privateChannel, ShouldNotBeNil)
			pe.Id = privateChannel.Id
			cp := &models.ChannelParticipant{}
			cp.AccountId = account.Id

			pe.Participants = []*models.ChannelParticipant{cp}

			participants, err := controller.fetchNotifiedParticipantIds(privateChannel, pe, AddedToChannelEventName)
			So(err, ShouldBeNil)
			So(len(participants), ShouldEqual, 1)
			So(participants[0], ShouldEqual, account.Id)
		})

		Convey("When user leaves a topic, all participants musts be notified", func() {
			privateChannel, err := rest.CreateChannelByGroupNameAndType(
				account.Id,
				groupName,
				models.Channel_TYPE_PRIVATE_MESSAGE,
				ses.ClientId,
			)
			So(err, ShouldBeNil)
			So(privateChannel, ShouldNotBeNil)
			pe.Id = privateChannel.Id
			cp := &models.ChannelParticipant{}
			cp.AccountId = account.Id

			pe.Participants = []*models.ChannelParticipant{cp}

			participants, err := controller.fetchNotifiedParticipantIds(privateChannel, pe, RemovedFromChannelEventName)
			So(err, ShouldBeNil)
			So(len(participants), ShouldEqual, 2)
			So(participants[0], ShouldEqual, account.Id)
		})
	})
}
