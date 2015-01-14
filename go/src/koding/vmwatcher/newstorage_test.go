package main

import (
	"fmt"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

var newStorage *NewRedisStorage

func TestNewStorage(t *testing.T) {
	var newStorage NewStorage
	newStorage = &NewRedisStorage{Client: controller.Redis.Client}

	key, member := "metric", "newstorage"

	Convey("Given key", t, func() {
		Convey("Then it should check for existence", func() {
			yes, err := newStorage.Exists(key, member)
			So(err, ShouldBeNil)

			So(yes, ShouldBeFalse)
		})

		Convey("Then it should save", func() {
			err := newStorage.Save(key, member)
			So(err, ShouldBeNil)

			Convey("Then it should check for existence", func() {
				yes, err := newStorage.Exists(key, member)
				So(err, ShouldBeNil)

				So(yes, ShouldBeTrue)
			})

			Convey("Then it should pop", func() {
				poppedMember, err := newStorage.Pop(key)
				So(err, ShouldBeNil)

				So(poppedMember, ShouldEqual, member)
			})
		})
	})

	Convey("Given key and score", t, func() {
		Convey("Then it should save even if key exists", func() {
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

			Convey("Then it should save only if key doesn't exist", func() {
				var newScore float64 = 2

				err := newStorage.UpsertScore(key, member, newScore)
				So(err, ShouldBeNil)

				fetchedScore, err := newStorage.GetScore(key, member)
				So(err, ShouldBeNil)

				So(fetchedScore, ShouldEqual, score)

				newMember := "newnewstorage"
				err = newStorage.UpsertScore(key, newMember, newScore)
				So(err, ShouldBeNil)

				fetchedScore, err = newStorage.GetScore(key, newMember)
				So(err, ShouldBeNil)

				So(fetchedScore, ShouldEqual, newScore)
			})
		})
	})
}
