package main

import (
	"fmt"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestNewStorage(t *testing.T) {
	newStorage = &NewRedisStorage{Client: controller.Redis.Client}

	Convey("Given key", t, func() {
		var key, subkey = "testmetric", "limit"
		var score, newScore float64 = 1, 2

		Convey("Then it should save key", func() {
			err := newStorage.Upsert(key, subkey, score)
			So(err, ShouldBeNil)

			fetchedScore, err := newStorage.Get(key, subkey)
			So(err, ShouldBeNil)

			So(score, ShouldEqual, fetchedScore)

			err = newStorage.Upsert(key, subkey, newScore)
			So(err, ShouldBeNil)

			fetchedScore, err = newStorage.Get(key, subkey)
			So(err, ShouldBeNil)

			So(fetchedScore, ShouldEqual, score)

			Reset(func() {
				controller.Redis.Client.Del(key)
			})
		})
	})

	Convey("Given key", t, func() {
		key, subkey, members := "metric", "exempt", []interface{}{"indianajones"}

		Convey("Then it should check for existence", func() {
			yes, err := newStorage.Exists(key, subkey, members[0].(string))
			So(err, ShouldBeNil)

			So(yes, ShouldBeFalse)

			Reset(func() {
				controller.Redis.Client.Del(key)
			})
		})

		Convey("Then it should save", func() {
			err := newStorage.Save(key, subkey, members)
			So(err, ShouldBeNil)

			Convey("Then it should check for existence", func() {
				yes, err := newStorage.Exists(key, subkey, members[0].(string))
				So(err, ShouldBeNil)

				So(yes, ShouldBeTrue)
			})

			Convey("Then it should pop", func() {
				poppedMember, err := newStorage.Pop(key, subkey)
				So(err, ShouldBeNil)

				So(poppedMember, ShouldEqual, members[0].(string))
			})

			Reset(func() {
				controller.Redis.Client.Del(key)
			})
		})
	})

	Convey("Given key and score", t, func() {
		Convey("Then it should save even if key exists", func() {
			var key, member = "metric", "newstorage"
			var score float64 = 1

			err := newStorage.SaveScore(key, member, score)
			So(err, ShouldBeNil)

			Convey("Then it should return score", func() {
				fetchedScore, err := newStorage.GetScore(key, member)
				So(err, ShouldBeNil)

				So(fetchedScore, ShouldEqual, score)
			})

			Convey("Then it should get from score", func() {
				scores := []float64{1, 2, 3}

				for index, score := range scores {
					member := fmt.Sprintf("score.%d", index)

					err := newStorage.SaveScore(key, member, score)
					So(err, ShouldBeNil)
				}

				scoreMembers, err := newStorage.GetFromScore(key, 2)
				So(err, ShouldBeNil)

				So(len(scoreMembers), ShouldEqual, 2)
			})

			Reset(func() {
				controller.Redis.Client.Del(key)
			})
		})
	})
}
