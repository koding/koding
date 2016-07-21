// Package tests has the unit tests of package messaging.
// pubnubEncryption_test.go contains the tests related to the Encryption/Decryption of messages
package tests

import (
	//"encoding/json"
	"fmt"
	"github.com/pubnub/go/messaging"
	"strings"
	"testing"
	"time"
	//"unicode/utf16"
)

func TestPamStart(t *testing.T) {
	PrintTestMessage("==========PAM tests start==========")
}

func TestSecretKeyRequired(t *testing.T) {
	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false, "")
	channel := "testChannel"

	returnPamChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)

	go pubnubInstance.GrantSubscribe(channel, true, true, 12, returnPamChannel, errorChannel)
	go ParsePamErrorResponse(errorChannel, "SecretKeyRequired", "Secret key is required", responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, "SecretKeyRequired")

}

func ParsePamErrorResponse(channel chan []byte, testName string, message string, responseChannel chan string) {
	for {
		value, ok := <-channel
		if !ok {
			break
		}
		returnVal := string(value)
		//fmt.Println("returnValErr:",returnVal);
		//fmt.Println("messageErr:",message);
		if returnVal != "[]" {
			if strings.Contains(returnVal, "aborted") || strings.Contains(returnVal, "reset"){
				continue;
			}
			if strings.Contains(returnVal, message) {
				responseChannel <- "Test '" + testName + "': passed."
				break
			} else {
				responseChannel <- "Test '" + testName + "': failed."
			}

			break
		}
	}
}

func ParsePamResponse(returnChannel chan []byte, pubnubInstance *messaging.Pubnub, message string, channel string, testName string, responseChannel chan string) {
	for {
		value, ok := <-returnChannel
		if !ok {
			break
		}
		if string(value) != "[]" {
			response := string(value)
			//fmt.Println(testName, " response:", response)
			//fmt.Println(testName, " message:",message);
			if strings.Contains(response, message) {

				responseChannel <- "Test '" + testName + "': passed."
				break
			} else {
				responseChannel <- "Test '" + testName + "': failed."
			}
		}
	}
}


func TestSubscribeGrantPositive(t *testing.T) {
	pubnubInstance := messaging.NewPubnub(PamPubKey, PamSubKey, PamSecKey, "", false, "")
	channel := "testChannelSubscribeGrantPositive"
	ttl := 1
	message := fmt.Sprintf(`{"status":200,"service":"Access Manager","message":"Success","payload":{"channels":{"%s":{"r":1,"m":0,"w":1}},"subscribe_key":"%s","ttl":%d,"level":"channel"}}`, channel, PamSubKey, ttl)
	message2 := fmt.Sprintf(`{"status":200,"service":"Access Manager","message":"Success","payload":{"channels":{"%s":{"r":0,"m":0,"w":0}},"subscribe_key":"%s","ttl":%d,"level":"channel"}}`, channel, PamSubKey, ttl)

	time.Sleep(time.Duration(5) * time.Second)
	
	returnPamChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)

	go pubnubInstance.GrantSubscribe(channel, true, true, ttl, returnPamChannel, errorChannel)
	go ParsePamResponse(returnPamChannel, pubnubInstance, message, channel, "SubscribeGrantPositiveGrant", responseChannel)
	go ParseErrorResponse(errorChannel, responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, "SubscribeGrantPositiveGrant")

	returnPamChannel2 := make(chan []byte)
	errorChannel2 := make(chan []byte)
	responseChannel2 := make(chan string)
	waitChannel2 := make(chan string)

	go pubnubInstance.GrantSubscribe(channel, false, false, -1, returnPamChannel2, errorChannel2)
	go ParsePamResponse(returnPamChannel2, pubnubInstance, message2, channel, "SubscribeGrantPositiveRevoke", responseChannel2)
	go ParseErrorResponse(errorChannel2, responseChannel2)
	go WaitForCompletion(responseChannel2, waitChannel2)
	ParseWaitResponse(waitChannel2, t, "SubscribeGrantPositiveRevoke")

}

func TestSubscribeGrantNegative(t *testing.T) {
	pubnubInstance := messaging.NewPubnub(PamPubKey, PamSubKey, PamSecKey, "", false, "")
	channel := "testChannelSubscribeGrantNegative"
	message := fmt.Sprintf(`{"status":403,"service":"Access Manager","error":true,"message":"Forbidden","payload":{"channels":["%s"]}}`, channel)

	time.Sleep(time.Duration(5) * time.Second)
	
	returnPamChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)

	go pubnubInstance.Subscribe(channel, "", returnPamChannel, false, errorChannel)
	go ParsePamErrorResponse(errorChannel, "SubscribeGrantNegative", message, responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, "SubscribeGrantNegative")
	returnPamChannel2 := make(chan []byte)
	errorChannel2 := make(chan []byte)

	go pubnubInstance.Unsubscribe(channel, returnPamChannel2, errorChannel2)
	pubnubInstance.CloseExistingConnection()
}

