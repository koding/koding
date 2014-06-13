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
			nonOwnerAccount.OldId = AccountOldId2.Hex()
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
				So(cmc.Interactions["like"].ActorsCount, ShouldEqual, 1)

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
				So(cmc.Interactions["like"].ActorsCount, ShouldEqual, 1)

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

			Convey("users should be able to  un-like message", func() {
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
				So(cmc.Interactions["like"].ActorsCount, ShouldEqual, 1)

				err = deleteInteraction("like", post.Id, account.Id)
				So(err, ShouldBeNil)

				cmc, err = getPostWithRelatedData(post.Id, post.AccountId, groupName)
				So(err, ShouldBeNil)
				So(cmc, ShouldNotBeNil)

				// it is liked by author
				So(cmc.Interactions["like"].IsInteracted, ShouldBeFalse)

				// actor length should be 1
				So(cmc.Interactions["like"].ActorsCount, ShouldEqual, 0)
			})

			Convey("owner can post reply to message", func() {
				post, err := createPost(groupChannel.Id, account.Id)
				So(err, ShouldBeNil)
				So(post, ShouldNotBeNil)

				reply, err := addReply(post.Id, post.AccountId, groupChannel.Id)
				So(err, ShouldBeNil)
				So(reply, ShouldNotBeNil)

				So(reply.AccountId, ShouldEqual, post.AccountId)

				cmc, err := getPostWithRelatedData(post.Id, post.AccountId, groupName)
				So(err, ShouldBeNil)
				So(cmc, ShouldNotBeNil)

				So(len(cmc.Replies), ShouldEqual, 1)

				So(cmc.Replies[0].Message.AccountId, ShouldEqual, post.AccountId)

			})

			Convey("we should be able to get only replies", func() {
				post, err := createPost(groupChannel.Id, account.Id)
				So(err, ShouldBeNil)
				So(post, ShouldNotBeNil)

				reply, err := addReply(post.Id, post.AccountId, groupChannel.Id)
				So(err, ShouldBeNil)
				So(reply, ShouldNotBeNil)

				reply, err = addReply(post.Id, post.AccountId, groupChannel.Id)
				So(err, ShouldBeNil)
				So(reply, ShouldNotBeNil)

				replies, err := getReplies(post.Id, post.AccountId, groupName)
				So(err, ShouldBeNil)
				So(len(replies), ShouldEqual, 2)

			})

			Convey("we should be able to get replies with \"from\" query param", nil)

			Convey("non-owner can post reply to message", func() {
				post, err := createPost(groupChannel.Id, account.Id)
				So(err, ShouldBeNil)
				So(post, ShouldNotBeNil)

				reply, err := addReply(post.Id, nonOwnerAccount.Id, groupChannel.Id)
				So(err, ShouldBeNil)
				So(reply, ShouldNotBeNil)

				So(reply.AccountId, ShouldEqual, nonOwnerAccount.Id)

				cmc, err := getPostWithRelatedData(post.Id, post.AccountId, groupName)
				So(err, ShouldBeNil)
				So(cmc, ShouldNotBeNil)

				So(len(cmc.Replies), ShouldEqual, 1)

				So(cmc.Replies[0].Message.AccountId, ShouldEqual, nonOwnerAccount.Id)
			})

			Convey("reply can be liked", func() {
				post, err := createPost(groupChannel.Id, account.Id)
				So(err, ShouldBeNil)
				So(post, ShouldNotBeNil)

				reply, err := addReply(post.Id, nonOwnerAccount.Id, groupChannel.Id)
				So(err, ShouldBeNil)
				So(reply, ShouldNotBeNil)

				So(reply.AccountId, ShouldEqual, nonOwnerAccount.Id)

				err = addInteraction("like", reply.Id, nonOwnerAccount.Id)
				So(err, ShouldBeNil)

				cmc, err := getPostWithRelatedData(post.Id, account.Id, groupName)
				So(err, ShouldBeNil)
				So(cmc, ShouldNotBeNil)

				// it is liked by reply author, not post owner
				So(cmc.Interactions["like"].IsInteracted, ShouldBeFalse)

				// we didnt like the post, we liked the reply
				So(cmc.Interactions["like"].ActorsCount, ShouldEqual, 0)

				So(len(cmc.Replies), ShouldEqual, 1)

				// we liked the reply
				So(cmc.Replies[0].Interactions["like"].ActorsCount, ShouldEqual, 1)

				So(cmc.Replies[0].Interactions["like"].IsInteracted, ShouldBeFalse)

			})

			// for now those will be handled by social worker
			Convey("reply can be deleted by admin", nil)
			Convey("reply can not be deleted by non owner", nil)

			Convey("reply can be deleted by owner", func() {
				post, err := createPost(groupChannel.Id, account.Id)
				So(err, ShouldBeNil)
				So(post, ShouldNotBeNil)

				reply, err := addReply(post.Id, nonOwnerAccount.Id, groupChannel.Id)
				So(err, ShouldBeNil)
				So(reply, ShouldNotBeNil)

				err = deletePost(reply.Id, nonOwnerAccount.Id, groupName)
				So(err, ShouldBeNil)

				cmc, err := getPostWithRelatedData(post.Id, account.Id, groupName)
				So(err, ShouldBeNil)
				So(cmc, ShouldNotBeNil)

				So(len(cmc.Replies), ShouldEqual, 0)

			})

			Convey("while deleting message, also replies should be deleted", func() {
				post, err := createPost(groupChannel.Id, account.Id)
				So(err, ShouldBeNil)
				So(post, ShouldNotBeNil)

				reply1, err := addReply(post.Id, nonOwnerAccount.Id, groupChannel.Id)
				So(err, ShouldBeNil)
				So(reply1, ShouldNotBeNil)

				reply2, err := addReply(post.Id, nonOwnerAccount.Id, groupChannel.Id)
				So(err, ShouldBeNil)
				So(reply2, ShouldNotBeNil)

				err = deletePost(post.Id, account.Id, groupName)
				So(err, ShouldBeNil)

				cmc, err := getPostWithRelatedData(reply1.Id, account.Id, groupName)
				So(err, ShouldNotBeNil)
				So(cmc, ShouldBeNil)

				cmc, err = getPostWithRelatedData(reply2.Id, account.Id, groupName)
				So(err, ShouldNotBeNil)
				So(cmc, ShouldBeNil)

			})

			Convey("while deleting message replies' likes should be deleted", func() {
				post, err := createPost(groupChannel.Id, account.Id)
				So(err, ShouldBeNil)
				So(post, ShouldNotBeNil)

				reply1, err := addReply(post.Id, nonOwnerAccount.Id, groupChannel.Id)
				So(err, ShouldBeNil)
				So(reply1, ShouldNotBeNil)

				reply2, err := addReply(post.Id, nonOwnerAccount.Id, groupChannel.Id)
				So(err, ShouldBeNil)
				So(reply2, ShouldNotBeNil)

				err = addInteraction("like", reply1.Id, account.Id)
				So(err, ShouldBeNil)

				err = addInteraction("like", reply2.Id, account.Id)
				So(err, ShouldBeNil)

				err = deletePost(post.Id, account.Id, groupName)
				So(err, ShouldBeNil)

				interactions, err := getInteractions("like", reply1.Id)
				So(err, ShouldBeNil)
				So(interactions, ShouldNotBeNil)

				interactions, err = getInteractions("like", reply2.Id)
				So(err, ShouldBeNil)
				So(interactions, ShouldNotBeNil)

			})

			Convey("while deleting message, message likes should be deleted", func() {
				post, err := createPost(groupChannel.Id, account.Id)
				So(err, ShouldBeNil)
				So(post, ShouldNotBeNil)

				err = addInteraction("like", post.Id, account.Id)
				So(err, ShouldBeNil)

				err = deletePost(post.Id, account.Id, groupName)
				So(err, ShouldBeNil)

				interactions, err := getInteractions("like", post.Id)
				So(err, ShouldBeNil)
				So(interactions, ShouldNotBeNil)
			})
			Convey("while deleting messages, they should be removed from all channels", nil)

			Convey("message can contain payload", func() {
				payload := make(map[string]interface{})
				payload["key1"] = "value1"
				payload["key2"] = 2
				payload["key3"] = true
				payload["key4"] = 3.4

				post, err := createPostWithPayload(groupChannel.Id, account.Id, payload)
				So(err, ShouldBeNil)
				So(post, ShouldNotBeNil)

				So(post.Payload, ShouldNotBeNil)
				So(*(post.Payload["key1"]), ShouldEqual, "value1")
				So(*(post.Payload["key2"]), ShouldEqual, "2")
				So(*(post.Payload["key3"]), ShouldEqual, "true")
				So(*(post.Payload["key4"]), ShouldEqual, "3.4")
			})
		})
	})
}

