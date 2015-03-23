package tests

import (
	"koding/db/mongodb/modelhelper"
	"math/rand"
	"socialapi/models"
	"socialapi/request"
	"socialapi/rest"
	"socialapi/workers/common/runner"
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"
)

func TestModeration(t *testing.T) {
	r := runner.New("test-moderation")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	rand.Seed(time.Now().UTC().UnixNano())
	modelhelper.Initialize(r.Conf.Mongo)
	defer modelhelper.Close()

	Convey("While creating a link to a channel", t, func() {
		// create admin
		admin, err := models.CreateAccountInBothDbs()
		So(err, ShouldBeNil)
		So(admin, ShouldNotBeNil)

		// create another account
		acc2, err := models.CreateAccountInBothDbs()
		So(err, ShouldBeNil)
		So(acc2, ShouldNotBeNil)

		groupName := models.RandomName()

		// create root channel with second acc
		root := models.CreateTypedGroupedChannelWithTest(acc2.Id, models.Channel_TYPE_TOPIC, groupName)
		So(root, ShouldNotBeNil)

		// create leaf channel with second acc
		leaf := models.CreateTypedGroupedChannelWithTest(acc2.Id, models.Channel_TYPE_TOPIC, groupName)
		So(leaf, ShouldNotBeNil)

		// create leaf2 channel with second acc
		leaf2 := models.CreateTypedGroupedChannelWithTest(acc2.Id, models.Channel_TYPE_TOPIC, groupName)
		So(leaf2, ShouldNotBeNil)

		// fetch admin's session
		ses, err := models.FetchOrCreateSession(admin.Nick)
		So(err, ShouldBeNil)
		So(ses, ShouldNotBeNil)

		Convey("We should be able to create it first", func() {
			res, err := rest.CreateLink(root.Id, leaf.Id, ses.ClientId)
			So(err, ShouldBeNil)
			So(res, ShouldNotBeNil)

			Convey("We should get error if we try to create the same link again", func() {
				res, err := rest.CreateLink(root.Id, leaf.Id, ses.ClientId)
				So(err, ShouldNotBeNil)
				So(res, ShouldBeNil)
			})

			Convey("We should not be able to list with non set root id", func() {
				links, err := rest.GetLinks(0, request.NewQuery(), ses.ClientId)
				So(err, ShouldNotBeNil)
				So(links, ShouldBeNil)
			})

			Convey("We should be able to list the linked channels", func() {
				res, err := rest.CreateLink(root.Id, leaf2.Id, ses.ClientId)
				So(err, ShouldBeNil)
				So(res, ShouldNotBeNil)

				links, err := rest.GetLinks(root.Id, request.NewQuery(), ses.ClientId)
				So(err, ShouldBeNil)
				So(links, ShouldNotBeNil)
				So(len(links), ShouldEqual, 2)
			})

			Convey("We should be able to unlink created link", func() {
				err = rest.UnLink(root.Id, leaf.Id, ses.ClientId)
				So(err, ShouldBeNil)
			})

			Convey("We should not be able to unlink with non-set root id", func() {
				err = rest.UnLink(0, rand.Int63(), ses.ClientId)
				So(err, ShouldNotBeNil)
			})

			Convey("We should not be able to unlink with non-set leaf id", func() {
				err = rest.UnLink(rand.Int63(), 0, ses.ClientId)
				So(err, ShouldNotBeNil)
			})

			Convey("We should not be able to unlink non existing leaf", func() {
				err = rest.UnLink(root.Id, rand.Int63(), ses.ClientId)
				So(err, ShouldNotBeNil)
			})

			Convey("We should not be able to unlink from non existing root", func() {
				err = rest.UnLink(rand.Int63(), leaf.Id, ses.ClientId)
				So(err, ShouldNotBeNil)
			})
		})

		Convey("We should be able to blacklist channel without any leaves", func() {
			So(rest.BlackList(root.Id, leaf.Id, ses.ClientId), ShouldBeNil)
		})

		Convey("We should not be able to blacklist channel with leaves", func() {
			res, err := rest.CreateLink(root.Id, leaf.Id, ses.ClientId)
			So(err, ShouldBeNil)
			So(res, ShouldNotBeNil)

			err = rest.BlackList(leaf.Id, root.Id, ses.ClientId)
			So(err, ShouldNotBeNil)
		})
	})
}
