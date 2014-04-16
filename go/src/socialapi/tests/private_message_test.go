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
		Convey("private message response should have created channel", func() {
			cmc, err := sendPrivateMessage(
				account.Id,
				"this is a body for private message",
				[]int64{recepient.Id, recepient2.Id},
				groupName,
			)
			So(err, ShouldBeNil)
			So(cmc, ShouldNotBeNil)
			So(cmc.Channel.TypeConstant, ShouldEqual, models.Channel_TYPE_PRIVATE_MESSAGE)
			So(cmc.Channel.Id, ShouldBeGreaterThan, 0)
			So(cmc.Channel.GroupName, ShouldEqual, groupName)
			So(cmc.Channel.PrivacyConstant, ShouldEqual, models.Channel_PRIVACY_PRIVATE)

		})

		Convey("private message response should have participant status data", func() {
			cmc, err := sendPrivateMessage(
				account.Id,
				"this is a body for private message",
				[]int64{recepient.Id, recepient2.Id},
				groupName,
			)
			So(err, ShouldBeNil)
			So(cmc, ShouldNotBeNil)
			So(cmc.IsParticipant, ShouldBeTrue)
		})

		Convey("private message response should have participant count", func() {
			cmc, err := sendPrivateMessage(
				account.Id,
				"this is a body for private message",
				[]int64{recepient.Id, recepient2.Id},
				groupName,
			)
			So(err, ShouldBeNil)
			So(cmc, ShouldNotBeNil)
			So(cmc.ParticipantCount, ShouldEqual, 3)
		})

		Convey("private message response should have participant preview", func() {
			cmc, err := sendPrivateMessage(
				account.Id,
				"this is a body for private message",
				[]int64{recepient.Id, recepient2.Id},
				groupName,
			)
			So(err, ShouldBeNil)
			So(cmc, ShouldNotBeNil)
			So(len(cmc.ParticipantsPreview), ShouldEqual, 3)
		})

		Convey("private message response should have last Message", func() {
			body := "this is a body for private message"
			cmc, err := sendPrivateMessage(
				account.Id,
				body,
				[]int64{recepient.Id, recepient2.Id},
				groupName,
			)
			So(err, ShouldBeNil)
			So(cmc, ShouldNotBeNil)
			So(cmc.LastMessage.Body, ShouldEqual, body)
		})

		Convey("private message should be listed by all recipients", func() {
			// use a different group name
			// in order not to interfere with another request
			groupName := "testgroup" + strconv.FormatInt(rand.Int63(), 10)

			body := "this is a body for private message"
			cmc, err := sendPrivateMessage(
				account.Id,
				body,
				[]int64{recepient.Id, recepient2.Id},
				groupName,
			)
			So(err, ShouldBeNil)
			So(cmc, ShouldNotBeNil)

			pm, err := getPrivateMessages(account.Id, groupName)
			So(err, ShouldBeNil)
			So(pm, ShouldNotBeNil)
			So(pm[0], ShouldNotBeNil)
			So(pm[0].Channel.TypeConstant, ShouldEqual, models.Channel_TYPE_PRIVATE_MESSAGE)
			So(pm[0].Channel.Id, ShouldEqual, cmc.Channel.Id)
			So(pm[0].Channel.GroupName, ShouldEqual, cmc.Channel.GroupName)
			So(pm[0].LastMessage.Body, ShouldEqual, cmc.LastMessage.Body)
			So(pm[0].Channel.PrivacyConstant, ShouldEqual, models.Channel_PRIVACY_PRIVATE)
			So(len(pm[0].ParticipantsPreview), ShouldEqual, 3)
			So(pm[0].IsParticipant, ShouldBeTrue)

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

func getPrivateMessages(accountId int64, groupName string) ([]models.ChannelContainer, error) {
	url := fmt.Sprintf("/privatemessage/list?accountId=%d&groupName=%s", accountId, groupName)
	res, err := sendRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}

	var privateMessages []models.ChannelContainer
	err = json.Unmarshal(res, &privateMessages)
	if err != nil {
		return nil, err
	}

	return privateMessages, nil
}