func createPost(channelId, accountId int64) (*models.ChannelMessage, error) {
	return createPostWithBody(channelId, accountId, "create a message")
}

type PayloadRequest struct {
	Body      string                 `json:"body"`
	AccountId int64                  `json:"accountId,string"`
	Payload   map[string]interface{} `json:"payload"`
}

func createPostWithPayload(channelId, accountId int64, payload map[string]interface{}) (*models.ChannelMessage, error) {
	pr := PayloadRequest{}
	pr.Body = "message with payload"
	pr.AccountId = accountId
	pr.Payload = payload

	return createPostRequest(channelId, pr)
}

func createPostWithBody(channelId, accountId int64, body string) (*models.ChannelMessage, error) {
	cm := models.NewChannelMessage()
	cm.Body = body
	cm.AccountId = accountId

	return createPostRequest(channelId, cm)
}

func createPostRequest(channelId int64, model interface{}) (*models.ChannelMessage, error) {
	url := fmt.Sprintf("/channel/%d/message", channelId)
	res, err := marshallAndSendRequest("POST", url, model)
	if err != nil {
		return nil, err
	}

	container := models.NewChannelMessageContainer()
	err = json.Unmarshal(res, container)
	if err != nil {
		return nil, err
	}

	return container.Message, nil
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

func getInteractions(interactionType string, postId int64) ([]string, error) {
	url := fmt.Sprintf("/message/%d/interaction/%s", postId, interactionType)
	res, err := sendRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}

	var interactions []string
	err = json.Unmarshal(res, &interactions)
	if err != nil {
		return nil, err
	}

	return interactions, nil
}

