package api

import (
	"fmt"
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
			firstInt := webhook.CreateUnpublishedIntegration(t)
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
					So(integration.IsPublished, ShouldBeFalse)
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

func TestWebhookIntegrationCreate(t *testing.T) {
	tearUp(func(h *Handler, m *mux.Mux) {
		Convey("while creating integrations", t, func() {
			in := webhook.CreateTestIntegration(t)
			acc := models.CreateAccountWithTest()
			groupName := models.RandomGroupName()
			models.CreateTypedGroupedChannelWithTest(acc.Id, models.Channel_TYPE_GROUP, groupName)
			topicChannel := models.CreateTypedGroupedChannelWithTest(acc.Id, models.Channel_TYPE_TOPIC, groupName)

			Convey("it should return error when necessary fields are missing", func() {
				ci := webhook.NewChannelIntegration()
				ci.IntegrationId = in.Id

				c := &models.Context{}
				c.Client = &models.Client{Account: acc}
				c.GroupName = groupName

				s, _, _, err := h.CreateChannelIntegration(
					mocking.URL(m, "POST", "/channelintegration/create"),
					mocking.Header(nil),
					ci,
					c,
				)

				So(err.Error(), ShouldEqual, models.ErrChannelIsNotSet.Error())
				So(s, ShouldEqual, http.StatusBadRequest)
			})

			Convey("it should return error when account is not a participant of the given channel", func() {
				ci := webhook.NewChannelIntegration()
				ci.IntegrationId = in.Id

				c := &models.Context{}
				c.Client = &models.Client{Account: acc}
				c.GroupName = groupName

				s, _, _, err := h.CreateChannelIntegration(
					mocking.URL(m, "POST", "/channelintegration/create"),
					mocking.Header(nil),
					ci,
					c,
				)

				So(err.Error(), ShouldEqual, models.ErrChannelIsNotSet.Error())
				So(s, ShouldEqual, http.StatusBadRequest)
			})

			Convey("it should create", func() {
				ci := webhook.NewChannelIntegration()
				ci.IntegrationId = in.Id
				ci.ChannelId = topicChannel.Id

				c := &models.Context{}
				c.Client = &models.Client{Account: acc}
				c.GroupName = groupName

				_, err := topicChannel.AddParticipant(acc.Id)
				So(err, ShouldBeNil)

				s, _, res, err := h.CreateChannelIntegration(
					mocking.URL(m, "POST", "/channelintegration/create"),
					mocking.Header(nil),
					ci,
					c,
				)

				So(err, ShouldBeNil)
				So(s, ShouldEqual, http.StatusOK)

				sr, srOk := res.(*response.SuccessResponse)
				So(srOk, ShouldBeTrue)

				newCi, ok := sr.Data.(*webhook.ChannelIntegration)
				So(ok, ShouldBeTrue)

				So(newCi, ShouldNotBeNil)
				So(newCi.Id, ShouldNotEqual, 0)
			})
		})
	})
}

func TestWebhookRegenerateToken(t *testing.T) {

	tearUp(func(h *Handler, m *mux.Mux) {
		Convey("while generating tokens", t, func() {
			// create dependencies
			in := webhook.CreateTestIntegration(t)
			acc := models.CreateAccountWithTest()
			groupName := models.RandomGroupName()
			models.CreateTypedGroupedChannelWithTest(acc.Id, models.Channel_TYPE_GROUP, groupName)
			topicChannel := models.CreateTypedGroupedChannelWithTest(acc.Id, models.Channel_TYPE_TOPIC, groupName)
			_, err := topicChannel.AddParticipant(acc.Id)
			So(err, ShouldBeNil)

			// create channel integration
			ci := webhook.NewChannelIntegration()
			ci.CreatorId = acc.Id
			ci.GroupName = groupName
			ci.ChannelId = topicChannel.Id
			ci.IntegrationId = in.Id

			err = ci.Create()
			So(err, ShouldBeNil)

			Convey("user from another channel should not be able to regenerate a token", func() {
				c := &models.Context{}
				c.Client = &models.Client{Account: acc}
				c.GroupName = models.RandomGroupName()

				s, _, _, err := h.RegenerateToken(
					mocking.URL(m, "POST", "/channelintegration/token"),
					mocking.Header(nil),
					ci,
					c,
				)
				So(err.Error(), ShouldEqual, ErrInvalidGroup.Error())
				So(s, ShouldEqual, http.StatusBadRequest)
			})

			Convey("we should be able to regenerate a token of a current integration", func() {

				c := &models.Context{}
				c.Client = &models.Client{Account: acc}
				c.GroupName = groupName

				s, _, res, err := h.RegenerateToken(
					mocking.URL(m, "POST", "/channelintegration/create"),
					mocking.Header(nil),
					ci,
					c,
				)

				So(err, ShouldBeNil)
				So(s, ShouldEqual, http.StatusOK)

				sr, srOk := res.(*response.SuccessResponse)
				So(srOk, ShouldBeTrue)

				newCi, ok := sr.Data.(*webhook.ChannelIntegration)
				So(ok, ShouldBeTrue)

				So(newCi, ShouldNotBeNil)
				So(newCi.Id, ShouldNotEqual, 0)
				So(newCi.Token, ShouldNotEqual, ci.Token)
			})
		})
	})
}

func TestWebhookGetChannelIntegration(t *testing.T) {
	tearUp(func(h *Handler, m *mux.Mux) {
		Convey("while fetching the channel integration", t, func() {
			in := webhook.CreateTestIntegration(t)
			acc := models.CreateAccountWithTest()
			groupName := models.RandomGroupName()
			models.CreateTypedGroupedChannelWithTest(acc.Id, models.Channel_TYPE_GROUP, groupName)
			topicChannel := models.CreateTypedGroupedChannelWithTest(acc.Id, models.Channel_TYPE_TOPIC, groupName)
			_, err := topicChannel.AddParticipant(acc.Id)
			So(err, ShouldBeNil)

			// create channel integration
			ci := webhook.NewChannelIntegration()
			ci.CreatorId = acc.Id
			ci.GroupName = groupName
			ci.ChannelId = topicChannel.Id
			ci.IntegrationId = in.Id

			err = ci.Create()
			So(err, ShouldBeNil)
			Convey("it should be fetched with a valid id", func() {

				c := &models.Context{}
				c.Client = &models.Client{Account: acc}
				c.GroupName = groupName
				endpoint := fmt.Sprintf("/channelintegration/%d", ci.Id)

				s, _, res, err := h.GetChannelIntegration(
					mocking.URL(m, "GET", endpoint),
					mocking.Header(nil),
					ci,
					c,
				)

				So(err, ShouldBeNil)
				So(s, ShouldEqual, http.StatusOK)

				sr, srOk := res.(*response.SuccessResponse)
				So(srOk, ShouldBeTrue)

				newCi, ok := sr.Data.(*webhook.ChannelIntegration)
				So(ok, ShouldBeTrue)

				So(newCi, ShouldNotBeNil)
				So(newCi.Id, ShouldEqual, ci.Id)
			})

		})
	})
}

func TestWebhookUpdateChannelIntegration(t *testing.T) {

	tearUp(func(h *Handler, m *mux.Mux) {
		Convey("while updating the channel integrations", t, func() {
			in := webhook.CreateTestIntegration(t)
			acc := models.CreateAccountWithTest()
			groupName := models.RandomGroupName()
			models.CreateTypedGroupedChannelWithTest(acc.Id, models.Channel_TYPE_GROUP, groupName)
			topicChannel := models.CreateTypedGroupedChannelWithTest(acc.Id, models.Channel_TYPE_TOPIC, groupName)
			_, err := topicChannel.AddParticipant(acc.Id)
			So(err, ShouldBeNil)

			// create channel integration
			ci := webhook.NewChannelIntegration()
			ci.CreatorId = acc.Id
			ci.GroupName = groupName
			ci.ChannelId = topicChannel.Id
			ci.IntegrationId = in.Id

			err = ci.Create()
			So(err, ShouldBeNil)
			Convey("token should not be changed", func() {
				currentToken := ci.Token
				ci.Token = "123123123"

				c := &models.Context{}
				c.Client = &models.Client{Account: acc}
				c.GroupName = groupName
				endpoint := fmt.Sprintf("/channelintegration/%d/update", ci.Id)

				s, _, _, err := h.UpdateChannelIntegration(
					mocking.URL(m, "POST", endpoint),
					mocking.Header(nil),
					ci,
					c,
				)

				newCi := webhook.NewChannelIntegration()
				err = newCi.ById(ci.Id)
				So(err, ShouldBeNil)
				So(s, ShouldEqual, http.StatusOK)
				So(newCi.Token, ShouldEqual, currentToken)
				So(newCi.Token, ShouldNotEqual, "123123123")
			})

			Convey("channel id should be updated", func() {

				c := &models.Context{}
				c.Client = &models.Client{Account: acc}
				c.GroupName = groupName
				endpoint := fmt.Sprintf("/channelintegration/%d/update", ci.Id)
				newChannel := models.CreateTypedGroupedChannelWithTest(acc.Id, models.Channel_TYPE_TOPIC, groupName)
				ci.ChannelId = newChannel.Id

				_, err := newChannel.AddParticipant(acc.Id)

				s, _, _, err := h.UpdateChannelIntegration(
					mocking.URL(m, "POST", endpoint),
					mocking.Header(nil),
					ci,
					c,
				)

				newCi := webhook.NewChannelIntegration()
				err = newCi.ById(ci.Id)
				So(err, ShouldBeNil)
				So(s, ShouldEqual, http.StatusOK)
				So(newCi.ChannelId, ShouldEqual, newChannel.Id)
			})
		})
	})
}
