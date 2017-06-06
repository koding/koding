// Package tests has the unit tests of package messaging.
// pubnubUnsubscribe_test.go contains the tests related to the Unsubscribe requests on pubnub Api
package tests

import (
	"encoding/json"
	"fmt"
	"testing"
	"time"

	"github.com/pubnub/go/messaging"
	"github.com/stretchr/testify/assert"
)

// TestUnsubscribeStart prints a message on the screen to mark the beginning of
// unsubscribe tests.
// PrintTestMessage is defined in the common.go file.
func TestUnsubscribeStart(t *testing.T) {
	PrintTestMessage("==========Unsubscribe tests start==========")
}

// TestUnsubscribeNotSubscribed will try to unsubscribe a non subscribed pubnub channel.
// The response should contain 'not subscribed'
func TestUnsubscribeNotSubscribed(t *testing.T) {
	assert := assert.New(t)
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, "", CreateLoggerForTests())

	currentTime := time.Now()
	channel := "testChannel" + currentTime.Format("20060102150405")

	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)

	go pubnubInstance.Unsubscribe(channel, successChannel, errorChannel)
	select {
	case <-successChannel:
		assert.Fail("Success unsubscribe response while expecting an error")
	case err := <-errorChannel:
		assert.Contains(string(err), "not subscribed")
		assert.Contains(string(err), channel)
	case <-timeout():
		assert.Fail("Unsubscribe request timeout")
	}
}

// TestUnsubscribe will subscribe to a pubnub channel and then send an unsubscribe request
// The response should contain 'unsubscribed'
func TestUnsubscribeChannel(t *testing.T) {
	assert := assert.New(t)

	stop, sleep := NewVCRBoth(
		"fixtures/unsubscribe/channel", []string{"uuid"})
	defer stop()

	channel := "Channel_UnsubscribeChannel"
	uuid := "UUID_UnsubscribeChannel"
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, uuid, CreateLoggerForTests())

	subscribeSuccessChannel := make(chan []byte)
	subscribeErrorChannel := make(chan []byte)
	unSubscribeSuccessChannel := make(chan []byte)
	unSubscribeErrorChannel := make(chan []byte)

	go pubnubInstance.Subscribe(channel, "", subscribeSuccessChannel,
		false, subscribeErrorChannel)
	select {
	case msg := <-subscribeSuccessChannel:
		val := string(msg)
		assert.Equal(val, fmt.Sprintf(
			"[1, \"Subscription to channel '%s' connected\", \"%s\"]",
			channel, channel))
	case err := <-subscribeErrorChannel:
		assert.Fail(string(err))
	}

	sleep(2)

	go pubnubInstance.Unsubscribe(channel, unSubscribeSuccessChannel,
		unSubscribeErrorChannel)
	select {
	case msg := <-unSubscribeSuccessChannel:
		val := string(msg)
		assert.Equal(val, fmt.Sprintf(
			"[1, \"Subscription to channel '%s' unsubscribed\", \"%s\"]",
			channel, channel))
	case err := <-unSubscribeErrorChannel:
		assert.Fail(string(err))
	}

	select {
	case ev := <-unSubscribeSuccessChannel:
		var event messaging.PresenceResonse

		err := json.Unmarshal(ev, &event)
		if err != nil {
			assert.Fail(err.Error())
		}

		assert.Equal("leave", event.Action)
		assert.Equal(200, event.Status)
	case err := <-unSubscribeErrorChannel:
		assert.Fail(string(err))
	}
}

// TestUnsubscribeEnd prints a message on the screen to mark the end of
// unsubscribe tests.
// PrintTestMessage is defined in the common.go file.
func TestUnsubscribeEnd(t *testing.T) {
	PrintTestMessage("==========Unsubscribe tests end==========")
}
