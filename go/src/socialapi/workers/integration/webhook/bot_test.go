package webhook

import (
	"koding/db/mongodb/modelhelper"
	"math/rand"
	"socialapi/config"
	"socialapi/models"
	"testing"
	"time"

	"github.com/koding/bongo"
	"github.com/koding/logging"
	"github.com/koding/runner"
	. "github.com/smartystreets/goconvey/convey"
)

var (
	r *runner.Runner
)

func initialize(t *testing.T) {

	r = runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("something went wrong: %s", err)
	}

	appConfig := config.MustRead(r.Conf.Path)
	r.Log.SetLevel(logging.CRITICAL)

	modelhelper.Initialize(appConfig.Mongo)

	botAcc, err := models.CreateAccountInBothDbsWithNick("bot")
	if err != nil || botAcc == nil {
		t.Fatalf("could not create bot account: %s", err)
	}
}

func TestSendMessage(t *testing.T) {

	initialize(t)
	defer r.Close()
	defer modelhelper.Close()

	Convey("while testing bot", t, func() {

		bot, err := NewBot()
		So(err, ShouldBeNil)

		rand.Seed(time.Now().UTC().UnixNano())
		groupName := models.RandomName()

		channel := models.CreateTypedGroupedChannelWithTest(bot.account.Id, models.Channel_TYPE_TOPIC, groupName)

		Convey("bot should be able to create message", func() {
			message := &Message{}
			message.Body = "testmessage"
			message.ChannelId = channel.Id
			message.ChannelIntegrationId = 13
			err := bot.SendMessage(message)
			So(err, ShouldBeNil)

			m, err := channel.FetchLastMessage()
			So(err, ShouldBeNil)
			So(m, ShouldNotBeNil)
			So(m.Body, ShouldEqual, message.Body)
			So(m.InitialChannelId, ShouldEqual, message.ChannelId)
			So(m.AccountId, ShouldEqual, bot.account.Id)
			So(m.TypeConstant, ShouldEqual, models.ChannelMessage_TYPE_BOT)
			So(*(m.GetPayload("channelIntegrationId")), ShouldEqual, "13")

		})
	})
}

func TestFetchBotChannel(t *testing.T) {

	initialize(t)
	defer r.Close()
	defer modelhelper.Close()

	Convey("while testing bot", t, func() {
		bot, err := NewBot()
		So(err, ShouldBeNil)

		acc, err := models.CreateAccountInBothDbsWithNick("bot-" + models.RandomName())
		So(err, ShouldBeNil)
		So(acc, ShouldNotBeNil)

		groupName := "group-" + models.RandomName()
		Convey("we should be able to create bot channel for each user", func() {
			// make sure the bot channel for the user does not exist
			channel, err := bot.fetchBotChannel(acc, groupName)
			So(err, ShouldEqual, bongo.RecordNotFound)

			channel, err = bot.fetchOrCreateChannel(acc, groupName)
			So(err, ShouldBeNil)
			So(channel, ShouldNotBeNil)
			So(channel.TypeConstant, ShouldEqual, models.Channel_TYPE_BOT)
			So(channel.CreatorId, ShouldEqual, acc.Id)
		})

		Convey("we should be able to fetch bot channel when it is already created", func() {
			// make sure the channel already exists
			channel, err := bot.createBotChannel(acc, groupName)
			So(err, ShouldBeNil)
			So(channel, ShouldNotBeNil)
			So(channel.TypeConstant, ShouldEqual, models.Channel_TYPE_BOT)
			So(channel.CreatorId, ShouldEqual, acc.Id)

			testchannel, err := bot.fetchOrCreateChannel(acc, groupName)
			So(err, ShouldBeNil)
			So(testchannel, ShouldNotBeNil)
			So(testchannel.Id, ShouldEqual, channel.Id)
		})

		Convey("we should not be able to fetch bot channel for a user when they are not participant of the group", func() {

			groupChannel := models.CreateTypedChannelWithTest(bot.account.Id, models.Channel_TYPE_GROUP)
			_, err := bot.FetchBotChannel(acc.Nick, groupChannel.GroupName)
			So(err, ShouldEqual, ErrAccountIsNotParticipant)
		})

		Convey("we should not be able to fetch bot channel when the user or group does not exist", func() {
			_, err := bot.FetchBotChannel(models.RandomName(), groupName)
			So(err, ShouldEqual, ErrAccountNotFound)

			_, err = bot.FetchBotChannel(acc.Nick, groupName)
			So(err, ShouldEqual, ErrGroupNotFound)
		})

		Convey("we should be able to fetch bot channel for the user with given nickname when the user is participant of the group", func() {
			groupChannel := models.CreateTypedChannelWithTest(bot.account.Id, models.Channel_TYPE_GROUP)
			_, err := groupChannel.AddParticipant(acc.Id)
			So(err, ShouldBeNil)

			testchannel, err := bot.FetchBotChannel(acc.Nick, groupChannel.GroupName)
			So(err, ShouldBeNil)
			So(testchannel, ShouldNotBeNil)
			So(testchannel.CreatorId, ShouldEqual, acc.Id)
		})

	})
}
