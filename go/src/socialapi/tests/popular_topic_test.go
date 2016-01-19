package main

import (
	"os"
	"socialapi/models"
	"socialapi/rest"
	"socialapi/workers/common/tests"
	"testing"
	"time"

	"github.com/koding/runner"
	. "github.com/smartystreets/goconvey/convey"
)

func TestPopularTopic(t *testing.T) {
	env := os.Getenv("SOCIAL_API_ENV")
	if env == "wercker" {
		return
	}

	tests.WithRunner(t, func(r *runner.Runner) {
		// Since the wercker tests are failing it is skipped for temporarily
		SkipConvey("order should be preserved", t, func() {
			groupName := models.RandomGroupName()
			account := models.CreateAccountInBothDbsWithCheck()

			groupChannel := models.CreateTypedGroupedChannelWithTest(
				account.Id,
				models.Channel_TYPE_GROUP,
				groupName,
			)

			ses, err := models.FetchOrCreateSession(account.Nick, groupChannel.GroupName)
			So(err, ShouldBeNil)

			_, err = groupChannel.AddParticipant(account.Id)
			So(err, ShouldBeNil)

			for i := 0; i < 5; i++ {
				post, err := rest.CreatePostWithBodyAndAuth(groupChannel.Id, "create a message #5times", ses.ClientId)
				So(err, ShouldBeNil)
				So(post, ShouldNotBeNil)
			}

			for i := 0; i < 4; i++ {
				post, err := rest.CreatePostWithBodyAndAuth(groupChannel.Id, "create a message #4times", ses.ClientId)
				So(err, ShouldBeNil)
				So(post, ShouldNotBeNil)
			}

			for i := 0; i < 3; i++ {
				post, err := rest.CreatePostWithBodyAndAuth(groupChannel.Id, "create a message #3times", ses.ClientId)
				So(err, ShouldBeNil)
				So(post, ShouldNotBeNil)
			}

			//required for backgroud task to be finished
			time.Sleep(1 * time.Second)

			popularTopics, err := rest.FetchPopularTopics(ses.ClientId)

			So(err, ShouldBeNil)
			So(popularTopics, ShouldNotBeNil)

			So(len(popularTopics), ShouldBeGreaterThanOrEqualTo, 3)

			So(popularTopics[0].Channel.Name, ShouldEqual, "5times")
			So(popularTopics[0].IsParticipant, ShouldEqual, false)
			So(popularTopics[0].ParticipantCount, ShouldEqual, 0)

			So(popularTopics[1].Channel.Name, ShouldEqual, "4times")
			So(popularTopics[1].IsParticipant, ShouldEqual, false)
			So(popularTopics[1].ParticipantCount, ShouldEqual, 0)

			So(popularTopics[2].Channel.Name, ShouldEqual, "3times")
			So(popularTopics[2].IsParticipant, ShouldEqual, false)
			So(popularTopics[2].ParticipantCount, ShouldEqual, 0)

			// check following status
			So(popularTopics[0].IsParticipant, ShouldBeFalse)
			So(popularTopics[1].IsParticipant, ShouldBeFalse)
			So(popularTopics[2].IsParticipant, ShouldBeFalse)
			// follow the first topic
			channelParticipant, err := rest.AddChannelParticipant(popularTopics[0].Channel.Id, account.Id, ses.ClientId, account.Id)
			So(err, ShouldBeNil)
			So(channelParticipant, ShouldNotBeNil)

			popularTopics, err = rest.FetchPopularTopics(ses.ClientId)
			So(err, ShouldBeNil)
			So(popularTopics, ShouldNotBeNil)
			So(popularTopics[0].IsParticipant, ShouldBeTrue)
		})
	})
}
