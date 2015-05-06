package algoliaconnector

import (
	"strconv"
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"
)

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
	deadLine := time.After(TestTimeout)
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
