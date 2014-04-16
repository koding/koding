package main

import (
	"encoding/json"
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

				cmc, err := getPostWithRelatedData(post.Id, post.AccountId, groupName)
				So(err, ShouldBeNil)
				So(cmc, ShouldNotBeNil)

				// it is liked by author
				So(cmc.Interactions["like"].IsInteracted, ShouldBeTrue)

				// actor length should be 1
				So(len(cmc.Interactions["like"].Actors), ShouldEqual, 1)

			})

			Convey("non-owner can like message", func() {
				post, err := createPost(groupChannel.Id, account.Id)
				So(err, ShouldBeNil)
				So(post, ShouldNotBeNil)

				err = addInteraction("like", post.Id, nonOwnerAccount.Id)
				So(err, ShouldBeNil)

				cmc, err := getPostWithRelatedData(post.Id, nonOwnerAccount.Id, groupName)
				So(err, ShouldBeNil)
				So(cmc, ShouldNotBeNil)

				// it is liked by author
				So(cmc.Interactions["like"].IsInteracted, ShouldBeTrue)

				// actor length should be 1
				So(len(cmc.Interactions["like"].Actors), ShouldEqual, 1)

			})

			Convey("we should be able to get only interactions", func() {
				post, err := createPost(groupChannel.Id, account.Id)
				So(err, ShouldBeNil)
				So(post, ShouldNotBeNil)

				err = addInteraction("like", post.Id, nonOwnerAccount.Id)
				So(err, ShouldBeNil)

				likes, err := getInteractions("like", post.Id)
				So(err, ShouldBeNil)

				So(len(likes), ShouldEqual, 1)

			})
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
	url := fmt.Sprintf("/message/%d?accountId=%d&groupName=%s", id, accountId, groupName)
	cm := models.NewChannelMessage()
	cmI, err := sendModel("GET", url, cm)
	if err != nil {
		return nil, err
	}
	return cmI.(*models.ChannelMessage), nil
}

func getPostWithRelatedData(id int64, accountId int64, groupName string) (*models.ChannelMessageContainer, error) {
	url := fmt.Sprintf("/message/%d/related?accountId=%d&groupName=%s", id, accountId, groupName)
	cm := models.NewChannelMessageContainer()
	cmI, err := sendModel("GET", url, cm)
	if err != nil {
		return nil, err
	}
	return cmI.(*models.ChannelMessageContainer), nil
}

func deletePost(id int64, accountId int64, groupName string) error {
	url := fmt.Sprintf("/message/%d?accountId=%d&groupName=%s", id, accountId, groupName)
	_, err := sendRequest("DELETE", url, nil)
	return err
}

func addInteraction(interactionType string, postId, accountId int64) error {
	cm := models.NewInteraction()
	cm.AccountId = accountId
	cm.MessageId = postId

	url := fmt.Sprintf("/message/%d/interaction/%s/add", postId, interactionType)
	_, err := sendModel("POST", url, cm)
	if err != nil {
		return err
	}
	return nil
}

func getInteractions(interactionType string, postId int64) ([]int64, error) {
	url := fmt.Sprintf("/message/%d/interaction/%s", postId, interactionType)
	res, err := sendRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}

	var interactions []int64
	err = json.Unmarshal(res, &interactions)
	if err != nil {
		return nil, err
	}

	return interactions, nil
}
