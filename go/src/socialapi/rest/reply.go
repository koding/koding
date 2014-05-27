package rest

import (
	"encoding/json"
	"fmt"
	"socialapi/models"
)

func GetPostWithRelatedData(id int64, accountId int64, groupName string) (*models.ChannelMessageContainer, error) {
	url := fmt.Sprintf("/message/%d/related?accountId=%d&groupName=%s", id, accountId, groupName)
	cm := models.NewChannelMessageContainer()
	cmI, err := sendModel("GET", url, cm)
	if err != nil {
		return nil, err
	}
	return cmI.(*models.ChannelMessageContainer), nil
}

func GetReplies(postId int64, accountId int64, groupName string) ([]*models.ChannelMessage, error) {
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

func AddReply(postId, accountId, channelId int64) (*models.ChannelMessage, error) {
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

func DeleteReply(postId, replyId int64) error {
	url := fmt.Sprintf("/message/%d/reply/%d/delete", postId, replyId)
	_, err := sendRequest("DELETE", url, nil)
	if err != nil {
		return err
	}
	return nil
}
