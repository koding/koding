// Package tests has the unit tests of package messaging.
// common file has the reused methods across the varoius unit test files
package tests

import (
	"bytes"
	"encoding/json"
	"encoding/xml"
	"errors"
	"fmt"
	"github.com/pubnub/go-vcr/cassette"
	"github.com/pubnub/go-vcr/recorder"
	"github.com/pubnub/go/messaging"
	"github.com/pubnub/go/messaging/tests/utils"
	"github.com/stretchr/testify/assert"
	"io/ioutil"
	"log"
	"math/rand"
	"net/http"
	"os"
	"strconv"
	"strings"
	"sync"
	"testing"
	"time"
)

// PamSubKey: key for pam tests
var PamSubKey = "sub-c-90c51098-c040-11e5-a316-0619f8945a4f"

// PamPubKey: key for pam tests
var PamPubKey = "pub-c-1bd448ed-05ba-4dbc-81a5-7d6ff5c6e2bb"

// PamSecKey: key for pam tests
var PamSecKey = "sec-c-ZDA1ZTdlNzAtYzU4Zi00MmEwLTljZmItM2ZhMDExZTE2ZmQ5"

// SubKey: key for non-pam tests
var SubKey = "sub-c-5c4fdcc6-c040-11e5-a316-0619f8945a4f"

// PubKey: key for non-pam tests
var PubKey = "pub-c-071e1a3f-607f-4351-bdd1-73a8eb21ba7c"

// SecKey: key for non-pam tests
var SecKey = "" //"sec-c-ZjM0NzNmODgtNzE4OC00OTBjLWFhMWMtYjUxZTllYmY5YWE4"

// SubKey: key for non-pam tests
var SubNoPermissionsKey = "sub-c-642a6fca-f5b9-11e5-9086-02ee2ddab7fe"

// PubKey: key for non-pam tests
var PubNoPermissionsKey = "pub-c-5375d0d0-2088-43c6-864e-bcf6a6714212"

// timeoutMessage is the text message displayed when the
// unit test times out
var timeoutMessage = "Test timed out."

// testTimeout in seconds
var testTimeout int = 30

// testTimeout in seconds
var connectionEventTimeout int = 20

// prefix for presence channels
var presenceSuffix string = "-pnpres"

// publishSuccessMessage: the response that is received when a message is
// successfully published on a pubnub channel.
var publishSuccessMessage = "1,\"Sent\""

// EmptyStruct provided the empty struct to test the encryption.
type EmptyStruct struct {
}

// CustomStruct to test the custom structure encryption and decryption
// The variables "foo" and "bar" as used in the other languages are not
// accepted by golang and give an empty value when serialized, used "Foo"
// and "Bar" instead.
type CustomStruct struct {
	Foo string
	Bar []int
}

// CustomSingleElementStruct Used to test the custom structure encryption and decryption
// The variables "foo" and "bar" as used in the other languages are not
// accepted by golang and give an empty value when serialized, used "Foo"
// and "Bar" instead.
type CustomSingleElementStruct struct {
	Foo string
}

// CustomComplexMessage is used to test the custom structure encryption and decryption.
// The variables "foo" and "bar" as used in the other languages are not
// accepted by golang and give an empty value when serialized, used "Foo"
// and "Bar" instead.
type CustomComplexMessage struct {
	VersionID     float32 `json:",string"`
	TimeToken     int64   `json:",string"`
	OperationName string
	Channels      []string
	DemoMessage   PubnubDemoMessage `json:",string"`
	SampleXML     string            `json:",string"`
}

// PubnubDemoMessage is a struct to test a non-alphanumeric message
type PubnubDemoMessage struct {
	DefaultMessage string `json:",string"`
}

// GenRandom gets a random instance
func GenRandom() *rand.Rand {
	return rand.New(rand.NewSource(time.Now().UnixNano()))
}

