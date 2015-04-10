package webhook

import (
	"net/http"
	"socialapi/config"
	"socialapi/workers/common/mux"
	"socialapi/workers/integration/webhook"
	"testing"

	"github.com/koding/logging"
	"github.com/koding/runner"
	"github.com/rcrowley/go-tigertonic/mocking"
	. "github.com/smartystreets/goconvey/convey"
)

func newRequest(body, channelName string) *webhook.WebhookRequest {
	return &webhook.WebhookRequest{
		Body:        body,
		ChannelName: channelName,
	}
}

func TestWebhookListen(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("something went wrong: %s", err)
	}
	r.Log.SetLevel(logging.CRITICAL)

	defer r.Close()
	config.MustRead(r.Conf.Path)
	mc := mux.NewConfig("testing", "", "")
	m := mux.New(mc, r.Log)

	h := webhook.NewHandler(r.Log)
	h.AddHandlers(m)

	Convey("while testing incoming webhook", t, func() {

		Convey("users should not be able to send any message when they don't have valid token", func() {
			token := "123123"
			s, _, _, err := h.Push(
				mocking.URL(m, "POST", "/webhook/push/"+token),
				mocking.Header(nil),
				newRequest("hey", "testingchannel"),
			)
			So(err, ShouldNotBeNil)
			So(s, ShouldEqual, http.StatusNotFound)

			token = ""
			s, _, _, err = h.Push(
				mocking.URL(m, "POST", "/webhook/push/"+token),
				mocking.Header(nil),
				newRequest("hey", "testingchannel"),
			)
			So(err.Error(), ShouldEqual, ErrTokenNotSet.Error())
			So(s, ShouldEqual, http.StatusBadRequest)
		})

		Convey("users should not be able to send any message when their request does not include body or channel name", func() {

			token := "123123"
			s, _, _, err := h.Push(
				mocking.URL(m, "POST", "/webhook/push/"+token),
				mocking.Header(nil),
				newRequest("", "testingchannel"),
			)
			So(err.Error(), ShouldEqual, ErrBodyNotSet.Error())
			So(s, ShouldEqual, http.StatusBadRequest)

			s, _, _, err = h.Push(
				mocking.URL(m, "POST", "/webhook/push/"+token),
				mocking.Header(nil),
				newRequest("hey", ""),
			)
			So(err.Error(), ShouldEqual, ErrChannelNotSet.Error())
			So(s, ShouldEqual, http.StatusBadRequest)
		})

		Convey("users should be able to send message when token is valid", nil)

	})
}
