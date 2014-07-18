package models

import (
	"socialapi/workers/common/runner"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestChannelCreate(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("while creating channel", t, func() {
		Convey("channel name should not be empty", func(){
			c := NewChannel()
			c.Name = ""
			So(c.Create().Error(), ShouldContainSubstring, "Validation failed")
		})

		Convey("channel groupName should not be empty", func(){
			c := NewChannel()
			c.GroupName = ""
			So(c.Create().Error(), ShouldContainSubstring, "Validation failed")
		})

		Convey("channel typeConstant should not be empty", func(){
			c := NewChannel()
			c.TypeConstant = ""
			So(c.Create().Error(), ShouldContainSubstring, "Validation failed")
		})

		Convey("channel name should not contain whitespace", func(){
			c := NewChannel()
			c.Name = "name channel"
			So(c.Create().Error(), ShouldContainSubstring, "has empty space")
		})
	})

}

func TestChannelTableName(t *testing.T) {
	Convey("while testing TableName()", t, func() {
		So(NewChannel().TableName(), ShouldEqual, ChannelTableName)
	})
}

func TestChannelCanOpen(t *testing.T) {
	Convey("while testing channel permissions", t, func() {
		Convey("can not open uninitialized channel", func() {
			c := NewChannel()
			canOpen, err := c.CanOpen(1231)
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrChannelIdIsNotSet)
			So(canOpen, ShouldBeFalse)
		})

		Convey("uninitialized account can not open channel", func() {
			c := NewChannel()
			c.Id = 123
			canOpen, err := c.CanOpen(0)
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrAccountIdIsNotSet)
			So(canOpen, ShouldBeFalse)
		})

		Convey("participants can open group channel", func() {
			// init account
			account, err := createAccount()
			So(err, ShouldBeNil)
			So(account, ShouldNotBeNil)
			So(account.Id, ShouldNotEqual, 0)

			// init channel
			c := NewChannel()
			c.CreatorId = account.Id
			c.TypeConstant = Channel_TYPE_GROUP

			So(c.Create(), ShouldBeNil)

			cp, err := c.AddParticipant(account.Id)
			So(err, ShouldBeNil)
			So(cp, ShouldNotBeNil)

			canOpen, err := c.CanOpen(account.Id)
			So(err, ShouldBeNil)
			So(canOpen, ShouldBeTrue)
		})

		Convey("everyone can open group channel", func() {
			// init account
			account, err := createAccount()
			So(err, ShouldBeNil)
			So(account, ShouldNotBeNil)
			So(account.Id, ShouldNotEqual, 0)

			// init channel
			c := NewChannel()
			c.CreatorId = account.Id
			c.TypeConstant = Channel_TYPE_GROUP

			So(c.Create(), ShouldBeNil)

			// 1 is just a random id
			canOpen, err := c.CanOpen(1)
			So(err, ShouldBeNil)
			So(canOpen, ShouldBeTrue)
		})

		Convey("everyone can open topic channel", func() {
			// init account
			account, err := createAccount()
			So(err, ShouldBeNil)
			So(account, ShouldNotBeNil)
			So(account.Id, ShouldNotEqual, 0)

			// init channel
			c := NewChannel()
			c.CreatorId = account.Id
			c.TypeConstant = Channel_TYPE_TOPIC

			So(c.Create(), ShouldBeNil)

			// 1 is just a random id
			canOpen, err := c.CanOpen(1)
			So(err, ShouldBeNil)
			So(canOpen, ShouldBeTrue)
		})

		Convey("participants can open pinned activity channel", func(){
			// init account
			account, err := createAccount()
			So(err, ShouldBeNil)
			So(account, ShouldNotBeNil)
			So(account.Id, ShouldNotEqual, 0)

			// init channel
			c := NewChannel()
			c.CreatorId = account.Id
			c.TypeConstant = Channel_TYPE_PINNED_ACTIVITY

			So(c.Create(), ShouldBeNil)

			cp, err := c.AddParticipant(account.Id)
			So(err, ShouldBeNil)
			So(cp, ShouldNotBeNil)

			canOpen, err := c.CanOpen(account.Id)
			So(err, ShouldBeNil)
			So(canOpen, ShouldBeFalse)
		})

		Convey("participants can open private message channel", func(){
			// init account
			account, err := createAccount()
			So(err, ShouldBeNil)
			So(account, ShouldNotBeNil)
			So(account.Id, ShouldNotEqual, 0)

			// init channel
			c := NewChannel()
			c.CreatorId = account.Id
			c.TypeConstant = Channel_TYPE_PRIVATE_MESSAGE

			So(c.Create(), ShouldBeNil)

			// add participant to the channel
			cp, err := c.AddParticipant(account.Id)
			So(err, ShouldBeNil)
			So(cp, ShouldNotBeNil)

			canOpen, err := c.CanOpen(account.Id)
			So(err, ShouldBeNil)
			So(canOpen, ShouldBeFalse)
		})

	})

}
