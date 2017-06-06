// Package tests has the unit tests of package messaging.
// pubnubGroupSubscribe_test.go contains the tests related to the Group
// Subscribe requests on pubnub Api
package tests

import (
	"encoding/json"
	"fmt"

	"github.com/pubnub/go/messaging"
	"github.com/pubnub/go/messaging/tests/utils"
	"github.com/stretchr/testify/assert"
	// "os"
	"strings"
	"sync"
	"testing"
)

var pnMu sync.Mutex

// TestGroupSubscribeStart prints a message on the screen to mark the beginning of
// subscribe tests.
// PrintTestMessage is defined in the common.go file.
func TestGroupSubscribeStart(t *testing.T) {
	PrintTestMessage("==========Group Subscribe tests start==========")
}

func TestGroupSubscriptionConnectedAndUnsubscribedSingle(t *testing.T) {
	assert := assert.New(t)

	stop, sleep := NewVCRBoth(
		"fixtures/groups/conAndUnsSingle", []string{"uuid"})
	defer stop()

	group := "Group_GroupSubscriptionConAndUnsSingle"
	uuid := "UUID_GroupSubscriptionConAndUnsSingle"
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, uuid, CreateLoggerForTests())

	createChannelGroups(pubnubInstance, []string{group})
	defer removeChannelGroups(pubnubInstance, []string{group})

	sleep(2)

	subscribeSuccessChannel := make(chan []byte)
	subscribeErrorChannel := make(chan []byte)
	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)

	go pubnubInstance.ChannelGroupSubscribe(group,
		subscribeSuccessChannel, subscribeErrorChannel)
	select {
	case msg := <-subscribeSuccessChannel:
		val := string(msg)
		assert.Equal(val, fmt.Sprintf(
			"[1, \"Subscription to channel group '%s' connected\", \"%s\"]",
			group, group))
	case err := <-subscribeErrorChannel:
		assert.Fail(string(err))
	}

	go pubnubInstance.ChannelGroupUnsubscribe(group, successChannel, errorChannel)
	select {
	case msg := <-successChannel:
		val := string(msg)
		assert.Equal(val, fmt.Sprintf(
			"[1, \"Subscription to channel group '%s' unsubscribed\", \"%s\"]",
			group, group))
	case err := <-errorChannel:
		assert.Fail(string(err))
	}

	select {
	case ev := <-successChannel:
		var event messaging.PresenceResonse

		err := json.Unmarshal(ev, &event)
		if err != nil {
			assert.Fail(err.Error())
		}

		assert.Equal("leave", event.Action)
		assert.Equal(200, event.Status)
	case err := <-errorChannel:
		assert.Fail(string(err))
	}

	// pubnubInstance.CloseExistingConnection()
}

