package emailnotifier

import (
	// "github.com/kr/pretty"
	"koding/db/models"
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
		// create account
		acc1, err := rest.CreateAccountInBothDbs()
		So(err, ShouldBeNil)

		// update email settings for account
		eFreq := models.EmailFrequency{
			Global:  true,
			Daily:   true,
			Comment: true,
		}
		modelhelper.UpdateEmailFrequency(acc1.OldId, eFreq)

		// fetch email settings
		// uc, err := emailnotifiermodels.FetchUserContact(acc1.Id)

		// create second account
		acc2, err := rest.CreateAccountInBothDbs()
		So(err, ShouldBeNil)

		acc3, err := rest.CreateAccountInBothDbs()
		So(err, ShouldBeNil)

		// create channel
		channel, err := rest.CreateChannel(acc1.Id)
		So(err, ShouldBeNil)

		// make post in channel by first account
		cm1, err := rest.CreatePost(channel.Id, acc1.Id)
		So(err, ShouldBeNil)

		// add comment to post by second account
		_, err = rest.AddReply(cm1.Id, acc2.Id, channel.Id)
		So(err, ShouldBeNil)

		_, err = rest.AddReply(cm1.Id, acc3.Id, channel.Id)
		So(err, ShouldBeNil)

		// sleep to wait for notification worker to its thing
		time.Sleep(200 * time.Millisecond)

		// nr, err := rest.GetNotificationList(acc1.Id)
		// pretty.Println(nr, err)

		key := prepareSetterCacheKey(acc1.Id)
		activityIds, err := redisConn.GetSetMembers(key)
		So(err, ShouldBeNil)

		Convey("it should save user activity in redis", func() {
			So(len(activityIds), ShouldEqual, 2)
		})
	})
}
