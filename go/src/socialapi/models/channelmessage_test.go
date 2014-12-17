package models

import (
	"socialapi/workers/common/runner"
	"testing"
	"time"

	"github.com/koding/bongo"
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
			cm := createMessageWithTest()
			cm.TypeConstant = ""
			So(cm.Create(), ShouldNotBeNil)
			// complete error message is this: pq: invalid input value for enum channel_message_type_constant_enum: \"\"
			// it is trimmed because wercker add schema name and returns api.channel_message_type_constant_enum
			So(cm.Create().Error(), ShouldContainSubstring, "pq: invalid input value for enum")
		})

		Convey("type constant can be post", func() {
			cm := createMessageWithTest()
			// remove type Constant
			cm.TypeConstant = ChannelMessage_TYPE_POST

			So(cm.Create(), ShouldBeNil)

			icm := NewChannelMessage()
			err := icm.ById(cm.Id)
			So(err, ShouldBeNil)
			So(icm.Id, ShouldEqual, cm.Id)
			So(icm.TypeConstant, ShouldEqual, ChannelMessage_TYPE_POST)
		})

		Convey("type constant can be reply", func() {
			cm := createMessageWithTest()
			// remove type Constant
			cm.TypeConstant = ChannelMessage_TYPE_REPLY

			So(cm.Create(), ShouldBeNil)

			icm := NewChannelMessage()
			err := icm.ById(cm.Id)
			So(err, ShouldBeNil)
			So(icm.Id, ShouldEqual, cm.Id)
			So(icm.TypeConstant, ShouldEqual, ChannelMessage_TYPE_REPLY)
		})
		Convey("type constant can be join", func() {
			cm := createMessageWithTest()
			// remove type Constant
			cm.TypeConstant = ChannelMessage_TYPE_JOIN

			So(cm.Create(), ShouldBeNil)

			icm := NewChannelMessage()
			err := icm.ById(cm.Id)
			So(err, ShouldBeNil)
			So(icm.Id, ShouldEqual, cm.Id)
			So(icm.TypeConstant, ShouldEqual, ChannelMessage_TYPE_JOIN)
		})

		Convey("type constant can be leave", func() {
			cm := createMessageWithTest()
			// remove type Constant
			cm.TypeConstant = ChannelMessage_TYPE_LEAVE

			So(cm.Create(), ShouldBeNil)

			icm := NewChannelMessage()
			err := icm.ById(cm.Id)
			So(err, ShouldBeNil)
			So(icm.Id, ShouldEqual, cm.Id)
			So(icm.TypeConstant, ShouldEqual, ChannelMessage_TYPE_LEAVE)
		})

		Convey("type constant can be privatemessage", func() {
			cm := createMessageWithTest()
			// remove type Constant
			cm.TypeConstant = ChannelMessage_TYPE_PRIVATE_MESSAGE

			So(cm.Create(), ShouldBeNil)

			icm := NewChannelMessage()
			err := icm.ById(cm.Id)
			So(err, ShouldBeNil)
			So(icm.Id, ShouldEqual, cm.Id)
			So(icm.TypeConstant, ShouldEqual, ChannelMessage_TYPE_PRIVATE_MESSAGE)
		})

		Convey("5 length body could be inserted ", func() {
			cm := createMessageWithTest()
			// set body
			cm.Body = "5five"

			// try to create the message
			So(cm.Create(), ShouldBeNil)
		})

		Convey("message should have slug after inserting ", func() {
			// create message
			cm := createMessageWithTest()
			// be sure that our message doesnt have slug
			So(cm.Id, ShouldBeZeroValue)
			So(cm.Slug, ShouldBeZeroValue)
			// try to create the message
			So(cm.Create(), ShouldBeNil)
			So(cm.Id, ShouldNotEqual, 0)

			// fetch created message
			icm := NewChannelMessage()
			err := icm.ById(cm.Id)
			So(err, ShouldBeNil)
			So(icm.Id, ShouldNotEqual, 0)
			So(icm.Slug, ShouldNotEqual, "")
		})
	})
}

