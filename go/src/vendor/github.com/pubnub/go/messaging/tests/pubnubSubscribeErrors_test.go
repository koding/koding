// Package tests has the unit tests of package messaging.
// pubnubSubscribe_test.go contains the tests related to the Subscribe requests on pubnub Api
package tests

import (
	"fmt"
	"testing"

	"github.com/pubnub/go/messaging"
	"github.com/stretchr/testify/assert"
)

// TestSubscribeStart prints a message on the screen to mark the beginning of
// subscribe tests.
// PrintTestMessage is defined in the common.go file.
func TestSubscribeErrorsStart(t *testing.T) {
	PrintTestMessage("==========Subscribe errors tests start==========")
}

func TestSubscriptionToNotPermittedChannel(t *testing.T) {
	assert := assert.New(t)

	stop, _ := NewVCRBoth(
		"fixtures/subscribeErrors/chnnelNotPermitted", []string{"uuid"})
	defer stop()

	channel := "Channel_NotPermitted"
	uuid := "UUID_NotPermitted"
	pubnubInstance := messaging.NewPubnub(PubNoPermissionsKey,
		SubNoPermissionsKey, "", "", false, uuid, CreateLoggerForTests())

	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	unsubscribeSuccessChannel := make(chan []byte)
	unsubscribeErrorChannel := make(chan []byte)

	go pubnubInstance.Subscribe(channel, "", successChannel, false, errorChannel)
	select {
	case resp := <-successChannel:
		assert.Fail("Success response while error is expected", string(resp))
	case er := <-errorChannel:
		err := string(er)

		assert.Contains(err, "Access Manager")
		assert.Contains(err, "Forbidden")
		assert.Contains(err, "channels")
		assert.Contains(err, "403")
		assert.Contains(err, channel)
	case <-timeouts(3):
		assert.Fail("Subscribe timeout 3s")
	}

	go pubnubInstance.Unsubscribe(channel, unsubscribeSuccessChannel, unsubscribeErrorChannel)
	select {
	case ev := <-unsubscribeSuccessChannel:
		event := string(ev)

		assert.Contains(event, channel)
	case err := <-unsubscribeErrorChannel:
		assert.Fail("Error while waiting for a unsubscribed event", err)
	case <-timeout():
		assert.Fail("timeout")
	}

	select {
	case ev := <-unsubscribeSuccessChannel:
		assert.Fail("Success response  while waiting for an error", string(ev))
	case er := <-unsubscribeErrorChannel:
		err := string(er)

		assert.Contains(err, channel)
		assert.Contains(err, "Access Manager")
		assert.Contains(err, "Forbidden")
		assert.Contains(err, "403")
		assert.Contains(err, "channels")
	case <-timeout():
		assert.Fail("timeout")
	}

	pubnubInstance.CloseExistingConnection()
}

// TestSubscriptionAlreadySubscribed sends out a subscribe request to a pubnub channel
// and when connected sends out another subscribe request. The response for the second
func TestSubscriptionAlreadySubscribed(t *testing.T) {
	assert := assert.New(t)

	stop, _ := NewVCRBoth("fixtures/subscribe/alreadySubscribed", []string{"uuid"})
	defer stop()

	channel := "Channel_AlreadySubscribed"
	uuid := "UUID_AlreadySubscribed"
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, uuid, CreateLoggerForTests())

	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	successChannel2 := make(chan []byte)
	errorChannel2 := make(chan []byte)
	unsubscribeSuccessChannel := make(chan []byte)
	unsubscribeErrorChannel := make(chan []byte)

	go pubnubInstance.Subscribe(channel, "", successChannel, false, errorChannel)
	select {
	case resp := <-successChannel:
		response := fmt.Sprintf("%s", resp)
		if response != "[]" {
			message := "'" + channel + "' connected"
			assert.Contains(response, message)
		}
	case err := <-errorChannel:
		if !IsConnectionRefusedError(err) {
			assert.Fail(string(err))
		}
	case <-timeouts(3):
		assert.Fail("Subscribe timeout 3s")
	}

	go pubnubInstance.Subscribe(channel, "", successChannel2, false, errorChannel2)
	select {
	case resp := <-successChannel2:
		assert.Fail(fmt.Sprintf(
			"Receive message on success channel, while expecting error: %s",
			string(resp)))
	case err := <-errorChannel2:
		assert.Contains(string(err), "already subscribe")
		assert.Contains(string(err), channel)
	case <-timeouts(3):
		assert.Fail("Subscribe timeout 3s")
	}

	go func() {
		successChannel := make(chan []byte)
		errorChannel := make(chan []byte)
		go pubnubInstance.Publish(channel, "blah", successChannel, errorChannel)
		select {
		case <-successChannel:
		case err := <-errorChannel:
			fmt.Println("Publish error", err)
		case <-timeouts(4):
			fmt.Println("Publish timeout")
		}
	}()

	await := make(chan bool)

	go func() {
		select {
		case resp := <-successChannel:
			assert.Contains(string(resp), "blah")
		case err := <-errorChannel:
			if !IsConnectionRefusedError(err) {
				assert.Fail(string(err))
			}
		case <-timeouts(5):
			assert.Fail("Subscribe timeout 5s")
		}

		await <- true
	}()

	go func() {
		select {
		case resp := <-successChannel2:
			assert.Fail("Success un 2nd subscribe channel", string(resp))
		case err := <-errorChannel2:
			assert.Fail("Error un 2nd subscribe channel", string(err))
		}

		await <- true
	}()

	<-await

	go pubnubInstance.Unsubscribe(channel, unsubscribeSuccessChannel, unsubscribeErrorChannel)
	ExpectUnsubscribedEvent(t, channel, "", unsubscribeSuccessChannel, unsubscribeErrorChannel)
}

