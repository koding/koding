// Package tests has the unit tests of package messaging.
// pubnubSubscribe_test.go contains the tests related to the Subscribe requests on pubnub Api
package tests

import (
	"encoding/json"
	"encoding/xml"
	"fmt"
	"github.com/pubnub/go/messaging"
	//"net/url"
	"strconv"
	"strings"
	"testing"
	"time"
)

// TestSubscribeStart prints a message on the screen to mark the beginning of
// subscribe tests.
// PrintTestMessage is defined in the common.go file.
func TestSubscribeStart(t *testing.T) {
	PrintTestMessage("==========Subscribe tests start==========")
}

// TestSubscriptionConnectStatus sends out a subscribe request to a pubnub channel
// and validates the response for the connect status.
func TestSubscriptionConnectStatus(t *testing.T) {
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, "")
	r := GenRandom()
	channel := fmt.Sprintf("testChannel_sub_%d", r.Intn(20))

	returnSubscribeChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)

	go pubnubInstance.Subscribe(channel, "", returnSubscribeChannel, false, errorChannel)
	go ParseSubscribeResponse(pubnubInstance, returnSubscribeChannel, t, channel, "", "SubscriptionConnectStatus", "", responseChannel)
	go ParseErrorResponse(errorChannel, responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, "SubscriptionConnectStatus")
	go pubnubInstance.Unsubscribe(channel, returnSubscribeChannel, errorChannel)
	pubnubInstance.CloseExistingConnection()
}

// TestSubscriptionAlreadySubscribed sends out a subscribe request to a pubnub channel
// and when connected sends out another subscribe request. The response for the second
func TestSubscriptionAlreadySubscribed(t *testing.T) {
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, "")

	r := GenRandom()
	channel := fmt.Sprintf("testChannel_sub_%d", r.Intn(20))
	testName := "SubscriptionAlreadySubscribed"

	returnSubscribeChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)

	go pubnubInstance.Subscribe(channel, "", returnSubscribeChannel, false, errorChannel)
	go ParseSubscribeResponse(pubnubInstance, returnSubscribeChannel, t, channel, "", testName, "", responseChannel)
	go ParseErrorResponse(errorChannel, responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, testName)
	go pubnubInstance.Unsubscribe(channel, returnSubscribeChannel, errorChannel)
	pubnubInstance.CloseExistingConnection()
}

// TestMultiSubscriptionConnectStatus send out a pubnub multi channel subscribe request and
// parses the response for multiple connection status.
func TestMultiSubscriptionConnectStatus(t *testing.T) {
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, "")
	testName := "TestMultiSubscriptionConnectStatus"
	r := GenRandom()
	channels := fmt.Sprintf("testChannel_sub_%d,testChannel_sub_%d", r.Intn(20), r.Intn(20))

	//channels := "testChannel1,testChannel2"

	returnSubscribeChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)

	go pubnubInstance.Subscribe(channels, "", returnSubscribeChannel, false, errorChannel)
	go ParseSubscribeResponseForMultipleChannels(returnSubscribeChannel, channels, testName, responseChannel)

	go ParseErrorResponse(errorChannel, responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, testName)
	go pubnubInstance.Unsubscribe(channels, returnSubscribeChannel, errorChannel)
	pubnubInstance.CloseExistingConnection()
}

// ParseSubscribeResponseForMultipleChannels parses the pubnub multi channel response
// for the number or channels connected and matches them to the connected channels.
func ParseSubscribeResponseForMultipleChannels(returnChannel chan []byte, channels string, testName string, responseChannel chan string) {
	noOfChannelsConnected := 0
	channelArray := strings.Split(channels, ",")
	for {
		value, ok := <-returnChannel
		if !ok {
			break
		}
		if string(value) != "[]" {
			response := fmt.Sprintf("%s", value)
			message := "' connected"
			messageReconn := "' reconnected"
			//fmt.Println("response: ", response)
			if (strings.Contains(response, message)) || (strings.Contains(response, messageReconn)) {
				noOfChannelsConnected++
				if noOfChannelsConnected >= len(channelArray) {
					responseChannel <- "Test '" + testName + "': passed."
					break
				}
			}
		}
	}
}

