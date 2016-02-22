package publicip

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestPublicIPRetry(t *testing.T) {
	var callCount int
	var eventualSuccessReq int
	successIP := "0.1.2.3"
	successTS := httptest.NewServer(http.HandlerFunc(
		func(w http.ResponseWriter, r *http.Request) {
			callCount++
			fmt.Fprint(w, successIP)
		}))
	defer successTS.Close()

	failTS := httptest.NewServer(http.HandlerFunc(
		func(w http.ResponseWriter, r *http.Request) {
			callCount++
		}))
	defer failTS.Close()

	eventualSuccessTS := httptest.NewServer(http.HandlerFunc(
		func(w http.ResponseWriter, r *http.Request) {
			callCount++
			if callCount > eventualSuccessReq {
				fmt.Fprint(w, successIP)
			}
		}))
	defer eventualSuccessTS.Close()

	Convey("Given a max of valid and invalid hosts", t, func() {
		callCount = 0

		hosts := []string{
			failTS.URL,
			successTS.URL,
			failTS.URL,
		}

		Convey("It should return the first succeeding host", func() {
			ip, err := publicIPRetry(hosts, 10, 0, nil)
			So(err, ShouldBeNil)
			So(ip, ShouldNotBeNil)
			So(ip.String(), ShouldEqual, "0.1.2.3")
			So(callCount, ShouldEqual, 2)
		})

		Convey("It should only return an error after exceeding maxRetries", func() {
			ip, err := publicIPRetry(hosts, 1, 0, nil)
			So(err, ShouldNotBeNil)
			So(ip, ShouldBeNil)
			So(callCount, ShouldEqual, 1)
		})

		Convey("It should support extra a newline after the IP", func() {
			successIP = fmt.Sprintf("%s\n", successIP)
			ip, err := publicIPRetry(hosts, 1, 0, nil)
			So(err, ShouldNotBeNil)
			So(ip, ShouldBeNil)
			So(callCount, ShouldEqual, 1)
		})
	})

	Convey("Given eventually succeeding hosts", t, func() {
		callCount = 0
		eventualSuccessReq = 3

		hosts := []string{
			failTS.URL,
			eventualSuccessTS.URL,
			failTS.URL,
		}

		Convey("It should repeat the entire hosts list until success within maxRetries", func() {
			ip, err := publicIPRetry(hosts, 10, 0, nil)
			So(err, ShouldBeNil)
			So(ip, ShouldNotBeNil)
			So(ip.String(), ShouldEqual, "0.1.2.3")
			So(callCount, ShouldEqual, 5)
		})
	})
}
