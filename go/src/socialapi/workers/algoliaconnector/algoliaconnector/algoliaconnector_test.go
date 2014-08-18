package algoliaconnector

import (
	"socialapi/models"
	"socialapi/workers/common/runner"

	"github.com/algolia/algoliasearch-client-go/algoliasearch"

	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestTopicSaved(t *testing.T) {
	r := runner.New("AlogoliaConnector-Test")
	err := r.Init()
	if err != nil {
		panic(err)
	}

	defer r.Close()

	algolia := algoliasearch.NewClient(r.Conf.Algolia.AppId, r.Conf.Algolia.ApiSecretKey)
	// create message handler
	handler := New(r.Log, algolia, r.Conf.Algolia.IndexSuffix)

	Convey("given some fake topic channel", t, func() {
		mockTopic := models.NewChannel()
		mockTopic.TypeConstant = models.Channel_TYPE_TOPIC
		Convey("it should save the document to algolia", func() {
			err := handler.TopicSaved(mockTopic)
			So(err, ShouldBeNil)
		})
	})
	Convey("given some fake non-topic channel", t, func() {
		mockTopic := models.NewChannel()
		mockTopic.TypeConstant = models.Channel_TYPE_PRIVATE_MESSAGE
		Convey("it should save the document to algolia", func() {
			err := handler.TopicSaved(mockTopic)
			So(err, ShouldBeNil)
		})
	})

}