// TestSubscriptionForSimpleMessage first subscribes to a pubnub channel and then publishes
// a message on the same pubnub channel. The subscribe response should receive this same message.
func TestSubscriptionForSimpleMessage(t *testing.T) {
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, "")

	r := GenRandom()
	channel := fmt.Sprintf("testChannel_sub_%d", r.Intn(20))

	returnSubscribeChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)

	go pubnubInstance.Subscribe(channel, "", returnSubscribeChannel, false, errorChannel)
	go ParseSubscribeResponse(pubnubInstance, returnSubscribeChannel, t, channel, "", "SubscriptionConnectedForSimple", "", responseChannel)
	go ParseErrorResponse(errorChannel, responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, "SubscriptionConnectedForSimple")
	go pubnubInstance.Unsubscribe(channel, returnSubscribeChannel, errorChannel)
	pubnubInstance.CloseExistingConnection()
}

// TestSubscriptionForSimpleMessageWithCipher first subscribes to a pubnub channel and then publishes
// an encrypted message on the same pubnub channel. The subscribe response should receive
// the decrypted message.
func TestSubscriptionForSimpleMessageWithCipher(t *testing.T) {
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "enigma", false, "")

	r := GenRandom()
	channel := fmt.Sprintf("testChannel_sub_%d", r.Intn(20))

	returnSubscribeChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)

	go pubnubInstance.Subscribe(channel, "", returnSubscribeChannel, false, errorChannel)
	go ParseSubscribeResponse(pubnubInstance, returnSubscribeChannel, t, channel, "", "SubscriptionConnectedForSimpleWithCipher", "enigma", responseChannel)
	go ParseErrorResponse(errorChannel, responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, "SubscriptionConnectedForSimpleWithCipher")
	go pubnubInstance.Unsubscribe(channel, returnSubscribeChannel, errorChannel)
	pubnubInstance.CloseExistingConnection()
}

// TestSubscriptionForComplexMessage first subscribes to a pubnub channel and then publishes
// a complex message on the same pubnub channel. The subscribe response should receive
// the same message.
func TestSubscriptionForComplexMessage(t *testing.T) {
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, "")

	r := GenRandom()
	channel := fmt.Sprintf("testChannel_sub_%d", r.Intn(20))

	returnSubscribeChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)

	go pubnubInstance.Subscribe(channel, "", returnSubscribeChannel, false, errorChannel)
	go ParseSubscribeResponse(pubnubInstance, returnSubscribeChannel, t, channel, "", "SubscriptionConnectedForComplex", "", responseChannel)
	go ParseErrorResponse(errorChannel, responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, "SubscriptionConnectedForComplex")
	go pubnubInstance.Unsubscribe(channel, returnSubscribeChannel, errorChannel)
	pubnubInstance.CloseExistingConnection()
}

// TestSubscriptionForComplexMessageWithCipher first subscribes to a pubnub channel and then publishes
// an encrypted complex message on the same pubnub channel. The subscribe response should receive
// the decrypted message.
func TestSubscriptionForComplexMessageWithCipher(t *testing.T) {
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "enigma", false, "")

	r := GenRandom()
	channel := fmt.Sprintf("testChannel_sub_%d", r.Intn(20))

	returnSubscribeChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)

	go pubnubInstance.Subscribe(channel, "", returnSubscribeChannel, false, errorChannel)
	go ParseSubscribeResponse(pubnubInstance, returnSubscribeChannel, t, channel, "", "SubscriptionConnectedForComplexWithCipher", "enigma", responseChannel)
	go ParseErrorResponse(errorChannel, responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, "SubscriptionConnectedForComplexWithCipher")
	go pubnubInstance.Unsubscribe(channel, returnSubscribeChannel, errorChannel)
	pubnubInstance.CloseExistingConnection()
}