func TestPresenceGrantPositive(t *testing.T) {
	pubnubInstance := messaging.NewPubnub(PamPubKey, PamSubKey, PamSecKey, "", false, "")
	channel := "testChannelPresenceGrantPositive"
	ttl := 1
	message := fmt.Sprintf(`{"status":200,"service":"Access Manager","message":"Success","payload":{"channels":{"%s-pnpres":{"r":1,"m":0,"w":1}},"subscribe_key":"%s","ttl":%d,"level":"channel"}}`, channel, PamSubKey, ttl)
	message2 := fmt.Sprintf(`{"status":200,"service":"Access Manager","message":"Success","payload":{"channels":{"%s-pnpres":{"r":0,"m":0,"w":0}},"subscribe_key":"%s","ttl":%d,"level":"channel"}}`, channel, PamSubKey, ttl)

	time.Sleep(time.Duration(5) * time.Second)
	
	returnPamChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)

	go pubnubInstance.GrantPresence(channel, true, true, ttl, returnPamChannel, errorChannel)
	go ParsePamResponse(returnPamChannel, pubnubInstance, message, channel, "PresenceGrantPositiveGrant", responseChannel)
	go ParseErrorResponse(errorChannel, responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, "PresenceGrantPositiveGrant")

	returnPamChannel2 := make(chan []byte)
	errorChannel2 := make(chan []byte)
	responseChannel2 := make(chan string)
	waitChannel2 := make(chan string)

	go pubnubInstance.GrantPresence(channel, false, false, -1, returnPamChannel2, errorChannel2)
	go ParsePamResponse(returnPamChannel2, pubnubInstance, message2, channel, "PresenceGrantPositiveRevoke", responseChannel2)
	go ParseErrorResponse(errorChannel2, responseChannel2)
	go WaitForCompletion(responseChannel2, waitChannel2)
	ParseWaitResponse(waitChannel2, t, "PresenceGrantPositiveRevoke")
	pubnubInstance.CloseExistingConnection()
}

func TestPresenceGrantNegative(t *testing.T) {
	pubnubInstance := messaging.NewPubnub(PamPubKey, PamSubKey, PamSecKey, "", false, "")
	channel := "testChannelPresenceGrantNegative"
	message := fmt.Sprintf(`{"status":403,"service":"Access Manager","error":true,"message":"Forbidden","payload":{"channels":["%s-pnpres"]}}`, channel)
	
	time.Sleep(time.Duration(5) * time.Second)
	
	returnPamChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)

	go pubnubInstance.Subscribe(channel, "", returnPamChannel, true, errorChannel)
	go ParsePamErrorResponse(errorChannel, "PresenceGrantNegative", message, responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, "PresenceGrantNegative")
	returnPamChannel2 := make(chan []byte)
	errorChannel2 := make(chan []byte)

	go pubnubInstance.Unsubscribe(channel, returnPamChannel2, errorChannel2)
	pubnubInstance.CloseExistingConnection()
}

