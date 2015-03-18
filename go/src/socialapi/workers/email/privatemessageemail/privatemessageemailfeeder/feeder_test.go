package feeder

import (
	"socialapi/models"
	"socialapi/workers/common/runner"
	"socialapi/workers/email/privatemessageemail/common"
	"socialapi/workers/email/privatemessageemail/testhelper"
	"socialapi/workers/helper"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestNewMessageCreation(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldn't start bongo %s", err.Error())
	}
	defer r.Close()

	redisConf := r.Conf
	redisConn := helper.MustInitRedisConn(redisConf)
	defer redisConn.Close()

	controller := New(r.Log, redisConn)

	Convey("while adding a new message to queue", t, func() {
		channel, accounts := models.CreateChannelWithParticipants()
		// test
		isEligibleToNotify = func(accountId int64) (bool, int, error) {
			return true, 5, nil
		}

		Convey("do not add any future notifier if message type is not private message", func() {
			cm := models.CreateMessage(channel.Id, accounts[0].Id, models.ChannelMessage_TYPE_JOIN)
			cm.TypeConstant = models.ChannelMessage_TYPE_JOIN
			err := controller.AddMessageToQueue(cm)
			So(err, ShouldBeNil)

			length, err := redisConn.GetHashLength(common.AccountNextPeriodHashSetKey())
			So(err, ShouldBeNil)
			So(length, ShouldEqual, 0)
		})

		Convey("do not send any notification email if message sender is a troll user", func() {
			cm := models.CreateTrollMessage(channel.Id, accounts[0].Id, models.ChannelMessage_TYPE_PRIVATE_MESSAGE)
			err := controller.AddMessageToQueue(cm)
			So(err, ShouldBeNil)
			length, err := redisConn.GetHashLength(common.AccountNextPeriodHashSetKey())
			So(err, ShouldBeNil)
			So(length, ShouldEqual, 0)
		})

		Convey("do not send any notification email if user has disabled email notifications for private messages", func() {
			isEligibleToNotify = func(accountId int64) (bool, int, error) {
				return false, 0, nil
			}

			cm := models.CreateMessage(channel.Id, accounts[0].Id, models.ChannelMessage_TYPE_PRIVATE_MESSAGE)
			cm.TypeConstant = models.ChannelMessage_TYPE_PRIVATE_MESSAGE
			err := controller.AddMessageToQueue(cm)
			So(err, ShouldBeNil)

			length, err := redisConn.GetHashLength(common.AccountNextPeriodHashSetKey())
			So(err, ShouldBeNil)
			So(length, ShouldEqual, 0)
		})

		Convey("when a message is sent to a channel with 3 participants two of them must be notified", func() {
			cm := models.CreateMessage(channel.Id, accounts[0].Id, models.ChannelMessage_TYPE_PRIVATE_MESSAGE)
			cml := models.NewChannelMessageList()
			cml.ChannelId = channel.Id
			cml.MessageId = cm.Id
			err := cml.Create()
			So(err, ShouldBeNil)

			err = controller.AddMessageToQueue(cm)
			So(err, ShouldBeNil)

			length, err := redisConn.GetHashLength(common.AccountNextPeriodHashSetKey())
			So(err, ShouldBeNil)
			So(length, ShouldEqual, 2)

			period := common.GetNextMailPeriod(5)

			// for next period two accounts must be inserted to the queue
			length, err = redisConn.Scard(common.PeriodAccountSetKey(period))
			So(err, ShouldBeNil)
			So(length, ShouldEqual, 2)

			// since first account is message owner he is not notified
			length, err = redisConn.GetHashLength(common.AccountChannelHashSetKey(accounts[0].Id))
			So(err, ShouldBeNil)
			So(length, ShouldEqual, 0)

			// second and third users must be notified
			length, err = redisConn.GetHashLength(common.AccountChannelHashSetKey(accounts[1].Id))
			So(err, ShouldBeNil)
			So(length, ShouldEqual, 1)

			length, err = redisConn.GetHashLength(common.AccountChannelHashSetKey(accounts[2].Id))
			So(err, ShouldBeNil)
			So(length, ShouldEqual, 1)

			keys, err := redisConn.Keys(testhelper.AllAccountChannelHashSetKey())
			So(err, ShouldBeNil)
			So(len(keys), ShouldEqual, 2)

			Convey("when a channel is glanced by message receiver, delete that channel from user's pending notification channel list", func() {
				cp := models.NewChannelParticipant()
				cp.ChannelId = channel.Id
				cp.AccountId = accounts[1].Id

				err := controller.GlanceChannel(cp)
				So(err, ShouldBeNil)

				// account does not have any more pending notification channel
				length, err = redisConn.GetHashLength(common.AccountChannelHashSetKey(accounts[1].Id))
				So(err, ShouldBeNil)
				So(length, ShouldEqual, 0)

				// we are only waiting notification for a single account
				keys, err := redisConn.Keys(testhelper.AllAccountChannelHashSetKey())
				So(err, ShouldBeNil)
				So(len(keys), ShouldEqual, 1)

				// TODO add one more test here for checking the existence of AccountNextPeriod field
			})
		})

		Reset(func() {
			testhelper.ResetCache(redisConn)
		})

	})
}
