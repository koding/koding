// Package tests has the unit tests of package messaging.
// pubnubPublish_test.go contains the tests related to the publish requests on pubnub Api
package tests

import (
	"encoding/json"
	"fmt"
	"github.com/pubnub/go/gae/messaging"
	"google.golang.org/appengine/aetest"
	"strings"
	"testing"
	"time"
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
	channel := "testChannel"
	var message interface{}
	message = nil
	returnChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)

	//go pubnubInstance.Publish(channel, message, returnChannel, errorChannel)
	go pubnubInstance.Publish(context, w, req, channel, message, returnChannel, errorChannel)
	//go ParsePublishResponse(returnChannel, channel, "Invalid Message", "NullMessage", responseChannel)
	go ParseResponseDummy(returnChannel)
	go ParseErrorResponseForTestSuccess("Invalid Message", errorChannel, responseChannel)
	//go ParseErrorResponse(errorChannel, responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, "NullMessage")
}

// TestUniqueGuid tests the generation of a unique GUID for the client.
func TestUniqueGuid(t *testing.T) {
	guid, err := messaging.GenUuid()
	if err != nil {
		fmt.Println("err: ", err)
		t.Error("Test 'UniqueGuid': failed.")
	} else if guid == "" {
		t.Error("Test 'UniqueGuid': failed.")
	} /*else {
		//fmt.Println("Test 'UniqueGuid': passed.")
	}*/
}

// TestSuccessCodeAndInfo sends out a message to the pubnub channel
// The response is parsed and should match the 'sent' status.
// _publishSuccessMessage is defined in the common.go file
func TestSuccessCodeAndInfo(t *testing.T) {
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
	channel := "testChannel"
	message := "Pubnub API Usage Example"
	returnChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)

	//go pubnubInstance.Publish(channel, message, returnChannel, errorChannel)
	go pubnubInstance.Publish(context, w, req, channel, message, returnChannel, errorChannel)
	go ParsePublishResponse(returnChannel, channel, publishSuccessMessage, "SuccessCodeAndInfo", responseChannel)

	go ParseErrorResponse(errorChannel, responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, "SuccessCodeAndInfo")
	time.Sleep(2 * time.Second)
}

// TestSuccessCodeAndInfoWithEncryption sends out an encrypted
// message to the pubnub channel
// The response is parsed and should match the 'sent' status.
// _publishSuccessMessage is defined in the common.go file
func TestSuccessCodeAndInfoWithEncryption(t *testing.T) {
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

	pubnubInstance := messaging.New(context, uuid, w, req, PubKey, SubKey, "", "enigma", false)

	//pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "enigma", false, "", "", false)
	channel := "testChannel"
	message := "Pubnub API Usage Example"
	returnChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)

	//go pubnubInstance.Publish(channel, message, returnChannel, errorChannel)
	go pubnubInstance.Publish(context, w, req, channel, message, returnChannel, errorChannel)
	go ParsePublishResponse(returnChannel, channel, publishSuccessMessage, "SuccessCodeAndInfoWithEncryption", responseChannel)

	go ParseErrorResponse(errorChannel, responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, "SuccessCodeAndInfoWithEncryption")
	time.Sleep(2 * time.Second)
}

// TestSuccessCodeAndInfoWithSecretAndEncryption sends out an encrypted
// secret keyed message to the pubnub channel
// The response is parsed and should match the 'sent' status.
// _publishSuccessMessage is defined in the common.go file
func TestSuccessCodeAndInfoWithSecretAndEncryption(t *testing.T) {
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

	pubnubInstance := messaging.New(context, uuid, w, req, PubKey, SubKey, SecKey, "enigma", false)
	//pubnubInstance := messaging.NewPubnub(PubKey, SubKey, SecKey, "enigma", false, "", "", false)
	channel := "testChannel"
	message := "Pubnub API Usage Example"
	returnChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)

	//go pubnubInstance.Publish(channel, message, returnChannel, errorChannel)
	go pubnubInstance.Publish(context, w, req, channel, message, returnChannel, errorChannel)
	go ParsePublishResponse(returnChannel, channel, publishSuccessMessage, "SuccessCodeAndInfoWithSecretAndEncryption", responseChannel)

	go ParseErrorResponse(errorChannel, responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, "SuccessCodeAndInfoWithSecretAndEncryption")
	time.Sleep(2 * time.Second)
}