func TestSubscribeAudit(t *testing.T) {
	pubnubInstance := messaging.NewPubnub(PamPubKey, PamSubKey, PamSecKey, "", false, "")
	channel := "testChannelSubscribeAudit"
	time.Sleep(time.Duration(5) * time.Second)
	ttl := 2
	//message1 := fmt.Sprintf(`{"status":200,"service":"Access Manager","message":"Success","payload":{"channels":{},"subscribe_key":"%s","level":"subkey"}}`, PamSubKey)
	//message1 := fmt.Sprintf(`"subscribe_key":"%s","level":"subkey"`, PamSubKey)
	//message1 := fmt.Sprintf(`"subscribe_key":"%s","objects":{},"level":"subkey"`, PamSubKey)
	//	{"status":200,"service":"Access Manager","message":"Success","payload":{"channels":{},"subscribe_key":"sub-c-a3d5a1c8-ae97-11e3-a952-02ee2ddab7fe","level":"channel"}}
	//message := fmt.Sprintf(`{"status":200,"service":"Access Manager","message":"Success","payload":{"channels":{},"subscribe_key":"%s","level":"channel"}}`, PamSubKey)
	message := fmt.Sprintf(`"subscribe_key":"%s","level":"channel"`, PamSubKey)
	message2 := fmt.Sprintf(`{"status":200,"service":"Access Manager","message":"Success","payload":{"channels":{"%s":{"r":1,"m":0,"w":1}},"subscribe_key":"%s","ttl":%d,"level":"channel"}}`, channel, PamSubKey, ttl)
	//{"status":200,"service":"Access Manager","message":"Success","payload":{"channels":{"testChannelSubscribeAudit":{"r":1,"w":1}},"subscribe_key":"sub-c-a3d5a1c8-ae97-11e3-a952-02ee2ddab7fe","ttl":1,"level":"channel"}}
	message3 := fmt.Sprintf(`"%s":{"r":1,"m":0,"w":1,"ttl":%d}`, channel, ttl)
	message4 := fmt.Sprintf(`"%s":{"r":1,"m":0,"w":1,"ttl":%d}`, channel, ttl)
	message5 := fmt.Sprintf(`[1, "Subscription to channel '%s' connected", "%s"]`, channel, channel)
	message6 := fmt.Sprintf(`[1, "Subscription to channel '%s' unsubscribed", "%s"]`, channel, channel)

	returnPamChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)

	//audit
	go pubnubInstance.AuditSubscribe(channel, returnPamChannel, errorChannel)
	//fmt.Println("message:", message)
	go ParsePamResponse(returnPamChannel, pubnubInstance, message, channel, "SubscribeAuditChannel", responseChannel)
	go ParseErrorResponse(errorChannel, responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, "SubscribeAuditChannel")

	/*returnPamChannel2 := make(chan []byte)
	errorChannel2 := make(chan []byte)
	responseChannel2 := make(chan string)
	waitChannel2 := make(chan string)

	time.Sleep(time.Duration(2) * time.Second)

	//audit
	go pubnubInstance.AuditSubscribe("", returnPamChannel2, errorChannel2)
	//fmt.Println("message1:", message1)
	go ParsePamResponse(returnPamChannel2, pubnubInstance, message1, "", "SubscribeAuditSubKey", responseChannel2)
	go ParseErrorResponse(errorChannel2, responseChannel2)
	go WaitForCompletion(responseChannel2, waitChannel2)
	ParseWaitResponse(waitChannel2, t, "SubscribeAuditSubKey")*/

	returnPamChannel3 := make(chan []byte)
	errorChannel3 := make(chan []byte)
	responseChannel3 := make(chan string)
	waitChannel3 := make(chan string)

	time.Sleep(time.Duration(1) * time.Second)
	//grant
	go pubnubInstance.GrantSubscribe(channel, true, true, ttl, returnPamChannel3, errorChannel3)
	//fmt.Println("message2:", message2)
	go ParsePamResponse(returnPamChannel3, pubnubInstance, message2, channel, "SubscribeAuditGrantPositiveGrant", responseChannel3)
	go ParseErrorResponse(errorChannel3, responseChannel3)
	go WaitForCompletion(responseChannel3, waitChannel3)
	ParseWaitResponse(waitChannel3, t, "SubscribeAuditGrantPositiveGrant")

	returnPamChannel4 := make(chan []byte)
	errorChannel4 := make(chan []byte)
	responseChannel4 := make(chan string)
	waitChannel4 := make(chan string)

	go pubnubInstance.Subscribe(channel, "", returnPamChannel4, false, errorChannel4)
	go ParsePamResponse(returnPamChannel4, pubnubInstance, message5, channel, "SubscribeAudit", responseChannel4)
	go ParseErrorResponse(errorChannel4, responseChannel4)
	go WaitForCompletion(responseChannel4, waitChannel4)
	ParseWaitResponse(waitChannel4, t, "SubscribeAudit")

	time.Sleep(time.Duration(5) * time.Second)

	returnPamChannel5 := make(chan []byte)
	errorChannel5 := make(chan []byte)
	responseChannel5 := make(chan string)
	waitChannel5 := make(chan string)

	//audit
	go pubnubInstance.AuditSubscribe(channel, returnPamChannel5, errorChannel5)
	//fmt.Println("message3:", message3)
	go ParsePamResponse(returnPamChannel5, pubnubInstance, message3, channel, "SubscribeAuditChannel2", responseChannel5)
	go ParseErrorResponse(errorChannel5, responseChannel5)
	go WaitForCompletion(responseChannel5, waitChannel5)
	ParseWaitResponse(waitChannel5, t, "SubscribeAuditChannel2")

	returnPamChannel6 := make(chan []byte)
	errorChannel6 := make(chan []byte)
	responseChannel6 := make(chan string)
	waitChannel6 := make(chan string)

	//audit
	go pubnubInstance.AuditSubscribe("", returnPamChannel6, errorChannel6)
	//fmt.Println("message4:", message4)
	go ParsePamResponse(returnPamChannel6, pubnubInstance, message4, channel, "SubscribeAuditSubKey2", responseChannel6)
	go ParseErrorResponse(errorChannel6, responseChannel6)
	go WaitForCompletion(responseChannel6, waitChannel6)
	ParseWaitResponse(waitChannel6, t, "SubscribeAuditSubKey2")

	returnPamChannel7 := make(chan []byte)
	errorChannel7 := make(chan []byte)
	responseChannel7 := make(chan string)
	waitChannel7 := make(chan string)

	go pubnubInstance.Unsubscribe(channel, returnPamChannel7, errorChannel7)
	go ParsePamResponse(returnPamChannel7, pubnubInstance, message6, channel, "SubscribeAuditUnsub", responseChannel7)
	go ParseErrorResponse(errorChannel7, responseChannel7)
	go WaitForCompletion(responseChannel7, waitChannel7)

	go pubnubInstance.GrantSubscribe(channel, false, false, -1, returnPamChannel7, errorChannel7)
	go ParsePamResponse(returnPamChannel7, pubnubInstance, message5, channel, "SubscribeAuditRevoke", responseChannel7)
	go ParseErrorResponse(errorChannel7, responseChannel7)
	go WaitForCompletion(responseChannel7, waitChannel7)
	pubnubInstance.CloseExistingConnection()
}

