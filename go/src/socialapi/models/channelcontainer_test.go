package models

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestChannelcontainerNewChannelContainers(t *testing.T) {
	Convey("While testing new channel container", t, func() {
		Convey("Function should return Channel container", func() {
			So(NewChannelContainer(), ShouldNotBeNil)
		})
	})
}
