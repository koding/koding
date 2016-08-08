// Package tests has the unit tests of package messaging.
// pubnubPresence_test.go contains the tests related to the presence requests on pubnub Api
package tests

import (
	"encoding/json"
	"fmt"
	"github.com/pubnub/go/messaging"
	"strings"
	"testing"
	"time"
)

// TestPresenceStart prints a message on the screen to mark the beginning of
// presence tests.
// PrintTestMessage is defined in the common.go file.
func TestPresenceStart(t *testing.T) {
	PrintTestMessage("==========Presence tests start==========")
}

// TestCustomUuid subscribes to a pubnub channel using a custom uuid and then
// makes a call to the herenow method of the pubnub api. The custom id should
// be present in the response else the test fails.
func TestCustomUuid(t *testing.T) {
	cipherKey := ""
	testName := "CustomUuid"
	customUuid := "customuuid"
	HereNow(t, cipherKey, customUuid, testName)
}

// TestHereNow subscribes to a pubnub channel and then
// makes a call to the herenow method of the pubnub api. The occupancy should
// be greater than one.
func TestHereNow(t *testing.T) {
	cipherKey := ""
	testName := "HereNow"
	customUuid := "customuuid"
	HereNow(t, cipherKey, customUuid, testName)
}

// TestHereNowWithCipher subscribes to a pubnub channel and then
// makes a call to the herenow method of the pubnub api. The occupancy should
// be greater than one.
func TestHereNowWithCipher(t *testing.T) {
	cipherKey := ""
	testName := "HereNowWithCipher"
	customUuid := "customuuid"
	HereNow(t, cipherKey, customUuid, testName)
}

func TestPresenceHeartbeat(t *testing.T) {
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, SecKey, "", false, "")
	pubnubInstance.SetPresenceHeartbeat(10)
	channel := fmt.Sprintf("presence_hb")
	
	returnSubscribeChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)
	
	testName := "Presence Heartbeat"
	go pubnubInstance.Subscribe(channel, "", returnSubscribeChannel, false, errorChannel)
	time.Sleep(time.Duration(3) * time.Second)
	go pubnubInstance.Subscribe(channel, "", returnSubscribeChannel, true, errorChannel)
	go ParsePresenceResponseForTimeout(returnSubscribeChannel, responseChannel, testName)
	//go ParseErrorResponse(errorChannel, responseChannel)
	go ParseResponseDummyMessage(errorChannel, "aborted", responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, testName)
	go pubnubInstance.PresenceUnsubscribe(channel, returnSubscribeChannel, errorChannel)
	go pubnubInstance.Unsubscribe(channel, returnSubscribeChannel, errorChannel)
	pubnubInstance.CloseExistingConnection()	
}

func ParsePresenceResponseForTimeout(returnChannel chan []byte, responseChannel chan string, testName string) {
	timeout := make(chan bool, 1)
	go func() {
		time.Sleep(20 * time.Second)
		timeout <- true
	}()
	for {
	select {
		case value, ok := <-returnChannel:
			if !ok {
				break
			}
			if string(value) != "[]" {
				response := string(value)
				//fmt.Println("response:", response)
				//fmt.Println("message:",message);
				if strings.Contains(response, "connected") || strings.Contains(response, "join") || strings.Contains(response, "leave"){
					continue
				}else if strings.Contains(response, "timeout") {
					responseChannel <- "Test '" + testName + "': failed."
				} else {
					responseChannel <- "Test '" + testName + "': passed."
				}
				break
			}
		case <-timeout:
			responseChannel <- "Test '" + testName + "': passed."
			break
		}
	}
}

// HereNow is a common method used by the tests TestHereNow, HereNowWithCipher, CustomUuid
// It subscribes to a pubnub channel and then
// makes a call to the herenow method of the pubnub api.
func HereNow(t *testing.T, cipherKey string, customUuid string, testName string) {
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, SecKey, cipherKey, false, customUuid)

	r := GenRandom()
	channel := fmt.Sprintf("testChannel_hn_%d", r.Intn(100))

	returnSubscribeChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)

	go pubnubInstance.Subscribe(channel, "", returnSubscribeChannel, false, errorChannel)
	go ParseSubscribeResponseForPresence(pubnubInstance, customUuid, returnSubscribeChannel, channel, testName, responseChannel)
	go ParseErrorResponse(errorChannel, responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, testName)
	go pubnubInstance.Unsubscribe(channel, returnSubscribeChannel, errorChannel)
	pubnubInstance.CloseExistingConnection()
	time.Sleep(1 * time.Second)
}