// TestResumeOnReconnectFalse upon reconnect, it should use a 0 (zero) timetoken.
// This has the effect of continuing from “this moment onward”.
// Any messages received since the previous timeout or network error are skipped
func xTestResumeOnReconnectFalse(t *testing.T) {
	messaging.SetResumeOnReconnect(false)
	messaging.SetSubscribeTimeout(3)

	r := GenRandom()
	assert := assert.New(t)
	pubnubChannel := fmt.Sprintf("testChannel_subror_%d", r.Intn(20))
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, "", CreateLoggerForTests())

	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	unsubscribeSuccessChannel := make(chan []byte)
	unsubscribeErrorChannel := make(chan []byte)

	go pubnubInstance.Subscribe(pubnubChannel, "", successChannel, false, errorChannel)
	for {
		select {
		case <-successChannel:
		case value := <-errorChannel:
			if string(value) != "[]" {
				newPubnubTest := &messaging.PubnubUnitTest{}

				assert.Equal("0", newPubnubTest.GetSentTimeToken(pubnubInstance))
			}
			return
		case <-messaging.Timeouts(20):
			assert.Fail("Subscribe timeout")
			return
		}
	}

	go pubnubInstance.Unsubscribe(pubnubChannel, unsubscribeSuccessChannel, unsubscribeErrorChannel)
	ExpectUnsubscribedEvent(t, pubnubChannel, "", unsubscribeSuccessChannel, unsubscribeErrorChannel)

	messaging.SetSubscribeTimeout(310)
}

// TestResumeOnReconnectTrue upon reconnect, it should use the last successfully retrieved timetoken.
// This has the effect of continuing, or “catching up” to missed traffic.
func TestResumeOnReconnectTrue(t *testing.T) {
	messaging.SetResumeOnReconnect(true)
	messaging.SetSubscribeTimeout(3)

	r := GenRandom()
	assert := assert.New(t)
	pubnubChannel := fmt.Sprintf("testChannel_subror_%d", r.Intn(20))
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, "", CreateLoggerForTests())

	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	unsubscribeSuccessChannel := make(chan []byte)
	unsubscribeErrorChannel := make(chan []byte)

	go pubnubInstance.Subscribe(pubnubChannel, "", successChannel, false, errorChannel)
	for {
		select {
		case <-successChannel:
		case value := <-errorChannel:
			if string(value) != "[]" {
				newPubnubTest := &messaging.PubnubUnitTest{}

				assert.Equal(newPubnubTest.GetTimeToken(pubnubInstance), newPubnubTest.GetSentTimeToken(pubnubInstance))
			}
			return
		case <-messaging.Timeouts(20):
			assert.Fail("Subscribe timeout")
			return
		}
	}

	go pubnubInstance.Unsubscribe(pubnubChannel, unsubscribeSuccessChannel, unsubscribeErrorChannel)
	ExpectUnsubscribedEvent(t, pubnubChannel, "", unsubscribeSuccessChannel, unsubscribeErrorChannel)

	messaging.SetSubscribeTimeout(310)
}

