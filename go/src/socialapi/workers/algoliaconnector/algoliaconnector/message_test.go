package algoliaconnector

import (
	"socialapi/models"
	"strconv"
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"
)

func TestMessageListSaved(t *testing.T) {
	runner, handler := getTestHandler()
	defer runner.Close()

	Convey("while testing message list save", t, func() {
		account := models.CreateAccountWithTest()
		channel := models.CreateChannelWithTest(account.Id)
		cm := models.CreateMessage(channel.Id, account.Id, models.ChannelMessage_TYPE_POST)

		Convey("messages can be saved", func() {
			cmls, err := cm.GetChannelMessageLists()
			So(err, ShouldBeNil)
			So(len(cmls), ShouldBeGreaterThan, 0)

			So(handler.MessageListSaved(&cmls[0]), ShouldBeNil)
			So(doBasicTestForMessage(handler, cmls[0].MessageId), ShouldBeNil)
		})

		Convey("messages can be cross-indexed", func() {
			c1 := models.CreateChannelWithTest(account.Id)
			_, err := c1.AddMessage(cm)
			So(err, ShouldBeNil)

			cmls, err := cm.GetChannelMessageLists()
			So(err, ShouldBeNil)
			So(len(cmls), ShouldEqual, 2)

			So(handler.MessageListSaved(&cmls[0]), ShouldBeNil)
			So(doBasicTestForMessage(handler, cmls[0].MessageId), ShouldBeNil)

			So(handler.MessageListSaved(&cmls[1]), ShouldBeNil)
			err = makeSureMessage(handler, cmls[1].MessageId, func(record map[string]interface{}, err error) bool {
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
	})
}

func TestMessageListDeleted(t *testing.T) {
	runner, handler := getTestHandler()
	defer runner.Close()
	Convey("while testing message list delete", t, func() {

		account := models.CreateAccountWithTest()
		channel := models.CreateChannelWithTest(account.Id)
		cm := models.CreateMessage(channel.Id, account.Id, models.ChannelMessage_TYPE_POST)

		Convey("messages can be deleted", func() {
			cmls, err := cm.GetChannelMessageLists()
			So(err, ShouldBeNil)
			So(len(cmls), ShouldBeGreaterThan, 0)

			So(handler.MessageListSaved(&cmls[0]), ShouldBeNil)
			So(doBasicTestForMessage(handler, cmls[0].MessageId), ShouldBeNil)

			So(handler.MessageListDeleted(&cmls[0]), ShouldBeNil)
			err = makeSureMessage(handler, cmls[0].MessageId, func(record map[string]interface{}, err error) bool {
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

		Convey("cross-indexed messages will not be deleted", func() {
			channel := models.CreateChannelWithTest(account.Id)
			channel.AddMessage(cm)

			cmls, err := cm.GetChannelMessageLists()
			So(err, ShouldBeNil)
			So(len(cmls), ShouldEqual, 2)

			So(handler.MessageListSaved(&cmls[0]), ShouldBeNil)
			err = makeSureMessage(handler, cmls[0].MessageId, func(record map[string]interface{}, err error) bool {
				if err != nil {
					return false
				}

				if len((record["_tags"]).([]interface{})) != 1 {
					return false
				}

				return true
			})
			So(err, ShouldBeNil)

			So(handler.MessageListSaved(&cmls[1]), ShouldBeNil)

			err = makeSureMessage(handler, cmls[1].MessageId, func(record map[string]interface{}, err error) bool {
				if err != nil {
					return false
				}

				if len((record["_tags"]).([]interface{})) != 2 {
					return false
				}

				return true
			})
			So(err, ShouldBeNil)

			So(handler.MessageListDeleted(&cmls[1]), ShouldBeNil)

			err = makeSureMessage(handler, cmls[1].MessageId, func(record map[string]interface{}, err error) bool {
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
	})
}

func TestMessageUpdated(t *testing.T) {
	runner, handler := getTestHandler()
	defer runner.Close()

	Convey("messages can be updated", t, func() {
		account := models.CreateAccountWithTest()
		channel := models.CreateChannelWithTest(account.Id)
		cm := models.CreateMessage(channel.Id, account.Id, models.ChannelMessage_TYPE_POST)

		cmls, err := cm.GetChannelMessageLists()
		So(err, ShouldBeNil)
		So(len(cmls), ShouldBeGreaterThan, 0)

		So(handler.MessageListSaved(&cmls[0]), ShouldBeNil)
		err = makeSureMessage(handler, cmls[0].MessageId, func(record map[string]interface{}, err error) bool {
			if err != nil {
				return false
			}

			return true
		})
		So(err, ShouldBeNil)

		cm.Body = "updated body"

		So(cm.Update(), ShouldBeNil)
		So(handler.MessageUpdated(cm), ShouldBeNil)
		err = makeSureMessage(handler, cmls[0].MessageId, func(record map[string]interface{}, err error) bool {
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

func ensureMessageWithTag(handler *Controller, id int64, tag string) error {
	return makeSureMessage(handler, id, func(record map[string]interface{}, err error) bool {
		if err != nil {
			return false
		}

		if record == nil {
			return false
		}

		tags, ok := record["_tags"]
		if !ok {
			return false
		}

		tis, ok := tags.([]interface{})
		if !ok {
			return false
		}

		for _, t := range tis {
			if t.(string) == tag {
				return true
			}
		}

		return false
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
			handler.log.Critical("deadline reached on message but not returning an error")
			return errDeadline
		}
	}
}
