package popularpost

import (
	"testing"

	"koding/db/mongodb/modelhelper"
	// "socialapi/models"
	"socialapi/rest"
	"socialapi/workers/common/runner"
	"socialapi/workers/helper"

	//"github.com/kr/pretty"
	. "github.com/smartystreets/goconvey/convey"
)

func TestPopularPost(t *testing.T) {
	r := runner.New("popular post")
	if err := r.Init(); err != nil {
		panic(err)
	}
	defer r.Close()

	// initialize mongo
	modelhelper.Initialize(r.Conf.Mongo)

	// initialize redis
	helper.MustGetRedisConn()

	// initialize popular post controller
	controller := New(r.Log, helper.MustInitRedisConn(r.Conf))

	Convey("When an interaction arrives", t, func() {
		account, err := rest.CreateAccountInBothDbs()
		So(err, ShouldEqual, nil)

		c, err := rest.CreateChannel(account.Id)
		So(err, ShouldEqual, nil)

		cm, err := rest.CreatePost(c.Id, account.Id)
		So(err, ShouldEqual, nil)

		i, err := rest.AddInteraction("like", cm.Id, account.Id)
		So(err, ShouldEqual, nil)

		err = controller.InteractionSaved(i)
		So(err, ShouldEqual, nil)

		Convey("Interaction is saved in daily bucket", func() {
			dailyKey := GetDailyKey(c, cm.CreatedAt)
			exists := controller.redis.Exists(dailyKey)

			So(exists, ShouldEqual, true)

			controller.redis.Del(dailyKey)
		})

		Convey("Interaction is saved in 7day bucket", func() {
			sevenDayKey := GetSevenDayKey(c, cm)
			exists := controller.redis.Exists(sevenDayKey)

			So(exists, ShouldEqual, true)

			controller.redis.Del(sevenDayKey)
		})
	})
}
