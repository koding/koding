package popularpost

import (
	"fmt"
	"testing"
	"time"

	"koding/db/mongodb/modelhelper"
	"socialapi/models"
	"socialapi/rest"
	"socialapi/workers/common/runner"
	"socialapi/workers/helper"

	"github.com/jinzhu/now"
	"github.com/koding/bongo"
	. "github.com/smartystreets/goconvey/convey"
)

func updateCreatedAt(id int64, ti time.Time) error {
	msg := models.NewChannelMessage()
	updateSql := fmt.Sprintf("UPDATE %s SET created_at=? WHERE id=?", msg.TableName())

	return bongo.B.DB.Exec(updateSql, ti, id).Error
}

func TestPopularPost(t *testing.T) {
	r := runner.New("popularpost")
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

	Convey("Given group, channelname and time to keyname", t, func() {
		keyname := &KeyName{
			GroupName: "koding", ChannelName: "public",
			Time: time.Now(),
		}

		today := now.New(time.Now().UTC()).BeginningOfDay()
		checkKey := fmt.Sprintf("%s:koding:popularpost:public:%d",
			r.Conf.Environment, today.Unix(),
		)

		Convey("Then it should generate daily key", func() {
			So(keyname.Today(), ShouldEqual, checkKey)
		})

		Convey("Then it should generate weekly key", func() {
			sevenDaysAgo := getDaysAgo(today, 7).UTC().Unix()
			checkKey = fmt.Sprintf("%s-%d", checkKey, sevenDaysAgo)

			So(keyname.Weekly(), ShouldEqual, checkKey)
		})
	})

	Convey("Given a post", t, func() {
		account, err := rest.CreateAccountInBothDbs()
		So(err, ShouldBeNil)

		c, err := rest.CreateChannel(account.Id)
		So(err, ShouldBeNil)

		cm, err := rest.CreatePost(c.Id, account.Id)
		So(err, ShouldBeNil)

		Convey("When an interaction arrives", func() {
			i, err := rest.AddInteraction("like", cm.Id, account.Id)
			So(err, ShouldBeNil)

			err = controller.InteractionSaved(i)
			So(err, ShouldBeNil)

			Convey("Then interaction is saved in daily bucket", func() {
				keyname := &KeyName{
					GroupName: c.GroupName, ChannelName: c.Name,
					Time: cm.CreatedAt,
				}
				key := keyname.Today()

				// check if key exists
				exists := controller.redis.Exists(key)
				So(exists, ShouldEqual, true)

				// check for scores
				score, err := controller.redis.SortedSetScore(key, cm.Id)
				So(err, ShouldBeNil)
				So(score, ShouldEqual, 1)

				controller.redis.Del(key)
			})

			Convey("Then interaction is saved in 7day bucket", func() {
				keyname := &KeyName{
					GroupName: c.GroupName, ChannelName: c.Name,
					Time: cm.CreatedAt,
				}
				key := keyname.Weekly()

				// check if key exists
				exists := controller.redis.Exists(key)
				So(exists, ShouldEqual, true)

				// check for scores
				score, err := controller.redis.SortedSetScore(key, cm.Id)
				So(err, ShouldBeNil)
				So(score, ShouldEqual, 1)

				controller.redis.Del(key)
			})
		})
	})

	Convey("Given two posts created on same day", t, func() {
		account, err := rest.CreateAccountInBothDbs()
		So(err, ShouldBeNil)

		c, err := rest.CreateChannel(account.Id)
		So(err, ShouldBeNil)

		cm, err := rest.CreatePost(c.Id, account.Id)
		So(err, ShouldBeNil)

		acc2, err := rest.CreateAccountInBothDbs()
		So(err, ShouldBeNil)

		post2, err := rest.CreatePost(c.Id, account.Id)
		So(err, ShouldBeNil)

		Convey("When interactions arrive", func() {
			// create 2 likes for post 1
			i, err := rest.AddInteraction("like", cm.Id, account.Id)
			So(err, ShouldBeNil)

			err = controller.InteractionSaved(i)
			So(err, ShouldBeNil)

			i, err = rest.AddInteraction("like", cm.Id, acc2.Id)
			So(err, ShouldBeNil)

			err = controller.InteractionSaved(i)
			So(err, ShouldBeNil)

			// create 1 likes for post 1
			i, err = rest.AddInteraction("like", post2.Id, account.Id)
			So(err, ShouldBeNil)

			err = controller.InteractionSaved(i)
			So(err, ShouldBeNil)

			Convey("Post with more interactions has higher score", func() {
				// check if key exists
				keyname := &KeyName{
					GroupName: c.GroupName, ChannelName: c.Name,
					Time: cm.CreatedAt,
				}
				key := keyname.Weekly()

				exists := controller.redis.Exists(key)
				So(exists, ShouldEqual, true)

				// check for scores
				score, err := controller.redis.SortedSetScore(key, cm.Id)
				So(err, ShouldBeNil)
				So(score, ShouldEqual, 2)

				score, err = controller.redis.SortedSetScore(key, post2.Id)
				So(err, ShouldBeNil)
				So(score, ShouldEqual, 1)

				controller.redis.Del(key)
			})
		})
	})

	Convey("Given two posts created on different days", t, func() {
		account, err := rest.CreateAccountInBothDbs()
		So(err, ShouldBeNil)

		c, err := rest.CreateChannel(account.Id)
		So(err, ShouldBeNil)

		// initialize key
		keyname := &KeyName{
			GroupName: c.GroupName, ChannelName: c.Name,
			Time: time.Now().UTC(),
		}
		key := keyname.Weekly()

		// create post with interaction today
		todayPost, err := rest.CreatePost(c.Id, account.Id)
		So(err, ShouldBeNil)

		// create post with interaction yesterday
		yesterdayPost, err := rest.CreatePost(c.Id, account.Id)
		So(err, ShouldBeNil)

		// update post to have yesterday's time
		yesterdayTime := now.BeginningOfDay().Add(-24 * time.Hour)
		updateCreatedAt(yesterdayPost.Id, yesterdayTime)

		// create post with interaction two days ago
		twoDaysAgo, err := rest.CreatePost(c.Id, account.Id)
		So(err, ShouldBeNil)

		// update post to have two days ago time
		twoDaysAgoTime := now.BeginningOfDay().Add(-48 * time.Hour)
		updateCreatedAt(twoDaysAgo.Id, twoDaysAgoTime)

		Convey("When interactions arrive for those posts", func() {
			i, err := rest.AddInteraction("like", todayPost.Id, account.Id)
			So(err, ShouldBeNil)

			err = controller.InteractionSaved(i)
			So(err, ShouldBeNil)

			i, err = rest.AddInteraction("like", yesterdayPost.Id, account.Id)
			So(err, ShouldBeNil)

			err = controller.InteractionSaved(i)
			So(err, ShouldBeNil)

			i, err = rest.AddInteraction("like", twoDaysAgo.Id, account.Id)
			So(err, ShouldBeNil)

			err = controller.InteractionSaved(i)
			So(err, ShouldBeNil)

			Convey("Posts with interactions today has higher score", func() {
				// check if key exists
				exists := controller.redis.Exists(key)
				So(exists, ShouldEqual, true)

				// check for scores
				checkForScores := map[int64]float64{
					todayPost.Id:     1,
					yesterdayPost.Id: 0.5,
					twoDaysAgo.Id:    0.3,
				}

				for id, num := range checkForScores {
					score, err := controller.redis.SortedSetScore(key, id)
					So(err, ShouldBeNil)
					So(score, ShouldEqual, num)
				}
			})
		})
	})
}
