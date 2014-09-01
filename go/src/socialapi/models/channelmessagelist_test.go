package models

import (
	"socialapi/workers/common/runner"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestChannelMessageListFetchMessageChannels(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("while fethcing channel message of a message", t, func() {
		Convey("channels should be valid", func() {
			c1 := createNewChannelWithTest()
			So(c1.Create(), ShouldBeNil)

			c2 := createNewChannelWithTest()
			So(c2.Create(), ShouldBeNil)

			c3 := createNewChannelWithTest()
			So(c3.Create(), ShouldBeNil)

			cm := NewChannelMessage()
			cm.Body = "gel beri abi"
			cm.AccountId = c1.CreatorId
			cm.InitialChannelId = c1.Id
			So(cm.Create(), ShouldBeNil)

			// add to first channel
			_, err := c1.AddMessage(cm.Id)
			So(err, ShouldBeNil)

			// add to second channel
			_, err = c2.AddMessage(cm.Id)
			So(err, ShouldBeNil)

			// add to 3rd channel
			_, err = c3.AddMessage(cm.Id)
			So(err, ShouldBeNil)

			channels, err := NewChannelMessageList().FetchMessageChannels(cm.Id)
			So(err, ShouldBeNil)
			So(len(channels), ShouldEqual, 3)

			So(c1.Name, ShouldEqual, channels[0].Name)
			So(c2.Name, ShouldEqual, channels[1].Name)
			So(c3.Name, ShouldEqual, channels[2].Name)

			So(c1.GroupName, ShouldEqual, channels[0].GroupName)
			So(c2.GroupName, ShouldEqual, channels[1].GroupName)
			So(c3.GroupName, ShouldEqual, channels[2].GroupName)
		})
	})
}

func TestChannelMessageListCount(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("while counting messages", t, func() {
		Convey("it should error if channel id is not set", func() {
			cml := NewChannelMessageList()

			c, err := cml.Count(0)
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrChannelIdIsNotSet)
			So(c, ShouldEqual, 0)
		})

		Convey("it should error  ", func() {
			// create message
			cm := createMessageWithTest()
			So(cm.Create(), ShouldBeNil)

			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)

			_, err := c.AddMessage(cm.Id)
			So(err, ShouldBeNil)

			cml := NewChannelMessageList()
			cml.ChannelId = c.Id

			cnt, err := cml.Count(cml.ChannelId)
			So(err, ShouldBeNil)
			So(cnt, ShouldEqual, 1)

		})
	})
}
