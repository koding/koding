package main

import (
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"
)

func TestTimeToAgo(t *testing.T) {
	Convey("Given 2d 12h 5m ago", t, func() {
		now := time.Now()
		ago := now.Add(-(time.Hour*24*2 + time.Hour*12 + time.Minute*5))
		res := timeToAgo(ago, now)

		Convey("It should return hours", func() {
			So(res, ShouldContainSubstring, "12h")
		})

		Convey("It should return days", func() {
			So(res, ShouldContainSubstring, "2d")
		})

		Convey("It should return 2d 12h", func() {
			So(res, ShouldEqual, "2d 12h")
		})
	})
}
