package transport

import (
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"
)

func TestRemoteTransport(t *testing.T) {
	var _ Transport = (*RemoteTransport)(nil)
}

func TestRemoteGetTellTimeout(tt *testing.T) {
	Convey("Given a method with a long timeout", tt, func() {
		t := getTellTimout("exec", time.Minute)

		Convey("It should return the long timeout", func() {
			So(t, ShouldEqual, defaultLongTellTimeout)
			So(t, ShouldNotEqual, time.Minute)
		})
	})

	Convey("Given a method without a long timeout", tt, func() {
		t := getTellTimout("fs.readFile", time.Minute)

		Convey("It should return the default timeout", func() {
			So(t, ShouldEqual, time.Minute)
			So(t, ShouldNotEqual, defaultLongTellTimeout)
		})
	})
}
