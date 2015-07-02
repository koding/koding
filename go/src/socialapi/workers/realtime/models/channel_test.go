package models

import (
	"fmt"
	"socialapi/config"
	"socialapi/models"
	"testing"

	"github.com/koding/runner"

	. "github.com/smartystreets/goconvey/convey"
)

func TestChannelPrepareName(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	appConfig := config.MustRead(r.Conf.Path)

	Convey("While creating PubNub channels", t, func() {
		Convey("Notification channel name format must be as 'notification'-[env]-[nickname]", func() {
			a := &models.Account{}
			a.Nick = "hello"
			nc := NewNotificationChannel(a)
			name := nc.PrepareName()
			expectedName := fmt.Sprintf("notification-%s-%s", appConfig.Environment, a.Nick)
			So(name, ShouldEqual, expectedName)
		})
		Convey("Message update and channel name format must be as 'channel'-[token]", func() {
			c := Channel{}
			c.Token = "12345"
			pc := NewPrivateMessageChannel(c)
			expectedName := fmt.Sprintf("channel-%s", c.Token)
			So(pc.PrepareName(), ShouldEqual, expectedName)

			uim := UpdateInstanceMessage{}
			uim.ChannelToken = "12345"

			um := NewMessageUpdateChannel(uim)
			So(um.PrepareName(), ShouldEqual, expectedName)
		})
	})
}

func TestIsPrivateChannel(t *testing.T) {
	Convey("While making private channel check", t, func() {
		Convey("it should return false for group, topic and announcement channels in koding", func() {
			c := &Channel{}
			c.Group = models.Channel_KODING_NAME
			c.Type = models.Channel_TYPE_TOPIC
			isPrivate := c.IsPrivateChannel()
			So(isPrivate, ShouldBeFalse)
		})

		Convey("it should return true for all the channels for teams", func() {
			c := &Channel{}
			c.Group = "testteam"
			c.Type = models.Channel_TYPE_TOPIC
			isPrivate := c.IsPrivateChannel()
			So(isPrivate, ShouldBeTrue)
		})
	})
}
