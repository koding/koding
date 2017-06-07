// Package tests has the unit tests of package messaging.
// pubnubSubscribe_test.go contains the tests related to the Subscribe requests on pubnub Api
package tests

import (
	"encoding/json"
	"encoding/xml"
	"fmt"
	"github.com/pubnub/go/messaging"
	"github.com/pubnub/go/messaging/tests/utils"
	"github.com/stretchr/testify/assert"
	//"log"
	//"os"
	"strconv"
	"strings"
	"sync"
	"testing"
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
	assert := assert.New(t)

	stop, _ := NewVCRBoth(
		"fixtures/subscribe/connectStatus", []string{"uuid"})
	defer stop()

	channel := "Channel_ConnectStatus"
	uuid := "UUID_ConnectStatus"
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, uuid, CreateLoggerForTests())

	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)
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

	go pubnubInstance.Unsubscribe(channel, unsubscribeSuccessChannel, unsubscribeErrorChannel)
	ExpectUnsubscribedEvent(t, channel, "", unsubscribeSuccessChannel, unsubscribeErrorChannel)
}

// TestMultiSubscriptionConnectStatus send out a pubnub multi channel subscribe request and
// parses the response for multiple connection status.
func TestMultiSubscriptionConnectStatus(t *testing.T) {
	// TODO: test passes successfully, but some errors about extra interactions exists
	assert := assert.New(t)

	stop, _ := NewVCRBoth("fixtures/subscribe/connectMultipleStatus", []string{"uuid"})
	defer stop()

	channels := "Channel_ConnectStatus_14,Channel_ConnectStatus_992"
	uuid := "UUID_ConnectStatus"
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, uuid, CreateLoggerForTests())

	expectedChannels := strings.Split(channels, ",")
	actualChannels := []string{}
	var actualMu sync.Mutex

	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	unsubscribeSuccessChannel := make(chan []byte)
	unsubscribeErrorChannel := make(chan []byte)
	await := make(chan bool)

	go pubnubInstance.Subscribe(channels, "", successChannel, false, errorChannel)
	go func() {

		for {
			select {
			case resp := <-successChannel:
				var response []interface{}

				err := json.Unmarshal(resp, &response)
				if err != nil {
					assert.Fail(err.Error())
				}

				assert.Len(response, 3)
				assert.Contains(response[1].(string), "Subscription to channel")
				assert.Contains(response[1].(string), "connected")

				actualMu.Lock()
				actualChannels = append(actualChannels, response[2].(string))
				l := len(actualChannels)
				actualMu.Unlock()

				if l == 2 {
					await <- true
					return
				}

			case err := <-errorChannel:
				assert.Fail(string(err))

				await <- false
			case <-timeouts(5):
				assert.Fail("Subscribe timeout 5s")
				await <- false
			}

		}
	}()

	select {
	case <-await:
		actualMu.Lock()
		assert.True(utils.AssertStringSliceElementsEqual(expectedChannels, actualChannels),
			fmt.Sprintf("%s(expected) should be equal to %s(actual)", expectedChannels, actualChannels))
		actualMu.Unlock()
	case <-timeouts(10):
		assert.Fail("Timeout connecting channels")
	}

	go pubnubInstance.Unsubscribe(channels, unsubscribeSuccessChannel, unsubscribeErrorChannel)
	ExpectUnsubscribedEvent(t, channels, "", unsubscribeSuccessChannel, unsubscribeErrorChannel)
}