func TestGroupSubscriptionConnectedAndUnsubscribedMultiple(t *testing.T) {
	assert := assert.New(t)

	stop, sleep := NewVCRBoth(
		"fixtures/groups/conAndUnsMultiple", []string{"uuid"})
	defer stop()

	uuid := "UUID_Multiple_CAU"
	pnMu.Lock()
	pubnub := messaging.NewPubnub(PubKey, SubKey, "", "", false, uuid, CreateLoggerForTests())
	pnMu.Unlock()
	groupsString := "Group_ConAndUnsMult_1,Group_ConAndUnsMult_2,Group_ConAndUnsMult_3"
	groups := strings.Split(groupsString, ",")

	createChannelGroups(pubnub, groups)
	defer removeChannelGroups(pubnub, groups)

	sleep(2)

	subscribeSuccessChannel := make(chan []byte)
	subscribeErrorChannel := make(chan []byte)
	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	await := make(chan bool)

	go pubnub.ChannelGroupSubscribe(groupsString,
		subscribeSuccessChannel, subscribeErrorChannel)

	go func() {
		var messages []string

		for {
			select {
			case message := <-subscribeSuccessChannel:
				var msg []interface{}

				err := json.Unmarshal(message, &msg)
				if err != nil {
					assert.Fail(err.Error())
				}

				assert.Contains(msg[1].(string), "Subscription to channel group")
				assert.Contains(msg[1].(string), "connected")
				assert.Len(msg, 3)

				messages = append(messages, string(msg[2].(string)))
			case err := <-subscribeErrorChannel:
				assert.Fail("Subscribe error", string(err))
			case <-timeouts(10):
				break
			}

			if len(messages) == 3 {
				break
			}
		}

		assert.True(utils.AssertStringSliceElementsEqual(groups, messages),
			fmt.Sprintf("Expected groups: %s. Actual groups: %s\n", groups, messages))

		await <- true
	}()

	select {
	case <-await:
	case <-timeouts(20):
		assert.Fail("Receive connected messages timeout")
	}

	go pubnub.ChannelGroupUnsubscribe(groupsString, successChannel, errorChannel)
	go func() {
		var messages []string
		var events int

		for {
			select {
			case message := <-successChannel:
				var msg []interface{}

				err := json.Unmarshal(message, &msg)
				if err != nil {
					var event map[string]interface{}
					err := json.Unmarshal(message, &event)
					if err != nil {
						assert.Fail(err.Error())
					}

					assert.Equal(event["action"].(string), "leave")
					assert.Equal(event["message"].(string), "OK")
					events++
				} else {

					assert.Contains(msg[1].(string), "Subscription to channel group")
					assert.Contains(msg[1].(string), "unsubscribed")
					assert.Len(msg, 3)

					messages = append(messages, string(msg[2].(string)))
				}
			case err := <-errorChannel:
				assert.Fail("Subscribe error", string(err))
			case <-timeouts(10):
				break
			}

			if len(messages) == 3 && events == 3 {
				break
			}
		}

		assert.True(utils.AssertStringSliceElementsEqual(groups, messages),
			fmt.Sprintf("Expected groups: %s. Actual groups: %s\n", groups, messages))

		await <- true
	}()

	select {
	case <-await:
	case <-timeouts(20):
		assert.Fail("Receive unsubscribed messages timeout")
	}

	// pubnub.CloseExistingConnection()
}

func TestGroupSubscriptionReceiveSingleMessage(t *testing.T) {
	assert := assert.New(t)

	stop, sleep := NewVCRBoth(
		"fixtures/groups/receiveSingleMessage", []string{"uuid"})
	defer stop()

	group := "Group_GroupReceiveSingleMessage"
	channel := "Channel_GroupReceiveSingleMessage"
	uuid := "UUID_GroupReceiveSingleMessage"
	pubnub := messaging.NewPubnub(PubKey, SubKey, "", "", false, uuid, CreateLoggerForTests())

	populateChannelGroup(pubnub, group, channel)
	defer removeChannelGroups(pubnub, []string{group})

	sleep(2)

	subscribeSuccessChannel := make(chan []byte)
	subscribeErrorChannel := make(chan []byte)
	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	unsubscribeSuccessChannel := make(chan []byte)
	unsubscribeErrorChannel := make(chan []byte)

	msgReceived := make(chan bool)

	go pubnub.ChannelGroupSubscribe(group,
		subscribeSuccessChannel, subscribeErrorChannel)
	ExpectConnectedEvent(t, "", group, subscribeSuccessChannel,
		subscribeErrorChannel)

	go func() {
		select {
		case message := <-subscribeSuccessChannel:
			var msg []interface{}

			err := json.Unmarshal(message, &msg)
			if err != nil {
				assert.Fail(err.Error())
			}

			assert.Len(msg, 4)
			assert.Equal(msg[2], channel)
			assert.Equal(msg[3], group)
			msgReceived <- true
		case err := <-subscribeErrorChannel:
			assert.Fail(string(err))
		case <-timeouts(3):
			assert.Fail("Subscription timeout")
		}
	}()

	go pubnub.Publish(channel, "hey", successChannel, errorChannel)
	select {
	case <-successChannel:
	case err := <-errorChannel:
		assert.Fail("Publish error", string(err))
	case <-messaging.Timeout():
		assert.Fail("Publish timeout")
	}

	<-msgReceived

	go pubnub.ChannelGroupUnsubscribe(group, unsubscribeSuccessChannel,
		unsubscribeErrorChannel)
	ExpectUnsubscribedEvent(t, "", group, unsubscribeSuccessChannel,
		unsubscribeErrorChannel)

	// pubnub.CloseExistingConnection()
}

