package main

import (
	"math/rand"
	"socialapi/models"
	"socialapi/rest"
	"strconv"
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"
)

func TestPinnedActivityChannel(t *testing.T) {
	Convey("while  testing pinned activity channel", t, func() {
		rand.Seed(time.Now().UnixNano())
		groupName := "testgroup" + strconv.FormatInt(rand.Int63(), 10)

		account := models.NewAccount()
		account.OldId = AccountOldId.Hex()
		account, err := rest.CreateAccount(account)
		So(err, ShouldBeNil)
		So(account, ShouldNotBeNil)
		So(account.Id, ShouldNotEqual, 0)

		nonOwnerAccount := models.NewAccount()
		nonOwnerAccount.OldId = AccountOldId.Hex()
		nonOwnerAccount, err = rest.CreateAccount(nonOwnerAccount)
		So(err, ShouldBeNil)
		So(nonOwnerAccount, ShouldNotBeNil)

		groupChannel, err := rest.CreateChannelByGroupNameAndType(account.Id, groupName, models.Channel_TYPE_GROUP)
		So(err, ShouldBeNil)
		So(groupChannel, ShouldNotBeNil)

		post, err := rest.CreatePost(groupChannel.Id, account.Id)
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
			channelParticipant, err := rest.AddChannelParticipant(channel.Id, account.Id, nonOwnerAccount.Id)
			// there should be an err
			So(err, ShouldNotBeNil)
			// channel should be nil
			So(channelParticipant, ShouldBeNil)
		})

		Convey("normal user shouldnt be able to add new participants to it", func() {
			channel, err := rest.FetchPinnedActivityChannel(account.Id, groupName)
			So(err, ShouldBeNil)
			So(channel, ShouldNotBeNil)
			channelParticipant, err := rest.AddChannelParticipant(channel.Id, nonOwnerAccount.Id, nonOwnerAccount.Id)
			// there should be an err
			So(err, ShouldNotBeNil)
			// channel should be nil
			So(channelParticipant, ShouldBeNil)
		})

		Convey("owner should  not be able to remove participant from it", func() {
			channel, err := rest.FetchPinnedActivityChannel(account.Id, groupName)
			So(err, ShouldBeNil)
			So(channel, ShouldNotBeNil)
			channelParticipant, err := rest.DeleteChannelParticipant(channel.Id, account.Id, nonOwnerAccount.Id)
			// there should be an err
			So(err, ShouldNotBeNil)
			// channel should be nil
			So(channelParticipant, ShouldBeNil)
		})

		Convey("normal user shouldnt be able to remove participants from it", func() {
			channel, err := rest.FetchPinnedActivityChannel(account.Id, groupName)
			So(err, ShouldBeNil)
			So(channel, ShouldNotBeNil)
			channelParticipant, err := rest.DeleteChannelParticipant(channel.Id, nonOwnerAccount.Id, nonOwnerAccount.Id)
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

			groupChannel, err := rest.CreateChannelByGroupNameAndType(account.Id, groupName, models.Channel_TYPE_DEFAULT)
			So(err, ShouldBeNil)
			So(groupChannel, ShouldNotBeNil)

			post1, err := rest.CreatePostWithBody(groupChannel.Id, nonOwnerAccount.Id, "create a message #1times")
			So(err, ShouldBeNil)
			So(post1, ShouldNotBeNil)

			post2, err := rest.CreatePostWithBody(groupChannel.Id, nonOwnerAccount.Id, "create a message #1another")
			So(err, ShouldBeNil)
			So(post2, ShouldNotBeNil)

			time.Sleep(time.Second * 5)

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

			// interactions should not be 0, like should be there
			So(len(history.MessageList[0].Interactions), ShouldEqual, 1)

			// like count should be 0
			So(history.MessageList[0].Interactions["like"].ActorsCount, ShouldEqual, 0)
			// current user should not be interacted with it
			So(history.MessageList[0].Interactions["like"].IsInteracted, ShouldBeFalse)
		})

		Convey("Messages shouldnt be added as pinned twice ", func() {
			// use account id as message id
			_, err := rest.AddPinnedMessage(account.Id, post.Id, "koding")
			// there should be an err
			So(err, ShouldBeNil)
			// use account id as message id
			_, err = rest.AddPinnedMessage(account.Id, post.Id, "koding")
			// there should be an err
			So(err, ShouldNotBeNil)
		})

		Convey("Non-exist message should not be added as pinned ", nil)

	})
}
