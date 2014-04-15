package main

import (
	"math/rand"
	"socialapi/models"
	"strconv"
	"testing"
	. "github.com/smartystreets/goconvey/convey"
)

func TestChannelMessage(t *testing.T) {
	Convey("While testing channel messages given a channel", t, func() {
		groupName := "testgroup" + strconv.FormatInt(rand.Int63(), 10)

		Convey("first we should create the account", func() {
			account := models.NewAccount()
			account.OldId = AccountOldId.Hex()
			account, err := createAccount(account)
			So(err, ShouldBeNil)
			So(account, ShouldNotBeNil)

			nonOwnerAccount := models.NewAccount()
			nonOwnerAccount.OldId = AccountOldId.Hex()
			nonOwnerAccount, err = createAccount(nonOwnerAccount)
			So(err, ShouldBeNil)
			So(nonOwnerAccount, ShouldNotBeNil)

			groupChannel, err := createChannelByGroupNameAndType(account.Id, groupName, models.Channel_TYPE_GROUP)
			So(err, ShouldBeNil)
			So(groupChannel, ShouldNotBeNil)

			Convey("message should be able added to the group channel", func() {
				post, err := createPost(groupChannel.Id, account.Id)
				So(err, ShouldBeNil)
				So(post, ShouldNotBeNil)
				So(post.Id, ShouldNotEqual, 0)
				So(post.Body, ShouldNotEqual, "")
				Convey("message can be edited by owner", func() {

					initialPostBody := post.Body
					post.Body = "edited message"

					editedPost, err := updatePost(post)
					So(err, ShouldBeNil)
					So(editedPost, ShouldNotBeNil)
					// body should not be same
					So(initialPostBody, ShouldNotEqual, editedPost.Body)
				})

				// for now social worker handles this issue
				Convey("message can be edited by an admin", nil)
				Convey("message can not be edited by non-owner", nil)

			})

			Convey("message can be deleted by owner", func() {
				post, err := createPost(groupChannel.Id, account.Id)
				So(err, ShouldBeNil)
				So(post, ShouldNotBeNil)
				err = deletePost(post.Id, account.Id, groupChannel.GroupName)
				So(err, ShouldBeNil)
			})

			// handled by social worker
			Convey("message can be deleted by an admin", nil)
			Convey("message can not be edited by non-owner", nil)

			Convey("owner can like message", nil)

			Convey("non-owner can like message", nil)

			Convey("owner can post reply to message", nil)

			Convey("reply can be liked by reply-owner", nil)

			Convey("reply can be liked", nil)

			Convey("non-owner can post reply to message", nil)

		})

	})
}
