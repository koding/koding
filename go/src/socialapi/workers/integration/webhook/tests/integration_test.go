package tests

import (
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/models"
	"socialapi/request"
	"socialapi/rest"
	"socialapi/workers/integration/webhook"
	"socialapi/workers/integration/webhook/api"
	"testing"

	"github.com/koding/integration/services"
	"github.com/koding/runner"
	. "github.com/smartystreets/goconvey/convey"
)

func newMiddlewareRequest(username, groupName string) *services.ServiceInput {
	return &services.ServiceInput{
		"username":  username,
		"eventName": "emailOpen",
		"message":   "testing it",
		"groupName": groupName,
	}
}

func newPushRequest(channelId int64, groupName string) *api.PushRequest {
	wr := &api.PushRequest{
		GroupName: groupName,
	}
	wr.Body = "hey"
	wr.ChannelId = channelId

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

	channelIntegration := webhook.CreateTestChannelIntegration(t)

	webhook.CreateIterableIntegration(t)

	Convey("We should be able to successfully push message", t, func() {

		account, err := models.CreateAccountInBothDbsWithNick("sinan")
		So(err, ShouldBeNil)

		channel := models.CreateTypedGroupedChannelWithTest(account.Id, models.Channel_TYPE_TOPIC, channelIntegration.GroupName)
		_, err = channel.AddParticipant(account.Id)
		So(err, ShouldBeNil)

		err = rest.DoPushRequest(newPushRequest(channel.Id, channelIntegration.GroupName), channelIntegration.Token)
		So(err, ShouldBeNil)

		ses, err := models.FetchOrCreateSession(account.Nick, channelIntegration.GroupName)
		So(err, ShouldBeNil)
		So(ses, ShouldNotBeNil)

		resp, err := rest.GetHistory(channel.Id,
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

	Convey("We should be able to successfully push messages via prepare endpoint", t, func() {

		account, err := models.CreateAccountInBothDbsWithNick(models.RandomName())
		So(err, ShouldBeNil)

		channel := models.CreateTypedGroupedChannelWithTest(account.Id, models.Channel_TYPE_GROUP, channelIntegration.GroupName)
		_, err = channel.AddParticipant(account.Id)

		pr := newMiddlewareRequest("xxx", channelIntegration.GroupName)
		err = rest.DoPrepareRequest(pr, channelIntegration.Token)
		So(err, ShouldNotBeNil)

		pr = newMiddlewareRequest(account.Nick, channelIntegration.GroupName)
		err = rest.DoPrepareRequest(pr, channelIntegration.Token)
		So(err, ShouldBeNil)

		ses, err := models.FetchOrCreateSession(account.Nick, channelIntegration.GroupName)
		So(err, ShouldBeNil)
		So(ses, ShouldNotBeNil)

		channelId, err := rest.DoBotChannelRequest(ses.ClientId)
		So(err, ShouldBeNil)

		resp, err := rest.GetHistory(channelId,
			&request.Query{
				AccountId: account.Id,
			},
			ses.ClientId,
		)

		So(err, ShouldBeNil)
		So(len(resp.MessageList), ShouldEqual, 1)
		So(resp.MessageList[0].Message.Body, ShouldEqual, "testing it")
	})

	Convey("We should not be able to send more than 100 requests per minute", t, func() {

		account, err := models.CreateAccountInBothDbsWithNick("sinan")
		So(err, ShouldBeNil)

		channel := models.CreateTypedGroupedChannelWithTest(account.Id, models.Channel_TYPE_TOPIC, channelIntegration.GroupName)
		_, err = channel.AddParticipant(account.Id)
		So(err, ShouldBeNil)

		for i := 0; i < 99; i++ {
			err = rest.DoPushRequest(newPushRequest(channel.Id, channelIntegration.GroupName), channelIntegration.Token)
			So(err, ShouldBeNil)
		}

		err = rest.DoPushRequest(newPushRequest(channel.Id, channelIntegration.GroupName), channelIntegration.Token)
		So(err, ShouldNotBeNil)

	})

}
