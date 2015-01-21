package main

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestStripe(t *testing.T) {
	Convey("Given webhook from stripe", t, func() {
		url := fmt.Sprintf("/stripe")

		r, err := http.NewRequest("POST", url, nil)
		So(err, ShouldBeNil)

		recorder := httptest.NewRecorder()

		st := &stripeMux{}
		st.ServeHTTP(recorder, r)

		Convey("Then it should return 200", func() {
			So(recorder.Code, ShouldEqual, 200)
		})
	})
}