func TestChannelMessageUpdate(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("while updating channel message", t, func() {
		Convey("0 length body could not be updated ", func() {
			cm := createMessageWithTest()
			So(cm.Create(), ShouldBeNil)

			// clear message body
			cm.Body = ""
			So(cm.Update(), ShouldNotBeEmpty)
			So(cm.Update().Error(), ShouldContainSubstring, "message body length should be greater than")
		})

		Convey("valid length body can  be updated ", func() {
			// create message in the db
			cm := createMessageWithTest()
			So(cm.Create(), ShouldBeNil)

			// update the db
			body := "my updated text"

			// clear message body
			cm.Body = body
			So(cm.Update(), ShouldBeEmpty)

			// fetch createed/updated message from db
			icm := NewChannelMessage()
			err := icm.ById(cm.Id)
			So(err, ShouldBeNil)
			So(icm.Body, ShouldEqual, body)
		})

		Convey("valid length body can  be updated ", func() {
			// create message in the db
			cm := createMessageWithTest()
			So(cm.Create(), ShouldBeNil)

			// update the db
			body := "my updated text"

			// clear message body
			cm.Body = body
			So(cm.Update(), ShouldBeEmpty)

			// fetch createed/updated message from db
			icm := NewChannelMessage()
			err := icm.ById(cm.Id)
			So(err, ShouldBeNil)
			So(icm.Body, ShouldEqual, body)
		})

		Convey("meta bits can not be updated", nil)

		Convey("token can not  be updated ", func() {
			// create message in the db
			cm := createMessageWithTest()
			So(cm.Create(), ShouldBeNil)

			// update the db
			token := NewToken(time.Now()).String()

			// clear message body
			cm.Token = token

			err := cm.Update()
			So(err, ShouldBeNil)

			// fetch created/updated message from db
			icm := NewChannelMessage()
			err = icm.ById(cm.Id)
			So(err, ShouldBeNil)
			So(icm.Token, ShouldNotEqual, token)
		})

		Convey("slug can not be updated", func() {
			// message is created in db
			cm := createMessageWithTest()
			So(cm.Slug, ShouldBeZeroValue)
			So(cm.Create(), ShouldBeNil)
			So(cm.Slug, ShouldNotEqual, "")

			// invoke a new slug
			slug := "another-test-for-slug"
			cm.Slug = slug

			// update the message
			// updating channel message will assign defaults
			err := cm.Update()
			So(err, ShouldBeNil)

			icm := NewChannelMessage()
			err = icm.ById(cm.Id)
			So(err, ShouldBeNil)
			So(icm.Slug, ShouldNotEqual, slug)
		})

		Convey("typeConstant can not be updated", func() {
			// message is created in db
			cm := createMessageWithTest()
			So(cm.Create(), ShouldBeNil)
			So(cm.TypeConstant, ShouldNotEqual, "")

			cm.TypeConstant = ChannelMessage_TYPE_JOIN

			// update the message
			// updating channel message will assign defaults
			err := cm.Update()
			So(err, ShouldBeNil)

			icm := NewChannelMessage()
			err = icm.ById(cm.Id)
			So(err, ShouldBeNil)
			So(icm.TypeConstant, ShouldNotEqual, ChannelMessage_TYPE_JOIN)
		})

		Convey("AccountId can not be updated", func() {
			// message is created in db
			cm := createMessageWithTest()
			So(cm.Create(), ShouldBeNil)
			So(cm.AccountId, ShouldNotEqual, 0)

			accId := cm.AccountId + 1
			cm.AccountId = accId

			// update the message
			// updating channel message will assign defaults
			err := cm.Update()
			So(err, ShouldBeNil)

			icm := NewChannelMessage()
			err = icm.ById(cm.Id)
			So(err, ShouldBeNil)
			So(icm.AccountId, ShouldNotEqual, accId)
		})

		Convey("InitialChannelId can not be updated", func() {
			// message is created in db
			cm := createMessageWithTest()
			So(cm.Create(), ShouldBeNil)
			So(cm.InitialChannelId, ShouldNotEqual, 0)

			cId := cm.InitialChannelId + 1
			cm.InitialChannelId = cId

			// update the message
			// updating channel message will assign defaults
			err := cm.Update()
			So(err, ShouldBeNil)

			icm := NewChannelMessage()
			err = icm.ById(cm.Id)
			So(err, ShouldBeNil)
			So(icm.InitialChannelId, ShouldNotEqual, cId)
		})

		Convey("CreatedAt can not be updated", func() {
			// message is created in db
			cm := createMessageWithTest()
			So(cm.Create(), ShouldBeNil)
			So(cm.CreatedAt, ShouldNotBeEmpty)

			timeNow := time.Now()
			cm.CreatedAt = timeNow

			// update the message
			// updating channel message will assign defaults
			err := cm.Update()
			So(err, ShouldBeNil)

			icm := NewChannelMessage()
			err = icm.ById(cm.Id)
			So(err, ShouldBeNil)
			So(icm.CreatedAt, ShouldNotEqual, timeNow)
		})

		Convey("Join/Leave message can not be updated", func() {
			// message is created in db
			cm := createMessageWithTest()
			cm.TypeConstant = ChannelMessage_TYPE_JOIN

			So(cm.Create(), ShouldBeNil)
			So(cm.CreatedAt, ShouldNotBeEmpty)

			cm.Body = "join me"
			err := cm.Update()
			So(err, ShouldEqual, ErrChannelMessageUpdatedNotAllowed)

			cm = createMessageWithTest()
			cm.TypeConstant = ChannelMessage_TYPE_LEAVE

			So(cm.Create(), ShouldBeNil)
			So(cm.CreatedAt, ShouldNotBeEmpty)

			cm.Body = "leave me"
			err = cm.Update()
			So(err, ShouldEqual, ErrChannelMessageUpdatedNotAllowed)
		})
	})
}

