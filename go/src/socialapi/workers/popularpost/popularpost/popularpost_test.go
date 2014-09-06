package popularpost

import (
	"testing"

	"koding/db/mongodb/modelhelper"
	"socialapi/rest"
	"socialapi/workers/common/runner"
	"socialapi/workers/helper"

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

	Convey("Popular post", t, func() {
		account, err := rest.CreateAccountInBothDbs()
		So(err, ShouldEqual, nil)

		c, err := rest.CreateChannel(account.Id)
		So(err, ShouldEqual, nil)

		cm, err := rest.CreatePost(c.Id, account.Id)
		So(err, ShouldEqual, nil)

		Convey("When an interaction arrives", func() {
			i, err := rest.AddInteraction("like", cm.Id, account.Id)
			So(err, ShouldEqual, nil)

			err = controller.InteractionSaved(i)
			So(err, ShouldEqual, nil)

			Convey("Interaction is saved in daily bucket", func() {
				keyname := &KeyName{
					GroupName: c.GroupName, ChannelName: c.Name,
					Time: cm.CreatedAt,
				}
				key := keyname.Today()

				exists := controller.redis.Exists(key)
				So(exists, ShouldEqual, true)

				score, err := controller.redis.SortedSetScore(key, cm.Id)
				So(err, ShouldEqual, nil)
				So(score, ShouldEqual, 1)

				controller.redis.Del(key)
			})

			Convey("Interaction is saved in 7day bucket", func() {
				keyname := &KeyName{
					GroupName: c.GroupName, ChannelName: c.Name,
					Time: cm.CreatedAt,
				}
				key := keyname.Weekly()

				exists := controller.redis.Exists(key)
				So(exists, ShouldEqual, true)

				score, err := controller.redis.SortedSetScore(key, cm.Id)
				So(err, ShouldEqual, nil)
				So(score, ShouldEqual, 1)

				controller.redis.Del(key)
			})
		})

		Convey("Posts with more interactions on same day have higher score", func() {
			acc2, err := rest.CreateAccountInBothDbs()
			So(err, ShouldEqual, nil)

			post2, err := rest.CreatePost(c.Id, account.Id)
			So(err, ShouldEqual, nil)

			// create 2 likes for post 1
			i, err := rest.AddInteraction("like", cm.Id, account.Id)
			So(err, ShouldEqual, nil)

			err = controller.InteractionSaved(i)
			So(err, ShouldEqual, nil)

			i, err = rest.AddInteraction("like", cm.Id, acc2.Id)
			So(err, ShouldEqual, nil)

			err = controller.InteractionSaved(i)
			So(err, ShouldEqual, nil)

			// create 1 likes for post 1
			i, err = rest.AddInteraction("like", post2.Id, account.Id)
			So(err, ShouldEqual, nil)

			err = controller.InteractionSaved(i)
			So(err, ShouldEqual, nil)

			keyname := &KeyName{
				GroupName: c.GroupName, ChannelName: c.Name,
				Time: cm.CreatedAt,
			}
			key := keyname.Weekly()

			exists := controller.redis.Exists(key)
			So(exists, ShouldEqual, true)

			score, err := controller.redis.SortedSetScore(key, cm.Id)
			So(err, ShouldEqual, nil)
			So(score, ShouldEqual, 2)

			score, err = controller.redis.SortedSetScore(key, post2.Id)
			So(err, ShouldEqual, nil)
			So(score, ShouldEqual, 1)

			controller.redis.Del(key)
		})
	})
}