// InitComplexMessage initializes a complex structure of the
// type CustomComplexMessage which includes a xml, struct of type PubnubDemoMessage,
// strings, float and integer.
func InitComplexMessage() CustomComplexMessage {
	pubnubDemoMessage := PubnubDemoMessage{
		DefaultMessage: "~!@#$%^&*()_+ `1234567890-= qwertyuiop[]\\ {}| asdfghjkl;' :\" zxcvbnm,./ <>? ",
	}

	xmlDoc := &Data{Name: "Doe", Age: 42}

	//_, err := xml.MarshalIndent(xmlDoc, "  ", "    ")
	//output, err := xml.MarshalIndent(xmlDoc, "  ", "    ")
	output := new(bytes.Buffer)
	enc := xml.NewEncoder(output)

	err := enc.Encode(xmlDoc)
	if err != nil {
		fmt.Printf("error: %v\n", err)
		return CustomComplexMessage{}
	}
	//fmt.Printf("xmlDoc: %v\n", xmlDoc)
	customComplexMessage := CustomComplexMessage{
		VersionID:     3.4,
		TimeToken:     13601488652764619,
		OperationName: "Publish",
		Channels:      []string{"ch1", "ch 2"},
		DemoMessage:   pubnubDemoMessage,
		//SampleXml        : xmlDoc,
		SampleXML: output.String(),
	}
	return customComplexMessage
}

// Data represents a <data> element.
type Data struct {
	XMLName xml.Name `xml:"data"`
	//Entry   []Entry  `xml:"entry"`
	Name string `xml:"name"`
	Age  int    `xml:"age"`
}

// Entry represents an <entry> element.
type Entry struct {
	Name string `xml:"name"`
	Age  int    `xml:"age"`
}

type PamResponse struct {
	Payload interface{}
	Status  int
	Service string
	Message string
}

// PrintTestMessage is  common method to print the message on the screen.
func PrintTestMessage(message string) {
	fmt.Println(" ")
	fmt.Println(message)
	fmt.Println(" ")
}

// ReplaceEncodedChars takes a string as a parameter and returns a string
// with the unicode chars \\u003c, \\u003e, \\u0026  with <,> and & respectively
func ReplaceEncodedChars(str string) string {
	str = strings.Replace(str, "\\u003c", "<", -1)
	str = strings.Replace(str, "\\u003e", ">", -1)
	str = strings.Replace(str, "\\u0026", "&", -1)
	return str
}

// WaitForCompletion reads the response on the responseChannel or waits till the timeout
// occurs. if the response is received before the timeout the response is sent to the
// waitChannel else the test is timed out.
//
// Parameters:
// responseChannel: channel to read.
// waitChannel: channel to respond to.
func WaitForCompletion(responseChannel chan string, waitChannel chan string) {
	timeout := make(chan bool, 1)
	go func() {
		time.Sleep(30 * time.Second)
		timeout <- true
	}()
	for {
		select {
		case value, ok := <-responseChannel:
			if !ok {
				break
			}

			if value != "[]" {
				waitChannel <- value
				timeout <- false
				//break
			}
			break
		case <-timeout:
			//case b, _ := <-timeout:
			//if b {
			waitChannel <- timeoutMessage
			//}
			break
		}
	}
}

// ParseWaitResponse parses the response of the wait channel.
// If the response contains the string "passed" then the test is passed else it is failed.
//
// Parameters:
// waitChannel: channel to read
// t: the testing.T instance
// testName to display.
func ParseWaitResponse(waitChannel chan string, t *testing.T, testName string) {
	for {
		value, ok := <-waitChannel
		if !ok {
			break
		}
		returnVal := string(value)
		if returnVal != "[]" {
			//fmt.Println("wait:", returnVal)
			if strings.Contains(returnVal, "passed") {
				//fmt.Println("Test '" + testName + "': passed.")
			} else {
				fmt.Println("Test '" + testName + "': failed. Message: " + returnVal)
				t.Error("Test '" + testName + "': failed.")
			}
			break
		}
	}
}