func TestPresenceAudit(t *testing.T) {
	/*{"status":200,"service":"Access Manager","message":"Success","payload":{"ch
	annels":{"test":{"r":1,"w":1,"ttl":9},"testChannelSubscribeGrantPositive":{"r":0
	,"w":0,"ttl":1},"testChannelPresenceGrantPositive":{"r":0,"w":0,"ttl":1},"test-p
	npres":{"r":1,"w":1,"ttl":12}},"subscribe_key":"sub-c-a3d5a1c8-ae97-11e3-a952-02
	ee2ddab7fe","level":"subkey"}}*/

	/*{"status":200,"service":"Access Manager","message":"Success","payload":{"ch
	annels":{"test-pnpres":{"r":1,"w":1,"ttl":12}},"subscribe_key":"sub-c-a3d5a1c8-a
	e97-11e3-a952-02ee2ddab7fe","level":"channel"}}*/

	pubnubInstance := messaging.NewPubnub(PamPubKey, PamSubKey, PamSecKey, "", false, "")
	pubnubInstance.SetAuthenticationKey ("")
	channel := "testChannelPresenceAudit"
	time.Sleep(time.Duration(10) * time.Second)
	ttl := 2
	//message1 := fmt.Sprintf(`{"status":200,"service":"Access Manager","message":"Success","payload":{"channels":{},"subscribe_key":"%s","level":"subkey"}}`, PamSubKey)
	//message1 := fmt.Sprintf(`"subscribe_key":"%s","level":"subkey"`, PamSubKey)
	//message1 := fmt.Sprintf(`"subscribe_key":"%s","objects":{},"level":"subkey"`, PamSubKey)

	//	{"status":200,"service":"Access Manager","message":"Success","payload":{"channels":{},"subscribe_key":"sub-c-a3d5a1c8-ae97-11e3-a952-02ee2ddab7fe","level":"channel"}}
	//message := fmt.Sprintf(`{"status":200,"service":"Access Manager","message":"Success","payload":{"channels":{},"subscribe_key":"%s","level":"channel"}}`, PamSubKey)
	message := fmt.Sprintf(`"subscribe_key":"%s","level":"channel"`, PamSubKey)
	message2 := fmt.Sprintf(`{"status":200,"service":"Access Manager","message":"Success","payload":{"channels":{"%s-pnpres":{"r":1,"m":0,"w":1}},"subscribe_key":"%s","ttl":%d,"level":"channel"}}`, channel, PamSubKey, ttl)
	//{"status":200,"service":"Access Manager","message":"Success","payload":{"channels":{"testChannelSubscribeAudit":{"r":1,"w":1}},"subscribe_key":"sub-c-a3d5a1c8-ae97-11e3-a952-02ee2ddab7fe","ttl":1,"level":"channel"}}
	message3 := fmt.Sprintf(`"%s-pnpres":{"r":1,"m":0,"w":1,"ttl":%d}`, channel, ttl)
	message4 := fmt.Sprintf(`"%s-pnpres":{"r":1,"m":0,"w":1,"ttl":%d}`, channel, ttl)
	//"testChannelPresenceAudit-pnpres":{"r":1,"w":1,"ttl":1}
	//"testChannelPresenceAudit-pnpres":{"r":1,"w":1,"ttl":1}
	message5 := fmt.Sprintf(`"Presence notifications for channel '%s' connected", "%s"`, channel, channel)
	message6 := fmt.Sprintf(`"Presence notifications for channel '%s' unsubscribed", "%s"`, channel, channel)

	returnPamChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)

	//audit
	go pubnubInstance.AuditPresence(channel, returnPamChannel, errorChannel)
	//fmt.Println("message:", message)
	go ParsePamResponse(returnPamChannel, pubnubInstance, message, channel, "PresenceAuditChannel", responseChannel)
	go ParseErrorResponse(errorChannel, responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, "PresenceAuditChannel")

	/*returnPamChannel2 := make(chan []byte)
	errorChannel2 := make(chan []byte)
	responseChannel2 := make(chan string)
	waitChannel2 := make(chan string)

	time.Sleep(time.Duration(2) * time.Second)

	//audit
	go pubnubInstance.AuditPresence("", returnPamChannel2, errorChannel2)
	//fmt.Println("message1:", message1)
	go ParsePamResponse(returnPamChannel2, pubnubInstance, message1, "", "PresenceAuditSubKey", responseChannel2)
	go ParseErrorResponse(errorChannel2, responseChannel2)
	go WaitForCompletion(responseChannel2, waitChannel2)
	ParseWaitResponse(waitChannel2, t, "PresenceAuditSubKey")*/

	returnPamChannel3 := make(chan []byte)
	errorChannel3 := make(chan []byte)
	responseChannel3 := make(chan string)
	waitChannel3 := make(chan string)

	//grant
	go pubnubInstance.GrantPresence(channel, true, true, ttl, returnPamChannel3, errorChannel3)
	//fmt.Println("message2:", message2)
	go ParsePamResponse(returnPamChannel3, pubnubInstance, message2, channel, "PresenceAuditGrant", responseChannel3)
	go ParseErrorResponse(errorChannel3, responseChannel3)
	go WaitForCompletion(responseChannel3, waitChannel3)
	ParseWaitResponse(waitChannel3, t, "PresenceAuditGrant")

	returnPamChannel4 := make(chan []byte)
	errorChannel4 := make(chan []byte)
	responseChannel4 := make(chan string)
	waitChannel4 := make(chan string)

	go pubnubInstance.Subscribe(channel, "", returnPamChannel4, true, errorChannel4)
	go ParsePamResponse(returnPamChannel4, pubnubInstance, message5, channel, "PresenceAudit", responseChannel4)
	go ParseErrorResponse(errorChannel4, responseChannel4)
	go WaitForCompletion(responseChannel4, waitChannel4)
	ParseWaitResponse(waitChannel4, t, "PresenceAudit")

	time.Sleep(time.Duration(5) * time.Second)

	returnPamChannel5 := make(chan []byte)
	errorChannel5 := make(chan []byte)
	responseChannel5 := make(chan string)
	waitChannel5 := make(chan string)

	//audit
	go pubnubInstance.AuditPresence(channel, returnPamChannel5, errorChannel5)
	//fmt.Println("message3:", message3)
	go ParsePamResponse(returnPamChannel5, pubnubInstance, message3, channel, "PresenceAuditChannel2", responseChannel5)
	go ParseErrorResponse(errorChannel5, responseChannel5)
	go WaitForCompletion(responseChannel5, waitChannel5)
	ParseWaitResponse(waitChannel5, t, "PresenceAuditChannel2")

	returnPamChannel6 := make(chan []byte)
	errorChannel6 := make(chan []byte)
	responseChannel6 := make(chan string)
	waitChannel6 := make(chan string)

	//audit
	go pubnubInstance.AuditPresence("", returnPamChannel6, errorChannel6)
	//fmt.Println("message4:", message4)
	go ParsePamResponse(returnPamChannel6, pubnubInstance, message4, channel, "PresenceAuditSubKey2", responseChannel6)
	go ParseErrorResponse(errorChannel6, responseChannel6)
	go WaitForCompletion(responseChannel6, waitChannel6)
	ParseWaitResponse(waitChannel6, t, "PresenceAuditSubKey2")

	returnPamChannel7 := make(chan []byte)
	errorChannel7 := make(chan []byte)
	responseChannel7 := make(chan string)
	waitChannel7 := make(chan string)

	go pubnubInstance.PresenceUnsubscribe(channel, returnPamChannel7, errorChannel7)
	go ParsePamResponse(returnPamChannel7, pubnubInstance, message6, channel, "PresenceAuditUnsub", responseChannel7)
	//go ParseErrorResponse(errorChannel7, responseChannel7)
	go WaitForCompletion(responseChannel7, waitChannel7)

	go pubnubInstance.GrantPresence(channel, false, false, -1, returnPamChannel7, errorChannel7)
	go ParsePamResponse(returnPamChannel7, pubnubInstance, message5, channel, "PresenceAuditRevoke", responseChannel7)
	//go ParseErrorResponse(errorChannel7, responseChannel7)
	go WaitForCompletion(responseChannel7, waitChannel7)
	pubnubInstance.CloseExistingConnection()
}

