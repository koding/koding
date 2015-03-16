package topicfeed

import (
	"fmt"
	"math/rand"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/common/runner"
	"socialapi/workers/topicfeed/topicfeed"
	"testing"

	"github.com/koding/bongo"
	. "github.com/smartystreets/goconvey/convey"
)

func TestMarkedAsTroll(t *testing.T) {
	Convey("while extracting topics", t, func() {
		Convey("duplicates should be returned as unique", func() {
			So(len(extractTopics("hi #topic #topic my topic")), ShouldEqual, 1)
		})

		Convey("public should be removed from topics list", func() {
			topics := extractTopics("hi #topic #public my topic")
			So(len(topics), ShouldEqual, 1)
			So(topics[0], ShouldEqual, "topic")
		})

		Convey("duplicate public should be removed from topics list", func() {
			topics := extractTopics("hi #public  #public  my topic")
			So(len(topics), ShouldEqual, 0)
		})
	})
}

func TestIsEligible(t *testing.T) {
	Convey("while testing isEligible", t, func() {
		Convey("initial channel id should be set", func() {
			c := models.NewChannelMessage()
			c.InitialChannelId = 0
			eligible, err := isEligible(c)
			So(err, ShouldBeNil)
			So(eligible, ShouldBeFalse)
		})

		Convey("type_constant should be Post", func() {
			c := models.NewChannelMessage()
			eligible, err := isEligible(c)
			So(err, ShouldBeNil)
			So(eligible, ShouldBeFalse)

			Convey("when it is set to Post, should be eligible", func() {
				c.InitialChannelId = rand.Int63()
				c.TypeConstant = models.ChannelMessage_TYPE_POST
				eligible, err := isEligible(c)
				So(err, ShouldBeNil)
				So(eligible, ShouldBeTrue)
			})
		})
	})
}

func TestMessageSaved(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	controller := topicfeed.New(r.Log)

	Convey("while testing MessageSaved", t, func() {

		Convey("newly created channels should be marked with needs moderation", func() {
			account := models.CreateAccountWithTest()
			groupChannel := models.CreateTypedPublicChannelWithTest(account.Id, models.Channel_TYPE_GROUP)

			// just a random topic name
			topicName := models.RandomName()
			fmt.Println("topicName-->", topicName)
			c := models.NewChannelMessage()
			c.InitialChannelId = groupChannel.Id
			c.AccountId = account.Id
			c.Body = "my test topic #" + topicName
			c.TypeConstant = models.ChannelMessage_TYPE_POST

			// create with unscoped
			err := bongo.B.Unscoped().Table(c.TableName()).Create(c).Error
			So(err, ShouldBeNil)

			So(controller.MessageSaved(c), ShouldBeNil)

			Convey("we should not be able to find them", func() {
				channels, err := models.NewChannel().Search(&request.Query{
					Name:      topicName,
					GroupName: groupChannel.GroupName,
					AccountId: account.Id,
				})
				So(err, ShouldBeNil)
				So(len(channels), ShouldEqual, 0)
			})

			Convey("after removing needs moderation flag", func() {
				// byname doesnt filter
				channel, err := models.NewChannel().ByName(&request.Query{
					Name:      topicName,
					GroupName: groupChannel.GroupName,
					AccountId: account.Id,
				})
				So(err, ShouldBeNil)
				So(channel, ShouldNotBeNil)

				channel.MetaBits.UnMark(models.NeedsModeration)

				So(channel.Update(), ShouldBeNil)

				Convey("we should be able to search them", func() {
					channels, err := models.NewChannel().Search(&request.Query{
						Name:      topicName,
						GroupName: groupChannel.GroupName,
						AccountId: account.Id,
						Privacy:   channel.PrivacyConstant,
					})
					So(err, ShouldBeNil)
					So(len(channels), ShouldEqual, 1)
					So(channels[0].Id, ShouldEqual, channel.Id)
				})
			})
		})
	})
}
