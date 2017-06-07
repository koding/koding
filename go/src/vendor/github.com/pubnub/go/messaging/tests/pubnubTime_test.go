// Package tests has the unit tests of package messaging.
// pubnubTime_test.go contains the tests related to the Time requests on pubnub Api
package tests

import (
	"strconv"
	"strings"
	"testing"

	"github.com/pubnub/go/messaging"
	"github.com/stretchr/testify/assert"
)

// TestTimeStart prints a message on the screen to mark the beginning of
// time tests.
// PrintTestMessage is defined in the common.go file.
func TestTimeStart(t *testing.T) {
	PrintTestMessage("==========Time tests start==========")
}

// TestServerTime calls the GetTime method of the messaging to test the time
func TestServerTime(t *testing.T) {
	stop, _ := NewVCRNonSubscribe("fixtures/time", []string{})
	defer stop()

	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, "testTime", CreateLoggerForTests())

	assert := assert.New(t)
	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)

	go pubnubInstance.GetTime(successChannel, errorChannel)
	select {
	case value := <-successChannel:
		response := string(value)
		timestamp, err := strconv.Atoi(strings.Trim(response, "[]\n"))
		if err != nil {
			assert.Fail(err.Error())
		}

		assert.NotZero(timestamp)
	case err := <-errorChannel:
		assert.Fail(string(err))
	case <-timeouts(10):
		assert.Fail("Getting server timestamp timeout")
	}
}

// TestTimeEnd prints a message on the screen to mark the end of
// time tests.
// PrintTestMessage is defined in the common.go file.
func TestTimeEnd(t *testing.T) {
	PrintTestMessage("==========Time tests end==========")
}
