package main

import (
	"bytes"
	"net/http"
	"net/http/httptest"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func paypalTest(body []byte) (*httptest.ResponseRecorder, error) {
	r, err := http.NewRequest("POST", "/", bytes.NewBuffer(body))
	if err != nil {
		return nil, err
	}

	recorder := httptest.NewRecorder()

	pp := &paypalMux{Controller: controller}
	pp.ServeHTTP(recorder, r)

	return recorder, nil
}

func TestPaypal(t *testing.T) {
	Convey("Given webhook from paypal", t, func() {
		Convey("When webhook isn't implemented", func() {
			body := []byte(`{"type":"random.webhook"}`)
			recorder, err := paypalTest(body)

			So(err, ShouldBeNil)

			Convey("Then it should return 200", func() {
				So(recorder.Code, ShouldEqual, 200)
			})
		})

		Convey("When webhook request is empty", func() {
			body := []byte(``)
			recorder, err := paypalTest(body)

			So(err, ShouldBeNil)

			Convey("Then it should return 500", func() {
				So(recorder.Code, ShouldEqual, 500)
			})
		})
	})
}