func TestAuthSubscribe(t *testing.T) {
	pubnubInstance := messaging.NewPubnub(PamPubKey, PamSubKey, PamSecKey, "", false, "")
	pubnubInstance.SetAuthenticationKey("authkey")
	channel := "testChannelSubscribeAuth"

	time.Sleep(time.Duration(10) * time.Second)
	ttl := 1
	message := fmt.Sprintf(`{"auths":{"authkey":{"r":1,"m":0,"w":1}}`)
	message2 := fmt.Sprintf(`{"status":200,"service":"Access Manager","message":"Success","payload":{"channels":{"%s":{"r":0,"m":0,"w":0}},"subscribe_key":"%s","ttl":%d,"level":"channel"}}`, channel, PamSubKey, ttl)
	message5 := fmt.Sprintf(`'%s' connected`, channel)
	message6 := fmt.Sprintf(`'%s' unsubscribed`, channel)

	returnPamChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)

	//grant
	go pubnubInstance.GrantSubscribe(channel, true, true, ttl, returnPamChannel, errorChannel)
	go ParsePamResponse(returnPamChannel, pubnubInstance, message, channel, "SubscribeAuthGrant", responseChannel)
	go ParseErrorResponse(errorChannel, responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, "SubscribeAuthGrant")

	returnPamChannel2 := make(chan []byte)
	errorChannel2 := make(chan []byte)
	responseChannel2 := make(chan string)
	waitChannel2 := make(chan string)
	
	time.Sleep(time.Duration(2) * time.Second)

	//subscribe
	go pubnubInstance.Subscribe(channel, "", returnPamChannel2, false, errorChannel2)
	go ParsePamResponse(returnPamChannel2, pubnubInstance, message5, channel, "SubscribeAuthSubscribe", responseChannel2)
	go ParseErrorResponse(errorChannel2, responseChannel2)
	go WaitForCompletion(responseChannel2, waitChannel2)
	//check connect
	ParseWaitResponse(waitChannel2, t, "SubscribeAuthSubscribe")

	returnPamChannel3 := make(chan []byte)
	errorChannel3 := make(chan []byte)
	responseChannel3 := make(chan string)
	waitChannel3 := make(chan string)

	go pubnubInstance.Unsubscribe(channel, returnPamChannel3, errorChannel3)
	go ParsePamResponse(returnPamChannel3, pubnubInstance, message6, channel, "SubscribeAuthUnsubscribe", responseChannel3)
	go ParseErrorResponse(errorChannel3, responseChannel3)
	go WaitForCompletion(responseChannel3, waitChannel3)
	ParseWaitResponse(waitChannel3, t, "SubscribeAuthUnsubscribe")

	returnPamChannel4 := make(chan []byte)
	errorChannel4 := make(chan []byte)
	responseChannel4 := make(chan string)
	waitChannel4 := make(chan string)

	//revoke
	go pubnubInstance.GrantSubscribe(channel, false, false, -1, returnPamChannel4, errorChannel4)
	go ParsePamResponse(returnPamChannel4, pubnubInstance, message2, channel, "SubscribeAuthRevoke", responseChannel4)
	go ParseErrorResponse(errorChannel4, responseChannel4)
	go WaitForCompletion(responseChannel4, waitChannel4)
	
	pubnubInstance.CloseExistingConnection()
}

