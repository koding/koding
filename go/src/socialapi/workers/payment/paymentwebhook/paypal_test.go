package main

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestPaypal(t *testing.T) {
	Convey("Given webhook from paypal", t, func() {
		url := fmt.Sprintf("/paypal")

		r, err := http.NewRequest("POST", url, nil)
		So(err, ShouldBeNil)

		recorder := httptest.NewRecorder()

		pp := &paypalMux{}
		pp.ServeHTTP(recorder, r)

		Convey("Then it should return 200", func() {
			So(recorder.Code, ShouldEqual, 200)
		})
	})
}
