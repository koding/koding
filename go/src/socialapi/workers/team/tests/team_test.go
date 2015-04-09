package tests

import (
	"math/rand"
	"socialapi/config"
	"socialapi/models"
	"testing"
	"time"

	"github.com/koding/runner"

	. "github.com/smartystreets/goconvey/convey"
)

func TestTeam(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	appConfig := config.MustRead(r.Conf.Path)
	rand.Seed(time.Now().UTC().UnixNano())
	Convey("While creating a link to a channel", t, func() {
		// create admin
		admin, err := models.CreateAccountInBothDbsWithNick("sinan")
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

		// fetch admin's session
		ses, err := models.FetchOrCreateSession(admin.Nick)
		So(err, ShouldBeNil)
		So(ses, ShouldNotBeNil)
	})
}
