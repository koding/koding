package models

import (
	"socialapi/workers/common/tests"
	"testing"

	"github.com/koding/bongo"
	"github.com/koding/runner"

	. "github.com/smartystreets/goconvey/convey"
)

func TestChannelMessageListFetchMessageChannels(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("while fethcing channel message of a message", t, func() {
			Convey("channels should be valid", func() {
				acc := CreateAccountWithTest()
				c1 := CreateChannelWithTest(acc.Id)
				c2 := CreateChannelWithTest(acc.Id)
				c3 := CreateChannelWithTest(acc.Id)

				cm := NewChannelMessage()
				cm.Body = "gel beri abi"
				cm.AccountId = c1.CreatorId
				cm.InitialChannelId = c1.Id
				So(cm.Create(), ShouldBeNil)

				// add to first channel
				_, err := c1.EnsureMessage(cm, false)
				So(err, ShouldBeNil)

				// add to second channel
				_, err = c2.EnsureMessage(cm, false)
				So(err, ShouldBeNil)

				// add to 3rd channel
				_, err = c3.EnsureMessage(cm, false)
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
	})
}

func TestChannelMessageListCount(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
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
				cm := CreateMessageWithTest()
				So(cm.Create(), ShouldBeNil)

				acc := CreateAccountWithTest()
				c := CreateChannelWithTest(acc.Id)

				_, err := c.AddMessage(cm)
				So(err, ShouldBeNil)

				cml := NewChannelMessageList()
				cml.ChannelId = c.Id

				cnt, err := cml.Count(cml.ChannelId)
				So(err, ShouldBeNil)
				So(cnt, ShouldEqual, 1)
			})
		})
	})
}

func TestChannelMessageListisExempt(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("while testing is exempt", t, func() {
			Convey("it should have error if message id is not set ", func() {
				cml := NewChannelMessageList()

				is, err := cml.isExempt()
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, ErrMessageIdIsNotSet)
				So(is, ShouldEqual, false)
			})

			Convey("it should return false is channel is not exempt", func() {
				// create account as not troll
				acc := CreateAccountWithTest()
				acc.IsTroll = false

				c := CreateChannelWithTest(acc.Id)
				c.CreatorId = acc.Id

				// create message
				msg := CreateMessageWithTest()
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
	})
}

func TestChannelMessageListMarkIfExempt(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("while marking if channel is exempt", t, func() {
			Convey("it should have error if message id is not set", func() {
				cml := NewChannelMessageList()

				err := cml.MarkIfExempt()
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, ErrMessageIdIsNotSet)
			})
		})
	})
}

func TestChannelMessageListUpdateAddedAt(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
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

			Convey("it should not have error if update is done successfully", func() {
				acc := CreateAccountWithTest()
				c := CreateChannelWithTest(acc.Id)

				// create message
				msg := CreateMessageWithTest()
				msg.AccountId = acc.Id
				So(msg.Create(), ShouldBeNil)

				_, erro := c.AddMessage(msg)
				So(erro, ShouldBeNil)

				cml := NewChannelMessageList()
				cml.ChannelId = c.Id
				cml.MessageId = msg.Id

				err := cml.UpdateAddedAt(cml.ChannelId, cml.MessageId)
				So(err, ShouldBeNil)
			})
		})
	})
}

func TestChannelMessageListUnreadCount(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
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
		})
	})
}

func TestChannelMessageListIsInChannel(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
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
				accTroll := CreateAccountWithTest()

				// create channel
				c := CreateChannelWithTest(accTroll.Id)

				// create message
				msg := CreateMessageWithTest()
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
				acc := CreateAccountWithTest()

				// create channel
				c := CreateChannelWithTest(acc.Id)

				// create message
				msg := CreateMessageWithTest()
				msg.AccountId = acc.Id
				So(msg.Create(), ShouldBeNil)

				_, err := c.AddMessage(msg)
				So(err, ShouldBeNil)

				cml := NewChannelMessageList()
				cml.ChannelId = c.Id
				cml.MessageId = msg.Id

				ch, errr := cml.IsInChannel(cml.MessageId, cml.ChannelId)
				So(errr, ShouldBeNil)
				So(ch, ShouldEqual, true)
			})
		})
	})
}

func TestChannelMessageListFetchMessageChannelIds(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("while fetching message channel ids", t, func() {
			Convey("it should have message id", func() {
				cml := NewChannelMessageList()
				fm, err := cml.FetchMessageChannelIds(0)
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, ErrMessageIdIsNotSet)
				So(fm, ShouldEqual, nil)
			})

			Convey("if message doesnt belong to any channel", func() {
				m := CreateMessageWithTest()
				So(m.Create(), ShouldBeNil)

				cml := NewChannelMessageList()
				cml.MessageId = m.Id

				fm, err := cml.FetchMessageChannelIds(m.Id)
				So(err, ShouldBeNil)
				So(fm, ShouldBeNil)
			})
		})
	})
}
