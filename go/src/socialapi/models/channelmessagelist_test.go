package models

import (
	"socialapi/workers/common/runner"
	"testing"

	"github.com/koding/bongo"
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

		Convey("it should not error if message in the channel", func() {
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

		Convey("it should not count message if account of message is troll ", func() {
			// create channel
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)

			// create account as troll
			acc1 := createAccountWithTest()
			err := acc1.MarkAsTroll()
			So(err, ShouldBeNil)

			acc2 := createAccountWithTest()

			// create message that creator is troll
			msg := createMessageWithTest()
			msg.AccountId = acc1.Id
			So(msg.Create(), ShouldBeNil)

			msg2 := createMessageWithTest()
			msg2.AccountId = acc2.Id
			So(msg2.Create(), ShouldBeNil)

			// add message to the channel
			// account is troll !!
			_, erro := c.AddMessage(msg.Id)
			So(erro, ShouldBeNil)

			_, erre := c.AddMessage(msg2.Id)
			So(erre, ShouldBeNil)

			cml := NewChannelMessageList()
			cml.ChannelId = c.Id

			// there is 2 message in the channel
			// but one of the account of message is troll so;
			// Count will not count this message
			// messages of troll is not valid to count
			cnt, err := cml.Count(cml.ChannelId)
			So(err, ShouldBeNil)
			So(cnt, ShouldEqual, 1)
		})
	})
}

func TestChannelMessageListisExempt(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("while testing is exempt", t, func() {
		Convey("it should have error if message id is not set ", func() {
			cml := NewChannelMessageList()

			is, err := cml.isExempt()
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrMessageIdIsNotSet)
			So(is, ShouldEqual, false)
		})

		Convey("it should return true is channel is exempt", func() {
			// create account as troll
			acc := createAccountWithTest()
			err := acc.MarkAsTroll()
			So(err, ShouldBeNil)

			// create channel
			c := createNewChannelWithTest()
			c.CreatorId = acc.Id

			// create message
			msg := createMessageWithTest()
			msg.AccountId = acc.Id
			So(msg.Create(), ShouldBeNil)

			cml := NewChannelMessageList()
			cml.ChannelId = c.Id
			cml.MessageId = msg.Id

			is, err := cml.isExempt()
			So(err, ShouldBeNil)
			So(is, ShouldEqual, true)
		})

		Convey("it should return false is channel is not exempt", func() {
			// create account as not troll
			acc := createAccountWithTest()
			acc.IsTroll = false

			// create channel
			c := createNewChannelWithTest()
			c.CreatorId = acc.Id

			// create message
			msg := createMessageWithTest()
			msg.AccountId = acc.Id
			So(msg.Create(), ShouldBeNil)

			cml := NewChannelMessageList()
			cml.ChannelId = c.Id
			cml.MessageId = msg.Id

			is, err := cml.isExempt()
			So(err, ShouldBeNil)
			So(is, ShouldEqual, false)
		})
	})
}

func TestChannelMessageListMarkIfExempt(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("while marking if channel is exempt", t, func() {
		Convey("it should have error if message id is not set", func() {
			cml := NewChannelMessageList()

			err := cml.MarkIfExempt()
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrMessageIdIsNotSet)
		})

		Convey("it should mark as exempt if channel is exempt", func() {
			// create account as troll
			acc := createAccountWithTest()
			err := acc.MarkAsTroll()
			So(err, ShouldBeNil)

			// create channel
			c := createNewChannelWithTest()
			c.CreatorId = acc.Id

			// create message
			msg := createMessageWithTest()
			msg.AccountId = acc.Id
			So(msg.Create(), ShouldBeNil)

			cml := NewChannelMessageList()
			cml.ChannelId = c.Id
			cml.MessageId = msg.Id

			errr := cml.MarkIfExempt()
			So(errr, ShouldBeNil)
		})

	})
}

func TestChannelMessageListUpdateAddedAt(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("while updating addedAt", t, func() {
		Convey("it should have message id otherwise error occurs", func() {
			cml := NewChannelMessageList()

			err := cml.UpdateAddedAt(0, 1092)
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrChannelOrMessageIdIsNotSet)
		})

		Convey("it should have channel id otherwise error occurs", func() {
			cml := NewChannelMessageList()

			err := cml.UpdateAddedAt(1091, 0)
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrChannelOrMessageIdIsNotSet)
		})

		Convey("it should have record not found error if channel id or message id does not exist", func() {
			cml := NewChannelMessageList()

			err := cml.UpdateAddedAt(1091, 1092)
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, bongo.RecordNotFound)
		})

		Convey("it should not have error if update is done successfuly", func() {
			// create account
			acc := createAccountWithTest()

			// create channel
			c := createNewChannelWithTest()
			c.CreatorId = acc.Id
			So(c.Create(), ShouldBeNil)

			// create message
			msg := createMessageWithTest()
			msg.AccountId = acc.Id
			So(msg.Create(), ShouldBeNil)

			_, erro := c.AddMessage(msg.Id)
			So(erro, ShouldBeNil)

			cml := NewChannelMessageList()
			cml.ChannelId = c.Id
			cml.MessageId = msg.Id

			err := cml.UpdateAddedAt(cml.ChannelId, cml.MessageId)
			So(err, ShouldBeNil)
		})
	})
}

