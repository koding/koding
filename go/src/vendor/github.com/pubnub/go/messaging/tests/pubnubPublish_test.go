// Package tests has the unit tests of package messaging.
// pubnubPublish_test.go contains the tests related to the publish requests on pubnub Api
package tests

import (
	"encoding/json"
	//"fmt"
	"github.com/pubnub/go/messaging"
	"github.com/stretchr/testify/assert"
	//"log"
	//"os"
	//"strings"
	"testing"
)

// TestPublishStart prints a message on the screen to mark the beginning of
// publish tests.
// PrintTestMessage is defined in the common.go file.
func TestPublishStart(t *testing.T) {
	PrintTestMessage("==========Publish tests start==========")
}

// TestNullMessage sends out a null message to a pubnub channel. The response should
// be an "Invalid Message".
func TestNullMessage(t *testing.T) {
	assert := assert.New(t)
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, "", CreateLoggerForTests())
	channel := "nullMessage"
	var message interface{}
	message = nil

	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)

	go pubnubInstance.Publish(channel, message, successChannel, errorChannel)
	select {
	case msg := <-successChannel:
		assert.Fail("Response on success channel while expecting an error", string(msg))
	case err := <-errorChannel:
		assert.Contains(string(err), "Invalid Message")
	case <-timeout():
		assert.Fail("Publish timeout")
	}
}

// TestSuccessCodeAndInfo sends out a message to the pubnub channel
func TestSuccessCodeAndInfo(t *testing.T) {
	assert := assert.New(t)

	stop, _ := NewVCRNonSubscribe("fixtures/publish/successCodeAndInfo",
		[]string{"uuid"})
	defer stop()

	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, "", CreateLoggerForTests())
	channel := "successCodeAndInfo"
	message := "Pubnub API Usage Example"

	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)

	go pubnubInstance.Publish(channel, message, successChannel, errorChannel)
	select {
	case msg := <-successChannel:
		assert.Contains(string(msg), "1,")
		assert.Contains(string(msg), "\"Sent\",")
	case err := <-errorChannel:
		assert.Fail(string(err))
	case <-timeout():
		assert.Fail("Publish timeout")
	}
}

// TestSuccessCodeAndInfoWithEncryption sends out an encrypted
// message to the pubnub channel
func TestSuccessCodeAndInfoWithEncryption(t *testing.T) {
	assert := assert.New(t)

	stop, _ := NewVCRNonSubscribe(
		"fixtures/publish/successCodeAndInfoWithEncryption", []string{"uuid"})
	defer stop()

	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "enigma", false, "", CreateLoggerForTests())
	channel := "successCodeAndInfo"
	message := "Pubnub API Usage Example"

	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)

	go pubnubInstance.Publish(channel, message, successChannel, errorChannel)
	select {
	case msg := <-successChannel:
		assert.Contains(string(msg), "1,")
		assert.Contains(string(msg), "\"Sent\",")
	case err := <-errorChannel:
		assert.Fail(string(err))
	case <-timeout():
		assert.Fail("Publish timeout")
	}
}

// TestSuccessCodeAndInfoForComplexMessage sends out a complex message to the pubnub channel
func TestSuccessCodeAndInfoForComplexMessage(t *testing.T) {
	assert := assert.New(t)

	stop, _ := NewVCRNonSubscribe(
		"fixtures/publish/successCodeAndInfoForComplexMessage", []string{"uuid"})
	defer stop()

	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, "", CreateLoggerForTests())
	channel := "successCodeAndInfoForComplexMessage"

	customStruct := CustomStruct{
		Foo: "hi!",
		Bar: []int{1, 2, 3, 4, 5},
	}

	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)

	go pubnubInstance.Publish(channel, customStruct, successChannel, errorChannel)
	select {
	case msg := <-successChannel:
		assert.Contains(string(msg), "1,")
		assert.Contains(string(msg), "\"Sent\",")
	case err := <-errorChannel:
		assert.Fail(string(err))
	case <-timeout():
		assert.Fail("Publish timeout")
	}
}