// PublishComplexMessage publises a complex message on a pubnub channel and
// calls the parse method to validate the message subscription.
// CustomComplexMessage and InitComplexMessage are defined in the common.go file.
func PublishComplexMessage(pubnubInstance *messaging.Pubnub, t *testing.T, channel string, testName string, cipherKey string, responseChannel chan string) {
	customComplexMessage := InitComplexMessage()

	returnChannel := make(chan []byte)
	errorChannel := make(chan []byte)

	go pubnubInstance.Publish(channel, customComplexMessage, returnChannel, errorChannel)
	go ParseSubscribeResponse(pubnubInstance, returnChannel, t, channel, "", testName, cipherKey, responseChannel)
	go ParseErrorResponse(errorChannel, responseChannel)
}

// PublishSimpleMessage publises a message on a pubnub channel and
// calls the parse method to validate the message subscription.
func PublishSimpleMessage(pubnubInstance *messaging.Pubnub, t *testing.T, channel string, testName string, cipherKey string, responseChannel chan string) {
	message := "Test message"

	returnChannel := make(chan []byte)
	errorChannel := make(chan []byte)

	go pubnubInstance.Publish(channel, message, returnChannel, errorChannel)
	go ParseSubscribeResponse(pubnubInstance, returnChannel, t, channel, "", testName, cipherKey, responseChannel)
	go ParseErrorResponse(errorChannel, responseChannel)
}

// ValidateComplexData takes an interafce as a parameter and iterates through it
// It validates each field of the response interface against the initialized struct
// CustomComplexMessage, ReplaceEncodedChars and InitComplexMessage are defined in the common.go file.
func ValidateComplexData(m map[string]interface{}) bool {
	//m := vv.(map[string]interface{})
	//if val,ok := m["VersionId"]; ok {
	//fmt.Println("VersionId",m["VersionId"])
	//}
	customComplexMessage := InitComplexMessage()
	valid := false
	for k, v := range m {
		//fmt.Println("k:", k, "v:", v)
		if k == "OperationName" {
			if m["OperationName"].(string) == customComplexMessage.OperationName {
				valid = true
			} else {
				//fmt.Println("OperationName")
				return false
			}
		} else if k == "VersionID" {
			if a, ok := v.(string); ok {
				verID, convErr := strconv.ParseFloat(a, 64)
				if convErr != nil {
					//fmt.Println(convErr)
					return false
				}
				if float32(verID) == customComplexMessage.VersionID {
					valid = true
				} else {
					//fmt.Println("VersionID")
					return false
				}
			}
		} else if k == "TimeToken" {
			i, convErr := strconv.ParseInt(v.(string), 10, 64)
			if convErr != nil {
				//fmt.Println(convErr)
				return false
			}
			if i == customComplexMessage.TimeToken {
				valid = true
			} else {
				//fmt.Println("TimeToken")
				return false
			}
		} else if k == "DemoMessage" {
			b1 := v.(map[string]interface{})
			jsonData, _ := json.Marshal(customComplexMessage.DemoMessage.DefaultMessage)
			if val, ok := b1["DefaultMessage"]; ok {
				if val.(string) != string(jsonData) {
					//fmt.Println("DefaultMessage")
					return false
				}
				valid = true
			}
		} else if k == "SampleXML" {
			data := &Data{}
			//s1, _ := url.QueryUnescape(m["SampleXML"].(string))
			s1, _ := m["SampleXML"].(string)

			reader := strings.NewReader(ReplaceEncodedChars(s1))
			err := xml.NewDecoder(reader).Decode(&data)

			if err != nil {
				//fmt.Println(err)
				return false
			}
			jsonData, _ := json.Marshal(customComplexMessage.SampleXML)
			if s1 == string(jsonData) {
				valid = true
			} else {	
				//fmt.Println("SampleXML")
				return false
			}
		} else if k == "Channels" {
			strSlice1, _ := json.Marshal(v)
			strSlice2, _ := json.Marshal(customComplexMessage.Channels)
			//s1, err := url.QueryUnescape(string(strSlice1))
			s1 := string(strSlice1)
			/*if err != nil {
				fmt.Println(err)
				return false
			}*/
			if s1 == string(strSlice2) {
				valid = true
			} else {
				//fmt.Println("Channels")
				return false
			}
		}
	}
	return valid
}

