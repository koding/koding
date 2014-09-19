package algoliaconnector

import (
	"socialapi/models"
	"socialapi/workers/common/runner"

	"labix.org/v2/mgo/bson"

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

func TestAccountSaved(t *testing.T) {
	r := runner.New("AlogoliaConnector-Test")
	err := r.Init()
	if err != nil {
		panic(err)
	}

	defer r.Close()

	algolia := algoliasearch.NewClient(r.Conf.Algolia.AppId, r.Conf.Algolia.ApiSecretKey)
	// create message handler
	handler := New(r.Log, algolia, r.Conf.Algolia.IndexSuffix)

	Convey("given some fake account", t, func() {
		mockAccount := &models.Account{
			OldId:   bson.NewObjectId().Hex(),
			Id:      100000000,
			Nick:    "fake-nickname",
			IsTroll: false,
		}
		Convey("it should save the document to algolia", func() {
			err := handler.AccountSaved(mockAccount)
			So(err, ShouldBeNil)
		})
	})
}

func TestMessageSaved(t *testing.T) {
	Convey("messages can be saved", t, func() {})
	Convey("messages can be cross-indexed", t, func() {})
}

func TestMessageDeleted(t *testing.T) {
	Convey("messages can be deleted", t, func() {})
	Convey("cross-indexed messages will not be deleted", func() {})
}

func TestMessageUpdated(t *testing.T) {
	Convey("messages can be updated", t, func() {})
}