// TestSuccessCodeAndInfoForComplexMessage sends out a complex message to the pubnub channel
// The response is parsed and should match the 'sent' status.
// _publishSuccessMessage and customstruct is defined in the common.go file
func TestSuccessCodeAndInfoForComplexMessage(t *testing.T) {
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

	//pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, "", "", false)
	channel := "testChannel"

	customStruct := CustomStruct{
		Foo: "hi!",
		Bar: []int{1, 2, 3, 4, 5},
	}

	returnChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)

	//go pubnubInstance.Publish(channel, customStruct, returnChannel, errorChannel)
	go pubnubInstance.Publish(context, w, req, channel, customStruct, returnChannel, errorChannel)
	go ParsePublishResponse(returnChannel, channel, publishSuccessMessage, "SuccessCodeAndInfoForComplexMessage", responseChannel)

	go ParseErrorResponse(errorChannel, responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, "SuccessCodeAndInfoForComplexMessage")
	time.Sleep(2 * time.Second)
}

// TestSuccessCodeAndInfoForComplexMessage2 sends out a complex message to the pubnub channel
// The response is parsed and should match the 'sent' status.
// _publishSuccessMessage and InitComplexMessage is defined in the common.go file
func TestSuccessCodeAndInfoForComplexMessage2(t *testing.T) {
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

	//pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, "", "", false)
	channel := "testChannel"

	customComplexMessage := InitComplexMessage()

	returnChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)

	//go pubnubInstance.Publish(channel, customComplexMessage, returnChannel, errorChannel)
	go pubnubInstance.Publish(context, w, req, channel, customComplexMessage, returnChannel, errorChannel)
	go ParsePublishResponse(returnChannel, channel, publishSuccessMessage, "SuccessCodeAndInfoForComplexMessage2", responseChannel)

	go ParseErrorResponse(errorChannel, responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, "SuccessCodeAndInfoForComplexMessage2")
	time.Sleep(2 * time.Second)
}

// TestSuccessCodeAndInfoForComplexMessage2WithSecretAndEncryption sends out an
// encypted and secret keyed complex message to the pubnub channel
// The response is parsed and should match the 'sent' status.
// _publishSuccessMessage and InitComplexMessage is defined in the common.go file
func TestSuccessCodeAndInfoForComplexMessage2WithSecretAndEncryption(t *testing.T) {
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

	pubnubInstance := messaging.New(context, uuid, w, req, PubKey, SubKey, SecKey, "enigma", false)

	//pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "secret", "enigma", false, "", "", false)
	channel := "testChannel"

	customComplexMessage := InitComplexMessage()

	returnChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)

	//go pubnubInstance.Publish(channel, customComplexMessage, returnChannel, errorChannel)
	go pubnubInstance.Publish(context, w, req, channel, customComplexMessage, returnChannel, errorChannel)
	go ParsePublishResponse(returnChannel, channel, publishSuccessMessage, "SuccessCodeAndInfoForComplexMessage2WithSecretAndEncryption", responseChannel)

	go ParseErrorResponse(errorChannel, responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, "SuccessCodeAndInfoForComplexMessage2WithSecretAndEncryption")
	time.Sleep(2 * time.Second)
}

