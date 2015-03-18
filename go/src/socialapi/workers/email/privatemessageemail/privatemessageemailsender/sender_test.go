package sender

import (
	"socialapi/workers/common/runner"
	"socialapi/workers/email/privatemessageemail/common"
	"socialapi/workers/email/privatemessageemail/testhelper"
	"socialapi/workers/helper"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestChatEmailSender(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldn't start bongo %s", err.Error())
	}
	defer r.Close()

	redisConf := r.Conf
	redisConn := helper.MustInitRedisConn(redisConf)
	defer redisConn.Close()

	controller, _ := New(redisConn, r.Log, r.Metrics)

	Convey("while fetching a message from pending notification queue", t, func() {
		testPeriod := "1"
		accountId := "12"
		channelId := "5938384687973007478"
		awaySince := "1257894000000000000"
		err := redisConn.HashMultipleSet(
			common.AccountNextPeriodHashSetKey(),
			map[string]interface{}{accountId: testPeriod},
		)
		So(err, ShouldBeNil)

		_, err = redisConn.AddSetMembers(common.PeriodAccountSetKey(testPeriod), accountId)
		So(err, ShouldBeNil)

		err = redisConn.HashMultipleSet(
			common.AccountChannelHashSetKey(12),
			map[string]interface{}{channelId: awaySince},
		)
		So(err, ShouldBeNil)

		Convey("should be able to get next account from set", func() {
			account, err := controller.NextAccount(testPeriod)
			So(err, ShouldBeNil)
			So(account.Id, ShouldEqual, 12)

			length, err := redisConn.Scard(common.PeriodAccountSetKey(testPeriod))
			So(err, ShouldBeNil)
			So(length, ShouldEqual, 0)

			length, err = redisConn.GetHashLength(common.AccountNextPeriodHashSetKey())
			So(err, ShouldBeNil)
			So(length, ShouldEqual, 0)
		})
		Reset(func() {
			testhelper.ResetCache(redisConn)
		})
	})

}
