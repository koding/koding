package models

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestChannelContainerNewChanelContainer(t *testing.T) {
	Convey("while testing New Channel Container", t, func() {
		Convey("Function call should return ChannelContainer", func() {
			So(NewChannelContainer(), ShouldNotBeNil)
		})
	})
}

func TestChannelContainerBongoName(t *testing.T) {
	Convey("while testing table name", t, func() {
		Convey("it should return api.channel ", func() {
			c := NewChannelContainer()

			So(c.BongoName(), ShouldNotBeNil)
			So(c.BongoName(), ShouldEqual, "api.channel")
		})
	})
}

func TestChannelContainerGetId(t *testing.T) {
	Convey("while getting id of the channel", t, func() {
		Convey("it should have zero value if channel is nil ", func() {
			c := NewChannelContainer()

			So(c.Channel, ShouldEqual, nil)
			So(c.GetId(), ShouldEqual, 0)
		})

		Convey("it should have channel id if channel is exist", func() {
			acc := CreateAccountWithTest()
			ch := CreateChannelWithTest(acc.Id)
			c := NewChannelContainer()
			c.Channel = ch

			So(c.Channel, ShouldNotBeEmpty)
			So(c.GetId(), ShouldEqual, ch.Id)
		})
	})
}