// ParseHereNowResponse parses the herenow response on the go channel.
// In case of customuuid it looks for the custom uuid in the response.
// And in other cases checks for the occupancy.
func ParseHereNowResponse(returnChannel chan []byte, channel string, message string, testName string, responseChannel chan string) {
	for {
		value, ok := <-returnChannel

		if !ok {
			break
		}
		if string(value) != "[]" {
			response := fmt.Sprintf("%s", value)
			//fmt.Println("Test '" + testName + "':" +response)
			if testName == "CustomUuid" {
				if strings.Contains(response, message) {
					responseChannel <- "Test '" + testName + "': passed."
					break
				} else {
					responseChannel <- "Test '" + testName + "': failed."
					break
				}
			} else if (testName == "WhereNow") || (testName == "GlobalHereNow") {
				if strings.Contains(response, channel) {
					responseChannel <- "Test '" + testName + "': passed."
					break
				} else {
					responseChannel <- "Test '" + testName + "': failed."
					break
				}
			} else {
				var occupants struct {
					Uuids     []map[string]string
					Occupancy int
				}

				err := json.Unmarshal(value, &occupants)
				if err != nil {
					//fmt.Println("Test '" + testName + "':",err, "\n")
					responseChannel <- "Test '" + testName + "': failed. Message: " + err.Error()
					break
				} else {
					found := false
					for _, v := range occupants.Uuids {
						if v["uuid"] == message {
							found = true
						}
					}
					if found {
						responseChannel <- "Test '" + testName + "': passed."
						break
					} else {
						responseChannel <- "Test '" + testName + "': failed."
						break
					}
					/*i := occupants.Occupancy
					if i <= 0 {
						responseChannel <- "Test '" + testName + "': failed. Occupancy mismatch"
						break
					} else {
						responseChannel <- "Test '" + testName + "': passed."
					}*/
				}
			}
		}
	}
}

// TestPresence subscribes to the presence notifications on a pubnub channel and
// then subscribes to a pubnub channel. The test waits till we get a response from
// the subscribe call. The method that parses the presence response sets the global
// variable _endPresenceTestAsSuccess to true if the presence contains a join info
// on the channel and _endPresenceTestAsFailure is otherwise.
func Test0Presence(t *testing.T) {
	customUuid := "customuuid"
	testName := "Presence"
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, SecKey, "", false, customUuid)
	r := GenRandom()
	channel := fmt.Sprintf("testChannel_pres_%d", r.Intn(100))

	returnPresenceChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)
	
	time.Sleep(time.Duration(3) * time.Second)
	
	go pubnubInstance.Subscribe(channel, "", returnPresenceChannel, true, errorChannel)
	go ParseSubscribeResponseForPresence(pubnubInstance, customUuid, returnPresenceChannel, channel, testName, responseChannel)
	//go ParseResponseDummy(errorChannel)
	go ParseResponseDummyMessage(errorChannel, "aborted", responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, testName)
	go pubnubInstance.Unsubscribe(channel, returnPresenceChannel, errorChannel)
	pubnubInstance.CloseExistingConnection()
	time.Sleep(2 * time.Second)
}

// TestWhereNow subscribes to a pubnub channel and then
// makes a call to the herenow method of the pubnub api. The occupancy should
// be greater than one.
func TestWhereNow(t *testing.T) {
	cipherKey := ""
	testName := "WhereNow"
	customUuid := "customuuid"

	WhereNow(t, cipherKey, customUuid, testName)
}

// WhereNow is a common method used by the tests TestHereNow, HereNowWithCipher, CustomUuid
// It subscribes to a pubnub channel and then
// makes a call to the herenow method of the pubnub api.
func WhereNow(t *testing.T, cipherKey string, customUuid string, testName string) {
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, SecKey, cipherKey, false, customUuid)

	r := GenRandom()
	channel := fmt.Sprintf("testChannel_wn_%d", r.Intn(100))

	returnSubscribeChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)

	go pubnubInstance.Subscribe(channel, "", returnSubscribeChannel, false, errorChannel)
	go ParseSubscribeResponseForPresence(pubnubInstance, customUuid, returnSubscribeChannel, channel, testName, responseChannel)
	go ParseErrorResponse(errorChannel, responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, testName)
	go pubnubInstance.Unsubscribe(channel, returnSubscribeChannel, errorChannel)
	pubnubInstance.CloseExistingConnection()
	time.Sleep(2 * time.Second)
}

