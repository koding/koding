package main

import (
	"socialapi/models"
	"socialapi/rest"
	"socialapi/workers/common/tests"
	"testing"

	"github.com/koding/runner"
	. "github.com/smartystreets/goconvey/convey"
)

func TestInteractionLikedMessages(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("While testing listing of the liked messages", t, func() {
			groupName := "koding"

			account1 := models.NewAccount()
			account1.OldId = AccountOldId.Hex()
			account, err := rest.CreateAccount(account1)
			So(err, ShouldBeNil)
			So(account, ShouldNotBeNil)

			ses, err := models.FetchOrCreateSession(account.Nick, groupName)
			So(err, ShouldBeNil)
			So(ses, ShouldNotBeNil)

			groupChannel, err := rest.CreateChannelByGroupNameAndType(
				account.Id,
				groupName,
				models.Channel_TYPE_GROUP,
				ses.ClientId,
			)
			So(err, ShouldBeNil)
			So(groupChannel, ShouldNotBeNil)

			post, err := rest.CreatePost(groupChannel.Id, ses.ClientId)
			So(err, ShouldBeNil)
			So(post, ShouldNotBeNil)

			_, err = rest.AddInteraction("like", post.Id, account.Id, ses.ClientId)
			So(err, ShouldBeNil)
			Convey("We should be able to list the messages that liked", func() {
				likes, err := rest.GetInteractions("like", post.Id)
				So(err, ShouldBeNil)
				So(len(likes), ShouldEqual, 1)
				interactedMessages, err := rest.ListMessageInteractionsByType(models.Interaction_TYPE_LIKE, account.Id, ses.ClientId)
				So(err, ShouldBeNil)
				So(len(interactedMessages), ShouldEqual, 1)
			})
		})
	})
}