// CheckComplexData iterates through the json interafce and will read when
// map type is encountered.
// CustomComplexMessage and InitComplexMessage are defined in the common.go file.
func CheckComplexData(b interface{}) bool {
	valid := false
	switch vv := b.(type) {
	case string:
		//fmt.Println( "is string", vv)
	case int:
		//fmt.Println( "is int", vv)
	case []interface{}:
		//fmt.Println( "is an array:")
		//for i, u := range vv {
		for _, u := range vv {
			return CheckComplexData(u)
			//fmt.Println(i, u)
		}
	case map[string]interface{}:
		m := vv
		return ValidateComplexData(m)
	default:
	}
	return valid
}

// ParseSubscribeData is used by multiple test cases and acts according to the testcase names.
// In case of complex message calls a sub method and in case of a simle message parses
// the response.
func ParseSubscribeData(t *testing.T, response []byte, testName string, cipherKey string, returnChannel chan string) bool {
	if response != nil {
		var b interface{}
		err := json.Unmarshal(response, &b)

		isValid := false
		if (testName == "SubscriptionConnectedForComplex") || (testName == "SubscriptionConnectedForComplexWithCipher") {
			isValid = CheckComplexData(b)
		} else if (testName == "SubscriptionConnectedForSimple") || (testName == "SubscriptionConnectedForSimpleWithCipher") {
			var arr []interface{}

			err := json.Unmarshal(response, &arr)
			//fmt.Println("response:", arr[1].(string))
			if err != nil {
				fmt.Println("err:", err)
			} else {
				if len(arr) > 0 {
					if message, ok := arr[0].([]interface{}); ok {
						if messageT, ok2 := message[0].(string); ok2 {
							if (len(message) > 0) && (messageT == "Test message") {
								isValid = true
							}
						}
					}
				}
			}
		}
		if err != nil {
			return false
		} else if !isValid {
			return false
		}
	}
	return true
}

// ParseSubscribeResponse reads the response from the go channel and unmarshal's it.
// It is used by multiple test cases and acts according to the testcase names.
// The idea is to parse each message in the response based on the type of message
// and test against the sent message. If both match the test case is successful.
// _publishSuccessMessage is defined in the common.go file.
func ParseSubscribeResponse(pubnubInstance *messaging.Pubnub, returnChannel chan []byte, t *testing.T, channel string, message string, testName string, cipherKey string, responseChannel chan string) {
	for {
		value, ok := <-returnChannel
		if !ok {
			break
		}
		if string(value) != "[]" {
			response := fmt.Sprintf("%s", value)
			//fmt.Println("Response1:", response)
			if (testName == "SubscriptionConnectedForComplex") || (testName == "SubscriptionConnectedForComplexWithCipher") {
				message = "'" + channel + "' connected"
				if strings.Contains(response, message) {
					PublishComplexMessage(pubnubInstance, t, channel, publishSuccessMessage, cipherKey, responseChannel)
				} else {
					//fmt.Println("resp:", response)
					if ParseSubscribeData(t, value, testName, cipherKey, responseChannel) {
						responseChannel <- "Test '" + testName + "': passed."
					} else {
						responseChannel <- "Test '" + testName + "': failed."
					}
					break
				}
			} else if (testName == "SubscriptionConnectedForSimple") || (testName == "SubscriptionConnectedForSimpleWithCipher") {
				message = "'" + channel + "' connected"
				if strings.Contains(response, message) {
					PublishSimpleMessage(pubnubInstance, t, channel, publishSuccessMessage, cipherKey, responseChannel)
				} else {
					if ParseSubscribeData(t, value, testName, cipherKey, responseChannel) {
						responseChannel <- "Test '" + testName + "': passed."
					} else {
						responseChannel <- "Test '" + testName + "': failed."
					}
					break
				}
			} else if testName == "SubscriptionAlreadySubscribed" {
				message = "'" + channel + "' connected"

				if strings.Contains(response, message) {
					returnSubscribeChannel2 := make(chan []byte)
					errorChannel2 := make(chan []byte)

					go pubnubInstance.Subscribe(channel, "", returnSubscribeChannel2, false, errorChannel2)
					go ParseSubscribeResponse(pubnubInstance, errorChannel2, t, channel, "already subscribed", "SubscriptionAlreadySubscribedResponse", "", responseChannel)
					go ParseResponseDummy(returnSubscribeChannel2)
				}
				break
			} else if testName == "SubscriptionAlreadySubscribedResponse" {
				message = "'" + channel + "' already subscribed"
				if strings.Contains(response, message) {
					responseChannel <- "Test '" + testName + "': passed."
				} else {
					responseChannel <- "Test '" + testName + "': failed."
					//t.Error("Test '" + testName + "': failed.");
				}
				break
			} else if testName == "SubscriptionConnectStatus" {
				message = "'" + channel + "' connected"
				if strings.Contains(response, message) {
					responseChannel <- "Test '" + testName + "': passed."
				} else {
					responseChannel <- "Test '" + testName + "': failed."
					//t.Error("Test '" + testName + "': failed.");
				}
				break
			}
		}
	}
}