// TestSubscriptionForSimpleMessageV2 first subscribes to a pubnub channel and then publishes
// a message on the same pubnub channel. The subscribe response should receive this same message.
func TestSubscriptionForSimpleMessageV2(t *testing.T) {
	assert := assert.New(t)

	stop, _ := NewVCRBoth("fixtures/subscribe/forSimpleMessage", []string{"uuid"})
	defer stop()

	channel := "Channel_SubscriptionConnectedForSimple"
	uuid := "UUID_SubscriptionConnectedForSimple"
	//messaging.LoggingEnabled(true)
	//messaging.SetLogOutput(os.Stdout)
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, uuid, CreateLoggerForTests())

	customMessage := "Test message"

	var statusChannel = make(chan *messaging.PNStatus)
	var messageChannel = make(chan *messaging.PNMessageResult)
	var presenceChannel = make(chan *messaging.PNPresenceEventResult)

	unsubscribeSuccessChannel := make(chan []byte)
	unsubscribeErrorChannel := make(chan []byte)
	await := make(chan bool)
	go pubnubInstance.SubscribeV2(channel, "", "", false, statusChannel, messageChannel, presenceChannel)
	go func() {
		for {
			select {
			case _ = <-presenceChannel:
			case response := <-messageChannel:
				assert.Equal(response.Payload, customMessage)
				close(await)
				return
			case err := <-statusChannel:
				if err.IsError {
					fmt.Println("Error:", err.ErrorData.Information)
					fmt.Println("Category:", err.Category)
					fmt.Println("AffectedChannels:", strings.Join(err.AffectedChannels, ","))
					fmt.Println("AffectedChannelGroups:", strings.Join(err.AffectedChannelGroups, ","))
				} else if err.Category == messaging.PNConnectedCategory {
					successChannel := make(chan []byte)
					errorChannel := make(chan []byte)

					go pubnubInstance.Publish(channel, customMessage,
						successChannel, errorChannel)
					select {
					case <-successChannel:
					case err := <-errorChannel:
						assert.Fail(string(err))
					case <-timeout():
						assert.Fail("Publish timeout")
					}
				} else {
					fmt.Println("Category:", err.Category)
				}
			case <-timeouts(5):
				assert.Fail("Subscribe timeout 3s")
				close(await)
				return
			}
		}
	}()

	<-await

	go pubnubInstance.Unsubscribe(channel, unsubscribeSuccessChannel, unsubscribeErrorChannel)
	ExpectUnsubscribedEvent(t, channel, "", unsubscribeSuccessChannel, unsubscribeErrorChannel)

	// pubnubInstance.CloseExistingConnection()
}

// TestSubscriptionForSimpleMessage first subscribes to a pubnub channel and then publishes
// a message on the same pubnub channel. The subscribe response should receive this same message.
func TestSubscriptionForSimpleMessage(t *testing.T) {
	assert := assert.New(t)

	stop, _ := NewVCRBoth("fixtures/subscribe/forSimpleMessage", []string{"uuid"})
	defer stop()

	channel := "Channel_SubscriptionConnectedForSimple"
	uuid := "UUID_SubscriptionConnectedForSimple"
	//messaging.LoggingEnabled(true)
	//messaging.SetLogOutput(os.Stdout)
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, uuid, CreateLoggerForTests())

	customMessage := "Test message"

	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	unsubscribeSuccessChannel := make(chan []byte)
	unsubscribeErrorChannel := make(chan []byte)
	await := make(chan bool)

	go pubnubInstance.Subscribe(channel, "", successChannel, false, errorChannel)
	go func() {
		for {
			select {
			case resp := <-successChannel:
				response := fmt.Sprintf("%s", resp)
				if response != "[]" {
					message := "'" + channel + "' connected"

					if strings.Contains(response, message) {

						successChannel := make(chan []byte)
						errorChannel := make(chan []byte)

						go pubnubInstance.Publish(channel, customMessage,
							successChannel, errorChannel)
						select {
						case <-successChannel:
						case err := <-errorChannel:
							assert.Fail(string(err))
						case <-timeout():
							assert.Fail("Publish timeout")
						}
					} else {
						assert.Contains(response, customMessage)

						close(await)
						return
					}
				}
			case err := <-errorChannel:
				assert.Fail(string(err))

				close(await)
				return
			case <-timeouts(5):
				assert.Fail("Subscribe timeout 3s")
				close(await)
				return
			}

		}
	}()

	<-await

	go pubnubInstance.Unsubscribe(channel, unsubscribeSuccessChannel, unsubscribeErrorChannel)
	ExpectUnsubscribedEvent(t, channel, "", unsubscribeSuccessChannel, unsubscribeErrorChannel)

	// pubnubInstance.CloseExistingConnection()
}