// TestFire sends out a complex message to the pubnub channel
func TestFire(t *testing.T) {
	assert := assert.New(t)

	stop, _ := NewVCRNonSubscribe(
		"fixtures/publish/fire", []string{"uuid"})
	defer stop()
	//messaging.SetLogOutput(os.Stdout)
	//messaging.LoggingEnabled(true)

	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, "", CreateLoggerForTests())
	channel := "fireChannel"

	message := "fireTest"
	await := make(chan bool)

	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)

	go pubnubInstance.Fire(channel, message, false, successChannel, errorChannel)
	go func() {
		select {
		case msg := <-successChannel:
			assert.Contains(string(msg), "1,")
			assert.Contains(string(msg), "\"Sent\",")
			await <- true
		case err := <-errorChannel:
			assert.Fail(string(err))
			await <- false
		case <-timeout():
			assert.Fail("Publish timeout")
			await <- false
		}
	}()

	<-await

	successChannelHis := make(chan []byte)
	errorChannelHis := make(chan []byte)

	go pubnubInstance.History(channel, 1, 0, 0, false, false,
		successChannelHis, errorChannelHis)
	select {
	case value := <-successChannelHis:
		data, _, _, err := pubnubInstance.ParseJSON(value, "")
		if err != nil {
			assert.Fail(err.Error())
		}

		assert.NotContains(data, message)
	case err := <-errorChannelHis:
		assert.Fail(string(err))
	}
}

// TestPublishWithMessageTTL sends out a complex message to the pubnub channel
func TestPublishWithMessageTTL(t *testing.T) {
	assert := assert.New(t)

	stop, _ := NewVCRNonSubscribe(
		"fixtures/publish/publishWithReplicateAndTTL", []string{"uuid"})
	defer stop()
	//messaging.SetLogOutput(os.Stdout)
	//messaging.LoggingEnabled(true)

	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, "", CreateLoggerForTests())
	channel := "publishWithReplicate"

	message := "publishWithReplicate"
	await := make(chan bool)

	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)

	go pubnubInstance.PublishExtendedWithMetaReplicateAndTTL(channel, message, nil, true, false, false, 10, successChannel, errorChannel)
	go func() {
		select {
		case msg := <-successChannel:
			assert.Contains(string(msg), "1,")
			assert.Contains(string(msg), "\"Sent\",")
			await <- true
		case err := <-errorChannel:
			assert.Fail(string(err))
			await <- false
		case <-timeout():
			assert.Fail("Publish timeout")
			await <- false
		}
	}()

	<-await

	successChannelHis := make(chan []byte)
	errorChannelHis := make(chan []byte)

	go pubnubInstance.History(channel, 1, 0, 0, false, false,
		successChannelHis, errorChannelHis)
	select {
	case value := <-successChannelHis:
		data, _, _, err := pubnubInstance.ParseJSON(value, "")
		if err != nil {
			assert.Fail(err.Error())
		}

		assert.Contains(data, message)
	case err := <-errorChannelHis:
		assert.Fail(string(err))
	}
}

// TestPublishWithReplicate sends out a complex message to the pubnub channel
func TestPublishWithReplicate(t *testing.T) {
	assert := assert.New(t)

	stop, _ := NewVCRNonSubscribe(
		"fixtures/publish/publishWithReplicate", []string{"uuid"})
	defer stop()
	//messaging.SetLogOutput(os.Stdout)
	//messaging.LoggingEnabled(true)

	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, "", CreateLoggerForTests())
	channel := "publishWithReplicate"

	message := "publishWithReplicate"
	await := make(chan bool)

	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)

	go pubnubInstance.PublishExtendedWithMetaAndReplicate(channel, message, nil, true, false, false, successChannel, errorChannel)
	go func() {
		select {
		case msg := <-successChannel:
			assert.Contains(string(msg), "1,")
			assert.Contains(string(msg), "\"Sent\",")
			await <- true
		case err := <-errorChannel:
			assert.Fail(string(err))
			await <- false
		case <-timeout():
			assert.Fail("Publish timeout")
			await <- false
		}
	}()

	<-await

	successChannelHis := make(chan []byte)
	errorChannelHis := make(chan []byte)

	go pubnubInstance.History(channel, 1, 0, 0, false, false,
		successChannelHis, errorChannelHis)
	select {
	case value := <-successChannelHis:
		data, _, _, err := pubnubInstance.ParseJSON(value, "")
		if err != nil {
			assert.Fail(err.Error())
		}

		assert.Contains(data, message)
	case err := <-errorChannelHis:
		assert.Fail(string(err))
	}
}

