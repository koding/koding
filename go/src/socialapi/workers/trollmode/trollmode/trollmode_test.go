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

	"github.com/koding/bongo"
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

		// create troll user
		trollUser := models.NewAccount()
		trollUser.OldId = bson.NewObjectId().Hex()
		trollUser, err := rest.CreateAccount(trollUser)
		tests.ResultedWithNoErrorCheck(trollUser, err)
		trollUser.IsTroll = true

		// create normal user
		normalUser := models.NewAccount()
		normalUser.OldId = bson.NewObjectId().Hex()
		normalUser, err = rest.CreateAccount(normalUser)
		tests.ResultedWithNoErrorCheck(normalUser, err)

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

		/////////////////////////  marking all content ////////////////////////
		// mark channel
		Convey("private channels of a troll should be marked as exempt", func() {
			// fetch from api, because we need to test system from there
			privatemessageChannelId1, err := createPrivateMessageChannel(trollUser.Id, groupName)
			So(err, ShouldBeNil)
			So(privatemessageChannelId1, ShouldBeGreaterThan, 0)

			privatemessageChannelId2, err := createPrivateMessageChannel(trollUser.Id, groupName)
			So(err, ShouldBeNil)
			So(privatemessageChannelId2, ShouldBeGreaterThan, 0)

			So(controller.markChannels(trollUser), ShouldBeNil)

			// fetch channel from db
			c1 := models.NewChannel()
			err = c1.ById(privatemessageChannelId1)
			So(err, ShouldBeNil)
			So(c1.Id, ShouldEqual, privatemessageChannelId1)
			// check here
			So(c1.MetaBits.IsTroll(), ShouldBeTrue)

			// fetch channel from db
			c2 := models.NewChannel()
			err = c2.ById(privatemessageChannelId2)
			So(err, ShouldBeNil)
			So(c2.Id, ShouldEqual, privatemessageChannelId2)

			// check here
			So(c2.MetaBits.IsTroll(), ShouldBeTrue)
		})

		})

	})
}