// TestSubscriptionForSimpleMessageWithCipher first subscribes to a pubnub channel and then publishes
// an encrypted message on the same pubnub channel. The subscribe response should receive
// the decrypted message.
func TestSubscriptionForSimpleMessageWithCipher(t *testing.T) {
	assert := assert.New(t)

	stop, _ := NewVCRBoth("fixtures/subscribe/forSimpleMessageWithCipher", []string{"uuid"})
	defer stop()

	channel := "Channel_SubscriptionConnectedForSimpleWithCipher"
	uuid := "UUID_SubscriptionConnectedForSimpleWithCipher"
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "enigma", false, uuid, CreateLoggerForTests())

	customMessage := "Test message"

	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	unsubscribeSuccessChannel := make(chan []byte)
	unsubscribeErrorChannel := make(chan []byte)
	await := make(chan bool)

	go pubnubInstance.Subscribe(channel, "", successChannel, false, errorChannel)
	go func() {
		for {
			select {
			case resp := <-successChannel:
				response := fmt.Sprintf("%s", resp)
				if response != "[]" {
					message := "'" + channel + "' connected"

					if strings.Contains(response, message) {

						successChannel := make(chan []byte)
						errorChannel := make(chan []byte)

						go pubnubInstance.Publish(channel, customMessage,
							successChannel, errorChannel)
						select {
						case <-successChannel:
						case err := <-errorChannel:
							assert.Fail(string(err))
						case <-timeout():
							assert.Fail("Publish timeout")
						}
					} else {
						assert.Contains(response, customMessage)

						close(await)
						return
					}
				}
			case err := <-errorChannel:
				assert.Fail(string(err))

				close(await)
				return
			case <-timeouts(3):
				assert.Fail("Subscribe timeout 3s")
				close(await)
				return
			}
		}
	}()

	<-await

	go pubnubInstance.Unsubscribe(channel, unsubscribeSuccessChannel, unsubscribeErrorChannel)
	ExpectUnsubscribedEvent(t, channel, "", unsubscribeSuccessChannel, unsubscribeErrorChannel)

	// pubnubInstance.CloseExistingConnection()
}

// TestSubscriptionForComplexMessage first subscribes to a pubnub channel and then publishes
// a complex message on the same pubnub channel. The subscribe response should receive
// the same message.
func TestSubscriptionForComplexMessage(t *testing.T) {
	assert := assert.New(t)

	stop, _ := NewVCRBoth("fixtures/subscribe/forComplexMessage", []string{"uuid"})
	defer stop()

	channel := "Channel_SubscriptionConnectedForComplex"
	uuid := "UUID_SubscriptionConnectedForComplex"
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, uuid, CreateLoggerForTests())

	customComplexMessage := InitComplexMessage()

	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	unsubscribeSuccessChannel := make(chan []byte)
	unsubscribeErrorChannel := make(chan []byte)
	await := make(chan bool)

	go pubnubInstance.Subscribe(channel, "", successChannel, false, errorChannel)
	go func() {
		for {
			select {
			case resp := <-successChannel:
				response := fmt.Sprintf("%s", resp)
				if response != "[]" {
					message := "'" + channel + "' connected"

					if strings.Contains(response, message) {

						successChannel := make(chan []byte)
						errorChannel := make(chan []byte)

						go pubnubInstance.Publish(channel, customComplexMessage,
							successChannel, errorChannel)
						select {
						case <-successChannel:
						case err := <-errorChannel:
							assert.Fail(string(err))
						case <-timeout():
							assert.Fail("Publish timeout")
						}
					} else {
						var arr []interface{}
						err := json.Unmarshal(resp, &arr)
						if err != nil {
							assert.Fail(err.Error())
						} else {
							assert.True(CheckComplexData(arr))
						}

						close(await)
						return
					}
				}
			case err := <-errorChannel:
				if !IsConnectionRefusedError(err) {
					assert.Fail(string(err))
				}

				close(await)
				return
			case <-timeouts(3):
				assert.Fail("Subscribe timeout 3s")
				close(await)
				return
			}

		}
	}()

	<-await

	go pubnubInstance.Unsubscribe(channel, unsubscribeSuccessChannel, unsubscribeErrorChannel)
	ExpectUnsubscribedEvent(t, channel, "", unsubscribeSuccessChannel, unsubscribeErrorChannel)

	// pubnubInstance.CloseExistingConnection()
}

