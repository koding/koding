package main

import (
	"koding/db/mongodb/modelhelper"
	"socialapi/models"
	"socialapi/rest"
	"socialapi/workers/common/tests"
	"testing"

	"github.com/koding/runner"
	. "github.com/smartystreets/goconvey/convey"
)

func TestFollowedTopics(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {

		Convey("While testing followed topics", t, func() {
			Convey("First Create User", func() {
				account, _, groupName := models.CreateRandomGroupDataWithChecks()

				ses, err := modelhelper.FetchOrCreateSession(account.Nick, groupName)
				So(err, ShouldBeNil)
				So(ses, ShouldNotBeNil)

				nonOwnerAccount := models.NewAccount()
				nonOwnerAccount.OldId = AccountOldId.Hex()
				nonOwnerAccount, err = rest.CreateAccount(nonOwnerAccount)
				So(err, ShouldBeNil)
				So(nonOwnerAccount, ShouldNotBeNil)

				topicChannel1, err := rest.CreateChannelByGroupNameAndType(
					account.Id,
					groupName,
					models.Channel_TYPE_TOPIC,
					ses.ClientId,
				)
				So(err, ShouldBeNil)

				topicChannel2, err := rest.CreateChannelByGroupNameAndType(
					account.Id,
					groupName,
					models.Channel_TYPE_TOPIC,
					ses.ClientId,
				)
				So(err, ShouldBeNil)

				Convey("user should be able to follow one topic", func() {
					channelParticipant, err := rest.AddChannelParticipant(topicChannel1.Id, ses.ClientId, account.Id)
					// there should be an err
					So(err, ShouldBeNil)
					// channel should be nil
					So(channelParticipant, ShouldNotBeNil)

					followedChannels, err := rest.FetchFollowedChannels(account.Id, ses.ClientId)
					So(err, ShouldBeNil)
					So(followedChannels, ShouldNotBeNil)
					So(len(followedChannels), ShouldBeGreaterThanOrEqualTo, 1)
				})

				Convey("user should be able to follow two topic", func() {
					channelParticipant, err := rest.AddChannelParticipant(topicChannel1.Id, ses.ClientId, account.Id)
					So(err, ShouldBeNil)
					So(channelParticipant, ShouldNotBeNil)

					channelParticipant, err = rest.AddChannelParticipant(topicChannel2.Id, ses.ClientId, account.Id)
					So(err, ShouldBeNil)
					So(channelParticipant, ShouldNotBeNil)

					followedChannels, err := rest.FetchFollowedChannels(account.Id, ses.ClientId)
					So(err, ShouldBeNil)
					So(followedChannels, ShouldNotBeNil)
					So(len(followedChannels), ShouldBeGreaterThanOrEqualTo, 2)
				})

				Convey("user should be participant of the followed topic", func() {
					channelParticipant, err := rest.AddChannelParticipant(topicChannel1.Id, ses.ClientId, account.Id)
					// there should be an err
					So(err, ShouldBeNil)
					// channel should be nil
					So(channelParticipant, ShouldNotBeNil)

					followedChannels, err := rest.FetchFollowedChannels(account.Id, ses.ClientId)
					So(err, ShouldBeNil)
					So(followedChannels, ShouldNotBeNil)
					So(len(followedChannels), ShouldBeGreaterThanOrEqualTo, 1)
					So(followedChannels[0].IsParticipant, ShouldBeTrue)
				})

				Convey("user should not be a participant of the un-followed topic", func() {
					channelParticipant, err := rest.AddChannelParticipant(topicChannel1.Id, ses.ClientId, account.Id)
					So(err, ShouldBeNil)
					So(channelParticipant, ShouldNotBeNil)

					followedChannels, err := rest.FetchFollowedChannels(account.Id, ses.ClientId)
					So(err, ShouldBeNil)
					So(followedChannels, ShouldNotBeNil)

					currentParticipatedChannelCount := len(followedChannels)
					channelParticipant, err = rest.DeleteChannelParticipant(topicChannel1.Id, ses.ClientId, account.Id)
					So(err, ShouldBeNil)
					So(channelParticipant, ShouldNotBeNil)

					followedChannels, err = rest.FetchFollowedChannels(account.Id, ses.ClientId)
					So(err, ShouldBeNil)
					So(followedChannels, ShouldNotBeNil)
					lastParticipatedChannelCount := len(followedChannels)

					So(currentParticipatedChannelCount-lastParticipatedChannelCount, ShouldEqual, 1)
				})

				Convey("participant count of the followed topic should be greater than 0", func() {
					channelParticipant, err := rest.AddChannelParticipant(topicChannel1.Id, ses.ClientId, account.Id)
					// there should be an err
					So(err, ShouldBeNil)
					// channel should be nil
					So(channelParticipant, ShouldNotBeNil)

					followedChannels, err := rest.FetchFollowedChannels(account.Id, ses.ClientId)
					So(err, ShouldBeNil)
					So(followedChannels, ShouldNotBeNil)
					So(len(followedChannels), ShouldBeGreaterThanOrEqualTo, 1)
					So(followedChannels[0].ParticipantCount, ShouldBeGreaterThanOrEqualTo, 1)
				})
			})
		})
	})
}
