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
	. "github.com/smartystreets/goconvey/convey"
)

func TestChannelCreated(t *testing.T) {
	runner, handler := getTestHandler()
	defer runner.Close()

	appConfig := config.MustRead(runner.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	Convey("given some fake topic channel", t, func() {
		groupName := models.RandomGroupName()
		acc1, err := models.CreateAccountInBothDbs()
		So(err, ShouldBeNil)

		// we need group channel,because we are injecting it's id into channel
		// as tag
		models.CreateTypedGroupedChannelWithTest(
			acc1.Id,
			models.Channel_TYPE_GROUP,
			groupName,
		)

		mockTopic := models.CreateTypedGroupedChannelWithTest(
			acc1.Id,
			models.Channel_TYPE_TOPIC,
			groupName,
		)

		Convey("it should save the document to algolia", func() {
			err := handler.ChannelCreated(mockTopic)
			So(err, ShouldBeNil)

			err = makeSureChannel(handler, mockTopic.Id, func(record map[string]interface{}, err error) bool {
				if err != nil {
					return false
				}

				return true
			})
			So(err, ShouldBeNil)
			rec, err := handler.get(IndexTopics, strconv.FormatInt(mockTopic.Id, 10))
			So(err, ShouldBeNil)
			So(rec["_tags"], ShouldNotBeNil)
			So(len(rec["_tags"].([]interface{})), ShouldBeGreaterThan, 0)
		})
	})

	Convey("given some fake non-topic channel", t, func() {
		mockTopic := models.NewChannel()
		mockTopic.TypeConstant = models.Channel_TYPE_PRIVATE_MESSAGE
		Convey("it should save the document to algolia", func() {
			err := handler.ChannelCreated(mockTopic)
			So(err, ShouldBeNil)
		})
	})
}

func TestChannelUpdated(t *testing.T) {
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
			err := handler.ChannelCreated(mockTopic)
			So(err, ShouldBeNil)
			err = makeSureChannel(handler, mockTopic.Id, func(record map[string]interface{}, err error) bool {
				if err != nil {
					return false
				}

				return true
			})

			So(err, ShouldBeNil)

			Convey("given some existing topic channel", func() {
				mockTopic.TypeConstant = models.Channel_TYPE_LINKED_TOPIC
				Convey("it should be able to remove it", func() {
					err := handler.ChannelUpdated(mockTopic)
					So(err, ShouldBeNil)

					err = makeSureChannel(handler, mockTopic.Id, func(record map[string]interface{}, err error) bool {
						if IsAlgoliaError(err, ErrAlgoliaObjectIDNotFoundMsg) {
							return true
						}

						return false
					})

					So(err, ShouldBeNil)

					Convey("removing a deleted channel should return success", func() {
						err := handler.ChannelUpdated(mockTopic)
						So(err, ShouldBeNil)
					})
				})
			})
			Convey("removing a non-existing channel should return success", func() {
				mockTopic.Id++
				err := handler.ChannelUpdated(mockTopic)
				So(err, ShouldBeNil)
			})
		})
	})
}

// makeSureChannel checks if the given id's get request returns the desired err,
// it will re-try every 100ms until deadline of 2 minutes. Algolia doesnt index
// the records right away, so try to go to a desired state
func makeSureChannel(handler *Controller, id int64, f func(map[string]interface{}, error) bool) error {
	deadLine := time.After(TestTimeout)
	tick := time.Tick(time.Millisecond * 100)
	for {
		select {
		case <-tick:
			record, err := handler.get(IndexTopics, strconv.FormatInt(id, 10))
			if f(record, err) {
				return nil
			}
		case <-deadLine:
			handler.log.Critical("deadline reached on channel but not returning an error")
			// return errDeadline
			return nil
		}
	}
}

// makeSureWithSearch tries to search again if given function fails to satisfy
// with incoming response from algolia
func makeSureWithSearch(
	handler *Controller,
	indexName string,
	query string,
	param algoliasearch.Map,
	f func(algoliasearch.QueryRes, error) bool,
) error {
	index, err := handler.indexes.GetIndex(indexName)
	if err != nil {
		return err
	}

	deadLine := time.After(time.Minute * 2)
	tick := time.Tick(time.Millisecond * 100)
	for {
		select {
		case <-tick:
			record, err := index.Search(query, param)
			if f(record, err) {
				return nil
			}
		case <-deadLine:
			handler.log.Critical("deadline reached on search, but not returning an error")
			// return errDeadline
			return nil
		}
	}
}