// TestSubscriptionForComplexMessageWithCipher first subscribes to a pubnub channel and then publishes
// an encrypted complex message on the same pubnub channel. The subscribe response should receive
// the decrypted message.
func TestSubscriptionForComplexMessageWithCipher(t *testing.T) {
	assert := assert.New(t)

	stop, _ := NewVCRBoth("fixtures/subscribe/forComplexMessageWithCipher", []string{"uuid"})
	defer stop()

	channel := "Channel_SubscriptionConnectedForComplexWithCipher"
	uuid := "UUID_SubscriptionConnectedForComplexWithCipher"
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "enigma", false, uuid, CreateLoggerForTests())

	customMessage := InitComplexMessage()

	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	unsubscribeSuccessChannel := make(chan []byte)
	unsubscribeErrorChannel := make(chan []byte)
	await := make(chan bool)

	go pubnubInstance.Subscribe(channel, "", successChannel, false, errorChannel)
	go func() {
		for {
			select {
			case resp := <-successChannel:
				response := fmt.Sprintf("%s", resp)
				if response != "[]" {
					message := "'" + channel + "' connected"

					if strings.Contains(response, message) {

						successChannel := make(chan []byte)
						errorChannel := make(chan []byte)

						go pubnubInstance.Publish(channel, customMessage,
							successChannel, errorChannel)
						select {
						case <-successChannel:
						case err := <-errorChannel:
							assert.Fail(string(err))
						case <-timeout():
							assert.Fail("Publish timeout")
						}
					} else {
						var arr []interface{}
						err := json.Unmarshal(resp, &arr)
						if err != nil {
							assert.Fail(err.Error())
						} else {
							assert.True(CheckComplexData(arr))
						}

						close(await)
						return
					}
				}
			case err := <-errorChannel:
				if !IsConnectionRefusedError(err) {
					assert.Fail(string(err))
				}

				close(await)
				return
			case <-timeouts(3):
				assert.Fail("Subscribe timeout 3s")
				close(await)
				return
			}
		}
	}()

	<-await

	go pubnubInstance.Unsubscribe(channel, unsubscribeSuccessChannel, unsubscribeErrorChannel)
	ExpectUnsubscribedEvent(t, channel, "", unsubscribeSuccessChannel, unsubscribeErrorChannel)

	// pubnubInstance.CloseExistingConnection()
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
		// fmt.Println("k:", k, "v:", v)
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

// TestMultipleResponse publishes 2 messages and then parses the response
// by creating a subsribe request with a timetoken prior to publishing of the messages
// on subscribing we will get one response with multiple messages which should be split into
// 2 by the client api.
func TestMultipleResponse(t *testing.T) {
	SendMultipleResponse(t, false, "multipleResponse", "")
}

// TestMultipleResponseEncrypted publishes 2 messages and then parses the response
// by creating a subsribe request with a timetoken prior to publishing of the messages
// on subscribing we will get one response with multiple messages which should be split into
// 2 by the clinet api.
func TestMultipleResponseEncrypted(t *testing.T) {
	SendMultipleResponse(t, true, "multipleResponseEncrypted", "enigma")
}

// SendMultipleResponse is the common implementation for TestMultipleResponsed and
// TestMultipleResponseEncrypted
func SendMultipleResponse(t *testing.T, encrypted bool, testName, cipher string) {
	assert := assert.New(t)

	stop, _ := NewVCRBoth(fmt.Sprintf("fixtures/subscribe/%s", testName), []string{"uuid"})
	defer stop()
	//messaging.LoggingEnabled(true)
	//messaging.SetLogOutput(os.Stdout)

	channel := "Channel_MultipleResponse"
	uuid := "UUID_MultipleResponse"
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", cipher, false, uuid, CreateLoggerForTests())

	unsubscribeSuccessChannel := make(chan []byte)
	unsubscribeErrorChannel := make(chan []byte)

	retTime := GetServerTimeString("time_uuid")
	//fmt.Println("time is", retTime)

	message1 := "message1"
	message2 := "message2"

	successChannelPublish := make(chan []byte)
	errorChannelPublish := make(chan []byte)
	await1 := make(chan bool)
	go pubnubInstance.Publish(channel, message1, successChannelPublish,
		errorChannelPublish)
	go func() {
		select {
		case <-successChannelPublish:
			//log.Printf("published %s", mess)
			await1 <- true
		case err := <-errorChannelPublish:
			assert.Fail("Publish #1 error", string(err))
			await1 <- true
		case <-timeout():
			assert.Fail("Publish #1 timeout")
			await1 <- true
		}
	}()
	<-await1
	successChannelPublish2 := make(chan []byte)
	errorChannelPublish2 := make(chan []byte)
	await2 := make(chan bool)
	go pubnubInstance.Publish(channel, message2, successChannelPublish2,
		errorChannelPublish2)
	go func() {
		select {
		case <-successChannelPublish2:
			//log.Printf("published %s", mess)
			await2 <- true
		case err := <-errorChannelPublish2:
			assert.Fail("Publish #2 error", string(err))
			await2 <- true
		case <-timeout():
			assert.Fail("Publish #2 timeout")
			await2 <- true
		}
	}()
	<-await2
	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	await := make(chan bool)

	go pubnubInstance.Subscribe(channel, retTime, successChannel, false, errorChannel)

	go func() {
		messageCount := 0
		//log.Printf("in func")
		for {
			//log.Printf("in for")
			select {
			case value := <-successChannel:
				response := fmt.Sprintf("%s", value)
				//log.Printf("response %s", response)
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
						await <- true
						return
					}
				}

			case err := <-errorChannel:
				assert.Fail("Subscribe error", string(err))
				await <- false
				return
			case <-timeout():
				assert.Fail("Subscribe timeout")
				await <- false
				return
			}
		}
	}()
	//log.Printf("awaiting")
	<-await
	//log.Printf("after wait")
	go pubnubInstance.Unsubscribe(channel, unsubscribeSuccessChannel, unsubscribeErrorChannel)
	ExpectUnsubscribedEvent(t, channel, "", unsubscribeSuccessChannel, unsubscribeErrorChannel)

	// pubnubInstance.CloseExistingConnection()
}

