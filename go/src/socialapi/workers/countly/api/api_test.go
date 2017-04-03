package api

import (
	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/common/tests"
	"testing"

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