func TestChannelMessageListUnreadCount(t *testing.T) {
	r := runner.New("test")
	defer r.Close()
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}

	Convey("while counting unread messages", t, func() {
		Convey("it should have error if channel id is not set", func() {
			cml := NewChannelMessageList()
			cp := NewChannelParticipant()

			cnt, err := cml.UnreadCount(cp)
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrChannelIdIsNotSet)
			So(cnt, ShouldEqual, 0)
		})

		Convey("it should have error if account id doesn't exist", func() {
			cp := NewChannelParticipant()
			cml := NewChannelMessageList()
			cp.ChannelId = 1920

			cnt, err := cml.UnreadCount(cp)
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrAccountIdIsNotSet)
			So(cnt, ShouldEqual, 0)
		})

		Convey("it should have error if last seen time is zero", func() {
			cml := NewChannelMessageList()
			cp := NewChannelParticipant()
			cp.ChannelId = 1920
			cp.AccountId = 1903
			cp.LastSeenAt = ZeroDate()

			cnt, err := cml.UnreadCount(cp)
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrLastSeenAtIsNotSet)
			So(cnt, ShouldEqual, 0)
		})

		Convey("it should count if participant is troll", func() {
			// create account as troll
			accTroll := createAccountWithTest()
			err := accTroll.MarkAsTroll()
			So(err, ShouldBeNil)

			// create channel
			c := createNewChannelWithTest()
			c.CreatorId = accTroll.Id
			So(c.Create(), ShouldBeNil)

			// create message
			msg := createMessageWithTest()
			msg.AccountId = accTroll.Id
			So(msg.Create(), ShouldBeNil)

			cml := NewChannelMessageList()
			cml.ChannelId = c.Id
			cml.MessageId = msg.Id

			_, errs := c.AddParticipant(accTroll.Id)
			So(errs, ShouldBeNil)

			cp := NewChannelParticipant()
			cp.ChannelId = c.Id
			cp.AccountId = accTroll.Id

			_, erre := c.AddMessage(msg.Id)
			So(erre, ShouldBeNil)

			cnt, err := cml.UnreadCount(cp)
			So(err, ShouldBeNil)
			So(cnt, ShouldEqual, 1)
		})
	})
}

func TestChannelMessageListIsInChannel(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("while testing message is in channel", t, func() {
		Convey("it should have error if message id doesn't exist", func() {
			cml := NewChannelMessageList()

			ch, err := cml.IsInChannel(0, 1020)
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrChannelOrMessageIdIsNotSet)
			So(ch, ShouldEqual, false)
		})

		Convey("it should have channel id, otherwise error occurs", func() {
			cml := NewChannelMessageList()

			ch, err := cml.IsInChannel(1040, 0)
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrChannelOrMessageIdIsNotSet)
			So(ch, ShouldEqual, false)
		})

		Convey("it should have record not found error if message or channel id doesn't exist in db", func() {
			cml := NewChannelMessageList()

			ch, err := cml.IsInChannel(1091, 1092)
			So(err, ShouldBeNil)
			So(ch, ShouldEqual, false)
		})

		Convey("it should return false if message is not in the channel", func() {
			// create account as troll
			accTroll := createAccountWithTest()

			// create channel
			c := createNewChannelWithTest()
			c.CreatorId = accTroll.Id
			So(c.Create(), ShouldBeNil)

			// create message
			msg := createMessageWithTest()
			msg.AccountId = accTroll.Id
			So(msg.Create(), ShouldBeNil)

			// we created messsage
			// but didn't add it to the channel
			cml := NewChannelMessageList()
			cml.ChannelId = c.Id
			cml.MessageId = msg.Id

			ch, errr := cml.IsInChannel(cml.MessageId, cml.ChannelId)
			So(errr, ShouldBeNil)
			So(ch, ShouldEqual, false)
		})

		Convey("it should return true if message is in the channel", func() {
			// create account as troll
			acc := createAccountWithTest()

			// create channel
			c := createNewChannelWithTest()
			c.CreatorId = acc.Id
			So(c.Create(), ShouldBeNil)

			// create message
			msg := createMessageWithTest()
			msg.AccountId = acc.Id
			So(msg.Create(), ShouldBeNil)

			_, err := c.AddMessage(msg.Id)
			So(err, ShouldBeNil)

			cml := NewChannelMessageList()
			cml.ChannelId = c.Id
			cml.MessageId = msg.Id

			ch, errr := cml.IsInChannel(cml.MessageId, cml.ChannelId)
			So(errr, ShouldBeNil)
			So(ch, ShouldEqual, true)
		})
	})
}

func TestChannelMessageListFetchMessageChannelIds(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("while fetching message channel ids", t, func() {
		Convey("it should have message id otherwise error occurs", func() {
			cml := NewChannelMessageList()

			fm, err := cml.FetchMessageChannelIds(0)
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrMessageIdIsNotSet)
			So(fm, ShouldEqual, nil)
		})

		// Convey("it should ", func() {
		// 	cml := NewChannelMessageList()
		// 	cml.MessageId = 1982

		// 	fm, err := cml.FetchMessageChannelIds(cml.MessageId)
		// 	// So(err, ShouldNotBeNil)
		// 	So(err, ShouldEqual, bongo.RecordNotFound)
		// 	So(fm, ShouldEqual, nil)
		// })
	})
}
