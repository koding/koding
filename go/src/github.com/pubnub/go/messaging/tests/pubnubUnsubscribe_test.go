// Package tests has the unit tests of package messaging.
// pubnubUnsubscribe_test.go contains the tests related to the Unsubscribe requests on pubnub Api
package tests

import (
	"fmt"
	"github.com/pubnub/go/messaging"
	"strings"
	"testing"
	"time"
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
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, "")

	currentTime := time.Now()
	channel := "testChannel" + currentTime.Format("20060102150405")

	returnUnsubscribeChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)

	go pubnubInstance.Unsubscribe(channel, returnUnsubscribeChannel, errorChannel)
	go ParseUnsubscribeResponse(errorChannel, channel, "not subscribed", responseChannel)
	go ParseErrorResponse(returnUnsubscribeChannel, responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, "UnsubscribeNotSubscribed")
}

// TestUnsubscribe will subscribe to a pubnub channel and then send an unsubscribe request
// The response should contain 'unsubscribed'
func TestUnsubscribe(t *testing.T) {
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, "")

	channel := "testChannel"

	returnSubscribeChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)

	go pubnubInstance.Subscribe(channel, "", returnSubscribeChannel, false, errorChannel)
	go ParseSubscribeResponseAndCallUnsubscribe(pubnubInstance, returnSubscribeChannel, channel, "connected", responseChannel)
	go ParseErrorResponse(errorChannel, responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, "Unsubscribe")
}

// ParseSubscribeResponseAndCallUnsubscribe will parse the response on the go channel.
// It will check the subscribe connection status and when connected
// it will initiate the unsubscribe request.
func ParseSubscribeResponseAndCallUnsubscribe(pubnubInstance *messaging.Pubnub, returnChannel chan []byte, channel string, message string, responseChannel chan string) {
	for {
		value, ok := <-returnChannel
		if !ok {
			break
		}
		if string(value) != "[]" {
			response := fmt.Sprintf("%s", value)
			message = "'" + channel + "' " + message
			//messageAbort := "'" + channel + "' aborted"
			//fmt.Printf("response:",response);
			//fmt.Printf("message:", message);
			
			if strings.Contains(response, message) {
				returnUnsubscribeChannel := make(chan []byte)
				errorChannel := make(chan []byte)

				go pubnubInstance.Unsubscribe(channel, returnUnsubscribeChannel, errorChannel)
				go ParseUnsubscribeResponse(returnUnsubscribeChannel, channel, "unsubscribed", responseChannel)
				go ParseResponseDummy(errorChannel)

				break
			} /*else if (strings.Contains(response, messageAbort)){
			      responseChannel <- "Test unsubscribed: failed."
			      break
			  } else {
			      responseChannel <- "Test unsubscribed: failed."
			      break
			  }*/
		}
	}
}

// ParseUnsubscribeResponse will parse the unsubscribe response on the go channel.
// If it contains unsubscribed the test will pass.
func ParseUnsubscribeResponse(returnChannel chan []byte, channel string, message string, responseChannel chan string) {
	for {
		value, ok := <-returnChannel
		if !ok {
			break
		}
		if string(value) != "[]" {
			response := fmt.Sprintf("%s", value)
			//fmt.Printf("response:",response);
			//fmt.Printf("message:", message);
			if strings.Contains(response, message) {
				responseChannel <- "Test '" + message + "': passed."
				break
			} else {
				responseChannel <- "Test '" + message + "': failed."
				break
			}
		}
	}
}

// TestUnsubscribeEnd prints a message on the screen to mark the end of
// unsubscribe tests.
// PrintTestMessage is defined in the common.go file.
func TestUnsubscribeEnd(t *testing.T) {
	PrintTestMessage("==========Unsubscribe tests end==========")
}
