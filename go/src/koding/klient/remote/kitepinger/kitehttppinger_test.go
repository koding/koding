package kitepinger

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestKiteHTTPPinger(tt *testing.T) {
	Convey("It should implement Pinger", tt, func() {
		var _ Pinger = &KitePinger{}
	})
}

func TestNewKiteHTTPPingerPing(tt *testing.T) {
	Convey("It should require a valid address", tt, func() {
		_, err := NewKiteHTTPPinger("")
		So(err, ShouldNotBeNil)

		_, err = NewKiteHTTPPinger("noprotocolhost.com:56789")
		So(err, ShouldNotBeNil)

		_, err = NewKiteHTTPPinger("http://goodhost.com:56789/some/path")
		So(err, ShouldBeNil)

		_, err = NewKiteHTTPPinger("http://goodhost.com:56789")
		So(err, ShouldBeNil)
	})
}

func TestKiteHTTPPingerPing(tt *testing.T) {
	Convey("Given a KiteHTTPPinger", tt, func() {
		Convey("When the address returns a normal kite response", func() {
			ts := httptest.NewServer(http.HandlerFunc(
				func(w http.ResponseWriter, r *http.Request) {
					fmt.Fprint(w, kiteHTTPResponse)
				}))
			defer ts.Close()
			p, err := NewKiteHTTPPinger(ts.URL)
			So(err, ShouldBeNil)

			Convey("It should return succes", func() {
				So(p.Ping(), ShouldEqual, Success)
			})
		})

		Convey("When the address returns a non-kite response", func() {
			ts := httptest.NewServer(http.HandlerFunc(
				func(w http.ResponseWriter, r *http.Request) {
					fmt.Fprint(w, "hello")
				}))
			defer ts.Close()
			p, err := NewKiteHTTPPinger(ts.URL)
			So(err, ShouldBeNil)

			Convey("It should return failure", func() {
				So(p.Ping(), ShouldEqual, Failure)
			})
		})
	})
}
