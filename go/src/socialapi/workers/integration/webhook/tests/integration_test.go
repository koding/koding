package tests

import (
	"errors"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/models"
	"socialapi/request"
	"socialapi/rest"
	"socialapi/workers/integration/webhook"
	"socialapi/workers/integration/webhook/api"
	"testing"
	"time"

	"github.com/koding/runner"
	. "github.com/smartystreets/goconvey/convey"
)

func newPushRequest(body string) *api.PushRequest {
	wr := &api.PushRequest{
		Message: webhook.Message{
			Body: body,
		},
	}

	return wr
}

func newBotChannelRequest(nick, groupName string) *api.BotChannelRequest {
	return &api.BotChannelRequest{
		GroupName: groupName,
		Username:  nick,
	}
}

func TestWebhook(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	Convey("We should be able to successfully push message", t, func() {
		channelIntegration, topicChannel := webhook.CreateTestChannelIntegration(t)

		account, err := models.CreateAccountInBothDbsWithNick("sinan")
		So(err, ShouldBeNil)

		_, err = topicChannel.AddParticipant(account.Id)
		So(err, ShouldBeNil)

		err = rest.DoPushRequest(newPushRequest(models.RandomName()), channelIntegration.Token)
		So(err, ShouldBeNil)

		ses, err := models.FetchOrCreateSession(account.Nick, channelIntegration.GroupName)
		So(err, ShouldBeNil)
		So(ses, ShouldNotBeNil)

		resp, err := rest.GetHistory(channelIntegration.ChannelId,
			&request.Query{
				AccountId: account.Id,
			},
			ses.ClientId,
		)

		So(err, ShouldBeNil)
		So(len(resp.MessageList), ShouldEqual, 1)
	})

	Convey("We should be able to successfully fetch bot channel of the user", t, func() {
		account, err := models.CreateAccountInBothDbsWithNick("sinan")
		So(err, ShouldBeNil)
		groupName := models.RandomGroupName()
		channel := models.CreateTypedGroupedChannelWithTest(account.Id, models.Channel_TYPE_GROUP, groupName)
		_, err = channel.AddParticipant(account.Id)
		So(err, ShouldBeNil)

		ses, err := models.FetchOrCreateSession(account.Nick, groupName)
		So(err, ShouldBeNil)
		So(ses, ShouldNotBeNil)

		channelId, err := rest.DoBotChannelRequest(ses.ClientId)

		So(err, ShouldBeNil)
		So(channelId, ShouldNotEqual, 0)
	})

	Convey("We should be able to successfully receive github push messages via middleware", t, func() {
		channelIntegration, topicChannel := webhook.CreateTestChannelIntegration(t)

		account, err := models.CreateAccountInBothDbsWithNick(models.RandomName())
		So(err, ShouldBeNil)

		channel := models.CreateTypedGroupedChannelWithTest(account.Id, models.Channel_TYPE_GROUP, channelIntegration.GroupName)

		_, err = channel.AddParticipant(account.Id)
		So(err, ShouldBeNil)
		_, err = topicChannel.AddParticipant(account.Id)
		So(err, ShouldBeNil)

		err = rest.DoGithubPush(githubPushEventData, channelIntegration.Token)
		So(err, ShouldBeNil)

		ses, err := models.FetchOrCreateSession(account.Nick, channelIntegration.GroupName)
		So(err, ShouldBeNil)
		So(ses, ShouldNotBeNil)

		tick := time.Tick(time.Millisecond * 200)
		deadLine := time.After(10 * time.Second)
		for {
			select {
			case <-tick:
				resp, err := rest.GetHistory(topicChannel.Id,
					&request.Query{},
					ses.ClientId,
				)
				So(err, ShouldBeNil)
				if len(resp.MessageList) > 0 {
					So(len(resp.MessageList), ShouldEqual, 1)
					So(resp.MessageList[0].Message.Body, ShouldStartWith, "[canthefason](https://github.com/canthefason) [pushed]")
					return
				}
			case <-deadLine:
				So(errors.New("Could not fetch messages"), ShouldBeNil)
			}
		}

	})

	Convey("We should be able to successfully receive payload of github push messages via middleware", t, func() {
		channelIntegration, topicChannel := webhook.CreateTestChannelIntegration(t)

		account, err := models.CreateAccountInBothDbsWithNick(models.RandomName())
		So(err, ShouldBeNil)

		channel := models.CreateTypedGroupedChannelWithTest(account.Id, models.Channel_TYPE_GROUP, channelIntegration.GroupName)

		_, err = channel.AddParticipant(account.Id)
		So(err, ShouldBeNil)
		_, err = topicChannel.AddParticipant(account.Id)
		So(err, ShouldBeNil)

		err = rest.DoGithubPush(githubPushEventData, channelIntegration.Token)
		So(err, ShouldBeNil)

		ses, err := models.FetchOrCreateSession(account.Nick, channelIntegration.GroupName)
		So(err, ShouldBeNil)
		So(ses, ShouldNotBeNil)

		tick := time.Tick(time.Millisecond * 200)
		deadLine := time.After(10 * time.Second)
		for {
			select {
			case <-tick:
				resp, err := rest.GetHistory(topicChannel.Id,
					&request.Query{},
					ses.ClientId,
				)
				So(err, ShouldBeNil)
				if len(resp.MessageList) > 0 {
					So(len(resp.MessageList), ShouldEqual, 1)
					So(*resp.MessageList[0].Message.Payload["eventType"], ShouldEqual, "push")
					return
				}
			case <-deadLine:
				So(errors.New("Could not fetch messages"), ShouldBeNil)
			}
		}

	})

	Convey("We should be able to successfully receive pivotal push messages via middleware", t, func() {
		channelIntegration, topicChannel := webhook.CreateTestChannelIntegration(t)

		account, err := models.CreateAccountInBothDbsWithNick(models.RandomName())
		So(err, ShouldBeNil)

		channel := models.CreateTypedGroupedChannelWithTest(account.Id, models.Channel_TYPE_GROUP, channelIntegration.GroupName)

		_, err = channel.AddParticipant(account.Id)
		So(err, ShouldBeNil)
		_, err = topicChannel.AddParticipant(account.Id)
		So(err, ShouldBeNil)

		err = rest.DoPivotalPush("POST", pivotalEventData, channelIntegration.Token)
		So(err, ShouldBeNil)

		ses, err := models.FetchOrCreateSession(account.Nick, channelIntegration.GroupName)
		So(err, ShouldBeNil)
		So(ses, ShouldNotBeNil)

		tick := time.Tick(time.Millisecond * 200)
		deadLine := time.After(10 * time.Second)
		for {
			select {
			case <-tick:
				resp, err := rest.GetHistory(topicChannel.Id,
					&request.Query{},
					ses.ClientId,
				)
				So(err, ShouldBeNil)
				if len(resp.MessageList) > 0 {
					So(len(resp.MessageList), ShouldEqual, 1)
					So(resp.MessageList[0].Message.Body, ShouldStartWith, "[pivotal-project] Mehmet Ali Savas started this feature")
					return
				}
			case <-deadLine:
				So(errors.New("Could not fetch messages"), ShouldBeNil)
			}
		}

	})
}
