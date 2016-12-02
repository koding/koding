package main

import (
	"koding/db/mongodb/modelhelper"
	"math/rand"
	"socialapi/models"
	"socialapi/rest"
	"socialapi/workers/common/tests"
	"strconv"
	"testing"

	"github.com/koding/runner"
	. "github.com/smartystreets/goconvey/convey"
)

func TestPinnedActivityChannel(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {

		SkipConvey("while  testing pinned activity channel", t, func() {
			groupName := models.RandomGroupName()

			account := models.NewAccount()
			account.OldId = AccountOldId.Hex()
			account, err := rest.CreateAccount(account)
			So(err, ShouldBeNil)
			So(account, ShouldNotBeNil)
			So(account.Id, ShouldNotEqual, 0)

			ses, err := modelhelper.FetchOrCreateSession(account.Nick, groupName)
			So(err, ShouldBeNil)
			So(ses, ShouldNotBeNil)

			nonOwnerAccount := models.NewAccount()
			nonOwnerAccount.OldId = AccountOldId.Hex()
			nonOwnerAccount, err = rest.CreateAccount(nonOwnerAccount)
			So(err, ShouldBeNil)
			So(nonOwnerAccount, ShouldNotBeNil)

			nonOwnerSes, err := modelhelper.FetchOrCreateSession(nonOwnerAccount.Nick, groupName)
			So(err, ShouldBeNil)
			So(nonOwnerSes, ShouldNotBeNil)

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

			Convey("requester should have one", func() {
				account := account
				channel, err := rest.FetchPinnedActivityChannel(account.Id, groupName)
				So(err, ShouldBeNil)
				So(channel, ShouldNotBeNil)
				So(channel.Id, ShouldNotEqual, 0)
				So(channel.TypeConstant, ShouldEqual, models.Channel_TYPE_PINNED_ACTIVITY)
				So(channel.CreatorId, ShouldEqual, account.Id)
			})

			Convey("owner should be able to update it", nil)

			Convey("non-owner should not be able to update it", nil)

			Convey("owner should not be able to add new participants into it", func() {
				channel, err := rest.FetchPinnedActivityChannel(account.Id, groupName)
				So(err, ShouldBeNil)
				So(channel, ShouldNotBeNil)
				channelParticipant, err := rest.AddChannelParticipant(channel.Id, ses.ClientId, nonOwnerAccount.Id)
				// there should be an err
				So(err, ShouldNotBeNil)
				// channel should be nil
				So(channelParticipant, ShouldBeNil)
			})

			Convey("normal user shouldnt be able to add new participants to it", func() {
				channel, err := rest.FetchPinnedActivityChannel(account.Id, groupName)
				So(err, ShouldBeNil)
				So(channel, ShouldNotBeNil)
				channelParticipant, err := rest.AddChannelParticipant(channel.Id, nonOwnerSes.ClientId, nonOwnerAccount.Id)
				// there should be an err
				So(err, ShouldNotBeNil)
				// channel should be nil
				So(channelParticipant, ShouldBeNil)
			})

			Convey("owner should  not be able to remove participant from it", func() {
				channel, err := rest.FetchPinnedActivityChannel(account.Id, groupName)
				So(err, ShouldBeNil)
				So(channel, ShouldNotBeNil)
				channelParticipant, err := rest.DeleteChannelParticipant(channel.Id, ses.ClientId, nonOwnerAccount.Id)
				// there should be an err
				So(err, ShouldNotBeNil)
				// channel should be nil
				So(channelParticipant, ShouldBeNil)
			})

			Convey("normal user shouldnt be able to remove participants from it", func() {
				channel, err := rest.FetchPinnedActivityChannel(account.Id, groupName)
				So(err, ShouldBeNil)
				So(channel, ShouldNotBeNil)
				channelParticipant, err := rest.DeleteChannelParticipant(channel.Id, nonOwnerSes.ClientId, nonOwnerAccount.Id)
				// there should be an err
				So(err, ShouldNotBeNil)
				// channel should be nil
				So(channelParticipant, ShouldBeNil)
			})

			Convey("owner should be able to add new message into it", func() {
				_, err := rest.AddPinnedMessage(account.Id, post.Id, "koding")
				// there should be an err
				So(err, ShouldBeNil)

				_, err = rest.RemovePinnedMessage(account.Id, post.Id, "koding")
				So(err, ShouldBeNil)

			})

			Convey("owner should be able to list messages", func() {
				groupName := "testgroup" + strconv.FormatInt(rand.Int63(), 10)

				pinnedChannel, err := rest.FetchPinnedActivityChannel(account.Id, groupName)
				So(err, ShouldBeNil)
				So(pinnedChannel, ShouldNotBeNil)

				groupChannel, err := rest.CreateChannelByGroupNameAndType(
					account.Id,
					groupName,
					models.Channel_TYPE_DEFAULT,
					ses.ClientId,
				)
				So(err, ShouldBeNil)
				So(groupChannel, ShouldNotBeNil)

				post1, err := rest.CreatePostWithBody(groupChannel.Id, nonOwnerAccount.Id, "create a message #1times")
				So(err, ShouldBeNil)
				So(post1, ShouldNotBeNil)

				_, err = rest.AddPinnedMessage(nonOwnerAccount.Id, post1.Id, groupName)
				// there should be an err
				So(err, ShouldBeNil)

				post2, err := rest.CreatePostWithBody(groupChannel.Id, nonOwnerAccount.Id, "create a message #1another")
				So(err, ShouldBeNil)
				So(post2, ShouldNotBeNil)

				_, err = rest.AddPinnedMessage(nonOwnerAccount.Id, post2.Id, groupName)
				// there should be an err
				So(err, ShouldBeNil)

				//time.Sleep(time.Second * 5)

				history, err := rest.FetchPinnedMessages(account.Id, groupName)
				// there should be an err
				So(err, ShouldBeNil)
				// channel should be nil
				So(history, ShouldNotBeNil)

				// message count should be 2
				So(len(history.MessageList), ShouldEqual, 2)

				// unread count should be 0
				So(history.UnreadCount, ShouldEqual, 0)

				// old id should be the same one
				So(history.MessageList[0].AccountOldId, ShouldContainSubstring, nonOwnerAccount.OldId)

				// replies count should be 0
				So(len(history.MessageList[0].Replies), ShouldEqual, 0)
			})

			Convey("Messages shouldnt be added as pinned twice ", func() {
				// use account id as message id
				_, err := rest.AddPinnedMessage(account.Id, post.Id, "koding")
				// there should be an err
				So(err, ShouldBeNil)
				// use account id as message id, pin message is idempotent, if it is
				// in the channel, wont give error
				_, err = rest.AddPinnedMessage(account.Id, post.Id, "koding")
				// there should not be an err
				So(err, ShouldBeNil)
			})

			Convey("Non-exist message should not be added as pinned ", nil)

		})
	})
}
