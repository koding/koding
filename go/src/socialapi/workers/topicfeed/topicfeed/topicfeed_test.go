package topicfeed

import (
	"math/rand"
	"socialapi/models"
	"testing"

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