// ParseErrorResponse parses the response of the Error channel.
// It prints the response to the response channel
func ParseErrorResponse(channel chan []byte, responseChannel chan string) {
	for {
		value, ok := <-channel
		if !ok {
			break
		}
		returnVal := string(value)
		if returnVal != "[]" {
			//fmt.Println("error:", returnVal)
			responseChannel <- returnVal
			break
		}
	}
}

// ParseErrorResponseForTestSuccess parses the response of the Error channel.
// It prints the response to the response channel
func ParseErrorResponseForTestSuccess(message string, channel chan []byte, responseChannel chan string) {
	for {
		value, ok := <-channel
		if !ok {
			break
		}
		returnVal := string(value)
		if returnVal != "[]" {
			//fmt.Println("returnVal ", returnVal)
			if strings.Contains(returnVal, message) {
				responseChannel <- "passed"
			} else {
				responseChannel <- "failed"
			}
			break
		}
	}
}

// ParseResponseDummy is a methods that reads the response on the channel
// but does notthing on it.
func ParseResponseDummy(channel chan []byte) {
	for {
		value, ok := <-channel
		if !ok {
			break
		}
		returnVal := string(value)
		if returnVal != "[]" {
			//fmt.Println ("ParseSubscribeResponseDummy", returnVal)
			break
		}
	}
}

// ParseResponseDummy is a methods that reads the response on the channel
// but does notthing on it.
func ParseResponseDummyMessage(channel chan []byte, message string, responseChannel chan string) {
	for {
		value, ok := <-channel
		if !ok {
			break
		}
		returnVal := string(value)
		if returnVal != "[]" {
			//fmt.Println ("ParseSubscribeResponseDummy", returnVal)
			response := fmt.Sprintf("%s", value)
			if strings.Contains(response, "aborted") {
				continue
			}

			responseChannel <- returnVal
			break
		}
	}
}

func IsConnectionRefusedError(err []byte) bool {
	er := string(err)
	if strings.Contains(er, "http: error connecting to proxy") &&
		strings.Contains(er, "getsockopt: connection refused") {
		return true
	} else if strings.Contains(er, "Get ") &&
		strings.Contains(er, "EOF") {
		return true
	} else {
		return false
	}
}

func ExpectConnectedEvent(t *testing.T,
	channels, groups string, successChannel, errorChannel <-chan []byte) {

	var initialChannelsArray, initialGroupsArray []string

	if len(channels) > 0 {
		initialChannelsArray = strings.Split(channels, ",")
	}

	if len(groups) > 0 {
		initialGroupsArray = strings.Split(groups, ",")
	}

	waitForEventOnEveryChannel(t, initialChannelsArray, initialGroupsArray,
		"connected", "join", successChannel, errorChannel)
}

func ExpectUnsubscribedEvent(t *testing.T,
	channels, groups string, successChannel, errorChannel <-chan []byte) {

	var initialChannelsArray, initialGroupsArray []string

	if len(channels) > 0 {
		initialChannelsArray = strings.Split(channels, ",")
	}

	if len(groups) > 0 {
		initialGroupsArray = strings.Split(groups, ",")
	}

	waitForEventOnEveryChannel(t, initialChannelsArray, initialGroupsArray,
		"unsubscribed", "leave", successChannel, errorChannel)
}

