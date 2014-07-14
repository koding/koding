package models

import (
	"socialapi/workers/common/runner"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestChannelMessageCreate(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("while creating channel message", t, func() {
		Convey("0 length body could not be inserted ", func() {
			cm := NewChannelMessage()
			So(cm.Create(), ShouldNotBeNil)
			So(cm.Create().Error(), ShouldContainSubstring, "message body length should be greater than")
		})

		Convey("type constant should be given", func() {
			cm := NewChannelMessage()

			// init account
			account, err := createAccount()
			So(err, ShouldBeNil)
			So(account, ShouldNotBeNil)
			So(account.Id, ShouldNotEqual, 0)
			// init channel
			channel, err := createChannel(account.Id)
			So(err, ShouldBeNil)
			So(channel, ShouldNotBeNil)

			// set account id
			cm.AccountId = account.Id
			// set channel id
			cm.InitialChannelId = channel.Id
			// set body
			cm.Body = "5five"
			// remove type Constant
			cm.TypeConstant = ""

			So(cm.Create(), ShouldNotBeNil)
			So(cm.Create().Error(), ShouldContainSubstring, "pq: invalid input value for enum channel_message_type_constant_enum: \"\"")
		})

		Convey("type constant can be post", func() {
			cm := NewChannelMessage()

			// init account
			account, err := createAccount()
			So(err, ShouldBeNil)
			So(account, ShouldNotBeNil)
			So(account.Id, ShouldNotEqual, 0)
			// init channel
			channel, err := createChannel(account.Id)
			So(err, ShouldBeNil)
			So(channel, ShouldNotBeNil)

			// set account id
			cm.AccountId = account.Id
			// set channel id
			cm.InitialChannelId = channel.Id
			// set body
			cm.Body = "5five"
			// remove type Constant
			cm.TypeConstant = ChannelMessage_TYPE_POST

			So(cm.Create(), ShouldBeNil)

			insertedChannelMessage := NewChannelMessage()
			err := insertedChannelMessage.ById(cm.Id)
			So(err, ShouldBeNil)
			So(insertedChannelMessage.Id, ShouldNotEqual, 0)
			So(insertedChannelMessage.Id, ShouldEqual, cm.Id)
			So(insertedChannelMessage.Body, ShouldEqual, "5five")
			So(insertedChannelMessage.TypeConstant, ShouldEqual, ChannelMessage_TYPE_POST)
		})

		Convey("type constant can be reply", func() {
			cm := NewChannelMessage()

			// init account
			account, err := createAccount()
			So(err, ShouldBeNil)
			So(account, ShouldNotBeNil)
			So(account.Id, ShouldNotEqual, 0)
			// init channel
			channel, err := createChannel(account.Id)
			So(err, ShouldBeNil)
			So(channel, ShouldNotBeNil)

			// set account id
			cm.AccountId = account.Id
			// set channel id
			cm.InitialChannelId = channel.Id
			// set body
			cm.Body = "5five"
			// remove type Constant
			cm.TypeConstant = ChannelMessage_TYPE_REPLY

			So(cm.Create(), ShouldBeNil)

			insertedChannelMessage := NewChannelMessage()
			err := insertedChannelMessage.ById(cm.Id)
			So(err, ShouldBeNil)
			So(insertedChannelMessage.Id, ShouldNotEqual, 0)
			So(insertedChannelMessage.Id, ShouldEqual, cm.Id)
			So(insertedChannelMessage.Body, ShouldEqual, "5five")
			So(insertedChannelMessage.TypeConstant, ShouldEqual, ChannelMessage_TYPE_REPLY)
		})
		Convey("type constant can be join", func() {
			cm := NewChannelMessage()

			// init account
			account, err := createAccount()
			So(err, ShouldBeNil)
			So(account, ShouldNotBeNil)
			So(account.Id, ShouldNotEqual, 0)
			// init channel
			channel, err := createChannel(account.Id)
			So(err, ShouldBeNil)
			So(channel, ShouldNotBeNil)

			// set account id
			cm.AccountId = account.Id
			// set channel id
			cm.InitialChannelId = channel.Id
			// set body
			cm.Body = "5five"
			// remove type Constant
			cm.TypeConstant = ChannelMessage_TYPE_JOIN

			So(cm.Create(), ShouldBeNil)

			insertedChannelMessage := NewChannelMessage()
			err := insertedChannelMessage.ById(cm.Id)
			So(err, ShouldBeNil)
			So(insertedChannelMessage.Id, ShouldNotEqual, 0)
			So(insertedChannelMessage.Id, ShouldEqual, cm.Id)
			So(insertedChannelMessage.Body, ShouldEqual, "5five")
			So(insertedChannelMessage.TypeConstant, ShouldEqual, ChannelMessage_TYPE_JOIN)
		})

		Convey("type constant can be leave", func() {
			cm := NewChannelMessage()

			// init account
			account, err := createAccount()
			So(err, ShouldBeNil)
			So(account, ShouldNotBeNil)
			So(account.Id, ShouldNotEqual, 0)
			// init channel
			channel, err := createChannel(account.Id)
			So(err, ShouldBeNil)
			So(channel, ShouldNotBeNil)

			// set account id
			cm.AccountId = account.Id
			// set channel id
			cm.InitialChannelId = channel.Id
			// set body
			cm.Body = "5five"
			// remove type Constant
			cm.TypeConstant = ChannelMessage_TYPE_LEAVE

			So(cm.Create(), ShouldBeNil)

			insertedChannelMessage := NewChannelMessage()
			err := insertedChannelMessage.ById(cm.Id)
			So(err, ShouldBeNil)
			So(insertedChannelMessage.Id, ShouldNotEqual, 0)
			So(insertedChannelMessage.Id, ShouldEqual, cm.Id)
			So(insertedChannelMessage.Body, ShouldEqual, "5five")
			So(insertedChannelMessage.TypeConstant, ShouldEqual, ChannelMessage_TYPE_LEAVE)
		})

		Convey("type constant can be chat", func() {
			cm := NewChannelMessage()

			// init account
			account, err := createAccount()
			So(err, ShouldBeNil)
			So(account, ShouldNotBeNil)
			So(account.Id, ShouldNotEqual, 0)
			// init channel
			channel, err := createChannel(account.Id)
			So(err, ShouldBeNil)
			So(channel, ShouldNotBeNil)

			// set account id
			cm.AccountId = account.Id
			// set channel id
			cm.InitialChannelId = channel.Id
			// set body
			cm.Body = "5five"
			// remove type Constant
			cm.TypeConstant = ChannelMessage_TYPE_CHAT

			So(cm.Create(), ShouldBeNil)

			insertedChannelMessage := NewChannelMessage()
			err := insertedChannelMessage.ById(cm.Id)
			So(err, ShouldBeNil)
			So(insertedChannelMessage.Id, ShouldNotEqual, 0)
			So(insertedChannelMessage.Id, ShouldEqual, cm.Id)
			So(insertedChannelMessage.Body, ShouldEqual, "5five")
			So(insertedChannelMessage.TypeConstant, ShouldEqual, ChannelMessage_TYPE_CHAT)
		})

		Convey("type constant can be privatemessage", func() {
			cm := NewChannelMessage()

			// init account
			account, err := createAccount()
			So(err, ShouldBeNil)
			So(account, ShouldNotBeNil)
			So(account.Id, ShouldNotEqual, 0)
			// init channel
			channel, err := createChannel(account.Id)
			So(err, ShouldBeNil)
			So(channel, ShouldNotBeNil)

			// set account id
			cm.AccountId = account.Id
			// set channel id
			cm.InitialChannelId = channel.Id
			// set body
			cm.Body = "5five"
			// remove type Constant
			cm.TypeConstant = ChannelMessage_TYPE_PRIVATE_MESSAGE

			So(cm.Create(), ShouldBeNil)

			insertedChannelMessage := NewChannelMessage()
			err := insertedChannelMessage.ById(cm.Id)
			So(err, ShouldBeNil)
			So(insertedChannelMessage.Id, ShouldNotEqual, 0)
			So(insertedChannelMessage.Id, ShouldEqual, cm.Id)
			So(insertedChannelMessage.Body, ShouldEqual, "5five")
			So(insertedChannelMessage.TypeConstant, ShouldEqual, ChannelMessage_TYPE_PRIVATE_MESSAGE)
		})
		// @todo add tests for followings
		// type constant can be
		//
		// ChannelMessage_TYPE_POST            = "post"
		// ChannelMessage_TYPE_REPLY           = "reply"
		// ChannelMessage_TYPE_JOIN            = "join"
		// ChannelMessage_TYPE_LEAVE           = "leave"
		// ChannelMessage_TYPE_CHAT            = "chat"
		// ChannelMessage_TYPE_PRIVATE_MESSAGE = "privatemessage"

		Convey("5 length body could be inserted ", func() {
			cm := NewChannelMessage()

			// init account
			account, err := createAccount()
			So(err, ShouldBeNil)
			So(account, ShouldNotBeNil)
			So(account.Id, ShouldNotEqual, 0)
			// init channel
			channel, err := createChannel(account.Id)
			So(err, ShouldBeNil)
			So(channel, ShouldNotBeNil)

			// set account id
			cm.AccountId = account.Id
			// set channel id
			cm.InitialChannelId = channel.Id
			// set body
			cm.Body = "5five"

			// try to create the message
			So(cm.Create(), ShouldBeNil)
		})
	})
}
