package algoliaconnector

import (
	"errors"
	"math/rand"
	"socialapi/config"
	"socialapi/models"
	"strconv"
	"testing"
	"time"

	"github.com/algolia/algoliasearch-client-go/algoliasearch"
	"github.com/koding/bongo"
	"github.com/koding/runner"
	"labix.org/v2/mgo/bson"

	. "github.com/smartystreets/goconvey/convey"
)

func TestTopicSaved(t *testing.T) {
	r := runner.New("AlogoliaConnector-Test")
	err := r.Init()
	if err != nil {
		panic(err)
	}

	defer r.Close()

	appConfig := config.MustRead(r.Conf.Path)

	algolia := algoliasearch.NewClient(appConfig.Algolia.AppId, appConfig.Algolia.ApiSecretKey)
	// create message handler
	handler := New(r.Log, algolia, appConfig.Algolia.IndexSuffix)

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
	runner, handler := getTestHandler()
	defer runner.Close()

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
	runner, handler := getTestHandler()
	defer runner.Close()

	Convey("messages can be saved", t, func() {
		mockMessage, _ := createAndSaveMessage()
		mockListing := getListings(mockMessage)[0]

		So(handler.MessageListSaved(&mockListing), ShouldBeNil)
		So(doBasicTestForMessage(handler, mockListing.MessageId), ShouldBeNil)
	})

	Convey("messages can be cross-indexed", t, func() {
		mockMessage, owner := createAndSaveMessage()

		// init channel
		cm, err := createChannel(owner.Id)
		So(err, ShouldBeNil)
		So(cm, ShouldNotBeNil)
		// init channel message list
		cml := createChannelMessageList(cm.Id, mockMessage.Id)
		So(cml, ShouldNotBeNil)

		listings := getListings(mockMessage)
		So(len(listings), ShouldEqual, 2)

		So(handler.MessageListSaved(&listings[0]), ShouldBeNil)
		So(doBasicTestForMessage(handler, listings[0].MessageId), ShouldBeNil)

		So(handler.MessageListSaved(&listings[1]), ShouldBeNil)
		err = makeSureMessage(handler, listings[1].MessageId, func(record map[string]interface{}, err error) bool {
			if err != nil {
				return false
			}

			if len((record["_tags"]).([]interface{})) != 2 {
				return false
			}

			return true
		})
		So(err, ShouldBeNil)
	})
}

func doBasicTestForMessage(handler *Controller, id int64) error {
	return makeSureMessage(handler, id, func(record map[string]interface{}, err error) bool {
		if err != nil {
			return false
		}

		if record == nil {
			return false
		}

		return true
	})
}

var errDeadline = errors.New("dead line")

// makeSureErr checks if the given id's get request returns the desired err, it
// will re-try every 100ms until deadline of 15 seconds reached. Algolia doesnt
// index the records right away, so try to go to a desired state
func makeSureMessage(handler *Controller, id int64, f func(map[string]interface{}, error) bool) error {
	deadLine := time.After(time.Minute * 2)
	tick := time.Tick(time.Millisecond * 100)
	for {
		select {
		case <-tick:
			record, err := handler.get("messages", strconv.FormatInt(id, 10))
			if f(record, err) {
				return nil
			}
		case <-deadLine:
			return errDeadline
		}
	}
}
func TestMessageListDeleted(t *testing.T) {
	runner, handler := getTestHandler()
	defer runner.Close()

	Convey("messages can be deleted", t, func() {
		mockMessage, _ := createAndSaveMessage()
		mockListing := getListings(mockMessage)[0]

		So(handler.MessageListSaved(&mockListing), ShouldBeNil)
		So(doBasicTestForMessage(handler, mockListing.MessageId), ShouldBeNil)

		So(handler.MessageListDeleted(&mockListing), ShouldBeNil)
		err := makeSureMessage(handler, mockListing.MessageId, func(record map[string]interface{}, err error) bool {
			if err == nil {
				return false
			}

			if record != nil {
				return false
			}

			return true
		})
		So(err, ShouldBeNil)
	})

	Convey("cross-indexed messages will not be deleted", t, func() {
		mockMessage, owner := createAndSaveMessage()

		// init channel
		cm, err := createChannel(owner.Id)
		So(err, ShouldBeNil)
		So(cm, ShouldNotBeNil)
		// init channel message list
		cml := createChannelMessageList(cm.Id, mockMessage.Id)
		So(cml, ShouldNotBeNil)

		listings := getListings(mockMessage)
		So(len(listings), ShouldEqual, 2)

		So(handler.MessageListSaved(&listings[0]), ShouldBeNil)
		err = makeSureMessage(handler, listings[0].MessageId, func(record map[string]interface{}, err error) bool {
			if err != nil {
				return false
			}

			if len((record["_tags"]).([]interface{})) != 1 {
				return false
			}

			return true
		})
		So(err, ShouldBeNil)

		So(handler.MessageListSaved(&listings[1]), ShouldBeNil)

		err = makeSureMessage(handler, listings[1].MessageId, func(record map[string]interface{}, err error) bool {
			if err != nil {
				return false
			}

			if len((record["_tags"]).([]interface{})) != 2 {
				return false
			}

			return true
		})
		So(err, ShouldBeNil)

		So(handler.MessageListDeleted(&listings[1]), ShouldBeNil)

		err = makeSureMessage(handler, listings[1].MessageId, func(record map[string]interface{}, err error) bool {
			if err != nil {
				return false
			}

			if len((record["_tags"]).([]interface{})) != 1 {
				return false
			}

			return true
		})

		So(err, ShouldBeNil)
	})
}

func TestMessageUpdated(t *testing.T) {
	runner, handler := getTestHandler()
	defer runner.Close()

	Convey("messages can be updated", t, func() {
		mockMessage, _ := createAndSaveMessage()
		mockListing := getListings(mockMessage)[0]

		So(handler.MessageListSaved(&mockListing), ShouldBeNil)
		err := makeSureMessage(handler, mockListing.MessageId, func(record map[string]interface{}, err error) bool {
			if err != nil {
				return false
			}

			return true
		})
		So(err, ShouldBeNil)

		mockMessage.Body = "updated body"

		So(mockMessage.Update(), ShouldBeNil)
		So(handler.MessageUpdated(mockMessage), ShouldBeNil)
		err = makeSureMessage(handler, mockListing.MessageId, func(record map[string]interface{}, err error) bool {
			if err != nil {
				return false
			}

			if record["body"].(string) != "updated body" {
				return false
			}

			return true
		})
		So(err, ShouldBeNil)
	})
}

func getTestHandler() (*runner.Runner, *Controller) {
	r := runner.New("AlogoliaConnector-Test")
	err := r.Init()
	if err != nil {
		panic(err)
	}

	appConfig := config.MustRead(r.Conf.Path)

	algolia := algoliasearch.NewClient(appConfig.Algolia.AppId, appConfig.Algolia.ApiSecretKey)
	// create message handler
	return r, New(r.Log, algolia, ".test")

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

	So(cml.Create(), ShouldBeNil)

	return cml
}

func createAndSaveMessage() (*models.ChannelMessage, *models.Account) {
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
	So(cml, ShouldNotBeNil)

	return cm, account
}

func getListings(message *models.ChannelMessage) []models.ChannelMessageList {
	mockListing := models.NewChannelMessageList()
	var listings []models.ChannelMessageList
	err := mockListing.Some(&listings, &bongo.Query{
		Selector: map[string]interface{}{"message_id": message.Id}})
	So(err, ShouldBeNil)
	return listings
}