// TestMultiplexing tests the multiplexed subscribe request.
func TestMultiplexing(t *testing.T) {
	SendMultiplexingRequest(t, "testMultiplexing", false, false)
}

// TestMultiplexing tests the multiplexed subscribe request wil ssl.
func xTestMultiplexingSSL(t *testing.T) {
	// TODO: handle SSL && VCR
	SendMultiplexingRequest(t, "testMultiplexingSSL", true, false)
}

// TestMultiplexing tests the encrypted multiplexed subscribe request.
func TestMultiplexingEncrypted(t *testing.T) {
	SendMultiplexingRequest(t, "testEncryptedMultiplexing", false, true)
}

// TestMultiplexing tests the encrypted multiplexed subscribe request with ssl.
func xTestMultiplexingEncryptedWithSSL(t *testing.T) {
	// TODO: handle SSL && VCR
	SendMultiplexingRequest(t, "testEncryptedMultiplexingWithSSL", true, true)
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
	assert := assert.New(t)

	stop, _ := NewVCRBoth(fmt.Sprintf("fixtures/subscribe/%s", testName),
		[]string{"uuid"})
	defer stop()

	cipher := ""
	if encrypted {
		cipher = "enigma"
	}

	message1 := "message1"
	message2 := "message2"

	pubnubChannel1 := "Mpx_Channel_1"
	pubnubChannel2 := "Mpx_Channel_2"

	pubnubChannels := pubnubChannel1 + "," + pubnubChannel2
	uuid := "UUID_Multiplexing"

	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", cipher, ssl, uuid, CreateLoggerForTests())

	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)

	unsubscribeSuccessChannel := make(chan []byte)
	unsubscribeErrorChannel := make(chan []byte)

	await := make(chan bool)

	go pubnubInstance.Subscribe(pubnubChannels, "", successChannel, false, errorChannel)

	go func() {
		messageCount := 0
		channelCount := 0

		for {
			select {
			case value := <-successChannel:

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
							select {
							case <-returnPublishChannel:
							case err := <-errorChannelPub:
								assert.Fail(string(err))
								return
							case <-timeout():
								assert.Fail("Publish msg#1 timeout")
							}

							returnPublishChannel2 := make(chan []byte)
							errorChannelPub2 := make(chan []byte)

							go pubnubInstance.Publish(pubnubChannel2, message2, returnPublishChannel2, errorChannelPub2)
							select {
							case <-returnPublishChannel2:
							case err := <-errorChannelPub2:
								assert.Fail(string(err))
								return
							case <-timeout():
								assert.Fail("Publish msg#2 timeout")
							}
						}
					} else {
						var s []interface{}
						err := json.Unmarshal(value, &s)
						if err == nil {
							if len(s) > 2 {
								if message, ok := s[0].([]interface{}); ok {
									if messageT, ok2 := message[0].(string); ok2 {
										// TODO: populate an actual slice and compare it to expected

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
							await <- true
							return
						}
					}
				}
			case err := <-errorChannel:
				assert.Fail(string(err))
			case <-timeouts(10):
				assert.Fail("Subscribe timeout")
			}
		}
	}()

	<-await

	go pubnubInstance.Unsubscribe(pubnubChannels, unsubscribeSuccessChannel, unsubscribeErrorChannel)
	ExpectUnsubscribedEvent(t, pubnubChannels, "", unsubscribeSuccessChannel, unsubscribeErrorChannel)

	// pubnubInstance.CloseExistingConnection()
}