func waitForEventOnEveryChannel(t *testing.T, channels, groups []string,
	cnAction, prAction string, successChannel, errorChannel <-chan []byte) {
	//log.SetOutput(os.Stdout)
	//log.SetFlags(log.Ldate | log.Ltime | log.Lmicroseconds)
	//log.Printf("groups %d", len(groups))
	//log.Printf("channels %d", len(channels))
	var triggeredChannels []string
	var triggeredGroups []string

	channel := make(chan bool)

	go func() {
		//log.Printf("waitForEventOnEveryChannel")
		for {
			select {
			case event := <-successChannel:
				//log.Printf("waitForEventOnEveryChannel success")
				var ary []interface{}

				eventString := string(event)
				assert.Contains(t, eventString, cnAction,
					"While expecting connection messages to be equal")

				err := json.Unmarshal(event, &ary)
				if err != nil {
					assert.Fail(t, err.Error())
				}

				if strings.Contains(eventString, "channel group") {
					triggeredGroups = append(triggeredGroups, ary[2].(string))
				} else if strings.Contains(eventString, "channel") {
					triggeredChannels = append(triggeredChannels, ary[2].(string))
				}
				if utils.AssertStringSliceElementsEqual(triggeredChannels, channels) &&
					utils.AssertStringSliceElementsEqual(triggeredGroups, groups) {
					channel <- true
					return
				}
				//break
			case err := <-errorChannel:
				assert.Fail(t, fmt.Sprintf(
					"Error while expecting for a %s connection event", cnAction),
					string(err))
				channel <- false
				return
			}
		}
		//return
	}()
	//log.Printf("waitForEventOnEveryChannel breaking out")
	select {
	case <-channel:
	case <-timeouts(connectionEventTimeout):
		assert.Fail(t, fmt.Sprintf(
			"Timeout occurred for %s event. Expected channels/groups: %s/%s. "+
				"Received channels/groups: %s/%s\n",
			cnAction, channels, groups, triggeredChannels, triggeredGroups))
	}

	if "unsubscribed" == cnAction {
		go func() {
			for {
				select {
				case ev := <-successChannel:
					var event messaging.PresenceResonse

					err := json.Unmarshal(ev, &event)
					if err != nil {
						assert.Fail(t, err.Error(), string(ev))
					}

					assert.Equal(t, prAction, event.Action)
					assert.Equal(t, 200, event.Status)
					channel <- true
					break
				case err := <-errorChannel:
					assert.Fail(t,
						fmt.Sprintf("Error while expecting for a %s presence event", prAction),
						string(err))
					channel <- false
					return
				}
			}
		}()

		select {
		case <-channel:
		case <-timeouts(connectionEventTimeout):
			assert.Fail(t, fmt.Sprintf(
				"Timeout occurred for %s event. Expected channels/groups: %s/%s. "+
					"Received channels/groups: %s/%s\n",
				prAction, channels, groups, triggeredChannels, triggeredGroups))
		}
	}
}

func timeout() <-chan time.Time {
	return time.After(time.Second * time.Duration(testTimeout))
}

func timeouts(seconds int) <-chan time.Time {
	return time.After(time.Second * time.Duration(seconds))
}

func GenerateTwoRandomChannelStrings(length int) (channels1, channels2 string) {
	var channelsArray []string

	r := GenRandom()
	channelsMap := make(map[string]struct{})

	for len(channelsMap) < length*2 {
		channel := fmt.Sprintf("testChannel_sub_%d", r.Intn(99999))

		if _, found := channelsMap[channel]; !found {
			channelsMap[channel] = struct{}{}
		}
	}

	for channel := range channelsMap {
		channelsArray = append(channelsArray, channel)
	}

	return strings.Join(channelsArray[:length], ","), strings.Join(channelsArray[length:], ",")
}

func RandomChannel() string {
	channel, _ := GenerateTwoRandomChannelStrings(1)
	return channel
}

func RandomChannels(length int) string {
	channel, _ := GenerateTwoRandomChannelStrings(length)
	return channel
}

var pubnubMatcher cassette.Matcher = utils.NewPubnubMatcher([]string{})

type VCRTransportStub int

const (
	vcrStubSubscribe VCRTransportStub = 1 << iota
	vcrStubNonSubscribe
)

var vcrMu sync.Mutex
var defaultFieldsToSkip = []string{"pnsdk"}