// TestSuccessCodeAndInfoForComplexMessage2WithEncryption sends out an
// encypted complex message to the pubnub channel
// The response is parsed and should match the 'sent' status.
// _publishSuccessMessage and InitComplexMessage is defined in the common.go file
func TestSuccessCodeAndInfoForComplexMessage2WithEncryption(t *testing.T) {
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

	pubnubInstance := messaging.New(context, uuid, w, req, PubKey, SubKey, "", "enigma", false)
	//pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "enigma", false, "", "", false)
	channel := "testChannel"

	customComplexMessage := InitComplexMessage()

	returnChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)

	//go pubnubInstance.Publish(channel, customComplexMessage, returnChannel, errorChannel)
	go pubnubInstance.Publish(context, w, req, channel, customComplexMessage, returnChannel, errorChannel)
	go ParsePublishResponse(returnChannel, channel, publishSuccessMessage, "SuccessCodeAndInfoForComplexMessage2WithEncryption", responseChannel)

	go ParseErrorResponse(errorChannel, responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, "SuccessCodeAndInfoForComplexMessage2WithEncryption")
	time.Sleep(2 * time.Second)
}

// ParsePublishResponse parses the response from the pubnub api to validate the
// sent status.
func ParsePublishResponse(returnChannel chan []byte, channel string, message string, testname string, responseChannel chan string) {
	for {
		value, ok := <-returnChannel
		if !ok {
			break
		}
		if string(value) != "[]" {
			response := fmt.Sprintf("%s", value)
			//fmt.Println("Test '" + testname + "':" +response)
			if strings.Contains(response, message) {
				responseChannel <- "Test '" + testname + "': passed."
				break
			} else {
				responseChannel <- "Test '" + testname + "': failed."
				break
			}
		}
	}
}

// TestLargeMessage tests the client by publshing a large message
// An error "message to large" should be returned from the server
/*func TestLargeMessage(t *testing.T) {
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, SecKey, "", false, "")
	channel := "testChannel"
	message := "This is a large message test which will return an error message. This is a large message test which will return an error message. This is a large message test which will return an error message. This is a large message test which will return an error message. This is a large message test which will return an error message. This is a large message test which will return an error message. This is a large message test which will return an error message. This is a large message test which will return an error message. This is a large message test which will return an error message. This is a large message test which will return an error message. This is a large message test which will return an error message. This is a large message test which will return an error message. This is a large message test which will return an error message. This is a large message test which will return an error message. This is a large message test which will return an error message. This is a large message test which will return an error message. This is a large message test which will return an error message. This is a large message test which will return an error message. This is a large message test which will return an error message. This is a large message test which will return an error message. This is a large message test which will return an error message. This is a large message test which will return an error message. This is a large message test which will return an error message. This is a large message test which will return an error message. This is a large message test which will return an error message. This is a large message test which will return an error message. This is a large message test which will return an error message. This is a large message test which will return an error message. This is a large message test which will return an error message. This is a large message test which will return an error message. This is a large message test which will return an error message. This is a large message test which will return an error message. "
	returnChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)

	go pubnubInstance.Publish(channel, message, returnChannel, errorChannel)
	go ParseLargeResponse("Message Too Large", errorChannel, responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, "MessageTooLarge")
}*/

// ParseLargeResponse parses the returnChannel and matches the message m
//
// Parameters:
// m: message to compare
// returnChannel: the channel to read
// responseChannel: the channel to send a response to.
func ParseLargeResponse(m string, returnChannel chan []byte, responseChannel chan string) {
	for {
		value, ok := <-returnChannel
		if !ok {
			break
		}
		returnVal := string(value)
		if returnVal != "[]" {
			var s []interface{}
			errJSON := json.Unmarshal(value, &s)

			if (errJSON == nil) && (len(s) > 0) {
				if message, ok := s[1].(string); ok {
					if message == m {
						responseChannel <- "passed"
					} else {
						responseChannel <- "failed"
					}
				} else {
					responseChannel <- "failed"
				}
			} else {
				responseChannel <- "failed"
			}
			break
		}
	}
}

// TestPublishEnd prints a message on the screen to mark the end of
// publish tests.
// PrintTestMessage is defined in the common.go file.
func TestPublishEnd(t *testing.T) {
	PrintTestMessage("==========Publish tests end==========")
}
