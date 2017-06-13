// Package tests has the unit tests of package messaging.
// pubnubDetailedHistory_test.go contains the tests related to the History requests on pubnub Api
package tests

import (
	"encoding/json"
	"fmt"
	"strconv"
	"testing"

	"github.com/pubnub/go/messaging"
	"github.com/stretchr/testify/assert"
)

// TestDetailedHistoryStart prints a message on the screen to mark the beginning of
// detailed history tests.
// PrintTestMessage is defined in the common.go file.
func TestDetailedHistoryStart(t *testing.T) {
	PrintTestMessage("==========DetailedHistory tests start==========")
}

// TestDetailedHistoryFor10Messages publish's 10 unencrypted messages to a pubnub channel, and after that
// calls the history method of the messaging package to fetch last 10 messages. These received
// messages are compared to the messages sent and if all match test is successful.
func TestDetailedHistoryFor10Messages(t *testing.T) {
	testName := "historyFor10Messages"
	DetailedHistoryFor10Messages(t, "", testName)
}

// TestDetailedHistoryFor10EncryptedMessages publish's 10 encrypted messages to a pubnub channel, and after that
// calls the history method of the messaging package to fetch last 10 messages. These received
// messages are compared to the messages sent and if all match test is successful.
func TestDetailedHistoryFor10EncryptedMessages(t *testing.T) {
	testName := "historyFor10EncryptedMessages"
	DetailedHistoryFor10Messages(t, "enigma", testName)
}

// DetailedHistoryFor10Messages is a common method used by both TestDetailedHistoryFor10EncryptedMessages
// and TestDetailedHistoryFor10Messages to publish's 10 messages to a pubnub channel, and after that
// call the history method of the messaging package to fetch last 10 messages. These received
// messages are compared to the messages sent and if all match test is successful.
func DetailedHistoryFor10Messages(t *testing.T, cipherKey string, testName string) {
	assert := assert.New(t)

	numberOfMessages := 10
	startMessagesFrom := 0

	stop, sleep := NewVCRNonSubscribe(fmt.Sprintf("fixtures/history/%s", testName),
		[]string{"uuid"})
	defer stop()

	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", cipherKey, false, "", CreateLoggerForTests())

	message := "Test Message "
	channel := testName

	messagesSent := PublishMessages(pubnubInstance, channel, t, startMessagesFrom,
		numberOfMessages, message, sleep)

	assert.True(messagesSent)

	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)

	go pubnubInstance.History(channel, numberOfMessages, 0, 0, false, false,
		successChannel, errorChannel)
	select {
	case value := <-successChannel:
		data, _, _, err := pubnubInstance.ParseJSON(value, cipherKey)
		if err != nil {
			assert.Fail(err.Error())
		}

		var arr []string
		err = json.Unmarshal([]byte(data), &arr)
		if err != nil {
			assert.Fail(err.Error())
		}

		messagesReceived := 0

		assert.Len(arr, numberOfMessages)

		for i := 0; i < len(arr); i++ {
			if arr[i] == message+strconv.Itoa(startMessagesFrom+i) {
				messagesReceived++
			}
		}

		assert.Equal(numberOfMessages, messagesReceived)
	case err := <-errorChannel:
		assert.Fail(string(err))
	}
}

// TestDetailedHistoryParamsFor10Messages publish's 10 unencrypted messages
// to a pubnub channel, and after that calls the history method of the messaging package to fetch
// last 10 messages with time parameters between which the messages were sent. These received
// messages are compared to the messages sent and if all match test is successful.
func TestDetailedHistoryParamsFor10Messages(t *testing.T) {
	testName := "historyParamsFor10Messages"
	DetailedHistoryParamsFor10Messages(t, "", "", testName)
}

// TestDetailedHistoryParamsFor10EncryptedMessages publish's 10 encrypted messages
// to a pubnub channel, and after that calls the history method of the messaging package to fetch
// last 10 messages with time parameters between which the messages were sent. These received
// messages are compared to the messages sent and if all match test is successful.
func TestDetailedHistoryParamsFor10EncryptedMessages(t *testing.T) {
	testName := "historyParamsFor10EncryptedMessages"
	DetailedHistoryParamsFor10Messages(t, "enigma", "", testName)
}