func NewVCRNonSubscribe(name string, skipFields []string) (
	func(), func(int)) {

	vcrMu.Lock()
	skipFields = append(skipFields, defaultFieldsToSkip...)
	ns, _ := recorder.New(fmt.Sprintf("%s_%s", name, "NonSubscribe"))
	nsMatcher := utils.NewPubnubMatcher(skipFields)
	ns.UseMatcher(nsMatcher)
	messaging.SetNonSubscribeTransport(ns.Transport)

	return func() {
			ns.Stop()

			messaging.SetNonSubscribeTransport(nil)
			vcrMu.Unlock()
		}, func(seconds int) {
			if ns.Mode() == recorder.ModeRecording {
				time.Sleep(time.Duration(seconds) * time.Second)
			} else {
				// do not sleep
			}
		}
}

func NewVCRSubscribe(name string, skipFields []string) func() {
	vcrMu.Lock()

	skipFields = append(skipFields, defaultFieldsToSkip...)
	s, _ := recorder.New(fmt.Sprintf("%s_%s", name, "Subscribe"))
	sMatcher := utils.NewPubnubSubscribeMatcher(skipFields)
	s.UseMatcher(sMatcher)
	messaging.SetSubscribeTransport(s.Transport)

	return func() {
		s.Stop()

		messaging.SetSubscribeTransport(nil)
		vcrMu.Unlock()
	}
}

func NewVCRBoth(name string, skipFields []string) (
	func(), func(int)) {

	vcrMu.Lock()

	skipFields = append(skipFields, defaultFieldsToSkip...)
	s, _ := recorder.New(fmt.Sprintf("%s_%s", name, "Subscribe"))
	s.UseMatcher(utils.NewPubnubSubscribeMatcher(skipFields))

	ns, _ := recorder.New(fmt.Sprintf("%s_%s", name, "NonSubscribe"))
	ns.UseMatcher(utils.NewPubnubMatcher(skipFields))

	messaging.SetSubscribeTransport(s.Transport)
	messaging.SetNonSubscribeTransport(ns.Transport)

	return func() {
			s.Stop()
			ns.Stop()

			messaging.SetSubscribeTransport(nil)
			messaging.SetNonSubscribeTransport(nil)
			vcrMu.Unlock()
		}, func(seconds int) {
			mode := recorder.ModeRecording
			if ns.Mode() == mode && s.Mode() == mode {
				time.Sleep(time.Duration(seconds) * time.Second)
			} else {
				// do not sleep
			}
		}
}

func NewAbortedTransport() func() {
	vcrMu.Lock()
	messaging.SetNonSubscribeTransport(abortedTransport)

	return func() {
		messaging.SetNonSubscribeTransport(nil)
		vcrMu.Unlock()
	}
}

func NewBadJSONTransport() func() {
	vcrMu.Lock()
	messaging.SetNonSubscribeTransport(badJSONTransport)

	return func() {
		messaging.SetNonSubscribeTransport(nil)
		vcrMu.Unlock()
	}
}

func NewHangingTransport() func() {
	vcrMu.Lock()
	messaging.SetNonSubscribeTransport(hangingTransport)

	return func() {
		messaging.SetNonSubscribeTransport(nil)
		vcrMu.Unlock()
	}
}

type BrokenConnectionTransport struct {
	Message   string
	PnMessage string
}

func (t *BrokenConnectionTransport) RoundTrip(r *http.Request) (*http.Response, error) {
	return nil, errors.New(t.Message)
}

var abortedTransport = &BrokenConnectionTransport{
	Message:   "closed network connection",
	PnMessage: "Connection aborted",
}

type BadJSONTransport struct {
	Message   string
	PnMessage string
}

func (t *BadJSONTransport) RoundTrip(r *http.Request) (*http.Response, error) {
	resp := http.Response{
		StatusCode: 200,
		Proto:      "HTTP/1.0",
		ProtoMajor: 1,
		ProtoMinor: 0,
	}

	header := http.Header{}
	header.Set("Content-Type", "text/javascript; charset=\"UTF-8\"")
	resp.Header = header

	resp.Body = ioutil.NopCloser(bytes.NewBuffer([]byte("i'm bad")))

	return &resp, nil
}

