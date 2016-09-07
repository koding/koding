package main

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestIsUpdateAvailable(t *testing.T) {
	Convey("It should return true if latest version is greater than current version", t, func() {
		mux := http.NewServeMux()
		mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
			fmt.Fprintf(w, "2")
		})

		server := httptest.NewServer(mux)
		defer server.Close()

		u := CheckUpdate{
			LocalVersion:       1,
			Location:           server.URL,
			RandomSeededNumber: 1,
		}

		yesUpdate, err := u.IsUpdateAvailable()
		So(err, ShouldBeNil)
		So(yesUpdate, ShouldBeTrue)
	})

	Convey("It should return false if latest version is less or equal to than current version", t, func() {
		mux := http.NewServeMux()
		mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
			fmt.Fprintf(w, "1")
		})

		server := httptest.NewServer(mux)
		defer server.Close()

		u := CheckUpdate{
			LocalVersion:       1,
			Location:           server.URL,
			RandomSeededNumber: 1,
		}

		noUpdate, err := u.IsUpdateAvailable()
		So(err, ShouldBeNil)
		So(noUpdate, ShouldBeFalse)
	})

	Convey("It should check for update if ForceCheck is enabled", t, func() {
		mux := http.NewServeMux()
		mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
			fmt.Fprintf(w, "1")
		})

		server := httptest.NewServer(mux)
		defer server.Close()

		u := CheckUpdate{
			LocalVersion:       1,
			Location:           server.URL,
			RandomSeededNumber: 2,
		}

		noUpdate, err := u.IsUpdateAvailable()
		So(err, ShouldBeNil)
		So(noUpdate, ShouldBeFalse)
	})

	Convey("It shouldn't update if randomly seeded number is not 1", t, func() {
		u := CheckUpdate{
			LocalVersion:       1,
			Location:           "http://location:9999",
			RandomSeededNumber: 2,
		}

		noUpdate, err := u.IsUpdateAvailable()
		So(err, ShouldBeNil)
		So(noUpdate, ShouldBeFalse)
	})

	Convey("It should return err if unable to check for update", t, func() {
		u := CheckUpdate{Location: "http://location:9999", RandomSeededNumber: 1}

		_, err := u.IsUpdateAvailable()
		So(err, ShouldNotBeNil)
	})

	Convey("It should return err if unable to check for update", t, func() {
		mux := http.NewServeMux()
		mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
			fmt.Fprintf(w, "sdfsdf")
		})

		server := httptest.NewServer(mux)
		defer server.Close()

		u := CheckUpdate{
			LocalVersion:       1,
			Location:           server.URL,
			RandomSeededNumber: 1,
		}

		_, err := u.IsUpdateAvailable()
		So(err, ShouldNotBeNil)
	})
}