// TestSuccessCodeAndInfoForComplexMessage2 sends out a complex message to the pubnub channel
func TestSuccessCodeAndInfoForComplexMessage2(t *testing.T) {
	assert := assert.New(t)

	stop, _ := NewVCRNonSubscribe(
		"fixtures/publish/successCodeAndInfoForComplexMessage2", []string{"uuid"})
	defer stop()

	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, "", CreateLoggerForTests())
	channel := "successCodeAndInfoForComplexMessage2"

	customComplexMessage := InitComplexMessage()

	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)

	go pubnubInstance.Publish(channel, customComplexMessage,
		successChannel, errorChannel)
	select {
	case msg := <-successChannel:
		assert.Contains(string(msg), "1,")
		assert.Contains(string(msg), "\"Sent\",")
	case err := <-errorChannel:
		assert.Fail(string(err))
	case <-timeout():
		assert.Fail("Publish timeout")
	}
}

// TestSuccessCodeAndInfoForComplexMessage2WithEncryption sends out an
// encypted complex message to the pubnub channel
func TestSuccessCodeAndInfoForComplexMessage2WithEncryption(t *testing.T) {
	assert := assert.New(t)

	stop, _ := NewVCRNonSubscribe(
		"fixtures/publish/successCodeAndInfoForComplexMessage2WithEncryption",
		[]string{"uuid"})
	defer stop()

	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "enigma", false, "", CreateLoggerForTests())
	channel := "successCodeAndInfoForComplexMessage2WithEncryption"

	customComplexMessage := InitComplexMessage()

	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)

	go pubnubInstance.Publish(channel, customComplexMessage,
		successChannel, errorChannel)
	select {
	case msg := <-successChannel:
		assert.Contains(string(msg), "1,")
		assert.Contains(string(msg), "\"Sent\",")
	case err := <-errorChannel:
		assert.Fail(string(err))
	case <-timeout():
		assert.Fail("Publish timeout")
	}
}

func TestPublishStringWithSerialization(t *testing.T) {
	assert := assert.New(t)

	stop, _ := NewVCRBoth(
		"fixtures/publish/publishStringWithSerialization",
		[]string{"uuid"})
	defer stop()

	channel := "Channel_PublishStringWithSerialization"
	uuid := "UUID_PublishStringWithSerialization"
	//messaging.SetLogOutput(os.Stdout)
	//messaging.LoggingEnabled(true)
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, uuid, CreateLoggerForTests())
	messageToPost := "{\"name\": \"Alex\", \"age\": \"123\"}"

	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)

	subscribeSuccessChannel := make(chan []byte)
	subscribeErrorChannel := make(chan []byte)

	unsubscribeSuccessChannel := make(chan []byte)
	unsubscribeErrorChannel := make(chan []byte)

	await := make(chan bool)
	//log.SetOutput(os.Stdout)
	//log.SetFlags(log.Ldate | log.Ltime | log.Lmicroseconds)
	//log.Printf("subscribing")

	go pubnubInstance.Subscribe(channel, "", subscribeSuccessChannel, false,
		subscribeErrorChannel)
	ExpectConnectedEvent(t, channel, "", subscribeSuccessChannel,
		subscribeErrorChannel)
	//log.Printf("connected")
	go func() {
		//log.Printf("waiting")
		select {
		case message := <-subscribeSuccessChannel:
			var response []interface{}
			//var msgs []interface{}
			var err error
			//log.Printf("message %s", message)
			/*if strings.Contains(string(message), fmt.Sprintf("'%s' connected", channel)) {
				log.Printf("connected %s", channel)

			} else {*/
			err = json.Unmarshal(message, &response)
			if err != nil {
				assert.Fail(err.Error())
			}

			switch t := response[0].(type) {
			case []interface{}:
				var messageToPostMap map[string]interface{}

				//msgs = response[0].([]interface{})
				err := json.Unmarshal([]byte(messageToPost), &messageToPostMap)
				if err != nil {
					assert.Fail(err.Error())
				}

				assert.Contains(messageToPost, messageToPostMap["age"])
				assert.Contains(messageToPost, messageToPostMap["name"])
			default:
				assert.Fail("Unexpected response type%s: ", t)
			}

			await <- true
			//}
		case err := <-subscribeErrorChannel:
			assert.Fail(string(err))
			await <- false
		case <-timeouts(10):
			assert.Fail("Timeout")
			await <- false
		}
	}()
	//sleep(1)
	go pubnubInstance.Publish(channel, messageToPost, successChannel, errorChannel)
	select {
	case <-successChannel:
		//log.Printf("pub message %s", message)
	case err := <-errorChannel:
		assert.Fail(string(err))
	case <-timeouts(30):
		assert.Fail("Publish timeout")
	}

	<-await

	go pubnubInstance.Unsubscribe(channel, unsubscribeSuccessChannel, unsubscribeErrorChannel)
	ExpectUnsubscribedEvent(t, channel, "", unsubscribeSuccessChannel, unsubscribeErrorChannel)
}

