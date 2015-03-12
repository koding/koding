package topic

import (
	"koding/db/mongodb/modelhelper"
	"math"
	"socialapi/models"
	"socialapi/workers/common/runner"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestUnlink(t *testing.T) {
	r := runner.New("test-moderation-unlink")
	err := r.Init()
	if err != nil {
		panic(err)
	}

	defer r.Close()

	modelhelper.Initialize(r.Conf.Mongo)
	defer modelhelper.Close()

	CreatePrivateMessageUser()

	Convey("given a controller", t, func() {

		controller := NewController(r.Log)

		Convey("err should be nil", func() {
			So(err, ShouldBeNil)
		})

		Convey("controller should be set", func() {
			So(controller, ShouldNotBeNil)
		})

		Convey("should return nil when given nil channel link request", func() {
			So(controller.UnLink(nil), ShouldBeNil)
		})

		Convey("should return nil when account id given 0", func() {
			So(controller.UnLink(models.NewChannelLink()), ShouldBeNil)
		})

		Convey("non existing account should not give error", func() {
			a := models.NewChannelLink()
			a.Id = math.MaxInt64
			So(controller.UnLink(a), ShouldBeNil)
		})
	})
}
