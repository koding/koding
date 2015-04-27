package api

import (
	"koding/db/mongodb/modelhelper"
	"math/rand"
	"net/http"
	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/common/mux"
	"socialapi/workers/integration/webhook"
	"socialapi/workers/integration/webhook/services"
	"testing"
	"time"

	"github.com/koding/logging"
	"github.com/koding/runner"
	"github.com/rcrowley/go-tigertonic/mocking"
	. "github.com/smartystreets/goconvey/convey"
)

var (
	r *runner.Runner
	h *Handler
	m *mux.Mux
)

func newRequest(body string, channelId int64, groupName string) *WebhookRequest {
	return &WebhookRequest{
		Message: webhook.Message{
			Body:      body,
			ChannelId: channelId,
		},
		GroupName: groupName,
	}
}

func newBotChannelRequest(groupName string) *BotChannelRequest {
	return &BotChannelRequest{
		GroupName: groupName,
	}
}

func init() {
	var err error
	r = runner.New("test")
	if err := r.Init(); err != nil {
		panic(err)
	}
	r.Log.SetLevel(logging.CRITICAL)

	defer r.Close()
	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)

	mc := mux.NewConfig("testing", "", "")
	m = mux.New(mc, r.Log)

	h, err = NewHandler(r.Log)
	if err != nil {
		panic(err)
	}

	h.AddHandlers(m)

	rand.Seed(time.Now().UTC().UnixNano())
}

func TestWebhookListen(t *testing.T) {

	account, err := models.CreateAccountInBothDbsWithNick("sinan")
	if err != nil {
		t.Fatalf("could not create test account: %s", err)
	}

	channelIntegration := webhook.CreateTestChannelIntegration(t)

	Convey("while testing incoming webhook", t, func() {

		groupName := models.RandomName()
		channel := models.CreateTypedGroupedChannelWithTest(account.Id, models.Channel_TYPE_TOPIC, groupName)

		Convey("users should not be able to send any message when they don't have valid token", func() {
			token := "123123"
			s, _, _, err := h.Push(
				mocking.URL(m, "POST", "/webhook/push/"+token),
				mocking.Header(nil),
				newRequest("hey", channel.Id, "koding"),
			)
			So(err, ShouldNotBeNil)
			So(s, ShouldEqual, http.StatusNotFound)

			token = ""
			s, _, _, err = h.Push(
				mocking.URL(m, "POST", "/webhook/push/"+token),
				mocking.Header(nil),
				newRequest("hey", channel.Id, "koding"),
			)
			So(err.Error(), ShouldEqual, ErrTokenNotSet.Error())
			So(s, ShouldEqual, http.StatusBadRequest)
		})

		Convey("users should not be able to send any message when their request does not include body or channel name", func() {

			token := "123123"
			s, _, _, err := h.Push(
				mocking.URL(m, "POST", "/webhook/push/"+token),
				mocking.Header(nil),
				newRequest("", channel.Id, "koding"),
			)
			So(err.Error(), ShouldEqual, ErrBodyNotSet.Error())
			So(s, ShouldEqual, http.StatusBadRequest)

			s, _, _, err = h.Push(
				mocking.URL(m, "POST", "/webhook/push/"+token),
				mocking.Header(nil),
				newRequest("hey", 0, "koding"),
			)
			So(err.Error(), ShouldEqual, ErrChannelNotSet.Error())
			So(s, ShouldEqual, http.StatusBadRequest)

			s, _, _, err = h.Push(
				mocking.URL(m, "POST", "/webhook/push/"+token),
				mocking.Header(nil),
				newRequest("hey", channel.Id, ""),
			)
			So(err.Error(), ShouldEqual, ErrGroupNotSet.Error())
			So(s, ShouldEqual, http.StatusBadRequest)
		})

		Convey("users should be able to send message when token is valid", func() {

			Convey("related integrations must be created", func() {

				token := channelIntegration.Token
				s, _, _, err := h.Push(
					mocking.URL(m, "POST", "/webhook/push/"+token),
					mocking.Header(nil),
					newRequest("hey", channel.Id, "koding"),
				)

				So(err, ShouldBeNil)
				So(s, ShouldEqual, http.StatusOK)
			})
		})

	})
}

func TestWebhookPrepare(t *testing.T) {

	webhook.CreateIterableIntegration(t)

	Convey("while testing incoming webhook", t, func() {

		Convey("users should not be able to send any message when they don't have valid token", func() {
			token := ""
			integrationName := "testing"
			s, _, _, err := h.Prepare(
				mocking.URL(m, "POST", "/webhook/"+integrationName+"/"+token),
				mocking.Header(nil),
				services.ServiceInput{},
			)
			So(err.Error(), ShouldEqual, ErrTokenNotSet.Error())
			So(s, ShouldEqual, http.StatusBadRequest)

			token = "123123123"
			integrationName = ""
			s, _, _, err = h.Prepare(
				mocking.URL(m, "POST", "/webhook/"+integrationName+"/"+token),
				mocking.Header(nil),
				services.ServiceInput{},
			)
			So(err.Error(), ShouldEqual, ErrNameNotSet.Error())
			So(s, ShouldEqual, http.StatusBadRequest)

			integrationName = "testing"
			s, _, _, err = h.Prepare(
				mocking.URL(m, "POST", "/webhook/"+integrationName+"/"+token),
				mocking.Header(nil),
				services.ServiceInput{},
			)
			So(err, ShouldNotBeNil)
			So(s, ShouldEqual, http.StatusNotFound)

			push = func(endPoint string, request map[string]string) error {
				return nil
			}
			s, _, _, err = h.Prepare(
				mocking.URL(m, "POST", "/webhook/iterable/"+token),
				mocking.Header(nil),
				services.ServiceInput{},
			)

			So(err, ShouldBeNil)
			So(s, ShouldEqual, http.StatusOK)
		})
	})
}

