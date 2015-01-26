package main

import (
	"net/http"
	"net/http/httptest"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

var paypalWebhookUrl = "/paypal"

func TestPaypal(t *testing.T) {
	SkipConvey("Given webhook from paypal", t, func() {
		r, err := http.NewRequest("POST", paypalWebhookUrl, nil)
		So(err, ShouldBeNil)

		recorder := httptest.NewRecorder()

		pp := &paypalMux{}
		pp.ServeHTTP(recorder, r)

		Convey("Then it should return 200", func() {
			So(recorder.Code, ShouldEqual, 200)
		})
	})
}
