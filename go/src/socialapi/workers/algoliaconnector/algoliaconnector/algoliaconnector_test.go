package algoliaconnector

import (
	"koding/db/mongodb/modelhelper"
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
	runner, handler := getTestHandler()
	defer runner.Close()

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

func TestTopicUpdated(t *testing.T) {
	runner, handler := getTestHandler()
	defer runner.Close()

	rand.Seed(time.Now().UnixNano())

	appConfig := config.MustRead(runner.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	Convey("given some fake topic channel", t, func() {
		mockTopic := models.NewChannel()
		mockTopic.Id = rand.Int63()
		mockTopic.TypeConstant = models.Channel_TYPE_TOPIC
		Convey("it should save the document to algolia", func() {
			err := handler.TopicSaved(mockTopic)
			So(err, ShouldBeNil)
			err = makeSureTopic(handler, mockTopic.Id, func(record map[string]interface{}, err error) bool {
				if err != nil {
					return false
				}

				return true
			})

			So(err, ShouldBeNil)

			Convey("given some existing topic channel", func() {
				mockTopic.TypeConstant = models.Channel_TYPE_LINKED_TOPIC
				Convey("it should be able to remove it", func() {
					err := handler.TopicUpdated(mockTopic)
					So(err, ShouldBeNil)

					err = makeSureTopic(handler, mockTopic.Id, func(record map[string]interface{}, err error) bool {
						if IsAlgoliaError(err, ErrAlgoliaObjectIdNotFoundMsg) {
							return true
						}

						return false
					})

					So(err, ShouldBeNil)

					Convey("removing a deleted channel should return success", func() {
						err := handler.TopicUpdated(mockTopic)
						So(err, ShouldBeNil)
					})
				})
			})
			Convey("removing a non-existing channel should return success", func() {
				mockTopic.Id++
				err := handler.TopicUpdated(mockTopic)
				So(err, ShouldBeNil)
			})
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

// makeSureMessage checks if the given id's get request returns the desired err, it
// will re-try every 100ms until deadline of 15 seconds reached. Algolia doesnt
// index the records right away, so try to go to a desired state
func makeSureMessage(handler *Controller, id int64, f func(map[string]interface{}, error) bool) error {
	deadLine := time.After(time.Minute * 2)
	tick := time.Tick(time.Millisecond * 100)
	for {
		select {
		case <-tick:
			record, err := handler.get(IndexMessages, strconv.FormatInt(id, 10))
			if f(record, err) {
				return nil
			}
		case <-deadLine:
			return errDeadline
		}
	}
}

// makeSureSynonyms checks if the given index's synonyms request returns the
// desired err, it will re-try every 100ms until deadline of 15 seconds reached.
// Algolia doesnt index the records right away, so try to go to a desired state
func makeSureSynonyms(handler *Controller, indexName string, f func([][]string, error) bool) error {
	deadLine := time.After(time.Minute * 2)
	tick := time.Tick(time.Millisecond * 100)
	for {
		select {
		case <-tick:
			synonyms, err := handler.getSynonyms(indexName)
			if err != nil {
				return err
			}

			if f(synonyms, err) {
				return nil
			}
		case <-deadLine:
			return errDeadline
		}
	}
}

// makeSureTopic checks if the given id's get request returns the desired err,
// it will re-try every 100ms until deadline of 2 minutes. Algolia doesnt index
// the records right away, so try to go to a desired state
func makeSureTopic(handler *Controller, id int64, f func(map[string]interface{}, error) bool) error {
	deadLine := time.After(time.Minute * 2)
	tick := time.Tick(time.Millisecond * 100)
	for {
		select {
		case <-tick:
			record, err := handler.get(IndexTopics, strconv.FormatInt(id, 10))
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

func TestIndexSettings(t *testing.T) {
	runner, handler := getTestHandler()
	defer runner.Close()

	appConfig := config.MustRead(runner.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	Convey("given some handler", t, func() {
		groupName := models.RandomName()

		Convey("we should be able to get the synonyms", func() {
			oldsynonymns, err := handler.getSynonyms(IndexMessages)
			So(err, ShouldBeNil)
			So(oldsynonymns, ShouldNotBeNil)

			Convey("when we add new synonyms", func() {

				acc, err := models.CreateAccountInBothDbs()
				So(acc, ShouldNotBeNil)

				root := models.CreateTypedGroupedChannelWithTest(acc.Id, models.Channel_TYPE_TOPIC, groupName)
				So(root, ShouldNotBeNil)

				leaf := models.CreateTypedGroupedChannelWithTest(acc.Id, models.Channel_TYPE_TOPIC, groupName)
				So(leaf, ShouldNotBeNil)

				cl := &models.ChannelLink{
					RootId: root.Id,
					LeafId: leaf.Id,
				}

				So(cl.Create(), ShouldBeNil)

				So(handler.CreateSynonym(cl), ShouldBeNil)

				Convey("synonyms should be in settings", func() {
					err = makeSureSynonyms(handler, IndexMessages, func(synonyms [][]string, err error) bool {
						if err != nil {
							return false
						}

						f1found, f2found := false, false

						for _, synonym := range synonyms {
							for _, synonymPair := range synonym {
								if synonymPair == root.Name {
									f1found = true
								}

								if synonymPair == leaf.Name {
									f2found = true
								}

								if f1found && f2found {
									return true
								}
							}
						}

						return false
					})

					So(err, ShouldBeNil)

					Convey("if we override one of the the synonyms with third one", func() {
						leaf2 := models.CreateTypedGroupedChannelWithTest(acc.Id, models.Channel_TYPE_TOPIC, groupName)
						So(err, ShouldBeNil)
						So(leaf, ShouldNotBeNil)

						cl := &models.ChannelLink{
							RootId: root.Id,
							LeafId: leaf2.Id,
						}

						So(cl.Create(), ShouldBeNil)
						So(handler.CreateSynonym(cl), ShouldBeNil)

						Convey("synonyms should be in settings", func() {
							err = makeSureSynonyms(handler, IndexMessages, func(synonyms [][]string, err error) bool {
								if err != nil {
									return false
								}

								f1found, f2found, f3found := false, false, false

								for _, synonym := range synonyms {
									for _, synonymPair := range synonym {
										if synonymPair == root.Name {
											f1found = true
										}

										if synonymPair == leaf.Name {
											f2found = true
										}

										if synonymPair == leaf2.Name {
											f3found = true
										}

										if f1found && f2found && f3found {
											return true
										}
									}
								}

								return false
							})

							So(err, ShouldBeNil)
						})

						// adding another synonym should not break anything
						Convey("adding another synonym should not break anything", func() {

							anotherRoot := models.CreateTypedGroupedChannelWithTest(acc.Id, models.Channel_TYPE_TOPIC, groupName)
							So(root, ShouldNotBeNil)

							anotherLeaf := models.CreateTypedGroupedChannelWithTest(acc.Id, models.Channel_TYPE_TOPIC, groupName)
							So(leaf, ShouldNotBeNil)

							cl := &models.ChannelLink{
								RootId: anotherRoot.Id,
								LeafId: anotherLeaf.Id,
							}

							So(cl.Create(), ShouldBeNil)

							So(handler.CreateSynonym(cl), ShouldBeNil)

							Convey("all synonyms should be in settings", func() {
								err = makeSureSynonyms(handler, IndexMessages, func(synonyms [][]string, err error) bool {
									if err != nil {
										return false
									}

									f1found, f2found := false, false

									for _, synonym := range synonyms {
										for _, synonymPair := range synonym {
											if synonymPair == root.Name {
												f1found = true
											}

											if synonymPair == leaf.Name {
												f2found = true
											}

											if f1found && f2found {
												return true
											}
										}
									}

									return false
								})

								So(err, ShouldBeNil)
								allsynonymns, err := handler.getSynonyms(IndexMessages)
								So(err, ShouldBeNil)
								// why ShouldBeGreaterThan? becase when we run
								// the same test again, there may be other
								// synonyms
								So(len(allsynonymns), ShouldBeGreaterThan, 2)
							})
						})
					})
				})
			})
		})
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
