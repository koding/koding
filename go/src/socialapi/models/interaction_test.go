package models

import (
	"fmt"
	"socialapi/config"
	"socialapi/request"
	"testing"
	"math/rand"
	"strconv"
	"time"

	"github.com/koding/bongo"
	"github.com/koding/runner"

	. "github.com/smartystreets/goconvey/convey"
)

func TestInteractiongetAccountId(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("while getting account id", t, func() {
		Convey("it should have error if interaction id is not set", func() {
			i := NewInteraction()

			in, err := i.getAccountId()
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldContainSubstring, "couldnt find accountId from content")
			So(in, ShouldEqual, 0)
		})

		Convey("it should have error if account is not set in db", func() {
			i := NewInteraction()
			i.Id = 4590

			in, err := i.getAccountId()
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, bongo.RecordNotFound)
			So(in, ShouldEqual, 0)
		})

		Convey("it should return quickly account id if id is set", func() {
			i := NewInteraction()
			i.AccountId = 1020

			in, err := i.getAccountId()
			So(err, ShouldBeNil)
			So(in, ShouldEqual, i.AccountId)
		})
	})
}

func TestInteractionListLikedMessage(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	config.MustRead(r.Conf.Path)

	Convey("while creating requirements", t, func() {
		account := CreateAccountWithTest()
		kodingGroup := "koding"

		channel := CreateTypedGroupedChannelWithTest(account.Id, Channel_TYPE_GROUP, kodingGroup)

		message1 := CreateMessageWithBody(channel.Id, account.Id, ChannelMessage_TYPE_POST, "bisiler")
		message2 := CreateMessageWithBody(channel.Id, account.Id, ChannelMessage_TYPE_POST, "bisiler22")

		query := request.NewQuery()
		query.AccountId = account.Id
		query.Type = Interaction_TYPE_LIKE

		int1, err := AddInteractionWithTest(Interaction_TYPE_LIKE, message1.Id, account.Id)
		So(int1, ShouldNotBeNil)
		So(err, ShouldBeNil)
		int2, err := AddInteractionWithTest(Interaction_TYPE_LIKE, message2.Id, account.Id)
		So(int2, ShouldNotBeNil)
		So(err, ShouldBeNil)

		Convey("it should list the message ids that liked", func() {
			i := NewInteraction()
			messageIds, err := i.ListLikedMessageIds(query, channel.Id)
			So(messageIds, ShouldNotBeNil)
			So(err, ShouldBeNil)
			fmt.Println(messageIds)
			So(len(messageIds), ShouldEqual, 2)
		})

		Convey("it should list the messages that liked", func() {
			messages, err := int1.ListLikedMessages(query, channel.Id)
			So(err, ShouldBeNil)
			So(messages, ShouldNotBeNil)
			So(messages[0].Body, ShouldEqual, message1.Body)
		})

		Convey("it should fetch the messages even if type is not same ", func() {
			channel2 := CreateTypedGroupedChannelWithTest(account.Id, Channel_TYPE_TOPIC, kodingGroup)
			message3 := CreateMessageWithBody(channel2.Id, account.Id, ChannelMessage_TYPE_POST, "topuc-not topic ?")
			int3, err := AddInteractionWithTest(Interaction_TYPE_LIKE, message3.Id, account.Id)
			So(int3, ShouldNotBeNil)
			So(err, ShouldBeNil)
			i := NewInteraction()
			messageIds, err := i.ListLikedMessageIds(query, channel2.Id)
			So(messageIds, ShouldNotBeNil)
			So(err, ShouldBeNil)
			fmt.Println(messageIds)
			So(len(messageIds), ShouldEqual, 1)
		})

		Convey("it should not fetch the messages if group is different ", func() {
			// 2 messages is sent the group84 & 2 msg sent to groupKoding,
			// we should only fetch 2 messages in group84, not messages in the groupKoding 
			rand.Seed(time.Now().UnixNano())
			group84 := "group" + strconv.Itoa(rand.Intn(10e9))
			channel2 := CreateTypedGroupedChannelWithTest(account.Id, Channel_TYPE_GROUP, group84)
			message4 := CreateMessageWithBody(channel2.Id, account.Id, ChannelMessage_TYPE_POST, "GroupSeksenDort")
			message5 := CreateMessageWithBody(channel2.Id, account.Id, ChannelMessage_TYPE_POST, "GroupSeksenDort-5")
			int4, err := AddInteractionWithTest(Interaction_TYPE_LIKE, message4.Id, account.Id)
			So(int4, ShouldNotBeNil)
			So(err, ShouldBeNil)
			int5, err := AddInteractionWithTest(Interaction_TYPE_LIKE, message5.Id, account.Id)
			So(int5, ShouldNotBeNil)
			So(err, ShouldBeNil)
			i := NewInteraction()
			messageIds, err := i.ListLikedMessageIds(query, channel2.Id)
			So(messageIds, ShouldNotBeNil)
			So(err, ShouldBeNil)
			So(len(messageIds), ShouldEqual, 2)
		})

		Convey("it should not fetch the messages if message is troll", func() {
			// Normally, we have 3 messages(2 message is exist above),
			// but one of the messages is troll message,
			// so, we should fetch 2 messages, not troll message 
			messageTroll := CreateTrollMessage(channel.Id, account.Id, ChannelMessage_TYPE_POST)
			int6, err := AddInteractionWithTest(Interaction_TYPE_LIKE, messageTroll.Id, account.Id)
			So(int6, ShouldNotBeNil)
			So(err, ShouldBeNil)
			i := NewInteraction()
			messageIds, err := i.ListLikedMessageIds(query, channel.Id)
			So(messageIds, ShouldNotBeNil)
			So(err, ShouldBeNil)
			So(len(messageIds), ShouldEqual, 2)
		})
	})
}