func TestAuthPresence(t *testing.T) {
	pubnubInstance := messaging.NewPubnub(PamPubKey, PamSubKey, PamSecKey, "", false, "")
	pubnubInstance.SetAuthenticationKey("authkey")
	channel := "testChannelPresenceAuth"

	time.Sleep(time.Duration(10) * time.Second)
	ttl := 1
	message := fmt.Sprintf(`{"auths":{"authkey":{"r":1,"m":0,"w":1}}`)
	message2 := fmt.Sprintf(`{"status":200,"service":"Access Manager","message":"Success","payload":{"channels":{"%s":{"r":0,"m":0,"w":0}},"subscribe_key":"%s","ttl":%d,"level":"channel"}}`, channel, PamSubKey, ttl)
	message5 := fmt.Sprintf(`'%s' connected`, channel)
	message6 := fmt.Sprintf(`'%s' unsubscribed`, channel)

	returnPamChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)

	//grant
	go pubnubInstance.GrantPresence(channel, true, true, ttl, returnPamChannel, errorChannel)
	go ParsePamResponse(returnPamChannel, pubnubInstance, message, channel, "PresenceAuthGrant", responseChannel)
	go ParseErrorResponse(errorChannel, responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, "PresenceAuthGrant")

	returnPamChannel2 := make(chan []byte)
	errorChannel2 := make(chan []byte)
	responseChannel2 := make(chan string)
	waitChannel2 := make(chan string)
	
	time.Sleep(time.Duration(1) * time.Second)

	//subscribe
	go pubnubInstance.Subscribe(channel, "", returnPamChannel2, true, errorChannel2)
	go ParsePamResponse(returnPamChannel2, pubnubInstance, message5, channel, "PresenceAuthSubscribe", responseChannel2)
	go ParseErrorResponse(errorChannel2, responseChannel2)
	go WaitForCompletion(responseChannel2, waitChannel2)
	//check connect
	ParseWaitResponse(waitChannel2, t, "PresenceAuthSubscribe")

	returnPamChannel3 := make(chan []byte)
	errorChannel3 := make(chan []byte)
	responseChannel3 := make(chan string)
	waitChannel3 := make(chan string)

	go pubnubInstance.PresenceUnsubscribe(channel, returnPamChannel3, errorChannel3)
	go ParsePamResponse(returnPamChannel3, pubnubInstance, message6, channel, "PresenceAuthUnsubscribe", responseChannel3)
	go ParseErrorResponse(errorChannel3, responseChannel3)
	go WaitForCompletion(responseChannel3, waitChannel3)
	ParseWaitResponse(waitChannel3, t, "PresenceAuthUnsubscribe")

	returnPamChannel4 := make(chan []byte)
	errorChannel4 := make(chan []byte)
	responseChannel4 := make(chan string)
	waitChannel4 := make(chan string)

	//revoke
	go pubnubInstance.GrantSubscribe(channel, false, false, -1, returnPamChannel4, errorChannel4)
	go ParsePamResponse(returnPamChannel4, pubnubInstance, message2, channel, "PresenceAuthRevoke", responseChannel4)
	go ParseErrorResponse(errorChannel4, responseChannel4)
	go WaitForCompletion(responseChannel4, waitChannel4)
}

