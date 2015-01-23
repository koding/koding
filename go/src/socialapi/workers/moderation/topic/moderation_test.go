package topic

import (
	"fmt"
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"math"
	"socialapi/models"
	"socialapi/workers/common/runner"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
	"labix.org/v2/mgo/bson"
)

func CreatePrivateMessageUser() {
	acc, err := modelhelper.GetAccount("sinan")
	if err == nil {
		return
	}

	if err != modelhelper.ErrNotFound {
		panic(err)
	}

	acc = new(mongomodels.Account)
	acc.Id = bson.NewObjectId()
	acc.Profile.Nickname = "sinan"

	modelhelper.CreateAccount(acc)
}

func TestCreateLink(t *testing.T) {
	r := runner.New("test-moderation-create-link")
	err := r.Init()
	if err != nil {
		panic(err)
	}

	defer r.Close()

	modelhelper.Initialize(r.Conf.Mongo)
	defer modelhelper.Close()

	CreatePrivateMessageUser()
	// disable logs
	// r.Log.SetLevel(logging.CRITICAL)

	Convey("given a controller", t, func() {

		controller := NewController(r.Log)

		Convey("err should be nil", func() {
			So(err, ShouldBeNil)
		})

		Convey("controller should be set", func() {
			So(controller, ShouldNotBeNil)
		})

		Convey("should return nil when given nil channel link request", func() {
			So(controller.CreateLink(nil), ShouldBeNil)
		})

		Convey("should return nil when account id given 0", func() {
			So(controller.CreateLink(models.NewChannelLink()), ShouldBeNil)
		})

		Convey("non existing account should not give error", func() {
			a := models.NewChannelLink()
			a.Id = math.MaxInt64
			So(controller.CreateLink(a), ShouldBeNil)
		})

		acc1 := models.CreateAccountWithTest()
		acc2 := models.CreateAccountWithTest()

		Convey("should process 0 participated channels with no messages", func() {
			cl := models.CreateChannelLinkWithTest(acc1.Id, acc2.Id)
			So(controller.CreateLink(cl), ShouldBeNil)

			Convey("leaf node should not have any participants", func() {
				cp := models.NewChannelParticipant()
				cp.ChannelId = cl.LeafId
				cpc, err := cp.FetchParticipantCount()

				So(err, ShouldBeNil)
				So(cpc, ShouldEqual, 0)

			})

			Convey("root node should have 0 participants", func() {
				cp := models.NewChannelParticipant()
				cp.ChannelId = cl.RootId
				cpc, err := cp.FetchParticipantCount()

				So(err, ShouldBeNil)
				So(cpc, ShouldEqual, 0)
			})
		})

		Convey("should process 0 participated channels with messages", func() {

			cl := models.CreateChannelLinkWithTest(acc1.Id, acc2.Id)

			// create a message to the regarding leaf channel
			models.CreateMessage(cl.LeafId, acc1.Id, models.ChannelMessage_TYPE_POST)
			models.CreateMessage(cl.LeafId, acc1.Id, models.ChannelMessage_TYPE_POST)
			models.CreateMessage(cl.LeafId, acc1.Id, models.ChannelMessage_TYPE_POST)

			So(controller.CreateLink(cl), ShouldBeNil)

			Convey("leaf node should not have any participants", func() {
				cp := models.NewChannelParticipant()
				cp.ChannelId = cl.LeafId
				cpc, err := cp.FetchParticipantCount()

				So(err, ShouldBeNil)
				So(cpc, ShouldEqual, 0)

			})

			Convey("root node should not have any participants", func() {
				cp := models.NewChannelParticipant()
				cp.ChannelId = cl.RootId
				cpc, err := cp.FetchParticipantCount()

				So(err, ShouldBeNil)
				So(cpc, ShouldEqual, 0)
			})
		})

		Convey("should process participated channels with no messages", func() {
			i := 0

			i++
			fmt.Println("-->", i)

			cl := models.CreateChannelLinkWithTest(acc1.Id, acc2.Id)
			// add participants with tests
			models.AddParticipants(cl.LeafId, acc1.Id, acc2.Id)

			cp := models.NewChannelParticipant()
			cp.ChannelId = cl.LeafId
			cpc, err := cp.FetchParticipantCount()
			So(err, ShouldBeNil)
			So(cpc, ShouldEqual, 2)

			// create the link
			So(controller.CreateLink(cl), ShouldBeNil)

			Convey("leaf node should not have any participants", func() {
				i++
				fmt.Println("-->", i)

				cp := models.NewChannelParticipant()
				cp.ChannelId = cl.LeafId
				cpc, err := cp.FetchParticipantCount()

				So(err, ShouldBeNil)
				So(cpc, ShouldEqual, 0)
			})

			Convey("root node should have 2 participants", func() {
				i++
				fmt.Println("-->", i)

				cp := models.NewChannelParticipant()
				cp.ChannelId = cl.RootId
				cpc, err := cp.FetchParticipantCount()

				So(err, ShouldBeNil)
				So(cpc, ShouldEqual, 2)
			})
		})

		Convey("should process participated channels with messages", func() {
			cl := models.CreateChannelLinkWithTest(acc1.Id, acc2.Id)
			// add participants with tests
			models.AddParticipants(cl.LeafId, acc1.Id, acc2.Id)

			// create messages to the regarding leaf channel
			models.CreateMessage(cl.LeafId, acc1.Id, models.ChannelMessage_TYPE_POST)
			models.CreateMessage(cl.LeafId, acc1.Id, models.ChannelMessage_TYPE_POST)
			models.CreateMessage(cl.LeafId, acc1.Id, models.ChannelMessage_TYPE_POST)

			So(controller.CreateLink(cl), ShouldBeNil)

			Convey("leaf node should not have any participants", func() {
				cp := models.NewChannelParticipant()
				cp.ChannelId = cl.LeafId
				cpc, err := cp.FetchParticipantCount()

				So(err, ShouldBeNil)
				So(cpc, ShouldEqual, 0)
			})

			Convey("root node should have 2 participants", func() {
				cp := models.NewChannelParticipant()
				cp.ChannelId = cl.RootId
				cpc, err := cp.FetchParticipantCount()

				So(err, ShouldBeNil)
				So(cpc, ShouldEqual, 2)
			})
		})
	})
}
