package algoliaconnector

import (
	"math/rand"
	"socialapi/models"
	"socialapi/workers/common/runner"
	"strconv"

	"github.com/algolia/algoliasearch-client-go/algoliasearch"
	"github.com/koding/bongo"
	"labix.org/v2/mgo/bson"

	"testing"
	"time"

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
	handler := getTestHandler()
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

func TestMessageListSaved(t *testing.T) {
	handler := getTestHandler()
	Convey("messages can be saved", t, func() {
		mockMessage := createAndSaveMessage()

		mockListing := models.NewChannelMessageList()
		err := mockListing.One(&bongo.Query{
			Selector: map[string]interface{}{"message_id": mockMessage.Id}})
		So(err, ShouldBeNil)

		So(handler.MessageListSaved(mockListing), ShouldBeNil)

		// apparently we need to give algolia enough time to save the document:
		time.Sleep(2 * time.Second)

		record, err := handler.get("messages", strconv.FormatInt(mockMessage.Id, 10))
		So(err, ShouldBeNil)
		So(record, ShouldNotBeNil)
	})
	Convey("messages can be cross-indexed", t, func() {})
}

func TestMessageListDeleted(t *testing.T) {
	Convey("messages can be deleted", t, func() {})
	Convey("cross-indexed messages will not be deleted", t, func() {})
}

func TestMessageUpdated(t *testing.T) {
	Convey("messages can be updated", t, func() {})
}

func getTestHandler() *Controller {
	r := runner.New("AlogoliaConnector-Test")
	err := r.Init()
	if err != nil {
		panic(err)
	}

	defer r.Close()

	algolia := algoliasearch.NewClient(r.Conf.Algolia.AppId, r.Conf.Algolia.ApiSecretKey)
	// create message handler
	return New(r.Log, algolia, ".test")

}

func createAccount() (*models.Account, error) {
	// create and account instance
	author := models.NewAccount()

	// create a fake mongo id
	oldId := bson.NewObjectId()
	// assign it to our test user
	author.OldId = oldId.Hex()

	// seed the random data generator
	rand.Seed(time.Now().UnixNano())

	author.Nick = "malitest" + strconv.Itoa(rand.Intn(10e9))

	if err := author.Create(); err != nil {
		return nil, err
	}

	return author, nil
}

func createChannel(accountId int64) (*models.Channel, error) {
	// create and account instance
	channel := models.NewChannel()
	channel.CreatorId = accountId

	if err := channel.Create(); err != nil {
		return nil, err
	}

	return channel, nil
}

func createChannelMessageList(channelId, messageId int64) *models.ChannelMessageList {
	cml := models.NewChannelMessageList()

	cml.ChannelId = channelId
	cml.MessageId = messageId

	return cml
}

func createAndSaveMessage() *models.ChannelMessage {
	cm := models.NewChannelMessage()

	// init account
	account, err := createAccount()
	So(err, ShouldBeNil)
	So(account, ShouldNotBeNil)
	So(account.Id, ShouldNotEqual, 0)
	// init channel
	channel, err := createChannel(account.Id)
	So(err, ShouldBeNil)
	So(channel, ShouldNotBeNil)
	// set account id
	cm.AccountId = account.Id
	// set channel id
	cm.InitialChannelId = channel.Id
	// set body
	cm.Body = "5five"
	So(cm.Create(), ShouldBeNil)
	// init listing
	cml := createChannelMessageList(channel.Id, cm.Id)
	So(cml.Create(), ShouldBeNil)

	return cm
}