func TestPublishStringWithoutSerialization(t *testing.T) {
	assert := assert.New(t)

	stop, _ := NewVCRBoth(
		"fixtures/publish/publishStringWithoutSerialization",
		[]string{"uuid"})
	defer stop()

	channel := "Channel_PublishStringWithoutSerialization"
	uuid := "UUID_PublishStringWithoutSerialization"
	//messaging.SetLogOutput(os.Stdout)
	//messaging.LoggingEnabled(true)
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, uuid, CreateLoggerForTests())
	messageToPost := "{\"name\": \"Alex\", \"age\": \"123\"}"

	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)

	subscribeSuccessChannel := make(chan []byte)
	subscribeErrorChannel := make(chan []byte)

	unsubscribeSuccessChannel := make(chan []byte)
	unsubscribeErrorChannel := make(chan []byte)

	await := make(chan bool)

	go pubnubInstance.Subscribe(channel, "", subscribeSuccessChannel, false,
		subscribeErrorChannel)
	ExpectConnectedEvent(t, channel, "", subscribeSuccessChannel,
		subscribeErrorChannel)

	go func() {
		select {
		case message := <-subscribeSuccessChannel:
			var response []interface{}
			//var msgs []interface{}
			var err error

			err = json.Unmarshal(message, &response)
			if err != nil {
				assert.Fail(err.Error())
			}

			switch t := response[0].(type) {
			case []interface{}:
				var messageToPostMap map[string]interface{}

				//msgs = response[0].([]interface{})
				err := json.Unmarshal([]byte(messageToPost), &messageToPostMap)
				if err != nil {
					assert.Fail(err.Error())
				}

				//assert.Equal(messageToPostMap, msgs[0])
				assert.Contains(messageToPost, messageToPostMap["age"])
				assert.Contains(messageToPost, messageToPostMap["name"])

			default:
				assert.Fail("Unexpected response type%s: ", t)
			}

			await <- true
		case err := <-subscribeErrorChannel:
			assert.Fail(string(err))
			await <- false
		case <-timeouts(10):
			assert.Fail("Timeout")
			await <- false
		}
	}()

	go pubnubInstance.PublishExtended(channel, messageToPost, false, true,
		successChannel, errorChannel)
	select {
	case <-successChannel:
	case err := <-errorChannel:
		assert.Fail(string(err))
	case <-timeout():
		assert.Fail("Publish timeout")
	}

	<-await

	go pubnubInstance.Unsubscribe(channel, unsubscribeSuccessChannel, unsubscribeErrorChannel)
	ExpectUnsubscribedEvent(t, channel, "", unsubscribeSuccessChannel, unsubscribeErrorChannel)
}

// TestPublishEnd prints a message on the screen to mark the end of
// publish tests.
// PrintTestMessage is defined in the common.go file.
func TestPublishEnd(t *testing.T) {
	PrintTestMessage("==========Publish tests end==========")
}
