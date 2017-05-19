package api

import (
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/common/tests"
	"socialapi/workers/countly/client"
	"testing"

	"github.com/koding/runner"
	. "github.com/smartystreets/goconvey/convey"
)

func TestCreateUser(t *testing.T) {
	tests.WithConfiguration(t, func(c *config.Config) {
		capi := NewCountlyAPI(c)
		Convey("Given Countly API", t, func() {

			Convey("We should be able create user", func() {
				slug := models.RandomGroupName()
				user, err := capi.EnsureUser(slug, "appID")
				So(err, ShouldBeNil)
				So(user.APIKey, ShouldNotBeEmpty)

				user2, err := capi.EnsureUser(slug, "appID")
				So(err, ShouldBeNil)
				So(user2.APIKey, ShouldNotBeEmpty)
				So(user2.APIKey, ShouldEqual, user.APIKey)
				So(user2.ID, ShouldEqual, user.ID)
			})
		})
	})
}

func TestPublish(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		capi := NewCountlyAPI(config.MustGet())
		Convey("Given Countly API", t, func() {
			models.WithStubData(func(username, slug, sessionID string) {
				Convey("We should be able publish a metric", func() {
					metric := client.Event{
						Key:          "event.Name",
						Count:        1,
						Segmentation: nil,
					}

					So(capi.Publish(slug, metric), ShouldBeNil)

					groupData := &mongomodels.GroupData{}
					err := modelhelper.GetGroupData(slug, groupData)
					So(err, ShouldBeNil)

					appKey, err := groupData.Payload.GetString("countly.appKey")
					So(err, ShouldBeNil)
					So(appKey, ShouldNotBeEmpty)
				})
			})
		})
	})
}