// TODO: verify that CG requests are not duplicated
func xTestGroupSubscriptionPresence(t *testing.T) {
	presenceTimeout := 15
	assert := assert.New(t)

	stop, sleep := NewVCRBoth(
		"fixtures/groups/presence", []string{"uuid"})
	defer stop()

	group := "Group_GroupPresence"
	pubnub := messaging.NewPubnub(PubKey, SubKey, "", "", false, "", CreateLoggerForTests())
	groupPresence := fmt.Sprintf("%s%s", group, presenceSuffix)

	createChannelGroups(pubnub, []string{group})
	defer removeChannelGroups(pubnub, []string{group})

	sleep(2)

	presenceSuccessChannel := make(chan []byte)
	presenceErrorChannel := make(chan []byte)
	subscribeSuccessChannel := make(chan []byte)
	subscribeErrorChannel := make(chan []byte)
	unsubscribeSuccessChannel := make(chan []byte)
	unsubscribeErrorChannel := make(chan []byte)

	await := make(chan bool)

	go pubnub.ChannelGroupSubscribe(groupPresence,
		presenceSuccessChannel, presenceErrorChannel)
	ExpectConnectedEvent(t, "", group, presenceSuccessChannel,
		presenceErrorChannel)

	go func() {
		for {
			select {
			case message := <-presenceSuccessChannel:
				var msg []interface{}

				msgString := string(message)

				err := json.Unmarshal(message, &msg)
				if err != nil {
					assert.Fail(err.Error())
				}

				if strings.Contains(msgString, "timeout") ||
					strings.Contains(msgString, "leave") {
					continue
				}

				assert.Equal("adsf", msg[2].(string))
				assert.Equal(group, msg[3].(string))

				assert.Contains(msgString, "join")
				assert.Contains(msgString, pubnub.GetUUID(),
					"While expecting equal uuids in routine #1")
				await <- true
				return
			case err := <-presenceErrorChannel:
				assert.Fail("Presence routine #1 error", string(err))
				await <- false
				return
			case <-timeouts(presenceTimeout):
				assert.Fail("Presence routine #1 timeout")
				await <- false
				return
			}
		}
	}()

	go pubnub.ChannelGroupSubscribe(group,
		subscribeSuccessChannel, subscribeErrorChannel)
	ExpectConnectedEvent(t, "", group, subscribeSuccessChannel,
		subscribeErrorChannel)

	<-await

	sleep(3)

	go func() {
		for {
			select {
			case message := <-presenceSuccessChannel:
				var msg []interface{}

				msgString := string(message)

				err := json.Unmarshal(message, &msg)
				if err != nil {
					assert.Fail(err.Error())
				}

				if strings.Contains(msgString, "timeout") ||
					strings.Contains(msgString, "join") {
					continue
				}

				assert.Equal("adsf", msg[2].(string))
				assert.Equal(group, msg[3].(string))

				assert.Contains(msgString, "leave")
				assert.Contains(msgString, pubnub.GetUUID(),
					"While expecting equal uuids in routine #2")
				await <- true
				return
			case err := <-presenceErrorChannel:
				assert.Fail("Presence routine #2 error", string(err))
				await <- false
				return
			case <-timeouts(presenceTimeout):
				assert.Fail("Presence routine #2 timeout")
				await <- false
				return
			}
		}
	}()

	<-await

	go pubnub.ChannelGroupUnsubscribe(group, unsubscribeSuccessChannel,
		unsubscribeErrorChannel)
	ExpectUnsubscribedEvent(t, "", group, unsubscribeSuccessChannel,
		unsubscribeErrorChannel)
}

// TestGroupSubscribeEnd prints a message on the screen to mark the end of
// subscribe tests.
// PrintTestMessage is defined in the common.go file.
func TestGroupSubscribeEnd(t *testing.T) {
	PrintTestMessage("==========Group Subscribe tests end==========")
}