// TestGlobalHereNow subscribes to a pubnub channel and then
// makes a call to the herenow method of the pubnub api. The occupancy should
// be greater than one.
func TestGlobalHereNow(t *testing.T) {
	cipherKey := ""
	testName := "GlobalHereNow"
	customUuid := "customuuid"
	//subscribe

	GlobalHereNow(t, cipherKey, customUuid, testName)
}

// GlobalHereNow is a common method used by the tests TestHereNow, HereNowWithCipher, CustomUuid
// It subscribes to a pubnub channel and then
// makes a call to the herenow method of the pubnub api.
func GlobalHereNow(t *testing.T, cipherKey string, customUuid string, testName string) {
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, SecKey, cipherKey, false, customUuid)

	r := GenRandom()
	channel := fmt.Sprintf("testChannel_ghn_%d", r.Intn(100))

	returnSubscribeChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)

	go pubnubInstance.Subscribe(channel, "", returnSubscribeChannel, false, errorChannel)
	go ParseSubscribeResponseForPresence(pubnubInstance, customUuid, returnSubscribeChannel, channel, testName, responseChannel)
	go ParseErrorResponse(errorChannel, responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, testName)
	go pubnubInstance.Unsubscribe(channel, returnSubscribeChannel, errorChannel)
	pubnubInstance.CloseExistingConnection()
	time.Sleep(2 * time.Second)
}

// ParseSubscribeResponseForPresence will look for the connection status in the response
// received on the go channel.
func ParseSubscribeResponseForPresence(pubnubInstance *messaging.Pubnub, customUuid string, returnChannel chan []byte, channel string, testName string, responseChannel chan string) {
	for {
		value, ok := <-returnChannel
		if !ok {
			break
		}
		//response := fmt.Sprintf("%s", value)
		//fmt.Println(response);

		if string(value) != "[]" {
			if (testName == "CustomUuid") || (testName == "HereNow") || (testName == "HereNowWithCipher") {
				response := fmt.Sprintf("%s", value)
				message := "'" + channel + "' connected"
				messageReconn := "'" + channel + "' reconnected"
				if (strings.Contains(response, message)) || (strings.Contains(response, messageReconn)) {
					errorChannel := make(chan []byte)
					returnChannel := make(chan []byte)
					time.Sleep(3 * time.Second)
					go pubnubInstance.HereNow(channel, true, true, returnChannel, errorChannel)
					go ParseHereNowResponse(returnChannel, channel, customUuid, testName, responseChannel)
					go ParseErrorResponse(errorChannel, responseChannel)
					break
				}
			} else if testName == "WhereNow" {
				response := fmt.Sprintf("%s", value)
				message := "'" + channel + "' connected"
				messageReconn := "'" + channel + "' reconnected"
				if (strings.Contains(response, message)) || (strings.Contains(response, messageReconn)) {
					errorChannel := make(chan []byte)
					returnChannel := make(chan []byte)
					time.Sleep(3 * time.Second)
					go pubnubInstance.WhereNow(customUuid, returnChannel, errorChannel)
					go ParseHereNowResponse(returnChannel, channel, customUuid, testName, responseChannel)
					go ParseErrorResponse(errorChannel, responseChannel)
					break
				}
			} else if testName == "GlobalHereNow" {
				response := fmt.Sprintf("%s", value)
				message := "'" + channel + "' connected"
				messageReconn := "'" + channel + "' reconnected"
				if (strings.Contains(response, message)) || (strings.Contains(response, messageReconn)) {
					errorChannel := make(chan []byte)
					returnChannel := make(chan []byte)
					time.Sleep(3 * time.Second)
					go pubnubInstance.GlobalHereNow(true, false, returnChannel, errorChannel)
					go ParseHereNowResponse(returnChannel, channel, customUuid, testName, responseChannel)
					go ParseErrorResponse(errorChannel, responseChannel)
					break
				}
			} else {
				response := fmt.Sprintf("%s", value)
				message := "'" + channel + "' connected"
				messageReconn := "'" + channel + "' reconnected"
				//fmt.Println("Test3 '" + testName + "':" +response)
				if (strings.Contains(response, message)) || (strings.Contains(response, messageReconn)) {

					errorChannel2 := make(chan []byte)
					returnSubscribeChannel := make(chan []byte)
					time.Sleep(1 * time.Second)
					go pubnubInstance.Subscribe(channel, "", returnSubscribeChannel, false, errorChannel2)
					go ParseResponseDummy(returnSubscribeChannel)
					go ParseResponseDummy(errorChannel2)
				} else {
					if testName == "Presence" {
						data, _, returnedChannel, err2 := messaging.ParseJSON(value, "")

						var occupants []struct {
							Action    string
							Uuid      string
							Timestamp float64
							Occupancy int
						}

						if err2 != nil {
							responseChannel <- "Test '" + testName + "': failed. Message: 1 :" + err2.Error()
							break
						}
						//fmt.Println("Test3 '" + testName + "':" +data)
						err := json.Unmarshal([]byte(data), &occupants)
						if err != nil {
							//fmt.Println("err '" + testName + "':",err)
							responseChannel <- "Test '" + testName + "': failed. Message: 2 :" + err.Error()
							break
						} else {
							channelSubRepsonseReceived := false
							for i := 0; i < len(occupants); i++ {
								if (occupants[i].Action == "join") && occupants[i].Uuid == customUuid {
									channelSubRepsonseReceived = true
									break
								}
							}
							if !channelSubRepsonseReceived {
								responseChannel <- "Test '" + testName + "': failed. Message: err3"
								break
							}
							if channel == returnedChannel {
								responseChannel <- "Test '" + testName + "': passed."
								break
							} else {
								responseChannel <- "Test '" + testName + "': failed. Message: err4"
								break
							}
						}
					}
				}
			}
		}
	}
}