// TestMultipleResponse publishes 2 messages and then parses the response
// by creating a subsribe request with a timetoken prior to publishing of the messages
// on subscribing we will get one response with multiple messages which should be split into
// 2 by the client api.
func TestMultipleResponse(t *testing.T) {
	SendMultipleResponse(t, false)
}

// TestMultipleResponseEncrypted publishes 2 messages and then parses the response
// by creating a subsribe request with a timetoken prior to publishing of the messages
// on subscribing we will get one response with multiple messages which should be split into
// 2 by the clinet api.
func TestMultipleResponseEncrypted(t *testing.T) {
	SendMultipleResponse(t, true)
}

// SendMultipleResponse is the common implementation for TestMultipleResponsed and
// TestMultipleResponseEncrypted
func SendMultipleResponse(t *testing.T, encrypted bool) {
	cipher := ""
	testName := "TestMultipleResponse"
	if encrypted {
		cipher = "enigma"
		testName = "TestMultipleResponseEncrypted"
	}
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", cipher, false, "")
	//pubnubChannel := "testChannel"
	r := GenRandom()
	pubnubChannel := fmt.Sprintf("testChannel_sub_%d", r.Intn(20))

	returnTimeChannel := make(chan []byte)
	errorChannelTime := make(chan []byte)

	go pubnubInstance.GetTime(returnTimeChannel, errorChannelTime)

	retTime, errTime := ParseTimeFromServer(returnTimeChannel, errorChannelTime)
	if errTime == nil {
		message1 := "message1"
		message2 := "message2"
		returnPublishChannel := make(chan []byte)
		errorChannelPub := make(chan []byte)

		go pubnubInstance.Publish(pubnubChannel, message1, returnPublishChannel, errorChannelPub)
		b1, _ := ParsePublishResponseFromServer(returnPublishChannel, errorChannelPub)

		returnPublishChannel2 := make(chan []byte)
		errorChannelPub2 := make(chan []byte)
		time.Sleep(time.Duration(2) * time.Second)

		go pubnubInstance.Publish(pubnubChannel, message2, returnPublishChannel2, errorChannelPub2)
		b2, _ := ParsePublishResponseFromServer(returnPublishChannel2, errorChannelPub2)

		if b1 && b2 {

			returnSubscribeChannel := make(chan []byte)
			errorChannelSub := make(chan []byte)
			responseChannelSub := make(chan string)
			waitChannelSub := make(chan string)

			go pubnubInstance.Subscribe(pubnubChannel, retTime, returnSubscribeChannel, false, errorChannelSub)
			go ParseSubscribeMultiResponse(pubnubChannel, returnSubscribeChannel, message1, message2, cipher, testName, responseChannelSub)
			go ParseErrorResponse(errorChannelSub, responseChannelSub)
			go WaitForCompletion(responseChannelSub, waitChannelSub)
			ParseWaitResponse(waitChannelSub, t, testName)
			go pubnubInstance.Unsubscribe(pubnubChannel, returnSubscribeChannel, errorChannelSub)
			pubnubInstance.CloseExistingConnection()
		}
	}
}

