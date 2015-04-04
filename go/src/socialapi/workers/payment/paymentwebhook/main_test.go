package main

import (
	"bytes"
	"net/http"
	"net/http/httptest"
	"socialapi/config"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

var controller *Controller

func init() {
	r := initializeRunner()
	appConfig := config.MustRead(r.Conf.Path)

	// initialize client to talk to kloud
	kiteClient := initializeKiteClient(r.Kite, appConfig.Kloud.SecretKey, appConfig.Kloud.Address)

	// initialize controller to inject dependencies
	cont := &Controller{Kite: kiteClient}

	controller = cont
}

func TestMux(t *testing.T) {
	Convey("Given mux", t, func() {
		st := &stripeMux{Controller: controller}
		pp := &paypalMux{Controller: controller}

		mux := initializeMux(st, pp)

		Convey("It should redirect stripe properly", func() {
			r, err := http.NewRequest("POST", "/-/payments/stripe/webhook", bytes.NewBuffer([]byte{}))
			So(err, ShouldBeNil)

			recorder := httptest.NewRecorder()

			mux.ServeHTTP(recorder, r)
			So(recorder.Code, ShouldNotEqual, 404)
		})

		Convey("It should redirect paypal properly", func() {
			r, err := http.NewRequest("POST", "/-/payments/paypal/webhook", bytes.NewBuffer([]byte{}))
			So(err, ShouldBeNil)

			recorder := httptest.NewRecorder()

			mux.ServeHTTP(recorder, r)
			So(recorder.Code, ShouldNotEqual, 404)
		})
	})
}
