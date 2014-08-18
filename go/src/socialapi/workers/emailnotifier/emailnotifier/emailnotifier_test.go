package emailnotifier

import (
	// "github.com/kr/pretty"
	"koding/db/mongodb/modelhelper"
	"socialapi/rest"
	"socialapi/workers/common/runner"
	"socialapi/workers/helper"
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"
)

func TestSaveDailyDigestNotification(t *testing.T) {
	r := runner.New("email notification")
	if err := r.Init(); err != nil {
		panic(err)
	}
	defer r.Close()

	// initialize mongo
	modelhelper.Initialize(r.Conf.Mongo)

	// initialize redis
	redisConn := helper.MustGetRedisConn()

	Convey("User replies to another user who has daily digests", t, func() {
		acc1, err := rest.CreateAccountWithDailyDigest()
		So(err, ShouldBeNil)

		acc2, err := rest.CreateAccountInBothDbs()
		So(err, ShouldBeNil)

		channel, err := rest.CreateChannel(acc1.Id)
		So(err, ShouldBeNil)

		cp := rest.NewCreatePost(channel.Id, acc1.Id, acc2.Id)
		_, err = cp.CreateReplies(2)
		So(err, ShouldBeNil)

		// sleep to wait for notification worker to its thing
		time.Sleep(200 * time.Millisecond)

		key := prepareSetterCacheKey(acc1.Id)
		activityIds, err := redisConn.GetSetMembers(key)
		So(err, ShouldBeNil)

		Convey("it should save user activity in redis", func() {
			So(len(activityIds), ShouldEqual, 2)
		})
	})
}