// ParseSubscribeMultiResponse reads the response on the returnChannel and looks for message1 and
// message2. If both messages are received the response with passed status is sent on the
// responseChannel.
func ParseSubscribeMultiResponse(channel string, returnChannel chan []byte, message1 string, message2 string, cipher string, testName string, responseChannel chan string) {
	messageCount := 0
	for {
		value, ok := <-returnChannel
		if !ok {
			break
		}
		if string(value) != "[]" {
			response := fmt.Sprintf("%s", value)
			message := "'" + channel + "' connected"
			if strings.Contains(response, message) {
				continue
			} else {
				var s []interface{}
				err := json.Unmarshal(value, &s)
				if err == nil {
					if len(s) > 0 {
						if message, ok := s[0].([]interface{}); ok {
							if messageT, ok2 := message[0].(string); ok2 {
								if (len(message) > 0) && (messageT == message1) {
									messageCount++
								}
								if (len(message) > 0) && (messageT == message2) {
									messageCount++
								}
							}
						}
					}
				}

				if messageCount >= 2 {
					responseChannel <- "Test '" + testName + "': passed."
					break
				}
			}
		}
	}
}

// ParsePublishResponseFromServer returns true if the "Sent" message is found
// on the returnChannel's response.
// On error it returns the error.
func ParsePublishResponseFromServer(returnChannel chan []byte, errorChannel chan []byte) (bool, error) {
	retBool := false
	retError := fmt.Errorf("")

	for {
		value, ok := <-returnChannel
		if !ok {
			break
		}
		if string(value) != "[]" {
			response := fmt.Sprintf("%s", value)
			message := "Sent"
			//fmt.Println("response:", string(value), strings.Contains(response, message))
			if strings.Contains(response, message) {
				retBool = true
			}
			break
		}
	}
	return retBool, retError
}

// ParseTimeResponse parses the time response from the pubnub api.
// On error it returns the error
func ParseTimeFromServer(returnChannel chan []byte, errorChannel chan []byte) (string, error) {
	retVal := ""
	retError := fmt.Errorf("")
	for {
		select {
		case value, ok := <-returnChannel:
			if !ok {
				fmt.Println("")
				break
			}

			if string(value) != "[]" {
				var s []interface{}
				err := json.Unmarshal(value, &s)
				//fmt.Println("response:", string(value))
				if err == nil {
					retVal = messaging.ParseInterfaceData(s[0])
					return retVal, nil
				}
				retError = err
				return "", retError
			}
			break
		case value, ok := <-errorChannel:
			if !ok {
				fmt.Println("")
				break
			}

			if string(value) != "[]" {
				retError = fmt.Errorf(timeoutMessage)
				return "", retError
			}
			break
		}
	}
	return retVal, retError
}

// TestResumeOnReconnectFalse upon reconnect, it should use a 0 (zero) timetoken.
// This has the effect of continuing from “this moment onward”.
// Any messages received since the previous timeout or network error are skipped
func TestResumeOnReconnectFalse(t *testing.T) {
	ResumeOnReconnect(t, false)
}

// TestResumeOnReconnectTrue upon reconnect, it should use the last successfully retrieved timetoken.
// This has the effect of continuing, or “catching up” to missed traffic.
func TestResumeOnReconnectTrue(t *testing.T) {
	ResumeOnReconnect(t, true)
}

// ResumeOnReconnect contains the actual impementation of both TestResumeOnReconnectFalse and TestResumeOnReconnectTrue
// the parameter b determines of resume on reconnect setting is true or false.
//
// The test contains a data race
func ResumeOnReconnect(t *testing.T, b bool) {
	testName := "ResumeOnReconnectFalse"
	if b {
		messaging.SetResumeOnReconnect(true)
		testName = "ResumeOnReconnectTrue"
	} else {
		messaging.SetResumeOnReconnect(false)
	}
	r := GenRandom()
	pubnubChannel := fmt.Sprintf("testChannel_subror_%d", r.Intn(20))

	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, "")
	returnSubscribeChannel := make(chan []byte)
	errorChannelSub := make(chan []byte)
	responseChannelSub := make(chan string)
	waitChannelSub := make(chan string)

	messaging.SetSubscribeTimeout(12)
	go pubnubInstance.Subscribe(pubnubChannel, "", returnSubscribeChannel, false, errorChannelSub)
	go ParseSubscribeForTimetoken(pubnubInstance, pubnubChannel, returnSubscribeChannel, errorChannelSub, testName, responseChannelSub)
	go WaitForCompletion(responseChannelSub, waitChannelSub)
	ParseWaitResponse(waitChannelSub, t, testName)
	messaging.SetSubscribeTimeout(310)
	go pubnubInstance.Unsubscribe(pubnubChannel, returnSubscribeChannel, errorChannelSub)
	pubnubInstance.CloseExistingConnection()
}

