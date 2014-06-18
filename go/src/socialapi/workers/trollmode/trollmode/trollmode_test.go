package trollmode

import (
	"math"
	"math/rand"
	"socialapi/models"
	"socialapi/rest"
	"socialapi/workers/common/runner"
	"socialapi/workers/common/tests"
	"strconv"
	"testing"
	"time"
	. "github.com/smartystreets/goconvey/convey"
	"labix.org/v2/mgo/bson"
)

func TestMarkedAsTroll(t *testing.T) {
	r := runner.New("TrollMode-Test")
	err := r.Init()
	if err != nil {
		panic(err)
	}

	defer r.Close()
	// disable logs
	// r.Log.SetLevel(logging.CRITICAL)

	Convey("given a controller", t, func() {

		// cretae admin user
		adminUser := models.NewAccount()
		adminUser.OldId = bson.NewObjectId().Hex()
		adminUser, err = rest.CreateAccount(adminUser)
		tests.ResultedWithNoErrorCheck(adminUser, err)

		// create groupName
		rand.Seed(time.Now().UnixNano())
		groupName := "testgroup" + strconv.FormatInt(rand.Int63(), 10)
		groupChannel, err := rest.CreateChannelByGroupNameAndType(
			adminUser.Id,
			groupName,
			models.Channel_TYPE_GROUP,
		)

		controller := NewController(r.Log)

		Convey("err should be nil", func() {
			So(err, ShouldBeNil)
		})

		Convey("controller should be set", func() {
			So(controller, ShouldNotBeNil)
		})

		Convey("should return nil when given nil account", func() {
			So(controller.MarkedAsTroll(nil), ShouldBeNil)
		})

		Convey("should return nil when account id given 0", func() {
			So(controller.MarkedAsTroll(models.NewAccount()), ShouldBeNil)
		})

		Convey("non existing account should not give error", func() {
			a := models.NewAccount()
			a.Id = math.MaxInt64
			So(controller.MarkedAsTroll(a), ShouldBeNil)
		})

		Convey("non existing account should not give error", func() {
			a := models.NewAccount()
			a.Id = math.MaxInt64
			So(controller.MarkedAsTroll(a), ShouldBeNil)
		})

		Convey("messages of a troll should be processed without any error", func() {
			trollUser := models.NewAccount()
			trollUser.OldId = bson.NewObjectId().Hex()
			trollUser, err := rest.CreateAccount(trollUser)
			tests.ResultedWithNoErrorCheck(trollUser, err)

			post, err := rest.CreatePost(groupChannel.Id, trollUser.Id)
			tests.ResultedWithNoErrorCheck(post, err)

			post, err = rest.CreatePost(groupChannel.Id, trollUser.Id)
			tests.ResultedWithNoErrorCheck(post, err)
		})

	})
}
