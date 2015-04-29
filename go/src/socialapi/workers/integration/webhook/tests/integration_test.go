package tests

import (
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/models"
	"socialapi/request"
	"socialapi/rest"
	"socialapi/workers/integration/webhook"
	"socialapi/workers/integration/webhook/api"
	"socialapi/workers/integration/webhook/services"
	"testing"

	"github.com/koding/runner"
	. "github.com/smartystreets/goconvey/convey"
)

func newPrepareRequest(email string) *services.ServiceInput {
	return &services.ServiceInput{
		"email":     email,
		"eventName": "emailOpen",
		"dataFields": map[string]interface{}{
			"templateId": float64(15120),
			"device":     "Gmail",
			"createdAt":  "2015-04-24 21:35:02 +00:00",
			"campaignId": float64(5654),
			"userAgent":  "Mozilla/5.0 (Windows NT 5.1; rv:11.0) Gecko Firefox/11.0 (via ggpht.com GoogleImageProxy)",
			"ip":         "66.249.93.139",
		},
	}
}

func newPushRequest(channelId int64, groupName string) *api.WebhookRequest {
	wr := &api.WebhookRequest{
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
	r := runner.New("test webhook")
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

		ses, err := models.FetchOrCreateSession(account.Nick)
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
		channel := models.CreateTypedGroupedChannelWithTest(account.Id, models.Channel_TYPE_GROUP, models.RandomName())
		_, err = channel.AddParticipant(account.Id)
		So(err, ShouldBeNil)

		ses, err := models.FetchOrCreateSession(account.Nick)
		So(err, ShouldBeNil)
		So(ses, ShouldNotBeNil)

		channelId, err := rest.DoBotChannelRequest(ses.ClientId)

		So(err, ShouldBeNil)
		So(channelId, ShouldNotEqual, 0)
	})

	Convey("We should be able to successfully push messages via prepare endpoint", t, func() {

		account, err := models.CreateAccountInBothDbsWithNick(models.RandomName())
		So(err, ShouldBeNil)

		err = rest.DoPrepareRequest(newPrepareRequest("xxx@koding.com"), channelIntegration.Token)
		So(err, ShouldNotBeNil)

		err = rest.DoPrepareRequest(newPrepareRequest(account.Nick+"@koding.com"), channelIntegration.Token)
		So(err, ShouldBeNil)

		ses, err := models.FetchOrCreateSession(account.Nick)
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
	})

}
