package main

import (
	"bytes"
	"net/http"
	"net/http/httptest"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

var paypalWebhookUrl = "/paypal"

func TestPaypal(t *testing.T) {
	Convey("Given webhook from paypal", t, func() {
		Convey("When webhook isn't implemented", func() {
			body := []byte(`{"type":"random.webhook"}`)
			r, err := http.NewRequest("POST", paypalWebhookUrl, bytes.NewBuffer(body))
			So(err, ShouldBeNil)

			recorder := httptest.NewRecorder()

			pp := &paypalMux{}
			pp.ServeHTTP(recorder, r)

			Convey("Then it should return 200", func() {
				So(recorder.Code, ShouldEqual, 200)
			})
		})
	})
}