func TestSubscriptionForMessageFiltering(t *testing.T) {
	assert := assert.New(t)

	stop, _ := NewVCRBoth("fixtures/subscribe/forMessageFiltering", []string{"uuid"})
	defer stop()

	channel := "Channel_SubscriptionConnectedForMessageFiltering"
	uuid := "UUID_SubscriptionConnectedForMessageFiltering"
	//messaging.LoggingEnabled(true)
	//messaging.SetLogOutput(os.Stdout)
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, uuid, CreateLoggerForTests())

	customMessage := "Test message"

	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	unsubscribeSuccessChannel := make(chan []byte)
	unsubscribeErrorChannel := make(chan []byte)
	await := make(chan bool)
	meta := "{\"meta\":\"filter\"}"

	pubnubInstance.SetFilterExpression(meta)
	go pubnubInstance.Subscribe(channel, "", successChannel, false, errorChannel)
	go func() {
		for {
			select {
			case resp := <-successChannel:
				response := fmt.Sprintf("%s", resp)
				if response != "[]" {
					message := "'" + channel + "' connected"

					if strings.Contains(response, message) {

						successChannel := make(chan []byte)
						errorChannel := make(chan []byte)

						go pubnubInstance.PublishExtendedWithMeta(channel, customMessage, meta,
							true, false, successChannel, errorChannel)
						select {
						case <-successChannel:
						case err := <-errorChannel:
							assert.Fail(string(err))
						case <-timeout():
							assert.Fail("Publish timeout")
						}
					} else {
						assert.Contains(response, customMessage)

						close(await)
						return
					}
				}
			case err := <-errorChannel:
				assert.Fail(string(err))

				close(await)
				return
			case <-timeouts(10):
				assert.Fail("Subscribe timeout 3s")
				close(await)
				return
			}

		}
	}()

	<-await

	go pubnubInstance.Unsubscribe(channel, unsubscribeSuccessChannel, unsubscribeErrorChannel)
	ExpectUnsubscribedEvent(t, channel, "", unsubscribeSuccessChannel, unsubscribeErrorChannel)

	// pubnubInstance.CloseExistingConnection()
}

func TestSubscriptionForMessageFiltering2(t *testing.T) {
	assert := assert.New(t)

	stop, _ := NewVCRBoth("fixtures/subscribe/forMessageFiltering2", []string{"uuid"})
	defer stop()

	channel := "Channel_SubscriptionConnectedForMessageFiltering2"
	uuid := "UUID_SubscriptionConnectedForMessageFiltering2"
	//messaging.LoggingEnabled(true)
	//messaging.SetLogOutput(os.Stdout)
	//log.SetOutput(os.Stdout)
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, uuid, CreateLoggerForTests())

	customMessage := "Test message"

	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	unsubscribeSuccessChannel := make(chan []byte)
	unsubscribeErrorChannel := make(chan []byte)
	await := make(chan bool)
	meta := "{\"meta\":\"filter\"}"

	pubnubInstance.SetFilterExpression(meta)
	go pubnubInstance.Subscribe(channel, "", successChannel, false, errorChannel)
	go func() {
		for {
			select {
			case resp := <-successChannel:
				response := fmt.Sprintf("%s", resp)
				if response != "[]" {
					message := "'" + channel + "' connected"

					if strings.Contains(response, message) {

						successChannel := make(chan []byte)
						errorChannel := make(chan []byte)

						go pubnubInstance.PublishExtended(channel,
							customMessage, true, false, successChannel, errorChannel)

						select {
						case <-successChannel:
							//log.Printf("message %s", s)
						case err := <-errorChannel:
							assert.Fail(string(err))
						case <-timeout():
							assert.Fail("Publish timeout")
						}
					} else {
						//log.Printf("message %s", response)
						assert.Contains(response, customMessage)
						assert.Fail("message not expected to come in")
						close(await)
						return
					}
				}
			case err := <-errorChannel:
				assert.Fail(string(err))

				close(await)
				return
			case <-timeouts(5):
				//log.Printf("timing out waiting for the message")

				//assert.Fail("Subscribe timeout 3s")
				close(await)
				return
			}

		}
	}()

	<-await

	go pubnubInstance.Unsubscribe(channel, unsubscribeSuccessChannel, unsubscribeErrorChannel)
	ExpectUnsubscribedEvent(t, channel, "", unsubscribeSuccessChannel, unsubscribeErrorChannel)

	// pubnubInstance.CloseExistingConnection()
}

// TestSubscribeEnd prints a message on the screen to mark the end of
// subscribe tests.
// PrintTestMessage is defined in the common.go file.
func TestSubscribeEnd(t *testing.T) {
	PrintTestMessage("==========Subscribe tests end==========")
}