var badJSONTransport = &BadJSONTransport{}

type HangingTransport struct {
	Message     string
	PnMessage   string
	HangTimeout int
}

func (t *HangingTransport) RoundTrip(r *http.Request) (*http.Response, error) {
	trans := &http.Transport{}
	time.Sleep(time.Duration(t.HangTimeout) * time.Second)
	return trans.RoundTrip(r)
}

var hangingTransport = &HangingTransport{
	HangTimeout: 3,
}

func GetServerTimeString(uuid string) string {
	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)

	pubnubInstance := messaging.NewPubnub(PubKey, SubKey, "", "", false,
		fmt.Sprintf("timeGetter_%s", uuid), CreateLoggerForTests())

	go pubnubInstance.GetTime(successChannel, errorChannel)
	select {
	case value := <-successChannel:
		return strings.Trim(string(value), "[]\n")
	case err := <-errorChannel:
		panic(string(err))
	case <-timeouts(10):
		panic("Getting server timestamp timeout")
	}
}

func GetServerTime(uuid string) int64 {
	timestamp, err := strconv.Atoi(GetServerTimeString(uuid))
	if err != nil {
		panic(err.Error())
	}

	return int64(timestamp)
}

func LogErrors(errorsChannel <-chan []byte) {
	fmt.Printf("ERROR: %s", <-errorsChannel)
}

func createChannelGroups(pubnub *messaging.Pubnub, groups []string) {
	successChannel := make(chan []byte, 1)
	errorChannel := make(chan []byte, 1)

	for _, group := range groups {
		// fmt.Println("Creating group", group)

		pubnub.ChannelGroupAddChannel(group, "adsf", successChannel, errorChannel)

		select {
		case <-successChannel:
			// fmt.Println("Group created")
		case <-errorChannel:
			fmt.Println("Channel group creation error")
		case <-timeout():
			fmt.Println("Channel group creation timeout")
		}
	}
}

func populateChannelGroup(pubnub *messaging.Pubnub, group, channels string) {

	successChannel := make(chan []byte, 1)
	errorChannel := make(chan []byte, 1)

	pubnub.ChannelGroupAddChannel(group, channels, successChannel, errorChannel)

	select {
	case <-successChannel:
		// fmt.Println("Group created")
	case <-errorChannel:
		fmt.Println("Channel group creation error")
	case <-timeout():
		fmt.Println("Channel group creation timeout")
	}
}

func removeChannelGroups(pubnub *messaging.Pubnub, groups []string) {
	successChannel := make(chan []byte, 1)
	errorChannel := make(chan []byte, 1)

	for _, group := range groups {
		// fmt.Println("Removing group", group)

		pubnub.ChannelGroupRemoveGroup(group, successChannel, errorChannel)

		select {
		case <-successChannel:
			// fmt.Println("Group removed")
		case <-errorChannel:
			fmt.Println("Channel group removal error")
		case <-timeout():
			fmt.Println("Channel group removal timeout")
		}
	}
}

func sleep(seconds int) {
	time.Sleep(time.Duration(seconds) * time.Second)
}

func CreateLoggerForTests() *log.Logger {
	var infoLogger *log.Logger
	logfileName := "pubnubMessagingTests.log"
	f, err := os.OpenFile(logfileName, os.O_RDWR|os.O_CREATE|os.O_APPEND, 0666)
	if err != nil {
		fmt.Println("error opening file: ", err.Error())
		fmt.Println("Logging disabled")
	} else {
		//fmt.Println("Logging enabled writing to ", logfileName)
		infoLogger = log.New(f, "", log.Ldate|log.Ltime|log.Lshortfile)
	}
	return infoLogger
}