func TestChannelMessageGetBongoName(t *testing.T) {
	Convey("while testing BongoName()", t, func() {
		So(NewChannelMessage().BongoName(), ShouldEqual, ChannelMessageBongoName)
	})
}

func TestChannelMessageGetAccountId(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("while getting account id ", t, func() {
		Convey("it should have channel id", func() {
			cm := NewChannelMessage()

			_, err := cm.getAccountId()
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldContainSubstring, "couldnt find accountId from content")
		})

		Convey("it should have error if account is not set", func() {
			cm := NewChannelMessage()
			cm.Id = 13531

			_, err := cm.getAccountId()
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, bongo.RecordNotFound)
		})

		Convey("it should not have error if channel & account are exist", func() {
			cm := NewChannelMessage()
			cm.Id = 2454
			cm.AccountId = 4353

			gid, err := cm.getAccountId()
			So(err, ShouldBeNil)
			So(gid, ShouldEqual, cm.AccountId)
		})

	})
}

func TestChannelMessageBodyLenCheck(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("while checking body length", t, func() {
		Convey("it should have error if body length is zero", func() {
			cm := createMessageWithTest()
			cm.Body = ""

			err := bodyLenCheck(cm.Body)
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldContainSubstring, "message body length should be greater than")
		})

		Convey("it should not have error if length of body is greater than zero ", func() {
			cm := createMessageWithTest()
			cm.Body = "message"

			err := bodyLenCheck(cm.Body)
			So(err, ShouldBeNil)
		})

	})
}

func TestChannelMessageBuildEmptyMessageContainer(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("while building empty message container", t, func() {
		Convey("it should have channel message id", func() {
			c := NewChannelMessage()

			_, err := c.BuildEmptyMessageContainer()
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrChannelMessageIdIsNotSet)
		})

		Convey("it should not have error if chanel is exist", func() {
			// create message
			c := createMessageWithTest()
			So(c.Create(), ShouldBeNil)

			bem, err := c.BuildEmptyMessageContainer()
			So(err, ShouldBeNil)
			So(bem.Message, ShouldEqual, c)
		})
	})
}
