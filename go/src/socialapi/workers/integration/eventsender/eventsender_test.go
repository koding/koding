package eventsender

import (
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/models"
	"testing"

	"github.com/koding/runner"

	. "github.com/smartystreets/goconvey/convey"
)

var r *runner.Runner

func createController() *Controller {
	r = runner.New("eventsender_test")
	if err := r.Init(); err != nil {
		panic(err)
	}

	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)

	c := New(appConfig, r.Log)

	return c
}

func TestEventSenderHandler(t *testing.T) {

	c := createController()
	defer c.Close()
	defer r.Close()
	acc, err := models.CreateAccountInBothDbs()
	if err != nil {
		t.Fatalf("Could not create account: %s", err)
	}

	Convey("We should be able to send events to Segment.io for user messages", t, func() {
		Convey("We should be able to send events for user messages", func() {
			groupName := models.RandomGroupName()
			groupChannel := models.CreateTypedGroupedChannelWithTest(acc.Id, models.Channel_TYPE_GROUP, groupName)
			models.CreateTypedGroupedChannelWithTest(acc.Id, models.Channel_TYPE_TOPIC, groupName)
			cm := models.NewChannelMessage()
			cm.Body = "hey"
			cm.AccountId = acc.Id
			cm.InitialChannelId = groupChannel.Id

			err = c.MessageCreated(cm)
			So(err, ShouldBeNil)
			//session, err := models.FetchOrCreateSession(acc.Nick)
			//So(err, ShouldBeNil)
			//botChannelId, err := rest.DoBotChannelRequest(session.ClientId)
			//So(err, ShouldBeNil)
			//time.Sleep(3 * time.Second)

			//cml := models.NewChannelMessageList()
			//mIds, err := cml.FetchMessageIdsByChannelId(botChannelId, &request.Query{})
			//So(err, ShouldBeNil)
			//So(len(mIds), ShouldEqual, 1)
			//botMessage := models.NewChannelMessage()
			//err = botMessage.ById(mIds[0])
			//So(err, ShouldBeNil)
		})

		Convey("We should be able to send events for created collaboration channels", func() {

			ch := models.NewChannel()
			ch.CreatorId = acc.Id
			ch.TypeConstant = models.Channel_TYPE_COLLABORATION

			err = c.ChannelCreated(ch)
			So(err, ShouldBeNil)
			//session, err := models.FetchOrCreateSession(acc.Nick)
			//So(err, ShouldBeNil)

			//botChannelId, err := rest.DoBotChannelRequest(session.ClientId)
			//So(err, ShouldBeNil)
			//time.Sleep(3 * time.Second)

			//cml := models.NewChannelMessageList()
			//mIds, err := cml.FetchMessageIdsByChannelId(botChannelId, &request.Query{})
			//So(err, ShouldBeNil)
			//So(len(mIds), ShouldEqual, 2)
			//botMessage := models.NewChannelMessage()
			//err = botMessage.ById(mIds[0])
			//So(err, ShouldBeNil)
			//fmt.Println("bakalim mi", botMessage.Body)

		})

		Convey("We should be able to send events for created workspaces", func() {

			ws := &WorkspaceData{}
			ws.AccountId = acc.Id
			err = c.WorkspaceCreated(ws)
			So(err, ShouldBeNil)
			//session, err := models.FetchOrCreateSession(acc.Nick)
			//So(err, ShouldBeNil)

			//botChannelId, err := rest.DoBotChannelRequest(session.ClientId)
			//So(err, ShouldBeNil)
			//time.Sleep(3 * time.Second)

			//cml := models.NewChannelMessageList()
			//mIds, err := cml.FetchMessageIdsByChannelId(botChannelId, &request.Query{})
			//So(err, ShouldBeNil)
			//So(len(mIds), ShouldEqual, 3)
			//botMessage := models.NewChannelMessage()
			//err = botMessage.ById(mIds[0])
			//So(err, ShouldBeNil)
			//fmt.Println("bakalim mi", botMessage.Body)
		})

	})
}
