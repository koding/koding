package main

import (
	"encoding/json"
	"koding/db/mongodb/modelhelper"
	"socialapi/models"
	"socialapi/request"
	"socialapi/rest"
	"socialapi/workers/common/tests"
	"testing"

	"github.com/koding/runner"

	. "github.com/smartystreets/goconvey/convey"
)

func TestCollaborationChannels(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("while testing collaboration channel", t, func() {
			devrim, err := models.CreateAccountInBothDbsWithNick("devrim")
			So(err, ShouldBeNil)
			So(devrim, ShouldNotBeNil)
			sinan, err := models.CreateAccountInBothDbsWithNick("sinan")
			So(err, ShouldBeNil)
			So(sinan, ShouldNotBeNil)

			groupName := models.RandomGroupName()

			// cretae admin user
			account, err := models.CreateAccountInBothDbs()
			tests.ResultedWithNoErrorCheck(account, err)
			// fetch admin's session
			ses, err := modelhelper.FetchOrCreateSession(account.Nick, groupName)
			So(err, ShouldBeNil)
			So(ses, ShouldNotBeNil)

			groupChannel := models.CreateTypedGroupedChannelWithTest(
				account.Id,
				models.Channel_TYPE_GROUP,
				groupName,
			)

			groupChannel.AddParticipant(account.Id)

			_, err = groupChannel.AddParticipant(devrim.Id)
			So(err, ShouldBeNil)
			_, err = groupChannel.AddParticipant(sinan.Id)
			So(err, ShouldBeNil)

			recipient, err := models.CreateAccountInBothDbs()
			tests.ResultedWithNoErrorCheck(recipient, err)

			recipient2, err := models.CreateAccountInBothDbs()
			tests.ResultedWithNoErrorCheck(recipient2, err)

			Convey("one can send initiate the collaboration channel with only him", func() {
				pmr := models.ChannelRequest{}
				pmr.AccountId = account.Id
				pmr.Body = "this is a body for private message"
				pmr.GroupName = groupName
				pmr.Recipients = []string{}
				pmr.TypeConstant = models.Channel_TYPE_COLLABORATION

				cmc, err := rest.SendPrivateChannelRequest(pmr, ses.ClientId)
				So(err, ShouldBeNil)
				So(cmc, ShouldNotBeNil)

			})

			Convey("one can send initiate the collaboration channel with 2 participants", func() {
				pmr := models.ChannelRequest{}
				pmr.AccountId = account.Id
				pmr.Body = "this is a body message for private message @devrim @sinan"
				pmr.GroupName = groupName
				pmr.Recipients = []string{"devrim", "sinan"}
				pmr.TypeConstant = models.Channel_TYPE_COLLABORATION

				cmc, err := rest.SendPrivateChannelRequest(pmr, ses.ClientId)
				So(err, ShouldBeNil)
				So(cmc, ShouldNotBeNil)

			})

			Convey("if group name is nil, should not fail to create collaboration channel", func() {
				ses, err := modelhelper.FetchOrCreateSession(sinan.Nick, "koding")
				So(err, ShouldBeNil)
				So(ses, ShouldNotBeNil)

				groupChannel, err := rest.CreateChannelByGroupNameAndType(
					sinan.Id,
					"koding",
					models.Channel_TYPE_GROUP,
					ses.ClientId,
				)
				tests.ResultedWithNoErrorCheck(groupChannel, err)
				groupChannel.AddParticipant(devrim.Id)  // ignore error
				groupChannel.AddParticipant(account.Id) // ignore error
				groupChannel.AddParticipant(sinan.Id)   // ignore error

				pmr := models.ChannelRequest{}
				pmr.AccountId = account.Id
				pmr.Body = "this is a body for private message @devrim @sinan"
				pmr.GroupName = ""
				pmr.Recipients = []string{"devrim", "sinan"}
				pmr.TypeConstant = models.Channel_TYPE_COLLABORATION

				cmc, err := rest.SendPrivateChannelRequest(pmr, ses.ClientId)
				So(err, ShouldBeNil)
				So(cmc, ShouldNotBeNil)
			})

			// we give token as parameter to SendPrivateChannelRequest
			// handler sets the accountId and groupname if not defined in handler's function
			// So it should not return any error unless account is defined
			Convey("if sender is not defined should not fail to create collaboration channel", func() {
				pmr := models.ChannelRequest{}
				pmr.AccountId = 0
				pmr.Body = "this is a body for private message"
				pmr.GroupName = ""
				pmr.Recipients = []string{}
				pmr.TypeConstant = models.Channel_TYPE_COLLABORATION

				cmc, err := rest.SendPrivateChannelRequest(pmr, ses.ClientId)
				So(err, ShouldBeNil)
				So(cmc, ShouldNotBeNil)
			})

			Convey("one can send private message to multiple person", func() {
				pmr := models.ChannelRequest{}
				pmr.AccountId = account.Id
				pmr.Body = "this is a body for private message @sinan"
				pmr.GroupName = groupName
				pmr.Recipients = []string{"sinan"}
				pmr.TypeConstant = models.Channel_TYPE_COLLABORATION

				cmc, err := rest.SendPrivateChannelRequest(pmr, ses.ClientId)
				So(err, ShouldBeNil)
				So(cmc, ShouldNotBeNil)

			})

			Convey("response should have created channel", func() {
				pmr := models.ChannelRequest{}
				pmr.AccountId = account.Id
				pmr.Body = "this is a body for private message @devrim @sinan"
				pmr.GroupName = groupName
				pmr.Recipients = []string{"devrim", "sinan"}
				pmr.TypeConstant = models.Channel_TYPE_COLLABORATION

				cmc, err := rest.SendPrivateChannelRequest(pmr, ses.ClientId)
				So(err, ShouldBeNil)
				So(cmc, ShouldNotBeNil)
				So(cmc.Channel.TypeConstant, ShouldEqual, models.Channel_TYPE_COLLABORATION)
				So(cmc.Channel.Id, ShouldBeGreaterThan, 0)
				So(cmc.Channel.GroupName, ShouldEqual, groupName)
				So(cmc.Channel.PrivacyConstant, ShouldEqual, models.Channel_PRIVACY_PRIVATE)

			})

			Convey("send response should have participant status data", func() {
				pmr := models.ChannelRequest{}
				pmr.AccountId = account.Id
				pmr.Body = "this is a body for private message @devrim @sinan"
				pmr.GroupName = groupName
				pmr.Recipients = []string{"devrim", "sinan"}
				pmr.TypeConstant = models.Channel_TYPE_COLLABORATION

				cmc, err := rest.SendPrivateChannelRequest(pmr, ses.ClientId)
				So(err, ShouldBeNil)
				So(cmc, ShouldNotBeNil)
				So(cmc.IsParticipant, ShouldBeTrue)
			})

			Convey("send response should have participant count", func() {
				pmr := models.ChannelRequest{}
				pmr.AccountId = account.Id
				pmr.Body = "this is a body for @sinan private message @devrim"
				pmr.GroupName = groupName
				pmr.Recipients = []string{"devrim", "sinan"}
				pmr.TypeConstant = models.Channel_TYPE_COLLABORATION

				cmc, err := rest.SendPrivateChannelRequest(pmr, ses.ClientId)
				So(err, ShouldBeNil)
				So(cmc, ShouldNotBeNil)
				So(cmc.ParticipantCount, ShouldEqual, 3)
			})

			Convey("send response should have participant preview", func() {
				pmr := models.ChannelRequest{}
				pmr.AccountId = account.Id
				pmr.Body = "this is @sinan a body for @devrim private message"
				pmr.GroupName = groupName
				pmr.Recipients = []string{"sinan", "devrim"}
				pmr.TypeConstant = models.Channel_TYPE_COLLABORATION

				cmc, err := rest.SendPrivateChannelRequest(pmr, ses.ClientId)
				So(err, ShouldBeNil)
				So(cmc, ShouldNotBeNil)
				So(len(cmc.ParticipantsPreview), ShouldEqual, 3)
			})

			Convey("send response should have last Message", func() {
				body := "hi @devrim this is a body for private message also for @sinan"
				pmr := models.ChannelRequest{}
				pmr.AccountId = account.Id
				pmr.Body = body
				pmr.GroupName = groupName
				pmr.Recipients = []string{"sinan", "devrim"}
				pmr.TypeConstant = models.Channel_TYPE_COLLABORATION

				cmc, err := rest.SendPrivateChannelRequest(pmr, ses.ClientId)
				So(err, ShouldBeNil)
				So(cmc, ShouldNotBeNil)
				So(cmc.LastMessage.Message.Body, ShouldEqual, body)
			})

			Convey("channel messages should be listed by all recipients", func() {
				// // use a different group name
				// // in order not to interfere with another request
				// groupName := "testgroup" + strconv.FormatInt(rand.Int63(), 10)

				body := "hi @devrim this is a body for private message also for @sinan"
				pmr := models.ChannelRequest{}
				pmr.AccountId = account.Id
				pmr.Body = body
				pmr.GroupName = groupName
				pmr.Recipients = []string{"sinan", "devrim"}
				pmr.TypeConstant = models.Channel_TYPE_COLLABORATION

				cmc, err := rest.SendPrivateChannelRequest(pmr, ses.ClientId)
				So(err, ShouldBeNil)
				So(cmc, ShouldNotBeNil)

				query := &request.Query{
					AccountId: account.Id,
					GroupName: groupName,
					Type:      models.Channel_TYPE_COLLABORATION,
				}

				pm, err := rest.GetPrivateChannels(query, ses.ClientId)
				So(err, ShouldBeNil)
				So(pm, ShouldNotBeNil)
				So(len(pm), ShouldNotEqual, 0)
				So(pm[0], ShouldNotBeNil)
				So(pm[0].Channel.TypeConstant, ShouldEqual, models.Channel_TYPE_COLLABORATION)
				So(pm[0].Channel.Id, ShouldEqual, cmc.Channel.Id)
				So(pm[0].Channel.GroupName, ShouldEqual, cmc.Channel.GroupName)
				So(pm[0].LastMessage.Message.Body, ShouldEqual, cmc.LastMessage.Message.Body)
				So(pm[0].Channel.PrivacyConstant, ShouldEqual, models.Channel_PRIVACY_PRIVATE)
				So(len(pm[0].ParticipantsPreview), ShouldEqual, 3)
				So(pm[0].IsParticipant, ShouldBeTrue)

			})

			Convey("user should be able to search collaboration channels via purpose field", func() {
				pmr := models.ChannelRequest{}
				pmr.AccountId = account.Id
				pmr.Body = "search collaboration channel"
				pmr.GroupName = groupName
				pmr.Recipients = []string{"sinan", "devrim"}
				pmr.Purpose = "test me up"
				pmr.TypeConstant = models.Channel_TYPE_COLLABORATION

				cmc, err := rest.SendPrivateChannelRequest(pmr, ses.ClientId)
				So(err, ShouldBeNil)

				query := request.Query{
					AccountId: account.Id,
					GroupName: groupName,
					Type:      models.Channel_TYPE_COLLABORATION,
				}

				_, err = rest.SearchPrivateChannels(&query, ses.ClientId)
				So(err, ShouldNotBeNil)

				query.Name = "test"
				pm, err := rest.SearchPrivateChannels(&query, ses.ClientId)
				So(err, ShouldBeNil)
				So(pm, ShouldNotBeNil)
				So(len(pm), ShouldNotEqual, 0)
				So(pm[0], ShouldNotBeNil)
				So(pm[0].Channel.TypeConstant, ShouldEqual, models.Channel_TYPE_COLLABORATION)
				So(pm[0].Channel.Id, ShouldEqual, cmc.Channel.Id)
				So(pm[0].Channel.GroupName, ShouldEqual, cmc.Channel.GroupName)
				So(pm[0].LastMessage.Message.Body, ShouldEqual, cmc.LastMessage.Message.Body)
				So(pm[0].Channel.PrivacyConstant, ShouldEqual, models.Channel_PRIVACY_PRIVATE)
				So(pm[0].IsParticipant, ShouldBeTrue)

			})

			Convey("user join activity should be listed by recipients", func() {
				groupName := models.RandomGroupName()

				// cretae admin user
				account, err := models.CreateAccountInBothDbs()
				tests.ResultedWithNoErrorCheck(account, err)
				// fetch admin's session
				ses, err := modelhelper.FetchOrCreateSession(account.Nick, groupName)
				So(err, ShouldBeNil)
				So(ses, ShouldNotBeNil)

				groupChannel := models.CreateTypedGroupedChannelWithTest(
					account.Id,
					models.Channel_TYPE_GROUP,
					groupName,
				)
				So(groupChannel, ShouldNotBeNil)

				_, err = groupChannel.AddParticipant(account.Id)
				So(err, ShouldBeNil)
				_, err = groupChannel.AddParticipant(devrim.Id)
				So(err, ShouldBeNil)
				_, err = groupChannel.AddParticipant(sinan.Id)
				So(err, ShouldBeNil)
				_, err = groupChannel.AddParticipant(recipient.Id)
				So(err, ShouldBeNil)

				pmr := models.ChannelRequest{}
				pmr.AccountId = account.Id
				pmr.Body = "test collaboration channel participants"
				pmr.GroupName = groupName
				pmr.Recipients = []string{"sinan", "devrim"}
				pmr.TypeConstant = models.Channel_TYPE_COLLABORATION

				cc, err := rest.SendPrivateChannelRequest(pmr, ses.ClientId)

				So(err, ShouldBeNil)
				So(cc, ShouldNotBeNil)

				history, err := rest.GetHistory(
					cc.Channel.Id,
					&request.Query{
						AccountId: account.Id,
					},
					ses.ClientId,
				)

				So(err, ShouldBeNil)
				So(history, ShouldNotBeNil)
				So(len(history.MessageList), ShouldEqual, 2)

				// add participant
				_, err = rest.AddChannelParticipant(cc.Channel.Id, ses.ClientId, recipient.Id)
				So(err, ShouldBeNil)

				history, err = rest.GetHistory(
					cc.Channel.Id,
					&request.Query{
						AccountId: account.Id,
					},
					ses.ClientId,
				)

				So(err, ShouldBeNil)
				So(history, ShouldNotBeNil)
				So(len(history.MessageList), ShouldEqual, 3)

				So(history.MessageList[0].Message, ShouldNotBeNil)
				So(history.MessageList[0].Message.TypeConstant, ShouldEqual, models.ChannelMessage_TYPE_SYSTEM)
				So(history.MessageList[0].Message.Payload, ShouldNotBeNil)
				addedBy, ok := history.MessageList[0].Message.Payload["addedBy"]
				So(ok, ShouldBeTrue)
				So(*addedBy, ShouldEqual, account.Nick)

				systemType, ok := history.MessageList[0].Message.Payload["systemType"]
				So(ok, ShouldBeTrue)
				So(*systemType, ShouldEqual, models.ChannelRequestMessage_TYPE_JOIN)

				// try to add same participant
				_, err = rest.AddChannelParticipant(cc.Channel.Id, ses.ClientId, recipient.Id)
				So(err, ShouldBeNil)

				history, err = rest.GetHistory(
					cc.Channel.Id,
					&request.Query{
						AccountId: account.Id,
					},
					ses.ClientId,
				)

				So(err, ShouldBeNil)
				So(history, ShouldNotBeNil)
				So(len(history.MessageList), ShouldEqual, 3)

			})

			Convey("user should not be able to edit join messages", func() {
				pmr := models.ChannelRequest{}
				pmr.AccountId = account.Id
				pmr.Body = "test collaboration channel participants again"
				pmr.GroupName = groupName
				pmr.Recipients = []string{"devrim"}
				pmr.TypeConstant = models.Channel_TYPE_COLLABORATION

				cc, err := rest.SendPrivateChannelRequest(pmr, ses.ClientId)
				So(err, ShouldBeNil)
				So(cc, ShouldNotBeNil)

				_, err = rest.AddChannelParticipant(cc.Channel.Id, ses.ClientId, recipient.Id)
				So(err, ShouldBeNil)

				ses, err := modelhelper.FetchOrCreateSession(account.Nick, groupName)
				So(err, ShouldBeNil)
				So(ses, ShouldNotBeNil)

				history, err := rest.GetHistory(
					cc.Channel.Id,
					&request.Query{
						AccountId: account.Id,
					},
					ses.ClientId,
				)

				So(err, ShouldBeNil)
				So(history, ShouldNotBeNil)
				So(len(history.MessageList), ShouldEqual, 3)

				joinMessage := history.MessageList[0].Message
				So(joinMessage, ShouldNotBeNil)

				_, err = rest.UpdatePost(joinMessage, ses.ClientId)
				So(err, ShouldNotBeNil)
			})

			Convey("first chat message should include initial participants", func() {
				pmr := models.ChannelRequest{}
				pmr.AccountId = account.Id
				pmr.Body = "test initial participation message"
				pmr.GroupName = groupName
				pmr.Recipients = []string{"sinan", "devrim"}
				pmr.TypeConstant = models.Channel_TYPE_COLLABORATION

				cc, err := rest.SendPrivateChannelRequest(pmr, ses.ClientId)
				So(err, ShouldBeNil)
				So(cc, ShouldNotBeNil)

				ses, err := modelhelper.FetchOrCreateSession(account.Nick, groupName)
				So(err, ShouldBeNil)
				So(ses, ShouldNotBeNil)

				history, err := rest.GetHistory(
					cc.Channel.Id,
					&request.Query{
						AccountId: account.Id,
					},
					ses.ClientId,
				)

				So(err, ShouldBeNil)
				So(history, ShouldNotBeNil)
				So(len(history.MessageList), ShouldEqual, 2)

				joinMessage := history.MessageList[1].Message
				So(joinMessage.TypeConstant, ShouldEqual, models.ChannelMessage_TYPE_SYSTEM)
				So(joinMessage.Payload, ShouldNotBeNil)
				initialParticipants, ok := joinMessage.Payload["initialParticipants"]
				So(ok, ShouldBeTrue)

				systemType, ok := history.MessageList[1].Message.Payload["systemType"]
				So(ok, ShouldBeTrue)
				So(*systemType, ShouldEqual, models.ChannelRequestMessage_TYPE_INIT)

				participants := make([]string, 0)
				err = json.Unmarshal([]byte(*initialParticipants), &participants)
				So(err, ShouldBeNil)
				So(len(participants), ShouldEqual, 2)
				So(participants, ShouldContain, "devrim")
				// So(*addedBy, ShouldEqual, account.OldId)

			})
		})
	})
}