// ParseSubscribeForTimetoken retrieves the last timetoken and matches with the senttimetoken
// In case if resumeonreconnect is true the time token should be same.
// and in case if resumeonreconnect is false the timetoken should be 0.
//
// parameters:
// pubnubInstance: messaging.Pubnub instance.
// pubnubChannel: pubnub channel used.
// returnChannel: channel used to read the response.
// errorChannel: channel used to read the error response.
// testName: testname for display.
// responseChannel: channel to send the response back.
func ParseSubscribeForTimetoken(pubnubInstance *messaging.Pubnub, pubnubChannel string, returnChannel chan []byte, errorChannel chan []byte, testName string, responseChannel chan string) {
	for {
		select {
		case value, ok := <-returnChannel:
			if !ok {
				fmt.Println("")
				break
			}
			if string(value) != "[]" {
			}
		case value, ok := <-errorChannel:
			if !ok {
				fmt.Println("")
				break
			}
			if string(value) != "[]" {
				newPubnubTest := &messaging.PubnubUnitTest{}
				if testName == "ResumeOnReconnectTrue" {
					fmt.Println(fmt.Sprintf("SentTimeToken %s TimeToken %s", newPubnubTest.GetSentTimeToken(pubnubInstance), newPubnubTest.GetTimeToken(pubnubInstance)))
					if newPubnubTest.GetSentTimeToken(pubnubInstance) == newPubnubTest.GetTimeToken(pubnubInstance) {
						responseChannel <- "passed"
					} else {
						responseChannel <- "failed"
					}
				} else {
					fmt.Println(fmt.Sprintf("SentTimeToken %s", newPubnubTest.GetSentTimeToken(pubnubInstance)))
					if newPubnubTest.GetSentTimeToken(pubnubInstance) != "0" {
						responseChannel <- "failed"
					} else {
						responseChannel <- "passed"
					}
				}
				break
			}
		}
	}
}

// TestMultiplexing tests the multiplexed subscribe request.
func TestMultiplexing(t *testing.T) {
	SendMultiplexingRequest(t, "TestMultiplexing", false, false)
}

// TestMultiplexing tests the multiplexed subscribe request wil ssl.
func TestMultiplexingSSL(t *testing.T) {
	SendMultiplexingRequest(t, "TestMultiplexingSSL", true, false)
}

// TestMultiplexing tests the encrypted multiplexed subscribe request.
func TestEncryptedMultiplexing(t *testing.T) {
	SendMultiplexingRequest(t, "TestEncryptedMultiplexing", false, true)
}

// TestMultiplexing tests the encrypted multiplexed subscribe request with ssl.
func TestEncryptedMultiplexingWithSSL(t *testing.T) {
	SendMultiplexingRequest(t, "TestEncryptedMultiplexingWithSSL", true, true)
}

