// Package tests has the unit tests of package messaging.
// pubnubWildcardSubscribe.go contains the tests related to the Group
// Subscribe requests on pubnub Api
package tests

import (
	"encoding/json"
	"fmt"

	"github.com/pubnub/go/messaging"
	"github.com/stretchr/testify/assert"
	//"os"
	"testing"
)

// TestWildcardSubscribeEnd prints a message on the screen to mark the beginning of
// subscribe tests.
// PrintTestMessage is defined in the common.go file.
func TestWildcardSubscribeStart(t *testing.T) {
	PrintTestMessage("==========Wildcard Subscribe tests start==========")
}

func TestWildcardSubscriptionConnectedAndUnsubscribedSingle(t *testing.T) {
	assert := assert.New(t)

	stop, _ := NewVCRBoth("fixtures/wildcard/connAndUns", []string{"uuid"})
	defer stop()

	major := "Channel_ConnAndUns"
	wildcard := fmt.Sprintf("%s.*", major)
	uuid := "UUID_ConnAndUns"
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, uuid, CreateLoggerForTests())

	subscribeSuccessChannel := make(chan []byte)
	subscribeErrorChannel := make(chan []byte)
	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)

	go pubnubInstance.Subscribe(wildcard, "",
		subscribeSuccessChannel, false, subscribeErrorChannel)
	select {
	case msg := <-subscribeSuccessChannel:
		val := string(msg)
		assert.Equal(fmt.Sprintf(
			"[1, \"Subscription to channel '%s' connected\", \"%s\"]",
			wildcard, wildcard), val)
	case err := <-subscribeErrorChannel:
		assert.Fail(string(err))
	}

	go pubnubInstance.Unsubscribe(wildcard, successChannel, errorChannel)
	ExpectUnsubscribedEvent(t, wildcard, "", successChannel, errorChannel)

	// pubnubInstance.CloseExistingConnection()
}

func TestWildcardSubscriptionMessage(t *testing.T) {
	assert := assert.New(t)

	stop, _ := NewVCRBoth("fixtures/wildcard/message", []string{"uuid"})
	defer stop()

	uuid := "UUID_SubscribeMajor"
	major := "Channel_SubscribeMajor"
	minor := "Channel_SubscribeMinor"
	channel := fmt.Sprintf("%s.%s", major, minor)
	wildcard := fmt.Sprintf("%s.*", major)
	//messaging.SetLogOutput(os.Stdout)
	//messaging.LoggingEnabled(true)

	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, uuid, CreateLoggerForTests())

	subscribeSuccessChannel := make(chan []byte)
	subscribeErrorChannel := make(chan []byte)
	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)

	await := make(chan bool)

	go pubnubInstance.Subscribe(wildcard, "",
		subscribeSuccessChannel, false, subscribeErrorChannel)

	ExpectConnectedEvent(t, wildcard, "", subscribeSuccessChannel,
		subscribeErrorChannel)

	go func() {
		select {
		case message := <-subscribeSuccessChannel:
			var msg []interface{}

			err := json.Unmarshal(message, &msg)
			if err != nil {
				assert.Fail(err.Error())
			}

			assert.Contains(string(message), "hey")
			assert.Equal(channel, msg[2].(string))
			assert.Equal(wildcard, msg[3].(string))
			await <- true
		case err := <-subscribeErrorChannel:
			assert.Fail(string(err))
			await <- false
		case <-messaging.SubscribeTimeout():
			assert.Fail("Subscribe timeout")
			await <- false
		}
	}()

	go pubnubInstance.Publish(channel, "hey", successChannel, errorChannel)
	select {
	case <-successChannel:
	case err := <-errorChannel:
		assert.Fail(string(err))
	}

	<-await

	go pubnubInstance.Unsubscribe(wildcard, successChannel, errorChannel)
	ExpectUnsubscribedEvent(t, wildcard, "", successChannel, errorChannel)

	// pubnubInstance.CloseExistingConnection()
}

// TODO test presence

// TestWildcardSubscribeEnd prints a message on the screen to mark the end of
// subscribe tests.
// PrintTestMessage is defined in the common.go file.
func TestWildcardSubscribeEnd(t *testing.T) {
	PrintTestMessage("==========Wildcard Subscribe tests end==========")
}