// TestSetGetUserState subscribes to a pubnub channel and then
// makes a call to the herenow method of the pubnub api. The occupancy should
// be greater than one.
func TestSetGetUserState(t *testing.T) {
	cipherKey := ""
	testName := "SetGetUserState"

	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, SecKey, cipherKey, false, "")

	r := GenRandom()
	channel := fmt.Sprintf("testChannel_us_%d", r.Intn(100))
	key := "testkey"
	val := "testval"
	CommonUserState(pubnubInstance, t, channel, key, val, testName)
}

func TestSetUserStateHereNow(t *testing.T) {
	cipherKey := ""
	testName := "SetGetUserStateHereNow"

	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, SecKey, cipherKey, false, "")

	r := GenRandom()
	channel := fmt.Sprintf("testChannel_us_%d", r.Intn(100))
	key := "testkey"
	val := "testval"

	CommonUserState(pubnubInstance, t, channel, key, val, testName)
}

func TestSetUserStateGlobalHereNow(t *testing.T) {
	cipherKey := ""
	testName := "SetGetUserStateGlobalHereNow"

	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, SecKey, cipherKey, false, "")

	r := GenRandom()
	channel := fmt.Sprintf("testChannel_us_%d", r.Intn(100))
	key := "testkey"
	val := "testval"

	CommonUserState(pubnubInstance, t, channel, key, val, testName)
}

func CommonUserState(pubnubInstance *messaging.Pubnub, t *testing.T, channel string, key string, val string, testName string) {
	returnSubscribeChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	waitChannel := make(chan string)
	//returnChannel := make(chan []byte)
	responseChannel := make(chan string)

	go pubnubInstance.Subscribe(channel, "", returnSubscribeChannel, false, errorChannel)
	go ParseSubcribeResponseForUserState(pubnubInstance, t, returnSubscribeChannel, channel, key, val, testName, responseChannel)
	go ParseResponseDummy(errorChannel)
	//go ParseErrorResponse(errorChannel, responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, testName)
	go pubnubInstance.Unsubscribe(channel, returnSubscribeChannel, errorChannel)
	pubnubInstance.CloseExistingConnection()
	time.Sleep(2 * time.Second)
}

func ParseSubcribeResponseForUserState(pubnubInstance *messaging.Pubnub, t *testing.T, returnChannel chan []byte, channel string, key string, val string, testName string, responseChannel chan string) {
	for {
		value, ok := <-returnChannel
		if !ok {
			break
		}
		if string(value) != "[]" {
			response := fmt.Sprintf("%s", value)
			message := "'" + channel + "' connected"
			messageReconn := "'" + channel + "' reconnected"
			if (strings.Contains(response, message)) || (strings.Contains(response, messageReconn)) {
				time.Sleep(1 * time.Second)
				errorChannel := make(chan []byte)
				returnChannel2 := make(chan []byte)

				go pubnubInstance.SetUserStateKeyVal(channel, key, val, returnChannel2, errorChannel)
				go ParseSetUserStateResponse(pubnubInstance, returnChannel2, channel, key, val, testName, responseChannel)
				go ParseErrorResponse(errorChannel, responseChannel)
			}
			break
		}
	}
}

