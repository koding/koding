package main

import (
	"bytes"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func stripeTest(body []byte) (*httptest.ResponseRecorder, error) {
	url := fmt.Sprintf("/stripe")

	r, err := http.NewRequest("POST", url, bytes.NewBuffer(body))
	if err != nil {
		return nil, err
	}

	recorder := httptest.NewRecorder()

	st := &stripeMux{Controller: controller}
	st.ServeHTTP(recorder, r)

	return recorder, nil
}

func TestStripe(t *testing.T) {
	Convey("Given webhook from stripe", t, func() {
		Convey("When webhook isn't implemented", func() {
			body := []byte(`{"type":"random.webhook"}`)
			recorder, err := stripeTest(body)

			So(err, ShouldBeNil)

			Convey("Then it should return 200", func() {
				So(recorder.Code, ShouldEqual, 200)
			})
		})

		Convey("When webhook is implemented", func() {
			body := []byte(`{
				"type":"customer.subscription.created",
				"data": {
					"object": {
						"plan": {
							"name": "Developer"
						},
						"id": "ch_00000000000000",
						"customer": "cus_00000000000000"
					}
				}
			}`)

			recorder, err := stripeTest(body)

			So(err, ShouldBeNil)

			Convey("Then it should return 200", func() {
				So(recorder.Code, ShouldEqual, 200)
			})
		})
	})
}
