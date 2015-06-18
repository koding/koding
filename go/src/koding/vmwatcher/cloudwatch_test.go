package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper/modeltesthelper"
	"net/http"
	"net/http/httptest"
	"net/url"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestCloudwatchFree(t *testing.T) {
	Convey("", t, func() {
		url, server := buildPaymentServer("free")
		PlanUrl = url

		defer server.Close()

		username := "indianajones"
		_, _, err := modeltesthelper.CreateUser(username)
		So(err, ShouldBeNil)

		defer modeltesthelper.DeleteUsersByUsername(username)

		Convey("Given user", func() {
			var networkOutMetric = metricsToSave[0]

			Convey("When user is overlimit", func() {
				var value float64 = NetworkOutLimit * PaidPlanMultiplier * 2

				err := networkOutMetric.Save(username, value)
				So(err, ShouldBeNil)

				Convey("Then they can't start their machine", func() {
					lr, err := networkOutMetric.IsUserOverLimit(username, StopLimitKey)
					So(err, ShouldBeNil)

					So(lr.CanStart, ShouldBeFalse)
				})
			})

			Convey("When user is underlimit", func() {
				var value float64 = NetworkOutLimit - 100

				err := networkOutMetric.Save(username, value)
				So(err, ShouldBeNil)

				Convey("Then they cna start their machine", func() {
					lr, err := networkOutMetric.IsUserOverLimit(username, StopLimitKey)
					So(err, ShouldBeNil)

					So(lr.CanStart, ShouldBeTrue)
				})
			})
		})
	})
}

func TestCloudwatchPaid(t *testing.T) {
	Convey("", t, func() {
		url, server := buildPaymentServer("hobbyist")
		PlanUrl = url

		defer server.Close()

		username := "indianajones"
		_, _, err := modeltesthelper.CreateUser(username)
		So(err, ShouldBeNil)

		defer modeltesthelper.DeleteUsersByUsername(username)

		Convey("Given user", func() {
			var networkOutMetric = metricsToSave[0]

			Convey("When user is overlimit", func() {
				var value float64 = NetworkOutLimit * PaidPlanMultiplier * 2

				err := networkOutMetric.Save(username, value)
				So(err, ShouldBeNil)

				Convey("Then they can't start their machine", func() {
					lr, err := networkOutMetric.IsUserOverLimit(username, StopLimitKey)
					So(err, ShouldBeNil)

					So(lr.CanStart, ShouldBeFalse)
				})
			})

			Convey("When user is underlimit", func() {
				var value float64 = (NetworkOutLimit * PaidPlanMultiplier) - 100

				err := networkOutMetric.Save(username, value)
				So(err, ShouldBeNil)

				Convey("Then they cna start their machine", func() {
					lr, err := networkOutMetric.IsUserOverLimit(username, StopLimitKey)
					So(err, ShouldBeNil)

					So(lr.CanStart, ShouldBeTrue)
				})
			})
		})
	})
}

func buildPaymentServer(planTitle string) (string, *httptest.Server) {
	mux := http.NewServeMux()
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, fmt.Sprintf(`{"planTitle":"%s"}`, planTitle))
	})

	server := httptest.NewServer(mux)
	url, _ := url.Parse(server.URL)

	return url.String(), server
}