func ParseUserStateResponse(returnChannel chan []byte, channel string, key string, val string, testName string, responseChannel chan string) {
	for {
		value, ok := <-returnChannel
		if !ok {
			break
		}
		if string(value) != "[]" {
			response := fmt.Sprintf("%s", value)
			message := fmt.Sprintf("{\"%s\": \"%s\"}", key, val)
			//fmt.Println(message)
			//fmt.Println(response)
			if strings.Contains(response, message) {
				responseChannel <- "Test '" + testName + "': passed."
				break
			} else {
				responseChannel <- "Test '" + testName + "': failed."
				break
			}
		}
	}
}

func ParseSetUserStateResponse(pubnubInstance *messaging.Pubnub, returnChannel chan []byte, channel string, key string, val string, testName string, responseChannel chan string) {
	for {
		value, ok := <-returnChannel
		if !ok {
			break
		}
		if string(value) != "[]" {
			response := fmt.Sprintf("%s", value)
			//fmt.Println("Test '" + testName + "':" +response)
			message := fmt.Sprintf("{\"%s\": \"%s\"}", key, val)
			//fmt.Println("%s", message)
			if strings.Contains(response, message) {
				errorChannel := make(chan []byte)
				returnChannel2 := make(chan []byte)
				time.Sleep(3 * time.Second)

				if testName == "SetGetUserState" {
					go pubnubInstance.GetUserState(channel, returnChannel2, errorChannel)
				} else if testName == "SetGetUserStateHereNow" {
					go pubnubInstance.HereNow(channel, true, true, returnChannel2, errorChannel)
				} else if testName == "SetGetUserStateGlobalHereNow" {
					go pubnubInstance.GlobalHereNow(true, true, returnChannel2, errorChannel)
				}
				go ParseUserStateResponse(returnChannel2, channel, key, val, testName, responseChannel)
				go ParseErrorResponse(errorChannel, responseChannel)

				break
			} else {
				responseChannel <- "Test '" + testName + "': failed."
				break
			}
		}
	}
}

func TestSetUserStateJSON(t *testing.T) {
	cipherKey := ""
	testName := "SetGetUserStateJSON"

	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, SecKey, cipherKey, false, "")

	r := GenRandom()
	channel := fmt.Sprintf("testChannel_us_%d", r.Intn(100))
	key1 := "testkey"
	val1 := "testval"
	key2 := "testkey2"
	val2 := "testval2"

	CommonUserStateJSON(pubnubInstance, t, channel, key1, val1, key2, val2, testName)
}

func CommonUserStateJSON(pubnubInstance *messaging.Pubnub, t *testing.T, channel string, key1 string, val1 string, key2 string, val2 string, testName string) {
	returnChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	waitChannel := make(chan string)
	responseChannel := make(chan string)

	jsonString := fmt.Sprintf("{\"%s\": \"%s\",\"%s\": \"%s\"}", key1, val1, key2, val2)
	time.Sleep(2 * time.Second)
	go pubnubInstance.SetUserStateJSON(channel, jsonString, returnChannel, errorChannel)
	go ParseSetUserStateResponseJSON(pubnubInstance, returnChannel, channel, key1, val1, key2, val2, jsonString, testName, responseChannel)
	go ParseErrorResponse(errorChannel, responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, testName)
}

func ParseSetUserStateResponseJSON(pubnubInstance *messaging.Pubnub, returnChannel chan []byte, channel string, key1 string, val1 string, key2 string, val2 string, jsonString string, testName string, responseChannel chan string) {
	for {
		value, ok := <-returnChannel
		if !ok {
			break
		}
		if string(value) != "[]" {
			response := fmt.Sprintf("%s", value)
			//fmt.Println("Test JSON'" + testName + "':" +response)
			jsonString = fmt.Sprintf("{\"%s\": \"%s\", \"%s\": \"%s\"}", key2, val2, key1, val1)
			if strings.Contains(response, jsonString) {
				errorChannel := make(chan []byte)
				returnChannel2 := make(chan []byte)
				time.Sleep(3 * time.Second)

				go pubnubInstance.SetUserStateKeyVal(channel, key2, "", returnChannel2, errorChannel)
				go ParseUserStateResponse(returnChannel2, channel, key1, val1, testName, responseChannel)
				go ParseErrorResponse(errorChannel, responseChannel)

				break
			} else {
				responseChannel <- "Test '" + testName + "': failed."
				break
			}
		}
	}
}

// TestPresenceEnd prints a message on the screen to mark the end of
// presence tests.
// PrintTestMessage is defined in the common.go file.
func TestPresenceEnd(t *testing.T) {
	PrintTestMessage("==========Presence tests end==========")
}