// SendMultiplexingRequest is the common method to test TestMultiplexing,
// TestMultiplexingSSL, TestEncryptedMultiplexing, TestEncryptedMultiplexingWithSSL.
//
// It subscribes to 2 channels in the same request and then calls the ParseSubscribeMultiplexedResponse
// for further processing.
//
// Parameters:
// t: *testing.T instance.
// testName: testname for display.
// ssl: ssl setting.
// encrypted: encryption setting.
func SendMultiplexingRequest(t *testing.T, testName string, ssl bool, encrypted bool) {
	cipher := ""
	if encrypted {
		cipher = "enigma"
	}
	message1 := "message1"
	message2 := "message2"
	r := GenRandom()

	pubnubChannel1 := fmt.Sprintf("testChannel_sub_%d", r.Intn(20))
	pubnubChannel2 := fmt.Sprintf("testChannel_sub_%d", r.Intn(20))

	pubnubChannel := pubnubChannel1 + "," + pubnubChannel2

	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", cipher, ssl, "")
	returnSubscribeChannel := make(chan []byte)
	errorChannelSub := make(chan []byte)
	responseChannelSub := make(chan string)
	waitChannelSub := make(chan string)

	go pubnubInstance.Subscribe(pubnubChannel, "", returnSubscribeChannel, false, errorChannelSub)
	go ParseSubscribeMultiplexedResponse(pubnubInstance, returnSubscribeChannel, message1, message2, pubnubChannel1, pubnubChannel2, testName, responseChannelSub)
	//go ParseErrorResponse(errorChannelSub, responseChannelSub)
	go ParseResponseDummyMessage(errorChannelSub, "aborted", responseChannelSub)
	go WaitForCompletion(responseChannelSub, waitChannelSub)
	ParseWaitResponse(waitChannelSub, t, testName)
	go pubnubInstance.Unsubscribe(pubnubChannel, returnSubscribeChannel, errorChannelSub)
	pubnubInstance.CloseExistingConnection()
}

// ParseSubscribeMultiplexedResponse publishes 2 messages on 2 different channels and
// when both the channels are connected
// it reads the responseChannel for the 2 messages. If we get the same 2 messages as response
// the test is passed.
//
// parameters:
// pubnubInstance: an instace of *messaging.Pubnub,
// returnSubscribeChannel: the channel to read the subscribe response on.
// message1: first message to publish.
// message2: second message to publish.
// pubnubChannel1: pubnub Channel 1 to publish the first message.
// pubnubChannel2: pubnub Channel 2 to publish the second message.
// testName: test name.
// responseChannel: the channelto send a response back.
func ParseSubscribeMultiplexedResponse(pubnubInstance *messaging.Pubnub, returnSubscribeChannel chan []byte, message1 string, message2 string, pubnubChannel1 string, pubnubChannel2 string, testName string, responseChannel chan string) {
	messageCount := 0
	channelCount := 0
	for {
		value, ok := <-returnSubscribeChannel
		if !ok {
			break
		}
		if string(value) != "[]" {
			response := fmt.Sprintf("%s", value)
			message := "' connected"
			messageT1 := "'" + pubnubChannel1 + "' connected"
			messageT2 := "'" + pubnubChannel2 + "' connected"
			if strings.Contains(response, message) {
				if strings.Contains(response, messageT1) {
					channelCount++
				}

				if strings.Contains(response, messageT2) {
					channelCount++
				}
				if channelCount >= 2 {
					returnPublishChannel := make(chan []byte)
					errorChannelPub := make(chan []byte)

					go pubnubInstance.Publish(pubnubChannel1, message1, returnPublishChannel, errorChannelPub)
					go ParseResponseDummy(returnPublishChannel)
					go ParseResponseDummy(errorChannelPub)

					returnPublishChannel2 := make(chan []byte)
					errorChannelPub2 := make(chan []byte)

					go pubnubInstance.Publish(pubnubChannel2, message2, returnPublishChannel2, errorChannelPub2)
					go ParseResponseDummy(returnPublishChannel2)
					go ParseResponseDummy(errorChannelPub2)
				}
			} else {
				var s []interface{}
				err := json.Unmarshal(value, &s)
				if err == nil {
					if len(s) > 2 {
						if message, ok := s[0].([]interface{}); ok {
							if messageT, ok2 := message[0].(string); ok2 {
								if (len(message) > 0) && (messageT == message1) && (s[2].(string) == pubnubChannel1) {
									messageCount++
								}
								if (len(message) > 0) && (messageT == message2) && (s[2].(string) == pubnubChannel2) {
									messageCount++
								}
							}
						}
					}
				}

				if messageCount >= 2 {
					responseChannel <- "Test '" + testName + "': passed."
					break
				}
			}
		}
	}
}

// TestSubscribeEnd prints a message on the screen to mark the end of
// subscribe tests.
// PrintTestMessage is defined in the common.go file.
func TestSubscribeEnd(t *testing.T) {
	PrintTestMessage("==========Subscribe tests end==========")
}
