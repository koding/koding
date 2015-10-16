package main

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestHealthCheckRemote(t *testing.T) {
	Convey("Should return no errors for working http servers", t, func() {
		ts := httptest.NewServer(http.HandlerFunc(
			func(w http.ResponseWriter, r *http.Request) {
				fmt.Fprint(w, "Welcome to SockJS!\n")
			}))
		defer ts.Close()

		// We can use the same url for inet and kontrol, since inet just
		// checks for no error
		So(HealthCheckRemote(ts.URL, ts.URL), ShouldBeNil)
	})

	Convey("Should return no internet if the inetAddress fails", t, func() {
		// Simulate no internet with a bad address
		err := HealthCheckRemote("http://foo", "http://bar")
		So(err, ShouldNotBeNil)
		So(err, ShouldHaveSameTypeAs, HealthErrorNoInternet{})
	})

	Convey("Should return no kontrol if the kontrolAddress fails", t, func() {
		tsNet := httptest.NewServer(http.HandlerFunc(
			func(w http.ResponseWriter, r *http.Request) {}))
		defer tsNet.Close()
		tsKon := httptest.NewServer(http.HandlerFunc(
			func(w http.ResponseWriter, r *http.Request) {
				w.WriteHeader(http.StatusNotFound)
				fmt.Fprint(w, "404 not found")
			}))
		defer tsKon.Close()

		err := HealthCheckRemote(tsNet.URL, tsKon.URL)
		So(err, ShouldNotBeNil)
		So(err, ShouldHaveSameTypeAs, HealthErrorNoKontrolHttp{})
	})

	Convey("Should return unexpected response if the kontrol response is.. unexpected", t, func() {
		tsNet := httptest.NewServer(http.HandlerFunc(
			func(w http.ResponseWriter, r *http.Request) {}))
		defer tsNet.Close()
		tsKon := httptest.NewServer(http.HandlerFunc(
			func(w http.ResponseWriter, r *http.Request) {
				fmt.Fprint(w, "foo bar baz\n")
			}))
		defer tsKon.Close()

		err := HealthCheckRemote(tsNet.URL, tsKon.URL)
		So(err, ShouldNotBeNil)
		So(err, ShouldHaveSameTypeAs, HealthErrorUnexpectedResponse{})
	})
}
