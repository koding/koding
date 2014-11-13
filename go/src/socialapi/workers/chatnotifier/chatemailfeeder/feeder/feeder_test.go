package feeder

import (
	"fmt"
	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/chatnotifier/common"
	"socialapi/workers/common/runner"
	"socialapi/workers/helper"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func createChannelWithParticipants() (*models.Channel, []*models.Account) {
	account1 := models.CreateAccountWithTest()
	account2 := models.CreateAccountWithTest()
	account3 := models.CreateAccountWithTest()
	accounts := []*models.Account{account1, account2, account3}

	channel := createChannel(account1.Id)
	addParticipants(channel.Id, account1.Id, account2.Id, account3.Id)

	// createMessage(channel.Id, account.Id)

	return channel, accounts
}

func createChannel(accountId int64) *models.Channel {
	// create and account instance
	channel := models.NewChannel()
	channel.CreatorId = accountId

	err := channel.Create()
	So(err, ShouldBeNil)

	return channel
}

func createMessage(channelId, accountId int64, typeConstant string) *models.ChannelMessage {
	cm := models.NewChannelMessage()

	cm.AccountId = accountId
	// set channel id
	cm.InitialChannelId = channelId
	cm.TypeConstant = typeConstant
	// set body
	cm.Body = "e-mail notification test"

	err := cm.Create()
	So(err, ShouldBeNil)

	return cm
}

func addParticipants(channelId int64, accountIds ...int64) {

	for _, accountId := range accountIds {
		participant := models.NewChannelParticipant()
		participant.ChannelId = channelId
		participant.AccountId = accountId

		err := participant.Create()
		So(err, ShouldBeNil)
	}
}

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
		channel, accounts := createChannelWithParticipants()
		// test
		eligibleToNotify = func(accountId int64) (bool, error) {
			return true, nil
		}

		Convey("do not add any future notifier if message type is not private message", func() {
			cm := createMessage(channel.Id, accounts[0].Id, models.ChannelMessage_TYPE_JOIN)
			cm.TypeConstant = models.ChannelMessage_TYPE_JOIN
			err := controller.AddMessageToQueue(cm)
			So(err, ShouldBeNil)

			length, err := redisConn.GetHashLength(common.AccountNextPeriodHashSetKey())
			So(err, ShouldBeNil)
			So(length, ShouldEqual, 0)
		})

		Convey("do not send any notification email if user has disabled email notifications for private messages", func() {
			eligibleToNotify = func(accountId int64) (bool, error) {
				return false, nil
			}

			cm := createMessage(channel.Id, accounts[0].Id, models.ChannelMessage_TYPE_JOIN)
			cm.TypeConstant = models.ChannelMessage_TYPE_PRIVATE_MESSAGE
			err := controller.AddMessageToQueue(cm)
			So(err, ShouldBeNil)

			length, err := redisConn.GetHashLength(common.AccountNextPeriodHashSetKey())
			So(err, ShouldBeNil)
			So(length, ShouldEqual, 0)
		})

		Convey("when a message is sent to a channel with 3 participants two of them must be notified", func() {
			cm := createMessage(channel.Id, accounts[0].Id, models.ChannelMessage_TYPE_PRIVATE_MESSAGE)

			err := controller.AddMessageToQueue(cm)
			So(err, ShouldBeNil)

			length, err := redisConn.GetHashLength(common.AccountNextPeriodHashSetKey())
			So(err, ShouldBeNil)
			So(length, ShouldEqual, 2)

			period := controller.getNextMailPeriod()

			// for next period two accounts must be inserted to the queue
			length, err = redisConn.Scard(common.PeriodAccountSetKey(period))
			So(err, ShouldBeNil)
			So(length, ShouldEqual, 2)

			// since first account is message owner he is not notified
			length, err = redisConn.GetHashLength(common.AccountChannelHashSetKey(accounts[0].Id, period))
			So(err, ShouldBeNil)
			So(length, ShouldEqual, 0)

			// second and third users must be notified
			length, err = redisConn.GetHashLength(common.AccountChannelHashSetKey(accounts[1].Id, period))
			So(err, ShouldBeNil)
			So(length, ShouldEqual, 1)

			length, err = redisConn.GetHashLength(common.AccountChannelHashSetKey(accounts[2].Id, period))
			So(err, ShouldBeNil)
			So(length, ShouldEqual, 1)

			keys, err := redisConn.Keys(allAccountChannelHashSetKey())
			So(err, ShouldBeNil)
			So(len(keys), ShouldEqual, 2)

			Convey("when a channel is glanced by message receiver, delete that channel from user's pending notification channel list", func() {
				cp := models.NewChannelParticipant()
				cp.ChannelId = channel.Id
				cp.AccountId = accounts[1].Id

				err := controller.GlanceChannel(cp)
				So(err, ShouldBeNil)

				// account does not have any more pending notification channel
				length, err = redisConn.GetHashLength(common.AccountChannelHashSetKey(accounts[1].Id, period))
				So(err, ShouldBeNil)
				So(length, ShouldEqual, 0)

				// we are only waiting notification for a single account
				keys, err := redisConn.Keys(allAccountChannelHashSetKey())
				So(err, ShouldBeNil)
				So(len(keys), ShouldEqual, 1)
			})
		})

		deleteKeys := func(pattern string) {
			keys, _ := redisConn.Keys(pattern)

			for _, key := range keys {
				val, _ := redisConn.String(key)
				redisConn.Del(val)
			}
		}

		Reset(func() {
			redisConn.Del(common.AccountNextPeriodHashSetKey())
			deleteKeys(allPeriodAccountSetKey())
			deleteKeys(allAccountChannelHashSetKey())
		})

	})
}

func allAccountChannelHashSetKey() string {
	return fmt.Sprintf("%s:%s:%s:*",
		config.MustGet().Environment,
		common.CachePrefix,
		"account-channelhashset",
	)
}

func allPeriodAccountSetKey() string {
	return fmt.Sprintf("%s:%s:%s:*",
		config.MustGet().Environment,
		common.CachePrefix,
		"periodaccountset",
	)
}