func TestAuthHereNow(t *testing.T) {
	pubnubInstance := messaging.NewPubnub(PamPubKey, PamSubKey, PamSecKey, "", false, "")
	pubnubInstance.SetAuthenticationKey("authkey")
	channel := "testChannelHereNowAuth"

	time.Sleep(time.Duration(10) * time.Second)
	ttl := 1
	message := fmt.Sprintf(`{"auths":{"authkey":{"r":1,"m":0,"w":1}}`)
	message2 := fmt.Sprintf(`{"status":200,"service":"Access Manager","message":"Success","payload":{"channels":{"%s":{"r":0,"m":0,"w":0}},"subscribe_key":"%s","ttl":%d,"level":"channel"}}`, channel, PamSubKey, ttl)
	message5 := fmt.Sprintf(`'%s' connected`, channel)
	message4 := pubnubInstance.GetUUID()
	message6 := fmt.Sprintf(`'%s' unsubscribed`, channel)

	returnPamChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)

	//grant
	go pubnubInstance.GrantPresence(channel, true, true, ttl, returnPamChannel, errorChannel)
	go ParsePamResponse(returnPamChannel, pubnubInstance, message, channel, "HereNowAuthGrant", responseChannel)
	go ParseErrorResponse(errorChannel, responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, "HereNowAuthGrant")

	returnPamChannel2 := make(chan []byte)
	errorChannel2 := make(chan []byte)
	responseChannel2 := make(chan string)
	waitChannel2 := make(chan string)

	//grant
	go pubnubInstance.GrantSubscribe(channel, true, true, ttl, returnPamChannel2, errorChannel2)
	go ParsePamResponse(returnPamChannel2, pubnubInstance, message, channel, "HereNowAuthSubscribe", responseChannel2)
	go ParseErrorResponse(errorChannel2, responseChannel2)
	go WaitForCompletion(responseChannel2, waitChannel2)
	ParseWaitResponse(waitChannel2, t, "HereNowAuthSubscribe")

	returnPamChannel3 := make(chan []byte)
	errorChannel3 := make(chan []byte)
	responseChannel3 := make(chan string)
	waitChannel3 := make(chan string)

	//subscribe
	go pubnubInstance.Subscribe(channel, "", returnPamChannel3, false, errorChannel3)
	go ParsePamResponse(returnPamChannel3, pubnubInstance, message5, channel, "HereNowAuthSubscribe", responseChannel3)
	go ParseErrorResponse(errorChannel3, responseChannel3)
	go WaitForCompletion(responseChannel3, waitChannel3)
	//check connect
	ParseWaitResponse(waitChannel3, t, "HereNowAuthSubscribe")

	time.Sleep(time.Duration(10) * time.Second)

	returnPamChannel4 := make(chan []byte)
	errorChannel4 := make(chan []byte)
	responseChannel4 := make(chan string)
	waitChannel4 := make(chan string)

	//herenow
	go pubnubInstance.HereNow(channel, true, true, returnPamChannel4, errorChannel4)
	go ParsePamResponse(returnPamChannel4, pubnubInstance, message4, channel, "HereNowAuthHereNow", responseChannel4)
	go ParseErrorResponse(errorChannel4, responseChannel4)
	go WaitForCompletion(responseChannel4, waitChannel4)
	//check connect
	ParseWaitResponse(waitChannel4, t, "HereNowAuthHereNow")

	returnPamChannel5 := make(chan []byte)
	errorChannel5 := make(chan []byte)
	responseChannel5 := make(chan string)
	waitChannel5 := make(chan string)

	go pubnubInstance.Unsubscribe(channel, returnPamChannel5, errorChannel5)
	go ParsePamResponse(returnPamChannel5, pubnubInstance, message6, channel, "HereNowAuthUnsubscribe", responseChannel5)
	go ParseErrorResponse(errorChannel5, responseChannel5)
	go WaitForCompletion(responseChannel5, waitChannel5)
	ParseWaitResponse(waitChannel5, t, "HereNowAuthUnsubscribe")

	returnPamChannel6 := make(chan []byte)
	errorChannel6 := make(chan []byte)
	responseChannel6 := make(chan string)
	waitChannel6 := make(chan string)

	//revoke
	go pubnubInstance.GrantSubscribe(channel, false, false, -1, returnPamChannel6, errorChannel6)
	go ParsePamResponse(returnPamChannel6, pubnubInstance, message2, channel, "HereNowAuthHereNow", responseChannel6)
	go ParseErrorResponse(errorChannel6, responseChannel6)
	go WaitForCompletion(responseChannel6, waitChannel6)

}

