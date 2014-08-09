package models

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestChannelcontainerNewChanelContainer(t *testing.T) {
	Convey("while testing New Channel Container", t, func() {
		Convey("Function call should return ChannelContainer", func() {
			So(NewChannelContainer(), ShouldNotBeNil)
		})
	})
}
