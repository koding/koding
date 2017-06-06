// Package tests has the unit tests of package messaging.
// pubnubTime_test.go contains the tests related to the Time requests on pubnub Api
package tests

import (
	"fmt"
	"github.com/pubnub/go/gae/messaging"
	"google.golang.org/appengine/aetest"
	"testing"
)

// TestTimeStart prints a message on the screen to mark the beginning of
// time tests.
// PrintTestMessage is defined in the common.go file.
func TestTimeStart(t *testing.T) {
	PrintTestMessage("==========Time tests start==========")
}

// TestServerTime calls the GetTime method of the messaging to test the time
func TestServerTime(t *testing.T) {
	/*context, err := aetest.NewContext(nil)
	if err != nil {
		t.Fatal(err)
	}
	defer context.Close()*/
	inst, err := aetest.NewInstance(&aetest.Options{"", true})
	context := CreateContext(inst)

	if err != nil {
		t.Fatal(err)
	}
	defer inst.Close()

	uuid := ""
	w, req := InitAppEngineContext(t)

	pubnubInstance := messaging.New(context, uuid, w, req, PubKey, SubKey, "", "", false)
	//pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, "")

	returnTimeChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)

	//go pubnubInstance.GetTime(returnTimeChannel, errorChannel)
	go pubnubInstance.GetTime(context, w, req, returnTimeChannel, errorChannel)
	go ParseTimeResponse(returnTimeChannel, responseChannel)
	go ParseErrorResponse(errorChannel, responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, "Time")
}

// ParseTimeResponse parses the time response from the pubnub api.
// On error the test fails.
func ParseTimeResponse(returnChannel chan []byte, responseChannel chan string) {
	for {
		value, ok := <-returnChannel
		if !ok {
			break
		}
		if string(value) != "[]" {
			response := fmt.Sprintf("%s", value)
			if response != "" {
				responseChannel <- "Server time: passed."
				break
			} else {
				responseChannel <- "Server time: failed."
				break
			}
		}
	}
}

// TestTimeEnd prints a message on the screen to mark the end of
// time tests.
// PrintTestMessage is defined in the common.go file.
func TestTimeEnd(t *testing.T) {
	PrintTestMessage("==========Time tests end==========")
}