func TestAuthHistory(t *testing.T) {
	pubnubInstance := messaging.NewPubnub(PamPubKey, PamSubKey, PamSecKey, "", false, "")
	pubnubInstance.SetAuthenticationKey("authkey")
	channel := "testChannelHistoryAuth"

	time.Sleep(time.Duration(10) * time.Second)
	ttl := 2
	message := fmt.Sprintf(`{"auths":{"authkey":{"r":1,"m":0,"w":1}}`)
	message2 := fmt.Sprintf(`{"status":200,"service":"Access Manager","message":"Success","payload":{"channels":{"%s":{"r":0,"m":0,"w":0}},"subscribe_key":"%s","ttl":%d,"level":"channel"}}`, channel, PamSubKey, ttl)
	message5 := "Test Message"

	returnPamChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	responseChannel := make(chan string)
	waitChannel := make(chan string)

	//grant
	go pubnubInstance.GrantPresence(channel, true, true, ttl, returnPamChannel, errorChannel)
	go ParsePamResponse(returnPamChannel, pubnubInstance, message, channel, "HistoryAuthGrant", responseChannel)
	go ParseErrorResponse(errorChannel, responseChannel)
	go WaitForCompletion(responseChannel, waitChannel)
	ParseWaitResponse(waitChannel, t, "HistoryAuthGrant")

	returnPamChannel2 := make(chan []byte)
	errorChannel2 := make(chan []byte)
	responseChannel2 := make(chan string)
	waitChannel2 := make(chan string)

	//grant
	go pubnubInstance.GrantSubscribe(channel, true, true, ttl, returnPamChannel2, errorChannel2)
	go ParsePamResponse(returnPamChannel2, pubnubInstance, message, channel, "HistoryAuthSubscribe", responseChannel2)
	go ParseErrorResponse(errorChannel2, responseChannel2)
	go WaitForCompletion(responseChannel2, waitChannel2)
	ParseWaitResponse(waitChannel2, t, "HistoryAuthSubscribe")

	returnPamChannel3 := make(chan []byte)
	errorChannel3 := make(chan []byte)
	responseChannel3 := make(chan string)
	waitChannel3 := make(chan string)

	//publish
	go pubnubInstance.Publish(channel, message5, returnPamChannel3, errorChannel3)
	go ParsePamResponse(returnPamChannel3, pubnubInstance, "Sent", channel, "HistoryAuthPublish", responseChannel3)
	go ParseErrorResponse(errorChannel3, responseChannel3)
	go WaitForCompletion(responseChannel3, waitChannel3)
	ParseWaitResponse(waitChannel3, t, "HistoryAuthPublish")

	returnPamChannel4 := make(chan []byte)
	errorChannel4 := make(chan []byte)
	responseChannel4 := make(chan string)
	waitChannel4 := make(chan string)

	//history
	go pubnubInstance.History(channel, 1, 0, 0, false, returnPamChannel4, errorChannel4)
	go ParsePamResponse(returnPamChannel4, pubnubInstance, message5, channel, "HistoryAuthHistory", responseChannel4)
	go ParseErrorResponse(errorChannel4, responseChannel4)
	go WaitForCompletion(responseChannel4, waitChannel4)
	//check connect
	ParseWaitResponse(waitChannel4, t, "HistoryAuthHistory")

	returnPamChannel5 := make(chan []byte)
	errorChannel5 := make(chan []byte)
	responseChannel5 := make(chan string)
	waitChannel5 := make(chan string)

	//revoke
	go pubnubInstance.GrantSubscribe(channel, false, false, -1, returnPamChannel5, errorChannel5)
	go ParsePamResponse(returnPamChannel5, pubnubInstance, message2, channel, "HistoryAuthHistory", responseChannel5)
	go ParseErrorResponse(errorChannel5, responseChannel5)
	go WaitForCompletion(responseChannel5, waitChannel5)

	//revoke
	go pubnubInstance.GrantSubscribe(channel, false, false, -1, returnPamChannel5, errorChannel5)
	go ParsePamResponse(returnPamChannel5, pubnubInstance, message2, channel, "HistoryAuthHereNow", responseChannel5)
	go ParseErrorResponse(errorChannel5, responseChannel5)
	go WaitForCompletion(responseChannel5, waitChannel5)

}

func TestPamEnd(t *testing.T) {
	PrintTestMessage("==========PAM tests End==========")
}
