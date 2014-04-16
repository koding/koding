package main

import (
	"fmt"
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
				post2, err := getPost(post.Id, account.Id, groupChannel.GroupName)
				So(err, ShouldNotBeNil)
				So(post2, ShouldBeNil)
			})

			// handled by social worker
			Convey("message can be deleted by an admin", nil)
			Convey("message can not be edited by non-owner", nil)

			Convey("owner can like message", func() {
				post, err := createPost(groupChannel.Id, account.Id)
				So(err, ShouldBeNil)
				So(post, ShouldNotBeNil)

				err = addInteraction("like", post.Id, post.AccountId)
				So(err, ShouldBeNil)
			})

			Convey("non-owner can like message", nil)

			Convey("owner can post reply to message", nil)

			Convey("reply can be liked by reply-owner", nil)

			Convey("reply can be liked", nil)

			Convey("non-owner can post reply to message", nil)

		})

	})
}

func createPost(channelId, accountId int64) (*models.ChannelMessage, error) {
	return createPostWithBody(channelId, accountId, "create a message")
}

func createPostWithBody(channelId, accountId int64, body string) (*models.ChannelMessage, error) {
	cm := models.NewChannelMessage()
	cm.Body = body
	cm.AccountId = accountId

	url := fmt.Sprintf("/channel/%d/message", channelId)
	cmI, err := sendModel("POST", url, cm)
	if err != nil {
		return nil, err
	}
	return cmI.(*models.ChannelMessage), nil
}

func updatePost(cm *models.ChannelMessage) (*models.ChannelMessage, error) {
	cm.Body = "after update"

	url := fmt.Sprintf("/message/%d", cm.Id)
	cmI, err := sendModel("POST", url, cm)
	if err != nil {
		return nil, err
	}

	return cmI.(*models.ChannelMessage), nil
}

func getPost(id int64, accountId int64, groupName string) (*models.ChannelMessage, error) {
	url := fmt.Sprintf("/message/%d?accountId=%d&groupName=%s", id)
	cm := models.NewChannelMessage()
	cmI, err := sendModel("GET", url, cm)
	if err != nil {
		return nil, err
	}
	return cmI.(*models.ChannelMessage), nil
}

func deletePost(id int64, accountId int64, groupName string) error {
	url := fmt.Sprintf("/message/%d?accountId=%d&groupName=%s", id, accountId, groupName)
	_, err := sendRequest("DELETE", url, nil)
	return err
}