func deleteInteraction(interactionType string, postId, accountId int64) error {
	cm := models.NewInteraction()
	cm.AccountId = accountId
	cm.MessageId = postId

	url := fmt.Sprintf("/message/%d/interaction/%s/delete", postId, interactionType)
	_, err := marshallAndSendRequest("POST", url, cm)
	if err != nil {
		return err
	}
	return nil
}

func getReplies(postId int64, accountId int64, groupName string) ([]*models.ChannelMessage, error) {
	url := fmt.Sprintf("/message/%d/reply?accountId=%d&groupName=%s", postId, accountId, groupName)
	res, err := sendRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}

	var replies []*models.ChannelMessage
	err = json.Unmarshal(res, &replies)
	if err != nil {
		return nil, err
	}

	return replies, nil
}

func addReply(postId, accountId, channelId int64) (*models.ChannelMessage, error) {
	cm := models.NewChannelMessage()
	cm.Body = "reply body"
	cm.AccountId = accountId
	cm.InitialChannelId = channelId

	url := fmt.Sprintf("/message/%d/reply", postId)
	res, err := marshallAndSendRequest("POST", url, cm)
	if err != nil {
		return nil, err
	}

	model := models.NewChannelMessageContainer()
	err = json.Unmarshal(res, model)
	if err != nil {
		return nil, err
	}

	return model.Message, nil
}

func deleteReply(postId, replyId int64) error {
	url := fmt.Sprintf("/message/%d/reply/%d/delete", postId, replyId)
	_, err := sendRequest("DELETE", url, nil)
	if err != nil {
		return err
	}
	return nil
}
