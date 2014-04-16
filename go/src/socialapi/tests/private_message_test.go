package main

import (
	"encoding/json"
	"math/rand"
	"socialapi/models"
	"strconv"
	"testing"
	. "github.com/smartystreets/goconvey/convey"
)

func TestPrivateMesssage(t *testing.T) {
	Convey("while testing private messages", t, func() {
		account := models.NewAccount()
		account.OldId = AccountOldId.Hex()
		account, err := createAccount(account)
		So(err, ShouldBeNil)
		So(account, ShouldNotBeNil)

		recepient := models.NewAccount()
		recepient.OldId = AccountOldId2.Hex()
		recepient, err = createAccount(recepient)
		So(err, ShouldBeNil)
		So(recepient, ShouldNotBeNil)

		recepient2 := models.NewAccount()
		recepient2.OldId = AccountOldId3.Hex()
		recepient2, err = createAccount(recepient2)
		So(err, ShouldBeNil)
		So(recepient2, ShouldNotBeNil)

		groupName := "testgroup" + strconv.FormatInt(rand.Int63(), 10)

		Convey("one can send private message to one person", func() {
			cmc, err := sendPrivateMessage(
				account.Id,
				"this is a body for private message",
				[]int64{recepient.Id},
				groupName,
			)
			So(err, ShouldBeNil)
			So(cmc, ShouldNotBeNil)

		})

		Convey("0 recipient should fail", func() {
			cmc, err := sendPrivateMessage(
				account.Id,
				"this is a body for private message",
				[]int64{},
				groupName,
			)
			So(err, ShouldNotBeNil)
			So(cmc, ShouldBeNil)

		})
		Convey("if body is nil, should fail to create PM", func() {
			cmc, err := sendPrivateMessage(
				account.Id,
				"",
				[]int64{recepient.Id},
				groupName,
			)
			So(err, ShouldNotBeNil)
			So(cmc, ShouldBeNil)
		})
		Convey("if group name is nil, should not fail to create PM", func() {
			cmc, err := sendPrivateMessage(
				account.Id,
				"this is a body for private message",
				[]int64{recepient.Id},
				"",
			)
			So(err, ShouldBeNil)
			So(cmc, ShouldNotBeNil)
		})

		Convey("if sender is not defined should fail to create PM", func() {
			cmc, err := sendPrivateMessage(
				0,
				"this is a body for private message",
				[]int64{recepient.Id},
				"",
			)
			So(err, ShouldNotBeNil)
			So(cmc, ShouldBeNil)
		})

		Convey("one can send private message to multiple person", func() {
			cmc, err := sendPrivateMessage(
				account.Id,
				"this is a body for private message",
				[]int64{recepient.Id, recepient2.Id},
				groupName,
			)
			So(err, ShouldBeNil)
			So(cmc, ShouldNotBeNil)

		})

		Convey("targetted account should be able to list private message channel of himself", nil)

	})
}

func sendPrivateMessage(senderId int64, body string, recepients []int64, groupName string) (*models.ChannelContainer, error) {

	pmr := models.PrivateMessageRequest{}
	pmr.AccountId = senderId
	pmr.Body = body
	pmr.Recepients = recepients
	pmr.GroupName = groupName

	url := "/privatemessage/send"
	res, err := marshallAndSendRequest("POST", url, pmr)
	if err != nil {
		return nil, err
	}

	model := models.NewChannelContainer()
	err = json.Unmarshal(res, model)
	if err != nil {
		return nil, err
	}

	return model, nil
}

// func getHistory(channelId, accountId int64) (*models.HistoryResponse, error) {
// 	url := fmt.Sprintf("/channel/%d/history?accountId=%d", channelId, accountId)
// 	res, err := sendRequest("GET", url, nil)
// 	if err != nil {
// 		return nil, err
// 	}

// 	var history models.HistoryResponse
// 	err = json.Unmarshal(res, &history)
// 	if err != nil {
// 		return nil, err
// 	}

// 	return &history, nil
// }