// DetailedHistoryFor10Messages is a common method used by both TestDetailedHistoryFor10EncryptedMessages
// and TestDetailedHistoryFor10Messages to publish's 10 messages to a pubnub channel, and after that
// call the history method of the messaging package to fetch last 10 messages with time parameters
// between which the messages were sent. These received message is compared to the messages sent and
// if all match test is successful.
func DetailedHistoryParamsFor10Messages(t *testing.T, cipherKey string, secretKey string, testName string) {
	assert := assert.New(t)
	numberOfMessages := 5

	stop, sleep := NewVCRNonSubscribe(fmt.Sprintf(
		"fixtures/history/%s", testName), []string{})
	defer stop()

	sleep(5)

	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", cipherKey, false,
		fmt.Sprintf("uuid_%s", testName), CreateLoggerForTests())

	message := "Test Message "
	channel := testName

	startTime := GetServerTime("start")
	startMessagesFrom := 0
	messagesSent := PublishMessages(pubnubInstance, channel, t,
		startMessagesFrom, numberOfMessages, message, sleep)
	midTime := GetServerTime("mid")
	startMessagesFrom = 5
	messagesSent2 := PublishMessages(pubnubInstance, channel, t,
		startMessagesFrom, numberOfMessages, message, sleep)
	endTime := GetServerTime("end")
	startMessagesFrom = 0

	assert.True(messagesSent, "Error while sending a first bunch of messages")
	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)

	go pubnubInstance.History(channel, numberOfMessages, startTime, midTime,
		false, false, successChannel, errorChannel)
	select {
	case value := <-successChannel:
		data, _, _, err := pubnubInstance.ParseJSON(value, cipherKey)
		if err != nil {
			assert.Fail(err.Error())
		}

		var arr []string
		err = json.Unmarshal([]byte(data), &arr)
		if err != nil {
			assert.Fail(err.Error())
		}

		messagesReceived := 0

		assert.Len(arr, numberOfMessages)

		for i := 0; i < len(arr); i++ {
			if arr[i] == message+strconv.Itoa(startMessagesFrom+i) {
				messagesReceived++
			}
		}

		assert.Equal(numberOfMessages, messagesReceived)
	case err := <-errorChannel:
		assert.Fail(string(err))
	}

	startMessagesFrom = 5

	assert.True(messagesSent2, "Error while sending a second bunch of messages")

	go pubnubInstance.History(channel, numberOfMessages, midTime, endTime, false,
		false, successChannel, errorChannel)
	select {
	case value := <-successChannel:
		data, _, _, err := pubnubInstance.ParseJSON(value, cipherKey)
		if err != nil {
			assert.Fail(err.Error())
		}

		var arr []string
		err = json.Unmarshal([]byte(data), &arr)
		if err != nil {
			assert.Fail(err.Error())
		}

		messagesReceived := 0

		assert.Len(arr, numberOfMessages)

		for i := 0; i < len(arr); i++ {
			if arr[i] == message+strconv.Itoa(startMessagesFrom+i) {
				messagesReceived++
			}
		}

		assert.Equal(numberOfMessages, messagesReceived)
	case err := <-errorChannel:
		assert.Fail(string(err))
	}
}

// PublishMessages calls the publish method of messaging package numberOfMessages times
// and appends the count with the message to distinguish from the others.
//
// Parameters:
// pubnubInstance: a reference of *messaging.Pubnub,
// channel: the pubnub channel to publish the messages,
// t: a reference to *testing.T,
// startMessagesFrom: the message identifer,
// numberOfMessages: number of messages to send,
// message: message to send.
//
// returns a bool if the publish of all messages is successful.
func PublishMessages(pubnubInstance *messaging.Pubnub, channel string,
	t *testing.T, startMessagesFrom int, numberOfMessages int,
	message string, sleep func(int)) bool {

	assert := assert.New(t)
	messagesReceived := 0
	messageToSend := ""
	tOut := messaging.GetNonSubscribeTimeout()
	messaging.SetNonSubscribeTimeout(30)

	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)

	for i := startMessagesFrom; i < startMessagesFrom+numberOfMessages; i++ {
		messageToSend = message + strconv.Itoa(i)

		go pubnubInstance.Publish(channel, messageToSend, successChannel, errorChannel)
		select {
		case <-successChannel:
			messagesReceived++
		case err := <-errorChannel:
			assert.Fail("Failed to get channel list", string(err))
		case <-messaging.Timeout():
			assert.Fail("WhereNow timeout")
		}
	}

	sleep(3)
	if messagesReceived == numberOfMessages {
		return true
	}

	messaging.SetNonSubscribeTimeout(tOut)

	return false
}

func TestHistoryWithTimetoken(t *testing.T) {
	assert := assert.New(t)

	stop, sleep := NewVCRNonSubscribe(fmt.Sprintf(
		"fixtures/history/withTimetoken"), []string{})
	defer stop()

	count := 10
	uuid := "UUID_HistoryWithTT"
	channel := "Channel_HistoryWithTT"
	message := "Test TT Message "
	pubnub := messaging.NewPubnub(PubKey, SubKey, "", "", false, uuid, CreateLoggerForTests())

	PublishMessages(pubnub, channel, t, 0, count, message, sleep)
	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)

	go pubnub.History(channel, count, 0, 0, false, true, successChannel, errorChannel)
	select {
	case value := <-successChannel:
		data, _, _, err := pubnub.ParseJSON(value, "")
		if err != nil {
			assert.Fail(err.Error())
		}

		var arr []map[string]interface{}
		err = json.Unmarshal([]byte(data), &arr)
		if err != nil {
			assert.Fail(err.Error())
		}

		messagesReceived := 0

		assert.Len(arr, count)

		for i := 0; i < len(arr); i++ {
			if len(arr[i]["message"].(string)) > 0 && arr[i]["timetoken"].(float64) > 0 {
				messagesReceived++
			}
		}

		assert.Equal(count, messagesReceived)
	case err := <-errorChannel:
		assert.Fail(string(err))
	}
}

// TestDetailedHistoryEnd prints a message on the screen to mark the end of
// detailed history tests.
// PrintTestMessage is defined in the common.go file.
func TestDetailedHistoryEnd(t *testing.T) {
	PrintTestMessage("==========DetailedHistory tests end==========")
}