func TestGroupSubscriptionAlreadySubscribed(t *testing.T) {
	assert := assert.New(t)

	stop, sleep := NewVCRBoth(
		"fixtures/groups/alreadySubscribed", []string{"uuid"})
	defer stop()

	group := "Group_AlreadySubscribed"
	uuid := "UUID_AlreadySubscribed"
	pubnub := messaging.NewPubnub(PubKey, SubKey, "", "", false, uuid, CreateLoggerForTests())

	createChannelGroups(pubnub, []string{group})
	defer removeChannelGroups(pubnub, []string{group})

	sleep(2)

	subscribeSuccessChannel := make(chan []byte)
	subscribeErrorChannel := make(chan []byte)
	subscribeSuccessChannel2 := make(chan []byte)
	subscribeErrorChannel2 := make(chan []byte)
	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)

	go pubnub.ChannelGroupSubscribe(group,
		subscribeSuccessChannel, subscribeErrorChannel)
	ExpectConnectedEvent(t, "", group, subscribeSuccessChannel, subscribeErrorChannel)

	go pubnub.ChannelGroupSubscribe(group,
		subscribeSuccessChannel2, subscribeErrorChannel2)
	select {
	case <-subscribeSuccessChannel2:
		assert.Fail("Received success message while expecting error")
	case err := <-subscribeErrorChannel2:
		assert.Contains(string(err), "Subscription to channel group")
		assert.Contains(string(err), "already subscribed")
	}

	go pubnub.ChannelGroupUnsubscribe(group, successChannel, errorChannel)
	ExpectUnsubscribedEvent(t, "", group, successChannel, errorChannel)
}

func TestGroupSubscriptionNotSubscribed(t *testing.T) {
	assert := assert.New(t)

	stop, sleep := NewVCRNonSubscribe(
		"fixtures/groups/notSubscribed", []string{"uuid"})
	defer stop()

	group := "Group_NotSubscribed"
	uuid := "UUID_NotSubscribed"
	pubnub := messaging.NewPubnub(PubKey, SubKey, "", "", false, uuid, CreateLoggerForTests())

	createChannelGroups(pubnub, []string{group})
	defer removeChannelGroups(pubnub, []string{group})

	sleep(2)

	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)

	go pubnub.ChannelGroupUnsubscribe(group, successChannel, errorChannel)
	select {
	case response := <-successChannel:
		assert.Fail("Received success message while expecting error", string(response))
	case err := <-errorChannel:
		assert.Contains(string(err), "Subscription to channel group")
		assert.Contains(string(err), "not subscribed")
	}

	pubnub.CloseExistingConnection()
}

func TestGroupSubscriptionToNotExistingChannelGroup(t *testing.T) {
	assert := assert.New(t)

	stop, sleep := NewVCRBoth(
		"fixtures/groups/notExistingCG", []string{"uuid"})
	defer stop()

	group := "Group_NotExistingCG"
	uuid := "UUID_NotExistingCG"
	pubnub := messaging.NewPubnub(PubKey, SubKey, "", "", false, uuid, CreateLoggerForTests())

	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	unsubscribeSuccessChannel := make(chan []byte)
	unsubscribeErrorChannel := make(chan []byte)

	removeChannelGroups(pubnub, []string{group})

	sleep(2)

	go pubnub.ChannelGroupSubscribe(group, successChannel, errorChannel)
	select {
	case response := <-successChannel:
		assert.Fail("Received success message while expecting error", string(response))
	case err := <-errorChannel:
		assert.Contains(string(err), "Channel group or groups result in empty subscription set")
		assert.Contains(string(err), group)
	}

	go pubnub.ChannelGroupUnsubscribe(group, unsubscribeSuccessChannel, unsubscribeErrorChannel)
	ExpectUnsubscribedEvent(t, "", group, unsubscribeSuccessChannel,
		unsubscribeErrorChannel)
}

// TestSubscribeEnd prints a message on the screen to mark the end of
// subscribe tests.
// PrintTestMessage is defined in the common.go file.
func TestSubscribeErrorsEnd(t *testing.T) {
	PrintTestMessage("==========Subscribe errors tests end==========")
}
