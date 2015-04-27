package api

import (
	"koding/db/mongodb/modelhelper"
	"math/rand"
	"net/http"
	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/common/mux"
	"socialapi/workers/integration/webhook"
	"testing"
	"time"

	"github.com/koding/logging"
	"github.com/koding/runner"
	"github.com/rcrowley/go-tigertonic/mocking"
	. "github.com/smartystreets/goconvey/convey"
)

func newRequest(body string, channelId int64, groupName string) *WebhookRequest {
	return &WebhookRequest{
		Message: &webhook.Message{
			Body:      body,
			ChannelId: channelId,
		},
		GroupName: groupName,
	}
}

func TestWebhookListen(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("something went wrong: %s", err)
	}
	r.Log.SetLevel(logging.CRITICAL)

	defer r.Close()
	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)

	mc := mux.NewConfig("testing", "", "")
	m := mux.New(mc, r.Log)

	h, err := NewHandler(r.Log)
	if err != nil {
		t.Fatalf("Could not initialize handler: %s", err)
	}

	h.AddHandlers(m)

	rand.Seed(time.Now().UTC().UnixNano())

	account, err := models.CreateAccountInBothDbsWithNick("sinan")
	if err != nil {
		t.Fatalf("could not create test account: %s", err)
	}

	teamIntegration := webhook.CreateTestTeamIntegration(t)

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

				token := teamIntegration.Token
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
