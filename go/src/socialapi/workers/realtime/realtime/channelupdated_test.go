package realtime

import (
	"socialapi/config"
	"socialapi/models"
	"testing"
	"time"

	"github.com/koding/runner"

	"gopkg.in/mgo.v2/bson"

	. "github.com/smartystreets/goconvey/convey"
)

func TestChannelUpdatedCalculateUnreadItemCount(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	config.MustRead(r.Conf.Path)

	groupName := models.RandomGroupName()

	Convey("while testing unread count", t, func() {
		Convey("channel should be set", func() {
			cue := &channelUpdatedEvent{}
			unreadCount, err := cue.calculateUnreadItemCount()
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, models.ErrChannelIsNotSet)
			So(unreadCount, ShouldEqual, 0)
		})

		Convey("unread count for group channel can not be calculated", func() {
			c := models.NewChannel()
			c.TypeConstant = models.Channel_TYPE_GROUP
			cue := &channelUpdatedEvent{
				Channel: c,
			}
			unreadCount, err := cue.calculateUnreadItemCount()
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldContainSubstring, "not supported channel type for unread count calculation")
			So(unreadCount, ShouldEqual, 0)
		})

		Convey("unread count for following feed channel can not be calculated", func() {
			c := models.NewChannel()
			c.TypeConstant = models.Channel_TYPE_FOLLOWINGFEED
			cue := &channelUpdatedEvent{
				Channel: c,
			}
			unreadCount, err := cue.calculateUnreadItemCount()
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldContainSubstring, "not supported channel type for unread count calculation")
			So(unreadCount, ShouldEqual, 0)
		})

		Convey("unread count for followers feed channel can not be calculated", func() {
			c := models.NewChannel()
			c.TypeConstant = models.Channel_TYPE_FOLLOWERS
			cue := &channelUpdatedEvent{
				Channel: c,
			}
			unreadCount, err := cue.calculateUnreadItemCount()
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldContainSubstring, "not supported channel type for unread count calculation")
			So(unreadCount, ShouldEqual, 0)
		})

		Convey("unread count for default channel can not be calculated", func() {
			c := models.NewChannel()
			c.TypeConstant = models.Channel_TYPE_DEFAULT
			cue := &channelUpdatedEvent{
				Channel: c,
			}
			unreadCount, err := cue.calculateUnreadItemCount()
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldContainSubstring, "not supported channel type for unread count calculation")
			So(unreadCount, ShouldEqual, 0)
		})

		Convey("channel participant should be set", func() {
			c := models.NewChannel()
			c.TypeConstant = models.Channel_TYPE_TOPIC
			cue := &channelUpdatedEvent{
				Channel: c,
			}
			unreadCount, err := cue.calculateUnreadItemCount()
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, models.ErrChannelParticipantIsNotSet)
			So(unreadCount, ShouldEqual, 0)
		})

		SkipConvey("pinned message's unread count could be calculated", func() {
			// create an account
			account, err := createAccount()
			So(err, ShouldBeNil)
			So(account, ShouldNotBeNil)

			// create their pinned activity channel
			c, err := models.EnsurePinnedActivityChannel(account.Id, groupName)
			So(err, ShouldBeNil)
			So(c, ShouldNotBeNil)

			// fetch participant
			cp, err := c.FetchParticipant(account.Id)
			So(err, ShouldBeNil)
			So(cp, ShouldNotBeNil)

			// create message
			cm := models.NewChannelMessage()
			cm.AccountId = account.Id
			// this cahnnel should be group channel
			cm.InitialChannelId = c.Id
			cm.Body = "hello all from test"
			So(cm.Create(), ShouldBeNil)

			// add message to the list
			cml, err := c.AddMessage(cm)
			So(err, ShouldBeNil)
			So(cml, ShouldNotBeNil)

			cue := &channelUpdatedEvent{
				Channel:              c,
				ChannelParticipant:   cp,
				ParentChannelMessage: cm,
			}

			unreadCount, err := cue.calculateUnreadItemCount()
			So(err, ShouldBeNil)
			So(unreadCount, ShouldEqual, 0)

			// add replies to the message
			addRepliesToMessage(c.Id, account.Id, cm.Id)
			addRepliesToMessage(c.Id, account.Id, cm.Id)

			cue = &channelUpdatedEvent{
				Channel:              c,
				ChannelParticipant:   cp,
				ParentChannelMessage: cm,
			}

			unreadCount, err = cue.calculateUnreadItemCount()
			So(err, ShouldBeNil)
			So(unreadCount, ShouldEqual, 2)

			// glance message
			cml.Glance()
			//after glancing the message, unread count should be zero

			cue = &channelUpdatedEvent{
				Channel:              c,
				ChannelParticipant:   cp,
				ParentChannelMessage: cm,
			}

			unreadCount, err = cue.calculateUnreadItemCount()
			So(err, ShouldBeNil)
			So(unreadCount, ShouldEqual, 0)
		})

		Convey("private message's unread count could be calculated", func() {
			// create an account
			account, err := createAccount()
			So(err, ShouldBeNil)
			So(account, ShouldNotBeNil)

			// create private message channel
			c := models.NewPrivateMessageChannel(account.Id, groupName)
			So(c.Create(), ShouldBeNil)

			// add participant into channel
			cp, err := c.AddParticipant(account.Id)
			So(err, ShouldBeNil)
			So(cp, ShouldNotBeNil)

			// create message
			cm := models.NewChannelMessage()
			cm.AccountId = account.Id
			cm.InitialChannelId = c.Id
			cm.Body = "hello all from test"
			So(cm.Create(), ShouldBeNil)

			// add message to the list
			// but message is already added into channel
			cml, err := c.EnsureMessage(cm, false)
			So(err, ShouldBeNil)
			So(cml, ShouldNotBeNil)

			cue := &channelUpdatedEvent{
				Channel:              c,
				ChannelParticipant:   cp,
				ParentChannelMessage: cm,
			}

			// calculate unread count
			unreadCount, err := cue.calculateUnreadItemCount()
			So(err, ShouldBeNil)
			So(unreadCount, ShouldEqual, 1)

			cp.LastSeenAt = time.Now().UTC()
			So(cp.Update(), ShouldBeNil)

			// calculate unread count
			unreadCount, err = cue.calculateUnreadItemCount()
			So(err, ShouldBeNil)
			So(unreadCount, ShouldEqual, 0)
		})

		Convey("collaboration channel's unread count could be calculated", func() {
			// create an account
			account, err := createAccount()
			So(err, ShouldBeNil)
			So(account, ShouldNotBeNil)

			// create private message channel
			c := models.NewCollaborationChannel(account.Id, groupName)
			So(c.Create(), ShouldBeNil)

			// add participant into channel
			cp, err := c.AddParticipant(account.Id)
			So(err, ShouldBeNil)
			So(cp, ShouldNotBeNil)

			// create message
			cm := models.NewChannelMessage()
			cm.AccountId = account.Id
			cm.InitialChannelId = c.Id
			cm.Body = "hello all from test"
			So(cm.Create(), ShouldBeNil)

			// add message to the list
			cml, err := c.EnsureMessage(cm, false)
			So(err, ShouldBeNil)
			So(cml, ShouldNotBeNil)

			cue := &channelUpdatedEvent{
				Channel:              c,
				ChannelParticipant:   cp,
				ParentChannelMessage: cm,
			}

			// calculate unread count
			unreadCount, err := cue.calculateUnreadItemCount()
			So(err, ShouldBeNil)
			So(unreadCount, ShouldEqual, 1)

			cp.LastSeenAt = time.Now().UTC()
			So(cp.Update(), ShouldBeNil)

			// calculate unread count
			unreadCount, err = cue.calculateUnreadItemCount()
			So(err, ShouldBeNil)
			So(unreadCount, ShouldEqual, 0)
		})

		Convey("topic channel's unread count could be calculated", func() {
			// create an account
			account, err := createAccount()
			So(err, ShouldBeNil)
			So(account, ShouldNotBeNil)

			// create private message channel
			c, err := createTypedChannel(account.Id, groupName, models.Channel_TYPE_TOPIC)
			So(err, ShouldBeNil)
			So(c.Create(), ShouldBeNil)

			// add participant into channel
			cp, err := c.AddParticipant(account.Id)
			So(err, ShouldBeNil)
			So(cp, ShouldNotBeNil)

			// create message
			cm := models.NewChannelMessage()
			cm.AccountId = account.Id
			cm.InitialChannelId = c.Id
			cm.Body = "hello all from test"
			So(cm.Create(), ShouldBeNil)

			// add message to the list
			cml, err := c.AddMessage(cm)
			So(err, ShouldBeNil)
			So(cml, ShouldNotBeNil)

			cue := &channelUpdatedEvent{
				Channel:              c,
				ChannelParticipant:   cp,
				ParentChannelMessage: cm,
			}

			// calculate unread count
			unreadCount, err := cue.calculateUnreadItemCount()
			So(err, ShouldBeNil)
			So(unreadCount, ShouldEqual, 1)

			cp.LastSeenAt = time.Now().UTC()
			So(cp.Update(), ShouldBeNil)

			// calculate unread count
			unreadCount, err = cue.calculateUnreadItemCount()
			So(err, ShouldBeNil)
			So(unreadCount, ShouldEqual, 0)
		})

		Convey("announcement channel's unread count could be calculated", func() {
			// create an account
			account, err := createAccount()
			So(err, ShouldBeNil)
			So(account, ShouldNotBeNil)

			// create private message channel
			c, err := createTypedChannel(account.Id, groupName, models.Channel_TYPE_ANNOUNCEMENT)
			So(err, ShouldBeNil)
			So(c.Create(), ShouldBeNil)

			// add participant into channel
			cp, err := c.AddParticipant(account.Id)
			So(err, ShouldBeNil)
			So(cp, ShouldNotBeNil)

			// create message
			cm := models.NewChannelMessage()
			cm.AccountId = account.Id
			cm.InitialChannelId = c.Id
			cm.Body = "hello all from test"
			So(cm.Create(), ShouldBeNil)

			// add message to the list
			cml, err := c.EnsureMessage(cm, false)
			So(err, ShouldBeNil)
			So(cml, ShouldNotBeNil)

			cue := &channelUpdatedEvent{
				Channel:              c,
				ChannelParticipant:   cp,
				ParentChannelMessage: cm,
			}

			// calculate unread count
			unreadCount, err := cue.calculateUnreadItemCount()
			So(err, ShouldBeNil)
			So(unreadCount, ShouldEqual, 1)

			cp.LastSeenAt = time.Now().UTC()
			So(cp.Update(), ShouldBeNil)

			// calculate unread count
			unreadCount, err = cue.calculateUnreadItemCount()
			So(err, ShouldBeNil)
			So(unreadCount, ShouldEqual, 0)
		})
	})
}

func addRepliesToMessage(channelId, accountId, messageId int64) {
	// add replies to the message
	rply1 := models.NewChannelMessage()
	rply1.AccountId = accountId
	rply1.InitialChannelId = channelId
	rply1.TypeConstant = models.ChannelMessage_TYPE_REPLY
	rply1.Body = "hello reply all from test"
	So(rply1.Create(), ShouldBeNil)

	mr := models.NewMessageReply()
	mr.ReplyId = rply1.Id
	mr.MessageId = messageId
	So(mr.Create(), ShouldBeNil)
}

func createAccount() (*models.Account, error) {
	// create and account instance
	account := models.NewAccount()
	// create a fake mongo id
	oldId := bson.NewObjectId()
	// assign it to our test user
	account.OldId = oldId.Hex()
	account.Nick = oldId.Hex()
	if err := account.Create(); err != nil {
		return nil, err
	}

	return account, nil
}

func createTypedChannel(creatorId int64, groupName, typeConstant string) (*models.Channel, error) {
	// create and account instance
	channel := models.NewChannel()
	channel.CreatorId = creatorId
	channel.GroupName = groupName
	channel.TypeConstant = typeConstant

	if err := channel.Create(); err != nil {
		return nil, err
	}

	return channel, nil
}
