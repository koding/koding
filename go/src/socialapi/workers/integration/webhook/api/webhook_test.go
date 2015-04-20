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
		Message: &webhook.Message{
			Body:      body,
			ChannelId: channelId,
		},
		GroupName: groupName,
	}
}

func newPrepareRequest(data *services.ServiceInput) *PrepareRequest {
	return &PrepareRequest{
		Data: data,
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
				newPrepareRequest(&services.ServiceInput{}),
			)
			So(err.Error(), ShouldEqual, ErrTokenNotSet.Error())
			So(s, ShouldEqual, http.StatusBadRequest)

			token = "123123123"
			integrationName = ""
			s, _, _, err = h.Prepare(
				mocking.URL(m, "POST", "/webhook/"+integrationName+"/"+token),
				mocking.Header(nil),
				newPrepareRequest(&services.ServiceInput{}),
			)
			So(err.Error(), ShouldEqual, ErrNameNotSet.Error())
			So(s, ShouldEqual, http.StatusBadRequest)

			integrationName = "testing"
			s, _, _, err = h.Prepare(
				mocking.URL(m, "POST", "/webhook/"+integrationName+"/"+token),
				mocking.Header(nil),
				newPrepareRequest(&services.ServiceInput{}),
			)
			So(err, ShouldNotBeNil)
			So(s, ShouldEqual, http.StatusNotFound)

			s, _, _, err = h.Prepare(
				mocking.URL(m, "POST", "/webhook/iterable/"+token),
				mocking.Header(nil),
				newPrepareRequest(&services.ServiceInput{}),
			)
			// TODO temporary assertion
			So(s, ShouldEqual, http.StatusNotImplemented)
			//So(err, ShouldBeNil)
		})
	})
}