func TestPrepareUsername(t *testing.T) {
	Convey("while testing prepareUsername", t, func() {
		Convey("it should not modify username when it already exists", func() {

			so := &services.ServiceOutput{}
			so.Username = "canthefason"
			err := h.prepareUsername(so)
			So(err, ShouldBeNil)
			So(so.Username, ShouldEqual, "canthefason")

			so = &services.ServiceOutput{}
			so.Username = "canthefason"
			so.Email = "ctf@koding.com"
			err = h.prepareUsername(so)
			So(err, ShouldBeNil)
			So(so.Username, ShouldEqual, "canthefason")
		})

		Convey("it should prepare username when it is not set depending on email", func() {

			_, err := models.CreateAccountInBothDbsWithNick("ctf")
			So(err, ShouldBeNil)

			so := &services.ServiceOutput{}
			so.Username = ""
			err = h.prepareUsername(so)
			So(err, ShouldBeNil)
			So(so.Username, ShouldEqual, "")

			so.Email = "ctf@koding.com"
			err = h.prepareUsername(so)
			So(err, ShouldBeNil)
			So(so.Username, ShouldEqual, "ctf")

			so.Email = "asdfasdfasdf@koding.com"
			so.Username = ""
			err = h.prepareUsername(so)
			So(err, ShouldEqual, ErrEmailNotFound)

		})

	})
}

func TestWebhookFetchBotChannel(t *testing.T) {

	Convey("while testing bot channel fetcher", t, func() {

		Convey("users should not be able to fetch bot channel when they don't have valid nick or group name", func() {
			nick := ""
			s, _, _, err := h.FetchBotChannel(
				mocking.URL(m, "POST", "/account/"+nick+"/bot-channel"),
				mocking.Header(nil),
				newBotChannelRequest("hi"),
			)
			So(err.Error(), ShouldEqual, ErrUsernameNotSet.Error())
			So(s, ShouldEqual, http.StatusBadRequest)

			nick = "canthefason"
			s, _, _, err = h.FetchBotChannel(
				mocking.URL(m, "POST", "/account/"+nick+"/bot-channel"),
				mocking.Header(nil),
				newBotChannelRequest(""),
			)
			So(err.Error(), ShouldEqual, ErrGroupNotSet.Error())
			So(s, ShouldEqual, http.StatusBadRequest)
		})

		Convey("we should not be able to fetch bot channel for a user when they are not participant of the group", func() {

			creator, err := models.CreateAccountInBothDbsWithNick("canthefason")
			So(err, ShouldBeNil)

			nick := models.RandomName()
			s, _, _, err := h.FetchBotChannel(
				mocking.URL(m, "POST", "/account/"+nick+"/bot-channel"),
				mocking.Header(nil),
				newBotChannelRequest("hi"),
			)
			So(err.Error(), ShouldEqual, ErrAccountNotFound.Error())
			So(s, ShouldEqual, http.StatusBadRequest)
			//So(err, ShouldEqual, ErrAccountIsNotParticipant)

			account, err := models.CreateAccountInBothDbsWithNick("sinan")
			if err != nil {
				t.Fatalf("could not create test account: %s", err)
			}

			s, _, _, err = h.FetchBotChannel(
				mocking.URL(m, "POST", "/account/"+account.Nick+"/bot-channel"),
				mocking.Header(nil),
				newBotChannelRequest("hi"),
			)
			So(err.Error(), ShouldEqual, ErrGroupNotFound.Error())
			So(s, ShouldEqual, http.StatusBadRequest)

			groupChannel := models.CreateTypedChannelWithTest(creator.Id, models.Channel_TYPE_GROUP)
			s, _, _, err = h.FetchBotChannel(
				mocking.URL(m, "POST", "/account/"+account.Nick+"/bot-channel"),
				mocking.Header(nil),
				newBotChannelRequest(groupChannel.GroupName),
			)
			So(err.Error(), ShouldEqual, ErrAccountIsNotParticipant.Error())
			So(s, ShouldEqual, http.StatusBadRequest)
		})

		Convey("we should be able to fetch bot channel for the user with given nickname when the user is participant of the group", func() {
			creator, err := models.CreateAccountInBothDbsWithNick("canthefason")
			So(err, ShouldBeNil)

			account, err := models.CreateAccountInBothDbsWithNick("sinan")
			So(err, ShouldBeNil)

			groupChannel := models.CreateTypedChannelWithTest(creator.Id, models.Channel_TYPE_GROUP)
			_, err = groupChannel.AddParticipant(account.Id)
			So(err, ShouldBeNil)

			s, _, res, err := h.FetchBotChannel(
				mocking.URL(m, "POST", "/account/"+account.Nick+"/bot-channel"),
				mocking.Header(nil),
				newBotChannelRequest(groupChannel.GroupName),
			)
			So(err, ShouldBeNil)
			So(s, ShouldEqual, http.StatusOK)
			So(res, ShouldNotBeNil)
			resultMap, ok := res.(map[string]string)
			So(ok, ShouldEqual, true)
			val, ok := resultMap["channelId"]
			So(ok, ShouldEqual, true)
			So(val, ShouldNotEqual, "")
		})

	})
}
