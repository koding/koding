package realtime

import (
	"koding/db/mongodb/modelhelper"
	"socialapi/models"
	"socialapi/rest"
	"socialapi/workers/common/tests"
	"testing"

	"github.com/koding/runner"

	. "github.com/smartystreets/goconvey/convey"
)

func TestAddRemoveChannelParticipant(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		controller := &Controller{}
		Convey("While testing add/remove channel participants", t, func() {
			account := models.CreateAccountInBothDbsWithCheck()
			groupName := models.RandomGroupName()
			_ = models.CreateTypedGroupedChannelWithTest(
				account.Id,
				models.Channel_TYPE_GROUP,
				groupName,
			)

			// fetch admin's session
			ses, err := modelhelper.FetchOrCreateSession(account.Nick, groupName)
			So(err, ShouldBeNil)
			So(ses, ShouldNotBeNil)

			pe := &models.ParticipantEvent{}

			Convey("When user follows/unfollows a topic, they must be notified", func() {
				topicChannel, err := rest.CreateChannelByGroupNameAndType(
					account.Id,
					groupName,
					models.Channel_TYPE_TOPIC,
					ses.ClientId,
				)
				tests.ResultedWithNoErrorCheck(topicChannel, err)

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

				tests.ResultedWithNoErrorCheck(privateChannel, err)

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
				tests.ResultedWithNoErrorCheck(privateChannel, err)

				pe.Id = privateChannel.Id
				cp := &models.ChannelParticipant{}
				cp.AccountId = account.Id

				pe.Participants = []*models.ChannelParticipant{cp}

				participants, err := controller.fetchNotifiedParticipantIds(privateChannel, pe, RemovedFromChannelEventName)
				tests.ResultedWithNoErrorCheck(participants, err)

				So(len(participants), ShouldEqual, 2)
				So(participants[0], ShouldEqual, account.Id)
			})
		})
	})

}
