package main

import (
	"math/rand"
	"socialapi/models"
	"socialapi/request"
	"socialapi/rest"
	"strconv"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestPrivateMesssage(t *testing.T) {
	Convey("while testing private messages", t, func() {
		account := models.NewAccount()
		account.OldId = AccountOldId.Hex()
		account, err := rest.CreateAccount(account)
		So(err, ShouldBeNil)
		So(account, ShouldNotBeNil)

		recipient := models.NewAccount()
		recipient.OldId = AccountOldId2.Hex()
		recipient, err = rest.CreateAccount(recipient)
		So(err, ShouldBeNil)
		So(recipient, ShouldNotBeNil)

		recipient2 := models.NewAccount()
		recipient2.OldId = AccountOldId3.Hex()
		recipient2, err = rest.CreateAccount(recipient2)
		So(err, ShouldBeNil)
		So(recipient2, ShouldNotBeNil)

		groupName := "testgroup" + strconv.FormatInt(rand.Int63(), 10)

		Convey("one can send private message to one person", func() {
			cmc, err := rest.SendPrivateMessage(
				account.Id,
				"this is a body message for private message @chris @devrim @sinan",
				groupName,
				[]string{"chris", "devrim", "sinan"},
			)
			So(err, ShouldBeNil)
			So(cmc, ShouldNotBeNil)

		})

		Convey("0 recipient should not fail", func() {
			cmc, err := rest.SendPrivateMessage(
				account.Id,
				"this is a body for private message",
				groupName,
				[]string{},
			)
			So(err, ShouldBeNil)
			So(cmc, ShouldNotBeNil)

		})
		Convey("if body is nil, should fail to create PM", func() {
			cmc, err := rest.SendPrivateMessage(
				account.Id,
				"",
				groupName,
				[]string{},
			)
			So(err, ShouldNotBeNil)
			So(cmc, ShouldBeNil)
		})
		Convey("if group name is nil, should not fail to create PM", func() {
			cmc, err := rest.SendPrivateMessage(
				account.Id,
				"this is a body for private message @chris @devrim @sinan",
				"",
				[]string{"chris", "devrim", "sinan"},
			)
			So(err, ShouldBeNil)
			So(cmc, ShouldNotBeNil)
		})

		Convey("if sender is not defined should fail to create PM", func() {
			cmc, err := rest.SendPrivateMessage(
				0,
				"this is a body for private message",
				"",
				[]string{},
			)
			So(err, ShouldNotBeNil)
			So(cmc, ShouldBeNil)
		})

		Convey("one can send private message to multiple person", func() {
			cmc, err := rest.SendPrivateMessage(
				account.Id,
				"this is a body for private message @sinan",
				groupName,
				[]string{"sinan"},
			)
			So(err, ShouldBeNil)
			So(cmc, ShouldNotBeNil)

		})
		Convey("private message response should have created channel", func() {
			cmc, err := rest.SendPrivateMessage(
				account.Id,
				"this is a body for private message @devrim @sinan",
				groupName,
				[]string{"devrim", "sinan"},
			)
			So(err, ShouldBeNil)
			So(cmc, ShouldNotBeNil)
			So(cmc.Channel.TypeConstant, ShouldEqual, models.Channel_TYPE_PRIVATE_MESSAGE)
			So(cmc.Channel.Id, ShouldBeGreaterThan, 0)
			So(cmc.Channel.GroupName, ShouldEqual, groupName)
			So(cmc.Channel.PrivacyConstant, ShouldEqual, models.Channel_PRIVACY_PRIVATE)

		})

		Convey("private message response should have participant status data", func() {
			cmc, err := rest.SendPrivateMessage(
				account.Id,
				"this is a body for private message @chris @devrim @sinan",
				groupName,
				[]string{"chris", "devrim", "sinan"},
			)
			So(err, ShouldBeNil)
			So(cmc, ShouldNotBeNil)
			So(cmc.IsParticipant, ShouldBeTrue)
		})

		Convey("private message response should have participant count", func() {
			cmc, err := rest.SendPrivateMessage(
				account.Id,
				"this is a body for @sinan private message @devrim",
				groupName,
				[]string{"devrim", "sinan"},
			)
			So(err, ShouldBeNil)
			So(cmc, ShouldNotBeNil)
			So(cmc.ParticipantCount, ShouldEqual, 3)
		})

		Convey("private message response should have participant preview", func() {
			cmc, err := rest.SendPrivateMessage(
				account.Id,
				"this is @chris a body for @devrim private message",
				groupName,
				[]string{"chris", "devrim"},
			)
			So(err, ShouldBeNil)
			So(cmc, ShouldNotBeNil)
			So(len(cmc.ParticipantsPreview), ShouldEqual, 3)
		})

		Convey("private message response should have last Message", func() {
			body := "hi @devrim this is a body for private message also for @chris"
			cmc, err := rest.SendPrivateMessage(
				account.Id,
				body,
				groupName,
				[]string{"chris", "devrim"},
			)
			So(err, ShouldBeNil)
			So(cmc, ShouldNotBeNil)
			So(cmc.LastMessage.Message.Body, ShouldEqual, body)
		})

		Convey("private message should be listed by all recipients", func() {
			// use a different group name
			// in order not to interfere with another request
			groupName := "testgroup" + strconv.FormatInt(rand.Int63(), 10)

			body := "hi @devrim this is a body for private message also for @chris"
			cmc, err := rest.SendPrivateMessage(
				account.Id,
				body,
				groupName,
				[]string{"chris", "devrim"},
			)
			So(err, ShouldBeNil)
			So(cmc, ShouldNotBeNil)

			pm, err := rest.GetPrivateMessages(&request.Query{AccountId: account.Id, GroupName: groupName})
			So(err, ShouldBeNil)
			So(pm, ShouldNotBeNil)
			So(pm[0], ShouldNotBeNil)
			So(pm[0].Channel.TypeConstant, ShouldEqual, models.Channel_TYPE_PRIVATE_MESSAGE)
			So(pm[0].Channel.Id, ShouldEqual, cmc.Channel.Id)
			So(pm[0].Channel.GroupName, ShouldEqual, cmc.Channel.GroupName)
			So(pm[0].LastMessage.Message.Body, ShouldEqual, cmc.LastMessage.Message.Body)
			So(pm[0].Channel.PrivacyConstant, ShouldEqual, models.Channel_PRIVACY_PRIVATE)
			So(len(pm[0].ParticipantsPreview), ShouldEqual, 3)
			So(pm[0].IsParticipant, ShouldBeTrue)

		})

		Convey("targetted account should be able to list private message channel of himself", nil)

	})
}
