package app

import (
	"testing"
	"time"

	"github.com/koding/kite/sockjsclient"
	. "github.com/smartystreets/goconvey/convey"
)

func TestKlientXHRClientFunc(t *testing.T) {
	Convey("Given DialOptions with a zero Timeout", t, func() {
		c := klientXHRClientFunc(&sockjsclient.DialOptions{})

		Convey("It should set the timeout to the defaultXHRTimeout", func() {
			So(c.Timeout, ShouldEqual, defaultXHRTimeout)
		})

		Convey("It should set cookieJar", func() {
			So(c.Jar, ShouldNotBeNil)
			So(c.Jar, ShouldEqual, cookieJar)
		})
	})

	Convey("Given DialOptions with a non-zero Timeout", t, func() {
		var expectedTimeout time.Duration = 7
		c := klientXHRClientFunc(&sockjsclient.DialOptions{
			Timeout: expectedTimeout,
		})

		Convey("It should use the given timeout", func() {
			So(c.Timeout, ShouldEqual, expectedTimeout)
		})

		Convey("It should set cookieJar", func() {
			So(c.Jar, ShouldNotBeNil)
			So(c.Jar, ShouldEqual, cookieJar)
		})
	})
}

func TestNewKite(t *testing.T) {
	Convey("", t, func() {
		k := newKite(&KlientConfig{
			Name:    "foo",
			Version: "0.0.0",
		})

		Convey("It should set the Clientfunc to klientXHRClientFunc", func() {
			So(k.ClientFunc, ShouldEqual, klientXHRClientFunc)
		})
	})
}
