package api

import (
	"koding/db/mongodb/modelhelper"
	"math/rand"
	"net/http"
	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/common/mux"
	"socialapi/workers/common/response"
	"socialapi/workers/integration/webhook"
	"strings"
	"testing"
	"time"

	"github.com/koding/logging"
	"github.com/koding/runner"
	"github.com/nu7hatch/gouuid"
	"github.com/rcrowley/go-tigertonic/mocking"
	. "github.com/smartystreets/goconvey/convey"
)

func newRequest(body string, channelId int64, groupName string) *PushRequest {
	return &PushRequest{
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

func newContext(accountId int64, nick, groupName string) *models.Context {

	return &models.Context{
		GroupName: groupName,
		Client: &models.Client{
			Account: &models.Account{
				Id:   accountId,
				Nick: nick,
			},
		},
	}
}

func tearUp(f func(h *Handler, m *mux.Mux)) {

	r := runner.New("test")
	if err := r.Init(); err != nil {
		panic(err)
	}
	defer r.Close()
	r.Log.SetLevel(logging.CRITICAL)

	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	redisConn := r.Bongo.MustGetRedisConn()

	mc := mux.NewConfig("testing", "", "")
	m := mux.New(mc, r.Log, r.Metrics)
	h, err := NewHandler(appConfig, redisConn, r.Log)
	if err != nil {
		panic(err)
	}

	h.AddHandlers(m)

	rand.Seed(time.Now().UTC().UnixNano())
	f(h, m)
}

func TestWebhookListen(t *testing.T) {

	tearUp(func(h *Handler, m *mux.Mux) {
		account, err := models.CreateAccountInBothDbsWithNick("sinan")
		if err != nil {
			t.Fatalf("could not create test account: %s", err)
		}

		channelIntegration := webhook.CreateTestChannelIntegration(t)

		Convey("while testing incoming webhook", t, func() {

			groupName := models.RandomGroupName()

			channel := models.CreateTypedGroupedChannelWithTest(account.Id, models.Channel_TYPE_TOPIC, groupName)

			Convey("users should not be able to send any message when they don't have valid token", func() {
				token := "123123"
				s, _, _, err := h.Push(
					mocking.URL(m, "POST", "/push/"+token),
					mocking.Header(nil),
					newRequest("hey", channel.Id, "koding"),
				)
				So(err, ShouldNotBeNil)
				So(err.Error(), ShouldEqual, ErrTokenNotValid.Error())
				So(s, ShouldEqual, http.StatusBadRequest)

				tk, err := uuid.NewV4()
				So(err, ShouldBeNil)
				token = tk.String()
				s, _, _, err = h.Push(
					mocking.URL(m, "POST", "/push/"+token),
					mocking.Header(nil),
					newRequest("hey", channel.Id, "koding"),
				)
				So(err, ShouldNotBeNil)
				So(s, ShouldEqual, http.StatusNotFound)

				token = ""
				s, _, _, err = h.Push(
					mocking.URL(m, "POST", "/push/"+token),
					mocking.Header(nil),
					newRequest("hey", channel.Id, "koding"),
				)
				So(err.Error(), ShouldEqual, ErrTokenNotSet.Error())
				So(s, ShouldEqual, http.StatusBadRequest)
			})

			Convey("users should not be able to send any message when their request does not include body or channel name", func() {

				tk, err := uuid.NewV4()
				So(err, ShouldBeNil)
				token := tk.String()
				s, _, _, err := h.Push(
					mocking.URL(m, "POST", "/push/"+token),
					mocking.Header(nil),
					newRequest("", channel.Id, "koding"),
				)
				So(err.Error(), ShouldEqual, ErrBodyNotSet.Error())
				So(s, ShouldEqual, http.StatusBadRequest)

				s, _, _, err = h.Push(
					mocking.URL(m, "POST", "/push/"+token),
					mocking.Header(nil),
					newRequest("hey", 0, "koding"),
				)
				So(err.Error(), ShouldEqual, ErrChannelNotSet.Error())
				So(s, ShouldEqual, http.StatusBadRequest)

			})

			Convey("users should be able to send message when token is valid", func() {

				Convey("related integrations must be created", func() {

					token := channelIntegration.Token
					s, _, _, err := h.Push(
						mocking.URL(m, "POST", "/push/"+token),
						mocking.Header(nil),
						newRequest("hey", channel.Id, "koding"),
					)

					So(err, ShouldBeNil)
					So(s, ShouldEqual, http.StatusOK)

					token = strings.ToUpper(channelIntegration.Token)

					s, _, _, err = h.Push(
						mocking.URL(m, "POST", "/push/"+token),
						mocking.Header(nil),
						newRequest("hey", channel.Id, "koding"),
					)

					So(err, ShouldBeNil)
					So(s, ShouldEqual, http.StatusOK)
				})
			})

		})
	})
}

func TestWebhookFetchBotChannel(t *testing.T) {

	tearUp(func(h *Handler, m *mux.Mux) {

		Convey("while testing bot channel fetcher", t, func() {

			Convey("users should not be able to fetch bot channel when they don't have valid nick or group name", func() {
				nick := ""
				s, _, _, err := h.FetchBotChannel(
					mocking.URL(m, "GET", "/botchannel"),
					mocking.Header(nil),
					nil,
					newContext(3, "", "koding"),
				)
				So(err.Error(), ShouldEqual, ErrUsernameNotSet.Error())
				So(s, ShouldEqual, http.StatusBadRequest)

				_, err = models.CreateAccountInBothDbsWithNick("canthefason")
				So(err, ShouldBeNil)

				nick = "canthefason"
				s, _, _, err = h.FetchBotChannel(
					mocking.URL(m, "GET", "/botchannel"),
					mocking.Header(nil),
					nil,
					newContext(3, nick, "team"),
				)
				So(err, ShouldNotBeNil)
				So(err.Error(), ShouldEqual, ErrGroupNotFound.Error())
				So(s, ShouldEqual, http.StatusBadRequest)
			})

			Convey("we should not be able to fetch bot channel for a user when they are not participant of the group", func() {

				creator, err := models.CreateAccountInBothDbsWithNick("canthefason")
				So(err, ShouldBeNil)

				nick := models.RandomName()
				s, _, _, err := h.FetchBotChannel(
					mocking.URL(m, "GET", "/botchannel"),
					mocking.Header(nil),
					nil,
					newContext(3, nick, "koding"),
				)
				So(err.Error(), ShouldEqual, ErrAccountNotFound.Error())
				So(s, ShouldEqual, http.StatusBadRequest)
				//So(err, ShouldEqual, ErrAccountIsNotParticipant)

				account, err := models.CreateAccountInBothDbsWithNick("sinan")
				if err != nil {
					t.Fatalf("could not create test account: %s", err)
				}

				s, _, _, err = h.FetchBotChannel(
					mocking.URL(m, "GET", "/botchannel"),
					mocking.Header(nil),
					nil,
					newContext(account.Id, account.Nick, models.RandomName()),
				)
				So(err.Error(), ShouldEqual, ErrGroupNotFound.Error())
				So(s, ShouldEqual, http.StatusBadRequest)

				groupChannel := models.CreateTypedChannelWithTest(creator.Id, models.Channel_TYPE_GROUP)
				s, _, _, err = h.FetchBotChannel(
					mocking.URL(m, "GET", "/botchannel"),
					mocking.Header(nil),
					nil,
					newContext(account.Id, account.Nick, groupChannel.GroupName),
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
					mocking.URL(m, "GET", "/botchannel"),
					mocking.Header(nil),
					nil,
					newContext(account.Id, account.Nick, groupChannel.GroupName),
				)
				So(err, ShouldBeNil)
				So(s, ShouldEqual, http.StatusOK)
				So(res, ShouldNotBeNil)

				result, ok := res.(*response.SuccessResponse)
				So(ok, ShouldEqual, true)
				val, ok := result.Data.(*models.ChannelContainer)
				So(ok, ShouldEqual, true)
				So(val, ShouldNotBeNil)
				So(val.Channel, ShouldNotBeNil)
				So(val.Channel.Id, ShouldNotEqual, 0)
			})

		})
	})
}

func TestWebhookGroupBotChannel(t *testing.T) {

	tearUp(func(h *Handler, m *mux.Mux) {

		channelIntegration := webhook.CreateTestChannelIntegration(t)
		Convey("while checking group bot channels", t, func() {
			Convey("we should be able to validate request", func() {
				token := ""
				username := ""
				s, _, _, err := h.FetchGroupBotChannel(
					mocking.URL(m, "GET", "/botchannel/"+token+"/user/"+username),
					mocking.Header(nil),
					nil,
				)
				So(err.Error(), ShouldEqual, ErrTokenNotSet.Error())
				So(s, ShouldEqual, http.StatusBadRequest)

				token = "123123"
				s, _, _, err = h.FetchGroupBotChannel(
					mocking.URL(m, "GET", "/botchannel/"+token+"/user/"+username),
					mocking.Header(nil),
					nil,
				)
				So(err.Error(), ShouldEqual, ErrUsernameNotSet.Error())
				So(s, ShouldEqual, http.StatusBadRequest)
			})

			Convey("we should be able to fetch bot channel for valid request", func() {

				creator, err := models.CreateAccountInBothDbsWithNick("canthefason")
				So(err, ShouldBeNil)

				account, err := models.CreateAccountInBothDbsWithNick("sinan")
				So(err, ShouldBeNil)

				groupChannel := models.CreateTypedGroupedChannelWithTest(creator.Id, models.Channel_TYPE_GROUP, channelIntegration.GroupName)
				_, err = groupChannel.AddParticipant(account.Id)
				So(err, ShouldBeNil)

				token := channelIntegration.Token
				username := account.Nick
				s, _, resp, err := h.FetchGroupBotChannel(
					mocking.URL(m, "GET", "/botchannel/"+token+"/user/"+username),
					mocking.Header(nil),
					nil,
				)
				So(err, ShouldBeNil)
				So(s, ShouldEqual, http.StatusOK)

				sr, srOK := resp.(*response.SuccessResponse)
				So(srOK, ShouldBeTrue)
				cast, castOK := sr.Data.(map[string]string)
				So(castOK, ShouldBeTrue)
				val, ok := cast["channelId"]
				So(ok, ShouldBeTrue)
				So(val, ShouldNotEqual, "")
			})
		})
	})
}

func TestWebhookIntegrationList(t *testing.T) {

	tearUp(func(h *Handler, m *mux.Mux) {

		Convey("while listing integrations ", t, func() {
			name := ".A" + models.RandomGroupName()
			firstInt := webhook.CreatePrivateIntegration(t)
			secondInt := webhook.CreateIntegration(t, name)

			Convey("it should only list public integrations", func() {

				_, _, res, err := h.List(
					mocking.URL(m, "GET", "/list"),
					mocking.Header(nil),
					nil,
				)

				So(err, ShouldBeNil)
				So(res, ShouldNotBeNil)
				r, ok := res.(*response.SuccessResponse)
				So(ok, ShouldBeTrue)

				integrations, ok := r.Data.([]webhook.Integration)
				So(ok, ShouldBeTrue)
				So(len(integrations), ShouldBeGreaterThanOrEqualTo, 1)

				for _, integration := range integrations {
					So(integration.IsPrivate, ShouldBeFalse)
					So(integration.Name, ShouldNotEqual, firstInt.Name)
				}
			})

			Reset(func() {

				err := firstInt.Delete()
				So(err, ShouldBeNil)

				err = secondInt.Delete()
				So(err, ShouldBeNil)
			})
		})
	})
}
