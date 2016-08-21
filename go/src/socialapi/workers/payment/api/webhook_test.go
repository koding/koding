package api

import (
	"fmt"
	"socialapi/rest"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestWebhook(t *testing.T) {
	Convey("Given a user", t, func() {
		withTestServer(t, func(endpoint string) {
			webhookUrl := fmt.Sprintf("%s/payment/webhook", endpoint)

			Convey("Should give error when event id is not valid", func() {
				req := []byte(webhookTestData["charge.succeeded"])
				_, err := rest.DoRequestWithAuth("POST", webhookUrl, req, "")
				So(err, ShouldNotBeNil)
			})

			Convey("Should not give error when event type is not supported", func() {
				req := []byte(webhookTestData["invalid.event_name"])
				_, err := rest.DoRequestWithAuth("POST", webhookUrl, req, "")
				So(err, ShouldBeNil)
			})
		})
	})
}