func TestInteractionisExempt(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("While testing interaction is exempt or not", t, func() {
		Convey("it should have error while getting account id from db when channel id is not set", func() {
			i := NewInteraction()

			ie, err := i.isExempt()
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldContainSubstring, "couldnt find accountId from content")
			So(ie, ShouldEqual, false)
		})

		Convey("it should have error if account id is not set", func() {
			i := NewInteraction()
			i.Id = 1098

			ie, err := i.isExempt()
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, bongo.RecordNotFound)
			So(ie, ShouldEqual, false)
		})

		Convey("it should return true if account is troll", func() {
			// create troll account
			accTroll := CreateAccountWithTest()
			err := accTroll.MarkAsTroll()
			So(err, ShouldBeNil)

			i := NewInteraction()
			i.AccountId = accTroll.Id

			ie, err := i.isExempt()
			So(err, ShouldBeNil)
			So(ie, ShouldEqual, true)
		})

		Convey("it should return false if account is not troll", func() {
			// create account
			acc := CreateAccountWithTest()

			i := NewInteraction()
			i.AccountId = acc.Id

			ie, err := i.isExempt()
			So(err, ShouldBeNil)
			So(ie, ShouldEqual, false)
		})

	})
}

func TestInteractionMarkIfExempt(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("While marking if interaction isexempt ", t, func() {
		Convey("it should return nil if exempt", func() {
			accTroll := CreateAccountWithTest()
			err := accTroll.MarkAsTroll()
			So(err, ShouldBeNil)

			msg := createMessageWithTest()
			So(msg.Create(), ShouldBeNil)

			i := NewInteraction()
			i.AccountId = accTroll.Id
			i.MessageId = msg.Id

			errs := i.MarkIfExempt()
			So(errs, ShouldBeNil)
		})

	})
}

func TestInteractionIsInteracted(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("while testing account is interacted", t, func() {
		Convey("it should have error if message id is not set", func() {
			i := NewInteraction()

			cnt, err := i.IsInteracted(0)
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrMessageIdIsNotSet)
			So(cnt, ShouldEqual, false)
		})

		Convey("it should return false if account id is not set", func() {
			i := NewInteraction()
			i.MessageId = 1050

			cnt, err := i.IsInteracted(0)
			So(err, ShouldBeNil)
			So(cnt, ShouldEqual, false)
		})

		Convey("it should return false&nil if account id is not found in db", func() {
			i := NewInteraction()
			i.MessageId = 1050

			cnt, err := i.IsInteracted(10209)
			So(err, ShouldBeNil)
			So(cnt, ShouldEqual, false)
		})

	})
}
