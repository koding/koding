// Package messaging provides the implemetation to connect to pubnub api.
// Build Date: Jul 29, 2015
// Version: 3.6.3
package messaging

//TODO:
//websockets instead of channels

import (
	"bytes"
	"crypto/aes"
	"crypto/cipher"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"crypto/tls"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net"
	"net/http"
	"net/url"
	//"os"
	"reflect"
	"runtime"
	"strconv"
	"strings"
	"sync"
	"time"
)

// Enums for send response.
const (
	responseAlreadySubscribed  = 1 << iota //1
	responseConnected                      //2
	responseUnsubscribed                   //3
	responseNotSubscribed                  //4
	responseAsIs                           //5
	responseReconnected                    //6
	responseInternetConnIssues             //7
	reponseAbortMaxRetry                   //8
	responseAsIsError                      //9
	responseWithoutChannel                 //10
	responseTimedOut                       //11
)

// Enums for diff types of connections
const (
	subscribeTrans = 1 << iota
	nonSubscribeTrans
	presenceHeartbeatTrans
	retryTrans
)

const (
	//Sdk Identification Param appended to each request
	sdkIdentificationParamKey = "pnsdk"
	sdkIdentificationParamVal = "PubNub-Go/3.6.3"

	// This string is appended to all presence channels
	// to differentiate from the subscribe requests.
	presenceSuffix = "-pnpres"

	// This string is used when the server returns a malformed or non-JSON response.
	invalidJSON = "Invalid JSON"

	// This string is returned as a message when the http request times out.
	operationTimeout = "Operation Timeout"

	// This string is returned as a message when the http request is aborted.
	connectionAborted = "Connection aborted"

	// This string is encountered when the http request couldn't connect to the origin.
	noSuchHost = "no such host"

	// This string is returned as a message when network connection is not avaialbe.
	networkUnavailable = "Network unavailable"

	// This string is used when the http request faces connectivity issues.
	closedNetworkConnection = "closed network connection"

	// This string is used when the http request faces connectivity issues.
	connectionResetByPeer = "connection reset by peer"

	// This string is returned as a message when the http request encounters network connectivity issues.
	connectionResetByPeerU = "Connection reset by peer"

	// This string is used when the http request times out.
	timeout = "timeout"

	// This string is returned as a message when the http request times out.
	timeoutU = "Timeout"

	// This string is retured when the client faces issues in initializing the transport.
	errorInInitializing = "Error in initializing connection: "

	// This string is used when the server returns a non 200 response on publish
	publishFailed = "Publish Failed"

	// This string is used when we get an error on conversion from string to JSON
	invalidUserStateMap = "Invalid User State Map"
)

var (
	sdkIdentificationParam = fmt.Sprintf("%s=%s", sdkIdentificationParamKey, url.QueryEscape(sdkIdentificationParamVal))
	//sdkIdentificationParam = fmt.Sprintf("%s=%s", sdkIdentificationParamKey, sdkIdentificationParamVal)

	// The time after which the Publish/HereNow/DetailedHitsory/Unsubscribe/
	// UnsibscribePresence/Time  request will timeout.
	// In seconds.
	nonSubscribeTimeout uint16 = 20 //sec

	// On Subscribe/Presence timeout, the number of times the reconnect attempts are made.
	maxRetries = 50 //times

	// The delay in the reconnect attempts on timeout.
	// In seconds
	retryInterval uint16 = 10 //sec

	// The HTTP transport Dial timeout.
	// In seconds.
	connectTimeout uint16 = 10 //sec

	// Root url value of pubnub api without the http/https protocol.
	origin = "pubsub.pubnub.com"

	// The time after which the Subscribe/Presence request will timeout.
	// In seconds.
	subscribeTimeout uint16 = 310 //sec

	// Mutex to lock the operations on presenceHeartbeat ops
	presenceHeartbeatMu sync.RWMutex

	// The time after which the server expects the contact from the client.
	// In seconds.
	// If the server doesnt get an heartbeat request within this time, it will send
	// a "timeout" message
	presenceHeartbeat uint16 //sec

	// The time after which the Presence Heartbeat will fire.
	// In seconds.
	// We apply the logic Presence Heartbeat/2-1 seconds to calculate it.
	// If a user enters a value greater than the Presence Heartbeat value,
	// we will reset it to this calculated value.
	presenceHeartbeatInterval uint16 //sec

	// If resumeOnReconnect is TRUE, then upon reconnect,
	// it should use the last successfully retrieved timetoken.
	// This has the effect of continuing, or “catching up” to missed traffic.
	// If resumeOnReconnect is FALSE, then upon reconnect,
	// it should use a 0 (zero) timetoken.
	// This has the effect of continuing from “this moment onward”.
	// Any messages received since the previous timeout or network error are skipped.
	resumeOnReconnect = true

	// 16 byte IV
	valIV = "0123456789012345"

	// If true logs will be written in the log file
	loggingEnabled = true

	// This stirng is used as a log file name
	logfileWriter io.Writer

	// Logger for info messages
	infoLogger *log.Logger

	// Logger for error messages
	errorLogger *log.Logger

	// Logger for warn messages
	warnLogger *log.Logger

	//logMutex
	logMu sync.Mutex
)

var (
	// Global variable to store connection instance for retry requests.
	retryConn net.Conn

	// Global variable to reuse a commmon transport instance for retry requests.
	retryTransport http.RoundTripper

	// Mutux to lock the operations on retryTransport
	retryTransportMu sync.RWMutex

	// Global variable to store connection instance for presence heartbeat requests.
	presenceHeartbeatConn net.Conn

	// Global variable to reuse a commmon transport instance for presence heartbeat requests.
	presenceHeartbeatTransport http.RoundTripper

	// Mutux to lock the operations on presence heartbeat transport
	presenceHeartbeatTransportMu sync.RWMutex

	// Global variable to store connection instance for non subscribe requests
	// Publish/HereNow/DetailedHitsory/Unsubscribe/UnsibscribePresence/Time.
	conn net.Conn

	// Global variable to store connection instance for Subscribe/Presence requests.
	subscribeConn net.Conn

	// Global variable to reuse a commmon transport instance for Subscribe/Presence requests.
	subscribeTransport http.RoundTripper

	// Mutux to lock the operations on subscribeTransport
	subscribeTransportMu sync.RWMutex

	// Global variable to reuse a commmon transport instance for non subscribe requests
	// Publish/HereNow/DetailedHitsory/Unsubscribe/UnsibscribePresence/Time.
	nonSubscribeTransport http.RoundTripper

	// Mutux to lock the operations on nonSubscribeTransport
	nonSubscribeTransportMu sync.RWMutex

	// No of retries made since disconnection.
	retryCount = 0

	// Mutux to lock the operations on retryCount
	retryCountMu sync.RWMutex

	// variable to store the proxy server if set.
	proxyServer string

	// variable to store the proxy port if set.
	proxyPort int

	// variable to store the proxy username if set.
	proxyUser string

	// variable to store the proxy password if set.
	proxyPassword string

	// Global variable to check if the proxy server if used.
	proxyServerEnabled = false
)

// VersionInfo returns the version of the this code along with the build date.
func VersionInfo() string {
	return "PubNub Go client SDK Version: 3.6.3; Build Date: Jul 29, 2015;"
}

// Pubnub structure.
// origin stores the root url value of pubnub api in the current instance.
// publishKey stores the user specific Publish Key in the current instance.
// subscribeKey stores the user specific Subscribe Key in the current instance.
// secretKey stores the user specific Secret Key in the current instance.
// cipherKey stores the user specific Cipher Key in the current instance.
// authenticationKey stores the Authentication Key in the current instance.
// isSSL is true if enabled, else is false for the current instance.
// uuid is the unique identifier, it can be a custom value or is automatically generated.
// subscribedChannels keeps a list of subscribed Pubnub channels by the user in the a comma separated string.
// timeToken is the current value of the servertime. This will be used to appened in each request.
// sentTimeToken: This is the timetoken sent to the server with the request
// resetTimeToken: In case of a new request or an error this variable is set to true so that the
// timeToken will be set to 0 in the next request.
// presenceChannels: All the presence responses will be routed to this channel. It stores the response channels for
// each pubnub channel as map using the pubnub channel name as the key.
// subscribeChannels: All the subscribe responses will be routed to this channel. It stores the response channels for
// each pubnub channel as map using the pubnub channel name as the key.
// presenceErrorChannels: All the presence error responses will be routed to this channel. It stores the response channels for
// each pubnub channel as map using the pubnub channel name as the key.
// subscribeErrorChannels: All the subscribe error responses will be routed to this channel. It stores the response channels for
// each pubnub channel as map using the pubnub channel name as the key.
// newSubscribedChannels keeps a list of the new subscribed Pubnub channels by the user in the a comma
// separated string, before they are appended to the Pubnub SubscribedChannels.
// isPresenceHeartbeatRunning a variable to keep a check on the presence heartbeat's status
// Mutex to lock the operations on the instance
type Pubnub struct {
	origin                     string
	publishKey                 string
	subscribeKey               string
	secretKey                  string
	cipherKey                  string
	authenticationKey          string
	isSSL                      bool
	uuid                       string
	subscribedChannels         string
	timeToken                  string
	sentTimeToken              string
	resetTimeToken             bool
	presenceChannels           map[string]chan []byte
	subscribeChannels          map[string]chan []byte
	presenceErrorChannels      map[string]chan []byte
	subscribeErrorChannels     map[string]chan []byte
	newSubscribedChannels      string
	userState                  map[string]map[string]interface{}
	isPresenceHeartbeatRunning bool
	sync.RWMutex
}

// PubnubUnitTest structure used to expose some data for unit tests.
type PubnubUnitTest struct {
}

// NewPubnub initializes pubnub struct with the user provided values.
// And then initiates the origin by appending the protocol based upon the sslOn argument.
// Then it uses the customuuid or generates the uuid.
//
// It accepts the following parameters:
// publishKey is the user specific Publish Key. Mandatory.
// subscribeKey is the user specific Subscribe Key. Mandatory.
// secretKey is the user specific Secret Key. Accepts empty string if not used.
// cipherKey stores the user specific Cipher Key. Accepts empty string if not used.
// sslOn is true if enabled, else is false.
// customUuid is the unique identifier, it can be a custom value or sent as empty for automatic generation.
//
// returns the pointer to Pubnub instance.
func NewPubnub(publishKey string, subscribeKey string, secretKey string, cipherKey string, sslOn bool, customUuid string) *Pubnub {
	initLogging()
	logMu.Lock()
	infoLogger.Println(fmt.Sprintf("Pubnub Init, %s", VersionInfo()))
	infoLogger.Println(fmt.Sprintf("OS: %s", runtime.GOOS))
	logMu.Unlock()

	newPubnub := &Pubnub{}
	newPubnub.origin = origin
	newPubnub.publishKey = publishKey
	newPubnub.subscribeKey = subscribeKey
	newPubnub.secretKey = secretKey
	newPubnub.cipherKey = cipherKey
	newPubnub.isSSL = sslOn
	newPubnub.uuid = ""
	newPubnub.subscribedChannels = ""
	newPubnub.resetTimeToken = true
	newPubnub.timeToken = "0"
	newPubnub.sentTimeToken = "0"
	newPubnub.newSubscribedChannels = ""
	newPubnub.presenceChannels = make(map[string]chan []byte)
	newPubnub.subscribeChannels = make(map[string]chan []byte)
	newPubnub.presenceErrorChannels = make(map[string]chan []byte)
	newPubnub.subscribeErrorChannels = make(map[string]chan []byte)
	newPubnub.isPresenceHeartbeatRunning = false

	if newPubnub.isSSL {
		newPubnub.origin = "https://" + newPubnub.origin
	} else {
		newPubnub.origin = "http://" + newPubnub.origin
	}

	logMu.Lock()
	infoLogger.Println(fmt.Sprintf("Origin: %s", newPubnub.origin))
	logMu.Unlock()
	//Generate the uuid is custmUuid is not provided
	newPubnub.SetUUID(customUuid)

	return newPubnub
}

var once sync.Once

// initLogging initaites the log file if loggingEnabled is true
func initLogging() {
	logMu.Lock()
	defer logMu.Unlock()
	onceBody := func() {
		infoLogger = log.New(logfileWriter, "INFO: ", log.Ldate|log.Ltime|log.Lshortfile)
		errorLogger = log.New(logfileWriter, "ERROR: ", log.Ldate|log.Ltime|log.Lshortfile)
		warnLogger = log.New(logfileWriter, "WARN: ", log.Ldate|log.Ltime|log.Lshortfile)

		infoLogger.Println("****************************************")
	}
	if (loggingEnabled) && (logfileWriter != nil) {
		once.Do(onceBody)
	} else {
		/*if loggingEnabled {
			infoLogger = log.New(os.Stdout, "logfile writer not initialized", log.Ldate|log.Ltime|log.Lshortfile)
		}*/
		infoLogger = log.New(ioutil.Discard, "INFO: ", log.Ldate|log.Ltime|log.Lshortfile)
		errorLogger = log.New(ioutil.Discard, "ERROR: ", log.Ldate|log.Ltime|log.Lshortfile)
		warnLogger = log.New(ioutil.Discard, "WARN: ", log.Ldate|log.Ltime|log.Lshortfile)
	}
}

// SetProxy sets the global variables for the parameters.
// It also sets the proxyServerEnabled value to true.
//
// It accepts the following parameters:
// proxyServer proxy server name or ip.
// proxyPort proxy port.
// proxyUser proxyUserName.
// proxyPassword proxyPassword.
func SetProxy(proxyServerVal string, proxyPortVal int, proxyUserVal string, proxyPasswordVal string) {
	proxyServer = proxyServerVal
	proxyPort = proxyPortVal
	proxyUser = proxyUserVal
	proxyPassword = proxyPasswordVal
	proxyServerEnabled = true
}

// SetResumeOnReconnect sets the value of resumeOnReconnect.
func SetResumeOnReconnect(val bool) {
	resumeOnReconnect = val
}

// LoggingEnabled sets the value of loggingEnabled
// If true logs will be written to the logfileWriter
// In addition to LoggingEnabled you also need to init
// the logfileWriter using SetLogOutput
func LoggingEnabled(val bool) {
	loggingEnabled = val
}

// SetLogOutput sets the full path of the logfile
// Default name is pubnubMessaging.log and is located in the same dir
// from where the go file is run
// In addition to this LoggingEnabled should be true for this to work.
func SetLogOutput(val io.Writer) {
	logfileWriter = val
}

// Logging gets the value of loggingEnabled
// If true logs will be written to a file
func Logging() bool {
	return loggingEnabled
}

// SetAuthenticationKey sets the value of authentication key
func (pub *Pubnub) SetAuthenticationKey(val string) {
	pub.Lock()
	defer pub.Unlock()
	pub.authenticationKey = val
}

// GetAuthenticationKey gets the value of authentication key
func (pub *Pubnub) GetAuthenticationKey() string {
	return pub.authenticationKey
}

// SetUUID sets the value of UUID
func (pub *Pubnub) SetUUID(val string) {
	pub.Lock()
	defer pub.Unlock()
	if strings.TrimSpace(val) == "" {
		uuid, err := GenUuid()
		if err == nil {
			pub.uuid = url.QueryEscape(uuid)
		} else {
			logMu.Lock()
			errorLogger.Println(err.Error())
			logMu.Unlock()
		}
	} else {
		pub.uuid = url.QueryEscape(val)
	}
}

// GetUUID returns the value of UUID
func (pub *Pubnub) GetUUID() string {
	return pub.uuid
}

// SetPresenceHeartbeat sets the value of presence heartbeat.
// When the presence heartbeat is set the presenceHeartbeatInterval is automatically set to
// (presenceHeartbeat / 2) - 1
// Starts the presence heartbeat request if both presenceHeartbeatInterval and presenceHeartbeat
// are set and a presence notifications are subsribed
func (pub *Pubnub) SetPresenceHeartbeat(val uint16) {
	presenceHeartbeatMu.Lock()
	defer presenceHeartbeatMu.Unlock()
	//set presenceHeartbeatInterval
	presenceHeartbeat = val
	if val <= 0 || val > 320 {
		presenceHeartbeat = 0
		presenceHeartbeatInterval = 0
	} else {
		presenceHeartbeat = val
		presenceHeartbeatInterval = uint16((presenceHeartbeat / 2) - 1)
	}
	go pub.runPresenceHeartbeat()
}

// GetPresenceHeartbeat gets the value of presenceHeartbeat
func (pub *Pubnub) GetPresenceHeartbeat() uint16 {
	presenceHeartbeatMu.RLock()
	defer presenceHeartbeatMu.RUnlock()
	return presenceHeartbeat
}

// SetPresenceHeartbeatInterval sets the value of presenceHeartbeatInterval.
// If the value is greater than presenceHeartbeat and there is a value set for presenceHeartbeat
// then is automatically set to (presenceHeartbeat / 2) - 1
// Starts the presence heartbeat request if both presenceHeartbeatInterval and presenceHeartbeat
// are set and a presence notifications are subsribed
func (pub *Pubnub) SetPresenceHeartbeatInterval(val uint16) {
	presenceHeartbeatMu.Lock()
	defer presenceHeartbeatMu.Unlock()
	//check presence heartbeat and set
	presenceHeartbeatInterval = val

	if (presenceHeartbeatInterval >= presenceHeartbeat) && (presenceHeartbeat > 0) {
		presenceHeartbeatInterval = (presenceHeartbeat / 2) - 1
	}
	go pub.runPresenceHeartbeat()
}

// GetPresenceHeartbeatInterval gets the value of presenceHeartbeatInterval
func (pub *Pubnub) GetPresenceHeartbeatInterval() uint16 {
	presenceHeartbeatMu.RLock()
	defer presenceHeartbeatMu.RUnlock()
	return presenceHeartbeatInterval
}

// SetSubscribeTimeout sets the value of subscribeTimeout.
func SetSubscribeTimeout(val uint16) {
	subscribeTransportMu.Lock()
	defer subscribeTransportMu.Unlock()
	subscribeTimeout = val
}

// GetSubscribeTimeout gets the value of subscribeTimeout
func GetSubscribeTimeout() uint16 {
	subscribeTransportMu.RLock()
	defer subscribeTransportMu.RUnlock()
	return subscribeTimeout
}

// SetRetryInterval sets the value of retryInterval.
func SetRetryInterval(val uint16) {
	retryInterval = val
}

// SetMaxRetries sets the value of maxRetries.
func SetMaxRetries(val int) {
	maxRetries = val
}

// SetNonSubscribeTimeout sets the value of nonsubscribeTimeout.
func SetNonSubscribeTimeout(val uint16) {
	nonSubscribeTransportMu.Lock()
	defer nonSubscribeTransportMu.Unlock()
	nonSubscribeTimeout = val
}

// GetNonSubscribeTimeout gets the value of nonSubscribeTimeout
func GetNonSubscribeTimeout() uint16 {
	nonSubscribeTransportMu.RLock()
	defer nonSubscribeTransportMu.RUnlock()
	return nonSubscribeTimeout
}

// SetIV sets the value of valIV.
func SetIV(val string) {
	valIV = val
}

// SetConnectTimeout sets the value of connectTimeout.
func SetConnectTimeout(val uint16) {
	connectTimeout = val
}

// SetOrigin sets the value of _origin. Should be called before PubnubInit
func SetOrigin(val string) {
	origin = val
}

// GetSentTimeToken returns the timetoken sent to the server, is used only for unit tests
func (pubtest *PubnubUnitTest) GetSentTimeToken(pub *Pubnub) string {
	pub.RLock()
	defer pub.RUnlock()
	return pub.sentTimeToken
}

// GetTimeToken returns the latest timetoken received from the server, is used only for unit tests
func (pubtest *PubnubUnitTest) GetTimeToken(pub *Pubnub) string {
	pub.RLock()
	defer pub.RUnlock()
	return pub.timeToken
}

// Abort is the struct Pubnub's instance method that closes the open connections for both subscribe
// and non-subscribe requests.
//
// It also sends a leave request for all the subscribed channel and
// sets the pub.SubscribedChannels as empty to break the loop in the func StartSubscribeLoop
func (pub *Pubnub) Abort() {
	if pub.subscribedChannels != "" {
		value, _, err := pub.sendLeaveRequest(pub.subscribedChannels)
		if err != nil {
			logMu.Lock()
			errorLogger.Println(fmt.Sprintf("Request aborted error:%s", err.Error()))
			logMu.Unlock()
			pub.sendResponseToChannel(nil, pub.subscribedChannels, responseAsIsError, err.Error(), "")
		} else {
			pub.sendResponseToChannel(nil, pub.subscribedChannels, responseAsIs, string(value), "")
		}
		logMu.Lock()
		infoLogger.Println(fmt.Sprintf("Request aborted for channels: %s", pub.subscribedChannels))
		logMu.Unlock()
		pub.Lock()
		pub.subscribedChannels = ""
		pub.Unlock()
	}

	nonSubscribeTransportMu.Lock()
	defer nonSubscribeTransportMu.Unlock()
	if conn != nil {
		logMu.Lock()
		infoLogger.Println(fmt.Sprintf("Closing conn"))
		logMu.Unlock()
		conn.Close()
	}

	pub.CloseExistingConnection()
	infoLogger.Println(fmt.Sprintf("CloseExistingConnection "))
	pub.closePresenceHeartbeatConnection()
	infoLogger.Println(fmt.Sprintf("closePresenceHeartbeatConnection"))
	pub.closeRetryConnection()
	infoLogger.Println(fmt.Sprintf("closeRetryConnection"))
}

// closePresenceHeartbeatConnection closes the presence heartbeat connection
func (pub *Pubnub) closePresenceHeartbeatConnection() {
	presenceHeartbeatTransportMu.Lock()
	if presenceHeartbeatConn != nil {
		logMu.Lock()
		infoLogger.Println(fmt.Sprintf("Closing presence conn"))
		logMu.Unlock()
		presenceHeartbeatConn.Close()
	}
	presenceHeartbeatTransportMu.Unlock()
}

// closeRetryConnection closes the retry connection
func (pub *Pubnub) closeRetryConnection() {
	retryTransportMu.Lock()
	if retryConn != nil {
		logMu.Lock()
		infoLogger.Println(fmt.Sprintf("Closing retry conn"))
		logMu.Unlock()
		retryConn.Close()
	}
	retryTransportMu.Unlock()
}

// GrantSubscribe is used to give a subscribe channel read, write permissions
// and set TTL values for it. To grant a permission set read or write as true
// to revoke all perms set read and write false and ttl as -1
//
// channel is options and if not provided will set the permissions at subkey level
//
// Both callbackChannel and errorChannel are mandatory. If either is nil the code will panic
func (pub *Pubnub) GrantSubscribe(channel string, read bool, write bool, ttl int, callbackChannel chan []byte, errorChannel chan []byte) {
	checkCallbackNil(callbackChannel, false, "GrantSubscribe")
	checkCallbackNil(errorChannel, true, "GrantSubscribe")

	pub.executePam(channel, read, write, ttl, "", callbackChannel, errorChannel, false)
}

// AuditSubscribe will make a call to display the permissions for a channel or subkey
//
// channel is options and if not provided will set the permissions at subkey level
//
// Both callbackChannel and errorChannel are mandatory. If either is nil the code will panic
func (pub *Pubnub) AuditSubscribe(channel string, callbackChannel chan []byte, errorChannel chan []byte) {
	checkCallbackNil(callbackChannel, false, "AuditSubscribe")
	checkCallbackNil(errorChannel, true, "AuditSubscribe")

	pub.executePam(channel, false, false, -1, "", callbackChannel, errorChannel, true)
}

// GrantPresence is used to give a presence channel read, write permissions
// and set TTL values for it. To grant a permission set read or write as true
// to revoke all perms set read and write false and ttl as -1
//
// channel is options and if not provided will set the permissions at subkey level
//
// Both callbackChannel and errorChannel are mandatory. If either is nil the code will panic
func (pub *Pubnub) GrantPresence(channel string, read bool, write bool, ttl int, callbackChannel chan []byte, errorChannel chan []byte) {
	checkCallbackNil(callbackChannel, false, "GrantPresence")
	checkCallbackNil(errorChannel, true, "GrantPresence")

	channel2 := convertToPresenceChannel(channel)
	pub.executePam(channel2, read, write, ttl, "", callbackChannel, errorChannel, false)
}

// AuditPresence will make a call to display the permissions for a channel or subkey
//
// channel is options and if not provided will set the permissions at subkey level
//
// Both callbackChannel and errorChannel are mandatory. If either is nil the code will panic
func (pub *Pubnub) AuditPresence(channel string, callbackChannel chan []byte, errorChannel chan []byte) {
	checkCallbackNil(callbackChannel, false, "AuditPresence")
	checkCallbackNil(errorChannel, true, "AuditPresence")

	channel2 := convertToPresenceChannel(channel)
	pub.executePam(channel2, false, false, -1, "", callbackChannel, errorChannel, true)
}

// removeSpacesFromChannelNames will remove the empty spaces from the channels (sent as a comma separated string)
// will return the channels in a comma separated stirng
//
func removeSpacesFromChannelNames(channel string) string {
	var retChannel string
	channelArray := strings.Split(channel, ",")
	comma := ""
	for i := 0; i < len(channelArray); i++ {
		if i >= 1 {
			comma = ","
		}
		if strings.TrimSpace(channelArray[i]) != "" {
			retChannel = fmt.Sprintf("%s%s%s", retChannel, comma, channelArray[i])
		}
	}

	return retChannel
}

// convertToPresenceChannel will add the presence suffix to the channel(s)
// multiple channels are provided as a comma separated string
// returns comma separated string
func convertToPresenceChannel(channel string) string {
	var retChannel string
	channelArray := strings.Split(channel, ",")
	comma := ""
	for i := 0; i < len(channelArray); i++ {
		if i >= 1 {
			comma = ","
		}
		if strings.TrimSpace(channelArray[i]) != "" {
			retChannel = fmt.Sprintf("%s%s%s%s", retChannel, comma, channelArray[i], presenceSuffix)
		}
	}

	return retChannel
}

func queryEscapeMultiple(q string, splitter string) string {
	channelArray := strings.Split(q, splitter)
	var pBuffer bytes.Buffer
	count := 0
	for i := 0; i < len(channelArray); i++ {
		if count > 0 {
			pBuffer.WriteString(splitter)
		}
		count++
		pBuffer.WriteString(url.QueryEscape(channelArray[i]))
	}
	return pBuffer.String()
}

// executePam is the main method which is called for all PAM requests
//
// for audit request the isAudit parameter should be true
func (pub *Pubnub) executePam(channel string, read, write bool, ttl int,
	authKey string, callbackChannel, errorChannel chan []byte, isAudit bool) {
	signature := ""
	noChannel := true
	grantOrAudit := "grant"
	authParam := ""
	channelParam := ""
	readParam := ""
	writeParam := ""
	timestampParam := ""
	ttlParam := ""

	var params bytes.Buffer

	if strings.TrimSpace(channel) != "" {
		if isAudit {
			channelParam = fmt.Sprintf("channel=%s", url.QueryEscape(channel))
		} else {
			channelParam = fmt.Sprintf("channel=%s&", url.QueryEscape(channel))
		}
		noChannel = false
	}

	if strings.TrimSpace(pub.secretKey) == "" {
		message := "Secret key is required"
		if noChannel {
			pub.sendResponseToChannel(errorChannel, "", responseWithoutChannel, message, "")
		} else {
			pub.sendResponseToChannel(errorChannel, channel, responseAsIsError, message, "")
		}
		return
	}

	if strings.TrimSpace(authKey) != "" {
		if isAudit {
			if !noChannel {
				authParam = fmt.Sprintf("auth=%s&", url.QueryEscape(authKey))
			} else {
				authParam = fmt.Sprintf("auth=%s", url.QueryEscape(authKey))
			}
		} else {
			authParam = fmt.Sprintf("auth=%s&", url.QueryEscape(authKey))
		}
	}

	var pamURLBuffer bytes.Buffer
	pamURLBuffer.WriteString("/v1/auth/")
	filler := "&"
	if (noChannel) && (strings.TrimSpace(authKey) == "") {
		filler = ""
	}
	if isAudit {
		grantOrAudit = "audit"
		timestampParam = fmt.Sprintf("timestamp=%s", getUnixTimeStamp())
	} else {
		timestampParam = fmt.Sprintf("timestamp=%s", getUnixTimeStamp())

		if read {
			readParam = "r=1&"
		} else {
			readParam = "r=0&"
		}

		if write {
			writeParam = "&w=1"
		} else {
			writeParam = "&w=0"
		}
		if ttl != -1 {
			if isAudit {
				ttlParam = fmt.Sprintf("&ttl=%s", strconv.Itoa(ttl))
			} else {
				ttlParam = fmt.Sprintf("ttl=%s", strconv.Itoa(ttl))
			}
		}
	}
	pamURLBuffer.WriteString(grantOrAudit)
	if isAudit {
		params.WriteString(fmt.Sprintf("%s%s%s%s&%s%s&uuid=%s%s%s", authParam, channelParam, filler, sdkIdentificationParam, readParam, timestampParam, pub.GetUUID(), ttlParam, writeParam))
	} else {
		if ttl != -1 {
			params.WriteString(fmt.Sprintf("%s%s%s&%s%s&%s&uuid=%s%s", authParam, channelParam, sdkIdentificationParam, readParam, timestampParam, ttlParam, pub.GetUUID(), writeParam))
		} else {
			params.WriteString(fmt.Sprintf("%s%s%s&%s%s&uuid=%s%s", authParam, channelParam, sdkIdentificationParam, readParam, timestampParam, pub.GetUUID(), writeParam))
		}
	}
	raw := fmt.Sprintf("%s\n%s\n%s\n%s", pub.subscribeKey, pub.publishKey, grantOrAudit, params.String())
	signature = getHmacSha256(pub.secretKey, raw)

	params.WriteString("&")
	params.WriteString("signature=")
	params.WriteString(signature)

	pamURLBuffer.WriteString("/sub-key/")
	pamURLBuffer.WriteString(pub.subscribeKey)
	pamURLBuffer.WriteString("?")
	pamURLBuffer.WriteString(params.String())

	value, responseCode, err := pub.httpRequest(pamURLBuffer.String(), nonSubscribeTrans)
	if (responseCode != 200) || (err != nil) {
		var message = ""
		if err != nil {
			message = err.Error()
			logMu.Lock()
			errorLogger.Println(fmt.Sprintf("PAM Error: %s", message))
			logMu.Unlock()
		} else {
			message = fmt.Sprintf("%s", value)
			logMu.Lock()
			errorLogger.Println(fmt.Sprintf("PAM Error: responseCode %d, message %s", responseCode, message))
			logMu.Unlock()
		}
		if noChannel {
			pub.sendResponseToChannel(errorChannel, "", responseWithoutChannel, message, "")
		} else {
			pub.sendResponseToChannel(errorChannel, channel, responseAsIsError, message, "")
		}
	} else {
		callbackChannel <- []byte(fmt.Sprintf("%s", value))
	}
}

// getUnixTimeStamp gets the unix timestamp
//
func getUnixTimeStamp() string {
	return fmt.Sprintf("%d", time.Now().Unix())
}

// GetTime is the struct Pubnub's instance method that calls the ExecuteTime
// method to process the time request.
//.
// It accepts the following parameters:
// callbackChannel on which to send the response.
// errorChannel on which to send the error response.
//
// Both callbackChannel and errorChannel are mandatory. If either is nil the code will panic
func (pub *Pubnub) GetTime(callbackChannel chan []byte, errorChannel chan []byte) {
	checkCallbackNil(callbackChannel, false, "GetTime")
	checkCallbackNil(errorChannel, true, "GetTime")

	pub.executeTime(callbackChannel, errorChannel, 0)
}

// executeTime is the struct Pubnub's instance method that creates a time request and sends back the
// response to the channel.
// Closes the channel when the response is sent.
// In case we get an invalid json response the routine retries till the _maxRetries to get a valid
// response.
//
// callbackChannel on which to send the response.
// errorChannel on which the error response is sent.
// retryCount to track the retry logic.
func (pub *Pubnub) executeTime(callbackChannel chan []byte, errorChannel chan []byte, retryCount int) {
	count := retryCount

	timeURL := ""
	timeURL += "/time"
	timeURL += "/0"

	timeURL += "?"
	timeURL += sdkIdentificationParam
	timeURL += "&uuid="
	timeURL += pub.GetUUID()

	value, _, err := pub.httpRequest(timeURL, nonSubscribeTrans)

	if err != nil {
		logMu.Lock()
		errorLogger.Println(fmt.Sprintf("Time Error: %s", err.Error()))
		logMu.Unlock()
		pub.sendResponseToChannel(errorChannel, "", responseWithoutChannel, err.Error(), "")
	} else {
		_, _, _, errJSON := ParseJSON(value, pub.cipherKey)
		if errJSON != nil && strings.Contains(errJSON.Error(), invalidJSON) {
			logMu.Lock()
			errorLogger.Println(fmt.Sprintf("Time Error: %s", errJSON.Error()))
			logMu.Unlock()
			pub.sendResponseToChannel(errorChannel, "", responseWithoutChannel, errJSON.Error(), "")
			if count < maxRetries {
				count++
				pub.executeTime(callbackChannel, errorChannel, count)
			}
		} else {
			callbackChannel <- []byte(fmt.Sprintf("%s", value))
		}
	}
}

// sendPublishRequest is the struct Pubnub's instance method that posts a publish request and
// sends back the response to the channel.
//
// It accepts the following parameters:
// channel: pubnub channel to publish to
// publishUrlString: The url to which the message is to be appended.
// jsonBytes: the message to be sent.
// callbackChannel: Channel on which to send the response.
// errorChannel on which the error response is sent.
func (pub *Pubnub) sendPublishRequest(channel string, publishURLString string, jsonBytes []byte, callbackChannel chan []byte, errorChannel chan []byte) {
	u := &url.URL{Path: string(jsonBytes)}
	encodedPath := u.String()
	logMu.Lock()
	infoLogger.Println(fmt.Sprintf("Publish: json: %s, encoded: %s", string(jsonBytes), encodedPath))
	logMu.Unlock()

	publishURL := fmt.Sprintf("%s%s", publishURLString, encodedPath)
	publishURL = fmt.Sprintf("%s?%s&uuid=%s%s", publishURL, sdkIdentificationParam, pub.GetUUID(), pub.addAuthParam(true))

	value, responseCode, err := pub.httpRequest(publishURL, nonSubscribeTrans)

	if (responseCode != 200) || (err != nil) {
		if (value != nil) && (responseCode > 0) {
			var s []interface{}
			errJSON := json.Unmarshal(value, &s)

			if (errJSON == nil) && (len(s) > 0) {
				if message, ok := s[1].(string); ok {
					pub.sendResponseToChannel(errorChannel, channel, responseAsIsError, message, strconv.Itoa(responseCode))
				} else {
					pub.sendResponseToChannel(errorChannel, channel, responseAsIsError, string(value), strconv.Itoa(responseCode))
				}
			} else {
				logMu.Lock()
				errorLogger.Println(fmt.Sprintf("Publish Error: %s", errJSON.Error()))
				logMu.Unlock()
				pub.sendResponseToChannel(errorChannel, channel, responseAsIsError, string(value), strconv.Itoa(responseCode))
			}
		} else if (err != nil) && (responseCode > 0) {
			logMu.Lock()
			errorLogger.Println(fmt.Sprintf("Publish Failed: %s, ResponseCode: %d", err.Error(), responseCode))
			logMu.Unlock()
			pub.sendResponseToChannel(errorChannel, channel, responseAsIsError, err.Error(), strconv.Itoa(responseCode))
		} else if err != nil {
			logMu.Lock()
			errorLogger.Println(fmt.Sprintf("Publish Failed: %s", err.Error()))
			logMu.Unlock()
			pub.sendResponseToChannel(errorChannel, channel, responseAsIsError, err.Error(), "")
		} else {
			logMu.Lock()
			errorLogger.Println(fmt.Sprintf("Publish Failed: ResponseCode: %d", responseCode))
			logMu.Unlock()
			pub.sendResponseToChannel(errorChannel, channel, responseAsIsError, publishFailed, strconv.Itoa(responseCode))
		}
	} else {
		_, _, _, errJSON := ParseJSON(value, pub.cipherKey)
		if errJSON != nil && strings.Contains(errJSON.Error(), invalidJSON) {
			logMu.Lock()
			errorLogger.Println(fmt.Sprintf("Publish Error: %s", errJSON.Error()))
			logMu.Unlock()
			pub.sendResponseToChannel(errorChannel, channel, responseAsIsError, errJSON.Error(), "")
		} else {
			callbackChannel <- []byte(fmt.Sprintf("%s", value))
		}
	}
}

func encodeURL(urlString string) string {
	var reqURL *url.URL
	reqURL, urlErr := url.Parse(urlString)
	if urlErr != nil {
		logMu.Lock()
		errorLogger.Println(fmt.Sprintf("Url encoding error: %s", urlErr.Error()))
		logMu.Unlock()
		return urlString
	}
	q := reqURL.Query()
	reqURL.RawQuery = q.Encode()
	return reqURL.String()
}

// invalidMessage takes the message in form of a interface and checks if the message is nil or empty.
// Returns true if the message is nil or empty.
// Returns false is the message is acceptable.
func invalidMessage(message interface{}) bool {
	if message == nil {
		logMu.Lock()
		warnLogger.Println(fmt.Sprintf("Message nil"))
		logMu.Unlock()
		return true
	}

	dataInterface := message.(interface{})

	switch vv := dataInterface.(type) {
	case string:
		if strings.TrimSpace(vv) != "" {
			return false
		}
	case []interface{}:
		if vv != nil {
			return false
		}
	default:
		if vv != nil {
			return false
		}
	}
	return true
}

// invalidChannel takes the Pubnub channel and the channel as parameters.
// Multiple Pubnub channels are accepted separated by comma.
// It splits the Pubnub channel string by a comma and checks if the channel empty.
// Returns true if any one of the channel is empty. And sends a response on the Pubnub channel stating
// that there is an "Invalid Channel".
// Returns false if all the channels is acceptable.
func invalidChannel(channel string, c chan []byte) bool {
	if strings.TrimSpace(channel) == "" {
		return true
	}
	channelArray := strings.Split(channel, ",")

	for i := 0; i < len(channelArray); i++ {
		if strings.TrimSpace(channelArray[i]) == "" {
			logMu.Lock()
			warnLogger.Println(fmt.Sprintf("Channel empty"))
			logMu.Unlock()
			c <- []byte(fmt.Sprintf("Invalid Channel: %s", channel))
			return true
		}
	}
	return false
}

// Publish is the struct Pubnub's instance method that creates a publish request and calls
// SendPublishRequest to post the request.
//
// It calls the InvalidChannel and InvalidMessage methods to validate the Pubnub channels and message.
// Calls the GetHmacSha256 to generate a signature if a secretKey is to be used.
// Creates the publish url
// Calls json marshal
// Calls the EncryptString method is the cipherkey is used and calls json marshal
// Closes the channel after the response is received
//
// It accepts the following parameters:
// channel: The Pubnub channel to which the message is to be posted.
// message: message to be posted.
// callbackChannel: Channel on which to send the response back.
// errorChannel on which the error response is sent.
//
// Both callbackChannel and errorChannel are mandatory. If either is nil the code will panic
func (pub *Pubnub) Publish(channel string, message interface{}, callbackChannel chan []byte, errorChannel chan []byte) {
	checkCallbackNil(callbackChannel, false, "Publish")
	checkCallbackNil(errorChannel, true, "Publish")

	if pub.publishKey == "" {
		logMu.Lock()
		warnLogger.Println(fmt.Sprintf("Publish key empty"))
		logMu.Unlock()
		pub.sendResponseToChannel(errorChannel, channel, responseAsIsError, "Publish key required.", "")
		return
	}

	if invalidChannel(channel, callbackChannel) {
		return
	}

	if invalidMessage(message) {
		pub.sendResponseToChannel(errorChannel, channel, responseAsIsError, "Invalid Message.", "")
		return
	}

	signature := ""
	if pub.secretKey != "" {
		signature = getHmacSha256(pub.secretKey, fmt.Sprintf("%s/%s/%s/%s/%s", pub.publishKey, pub.subscribeKey, pub.secretKey, channel, message))
	} else {
		signature = "0"
	}
	var publishURLBuffer bytes.Buffer
	publishURLBuffer.WriteString("/publish")
	publishURLBuffer.WriteString("/")
	publishURLBuffer.WriteString(pub.publishKey)
	publishURLBuffer.WriteString("/")
	publishURLBuffer.WriteString(pub.subscribeKey)
	publishURLBuffer.WriteString("/")
	publishURLBuffer.WriteString(signature)
	publishURLBuffer.WriteString("/")
	publishURLBuffer.WriteString(url.QueryEscape(channel))
	publishURLBuffer.WriteString("/0/")

	jsonSerialized, err := json.Marshal(message)
	if err != nil {
		pub.sendResponseToChannel(errorChannel, channel, responseAsIsError, fmt.Sprintf("error in serializing: %s", err), "")
	} else {
		if pub.cipherKey != "" {
			//Encrypt and Serialize
			jsonEncBytes, errEnc := json.Marshal(EncryptString(pub.cipherKey, fmt.Sprintf("%s", jsonSerialized)))
			if errEnc != nil {
				logMu.Lock()
				errorLogger.Println(fmt.Sprintf("Publish error: %s", errEnc.Error()))
				logMu.Unlock()
				pub.sendResponseToChannel(errorChannel, channel, responseAsIsError, fmt.Sprintf("error in serializing: %s", errEnc), "")
			} else {
				pub.sendPublishRequest(channel, publishURLBuffer.String(), jsonEncBytes, callbackChannel, errorChannel)
			}
		} else {
			pub.sendPublishRequest(channel, publishURLBuffer.String(), jsonSerialized, callbackChannel, errorChannel)
		}
	}
}

// sendResponseToChannel is the struct Pubnub's instance method that sends a reponse on the channel
// provided as an argument or to the subscribe / presence channel is the argument is nil.
//
// Constructs the response based on the action (1-9). In case the action is 5 sends the response
// as in the parameter response.
//
// It accepts the following parameters:
// c: Channel on which to send the response back. Can be nil. If nil, assumes that if the channel name
// is suffixed with "-pnpres" it is a presence channel else subscribe channel and sends the response to all the
// respective channels. Then it fetches the corresonding channel from the pub.PresenceChannels or pub.SubscribeChannels
// in case of callback and pub.PresenceErrorChannels or pub.SubscribeErrorChannels in case of error
//
// channels: Pubnub Channels to send a response to. Comma separated string for multiple channels.
// action: (1-9)
// response: can be nil, is used only in the case action is '5'.
// response2: Additional error info.
func (pub *Pubnub) sendResponseToChannel(c chan []byte, channels string, action int, response string, response2 string) {
	message := ""
	intResponse := "0"
	sendReponseAsIs := false
	sendErrorResponse := false
	errorWithoutChannel := false
	switch action {
	case responseAlreadySubscribed:
		message = "already subscribed"
		intResponse = "0"
	case responseConnected:
		message = "connected"
		intResponse = "1"
	case responseUnsubscribed:
		message = "unsubscribed"
		intResponse = "1"
	case responseNotSubscribed:
		message = "not subscribed"
		intResponse = "0"
	case responseAsIs:
		sendReponseAsIs = true
	case responseReconnected:
		message = "reconnected"
		intResponse = "1"
	case responseInternetConnIssues:
		message = "disconnected due to internet connection issues, trying to reconnect. Retry count:" + response
		response = ""
		intResponse = "0"
		sendErrorResponse = true
	case reponseAbortMaxRetry:
		message = "aborted due to max retry limit"
		intResponse = "0"
		sendErrorResponse = true
	case responseAsIsError:
		sendErrorResponse = true
		sendReponseAsIs = true
		intResponse = "0"
	case responseWithoutChannel:
		errorWithoutChannel = true
	case responseTimedOut:
		message = "timed out."
		response = ""
		intResponse = "0"
		sendErrorResponse = true
	}
	var value string
	channelArray := strings.Split(channels, ",")

	for i := 0; i < len(channelArray); i++ {
		responseChannel := c
		presence := "Subscription to channel "
		channel := strings.TrimSpace(channelArray[i])
		if channel == "" {
			continue
		}

		if response == "" {
			response = message
		}
		if sendErrorResponse {
			isPresence := false
			if responseChannel == nil {
				responseChannel, isPresence = pub.getChannelForPubnubChannel(channel, true)
			} else {
				isPresence = strings.Contains(channel, presenceSuffix)
			}
			if isPresence {
				presence = "Presence notifications for channel "
			}
			if sendReponseAsIs {
				presence = ""
			}
			if (response2 != "") && (response2 != "0") {
				value = fmt.Sprintf("[%s, \"%s%s\", %s, \"%s\"]", intResponse, presence, response, response2, strings.Replace(channel, presenceSuffix, "", -1))
			} else {
				value = fmt.Sprintf("[%s, \"%s%s\", \"%s\"]", intResponse, presence, response, strings.Replace(channel, presenceSuffix, "", -1))
			}
			logMu.Lock()
			infoLogger.Println(fmt.Sprintf("Response value: %s", value))
			logMu.Unlock()

			if responseChannel != nil {
				responseChannel <- []byte(value)
			}
		} else {
			isPresence := false
			if responseChannel == nil {
				responseChannel, isPresence = pub.getChannelForPubnubChannel(channel, false)
			} else {
				isPresence = strings.Contains(channel, presenceSuffix)
			}
			if isPresence {
				channel = strings.Replace(channel, presenceSuffix, "", -1)
				presence = "Presence notifications for channel "
			}

			if sendReponseAsIs {
				value = strings.Replace(response, presenceSuffix, "", -1)
			} else {
				value = fmt.Sprintf("[%s, \"%s'%s' %s\", \"%s\"]", intResponse, presence, channel, message, channel)
			}
			logMu.Lock()
			infoLogger.Println(fmt.Sprintf("Response value: %s", value))
			logMu.Unlock()
			if responseChannel != nil {
				responseChannel <- []byte(value)
			}
		}
	}
	if errorWithoutChannel {
		responseChannel := c
		value = fmt.Sprintf("[%s, \"%s\"]", intResponse, response)
		logMu.Lock()
		infoLogger.Println(fmt.Sprintf("Response value without channel: %s", value))
		logMu.Unlock()
		if responseChannel != nil {
			responseChannel <- []byte(value)
		}
	}
}

// getChannelForPubnubChannel parses the pubnub channel and returns the the callback or the erro channel
//
// Accepts the pubnub channel name channel as string, the string is parsed to check if it is a
// Subscribe or a Presence channel.
//
// and isErrorChannel as bool. If it is true PresenceErrorChannels or SubscribeErrorChannels
// will be used to fetch the corresponding channel.
//
// Returns channel to send a response on
// and bool if true means it is a pubnub Presence channel. Else it is a pubnub Subscribe channel.
func (pub *Pubnub) getChannelForPubnubChannel(channel string, isErrorChannel bool) (chan []byte, bool) {
	isPresence := strings.Contains(channel, presenceSuffix)
	pub.RLock()
	defer pub.RUnlock()
	if isPresence {
		channel = strings.Replace(string(channel), presenceSuffix, "", -1)
		if isErrorChannel {
			c, found := pub.presenceErrorChannels[channel]
			if found {
				return c, true
			}
		} else {
			c, found := pub.presenceChannels[channel]
			if found {
				return c, true
			}
		}
	} else {
		if isErrorChannel {
			c, found := pub.subscribeErrorChannels[channel]
			if found {
				return c, false
			}
		} else {
			c, found := pub.subscribeChannels[channel]
			if found {
				return c, false
			}
		}
	}
	return nil, false
}

// getSubscribedChannels is the struct Pubnub's instance method that iterates through the Pubnub
// SubscribedChannels and appends the new channels.
//
// It splits the Pubnub channels in the parameter by a comma and compares them to the existing
// subscribed Pubnub channels.
// If a new Pubnub channels is found it is appended to the Pubnub SubscribedChannels. The return
// parameter channelsModified is set to true
// If an subscribed pubnub channel is already present in the Pubnub SubscribedChannels it is added to
// the alreadySubscribedChannels string and a response is sent back to the channel
//
// It accepts the following parameters:
// channels: Pubnub Channels to send a response to. Comma separated string for multiple channels.
// c: Channel on which to send the response back. Can be nil. If nil assumes that if the channel name
// is suffixed with "-pnpres" it is a presence channel else subscribe channel and send the response to
// the respective channel.
// isPresenceSubscribe: can be nil, is used only in the case action is '5'.
// errorChannel: channel to send the error response to.
//
// Returns:
// subChannels: the Pubnub subscribed channels as a comma separated string.
// newSubChannels: the new Pubnub subscribed channels as a comma separated string.
// b: The return parameter channelsModified is set to true if new channels are added.
func (pub *Pubnub) getSubscribedChannels(channels string, callbackChannel chan []byte, isPresenceSubscribe bool, errorChannel chan []byte) (subChannels string, newSubChannels string, b bool) {
	pub.RLock()
	defer pub.RUnlock()
	channelArray := strings.Split(channels, ",")
	subscribedChannels := pub.subscribedChannels
	newSubscribedChannels := ""
	channelsModified := false
	alreadySubscribedChannels := ""

	for i := 0; i < len(channelArray); i++ {
		channelToSub := strings.TrimSpace(channelArray[i])
		if isPresenceSubscribe {
			channelToSub += presenceSuffix
		}

		if pub.notDuplicate(channelToSub) {
			if len(subscribedChannels) > 0 {
				subscribedChannels += ","
			}
			subscribedChannels += channelToSub

			if len(newSubscribedChannels) > 0 {
				newSubscribedChannels += ","
			}
			newSubscribedChannels += channelToSub
			channelsModified = true
		} else {
			if len(alreadySubscribedChannels) > 0 {
				alreadySubscribedChannels += ","
			}
			alreadySubscribedChannels += channelToSub
		}
	}

	if len(alreadySubscribedChannels) > 0 {
		pub.sendResponseToChannel(errorChannel, alreadySubscribedChannels, responseAlreadySubscribed, "", "")
	}

	return subscribedChannels, newSubscribedChannels, channelsModified
}

// checkForTimeoutAndRetries parses the error in case of subscribe error response. Its an Pubnub instance method.
// If any of the strings "Error in initializating connection", "timeout", "no such host"
// are found it assumes that a network connection is lost.
// Sends a response to the subscribe/presence channel.
//
// If max retries limit is reached it empties the Pubnub SubscribedChannels thus initiating
// the subscribe/presence subscription closure.
//
// It accepts the following parameters:
// err: error object
// errChannel: channel to send a response to.
//
// Returns:
// b: Bool variable true incase the connection is lost.
// bTimeOut: bool variable true in case Timeout condition is met.
func (pub *Pubnub) checkForTimeoutAndRetries(err error, errChannel chan []byte) (bool, bool) {
	bRet := false
	bTimeOut := false

	retryCountMu.RLock()
	retryCountLocal := retryCount
	retryCountMu.RUnlock()

	pub.RLock()
	subChannels := pub.subscribedChannels
	pub.RUnlock()

	errorInitConn := strings.Contains(err.Error(), errorInInitializing)
	if errorInitConn {
		sleepForAWhile(true)
		message := fmt.Sprintf("Error %s, Retry count: %s", err.Error(), strconv.Itoa(retryCountLocal))
		logMu.Lock()
		errorLogger.Println(message)
		logMu.Unlock()
		pub.sendResponseToChannel(nil, subChannels, responseAsIsError, err.Error(), message)
		bRet = true
	} else if strings.Contains(err.Error(), timeoutU) {
		sleepForAWhile(false)
		message := strconv.Itoa(retryCountLocal)
		logMu.Lock()
		errorLogger.Println(fmt.Sprintf("%s %s:", err.Error(), message))
		logMu.Unlock()
		pub.sendResponseToChannel(nil, subChannels, responseTimedOut, message, "")
		bRet = true
		bTimeOut = true
	} else if strings.Contains(err.Error(), noSuchHost) || strings.Contains(err.Error(), networkUnavailable) {
		sleepForAWhile(true)
		message := strconv.Itoa(retryCountLocal)
		logMu.Lock()
		errorLogger.Println(fmt.Sprintf("%s %s:", err.Error(), message))
		logMu.Unlock()
		pub.sendResponseToChannel(nil, subChannels, responseInternetConnIssues, message, "")
		bRet = true
	}

	if retryCountLocal >= maxRetries {
		pub.sendResponseToChannel(nil, subChannels, reponseAbortMaxRetry, "", "")
		pub.Lock()
		pub.subscribedChannels = ""
		pub.Unlock()

		retryCountLocal = 0
		retryCountMu.Lock()
		defer retryCountMu.Unlock()
		retryCount = 0
	}

	if retryCountLocal > 0 {
		return bRet, bTimeOut
	}
	return bRet, bTimeOut
}

// resetRetryAndSendResponse resets the retryCount and sends the reconnection
// message to all the channels
func (pub *Pubnub) resetRetryAndSendResponse() bool {
	retryCountMu.Lock()
	defer retryCountMu.Unlock()

	if retryCount > 0 {
		pub.sendResponseToChannel(nil, pub.subscribedChannels, responseReconnected, "", "")
		retryCount = 0
		return true
	}
	return false
}

// retryLoop checks for the internet connection and intiates the rety logic of
// connection fails
func (pub *Pubnub) retryLoop(errorChannel chan []byte) {
	for {
		pub.RLock()
		subChannels := pub.subscribedChannels
		pub.RUnlock()
		if len(subChannels) > 0 {
			_, responseCode, err := pub.httpRequest("", retryTrans)

			retryCountMu.RLock()
			retryCountLocal := retryCount
			retryCountMu.RUnlock()

			if (err != nil) && (responseCode != 403) && (retryCountLocal <= 0) {
				logMu.Lock()
				errorLogger.Println(fmt.Sprintf("%s, response code: %d:", err.Error(), responseCode))
				logMu.Unlock()
				pub.checkForTimeoutAndRetries(err, errorChannel)
				pub.CloseExistingConnection()
			} else if (err == nil) && (retryCountLocal > 0) {
				pub.resetRetryAndSendResponse()
			}
			sleepForAWhile(false)
		} else {
			pub.closeRetryConnection()
			break
		}
	}
}

// createPresenceHeartbeatURL creates the URL for the presence heartbeat.
func (pub *Pubnub) createPresenceHeartbeatURL() string {
	var presenceURLBuffer bytes.Buffer
	presenceURLBuffer.WriteString("/v2/presence")
	presenceURLBuffer.WriteString("/sub_key/")
	presenceURLBuffer.WriteString(pub.subscribeKey)
	presenceURLBuffer.WriteString("/channel/")
	pub.RLock()
	//get only sub channels
	var presenceChannelsBuffer bytes.Buffer
	count := 0
	for i := range pub.subscribeChannels {
		if count > 0 {
			presenceChannelsBuffer.WriteString(",")
		}
		count++
		presenceChannelsBuffer.WriteString(url.QueryEscape(i))
	}
	//presenceURLBuffer.WriteString(pub.subscribedChannels)
	presenceURLBuffer.WriteString(presenceChannelsBuffer.String())
	pub.RUnlock()
	presenceURLBuffer.WriteString("/heartbeat")
	presenceURLBuffer.WriteString("?uuid=")
	presenceURLBuffer.WriteString(pub.GetUUID())
	presenceURLBuffer.WriteString(pub.addAuthParam(true))
	presenceHeartbeatMu.RLock()
	if presenceHeartbeat > 0 {
		presenceURLBuffer.WriteString("&heartbeat=")
		presenceURLBuffer.WriteString(strconv.Itoa(int(presenceHeartbeat)))
	}
	presenceHeartbeatMu.RUnlock()
	pub.RLock()
	jsonSerialized, err := json.Marshal(pub.userState)
	pub.RUnlock()
	if err != nil {
		logMu.Lock()
		errorLogger.Println(fmt.Sprintf("createPresenceHeartbeatURL %s", err.Error()))
		logMu.Unlock()
	} else {
		userState := string(jsonSerialized)
		if (strings.TrimSpace(userState) != "") && (userState != "null") {
			presenceURLBuffer.WriteString("&state=")
			presenceURLBuffer.WriteString(url.QueryEscape(userState))
		}
	}
	presenceURLBuffer.WriteString("&")
	presenceURLBuffer.WriteString(sdkIdentificationParam)

	return presenceURLBuffer.String()
}

// runPresenceHeartbeat Starts the presence heartbeat request if both presenceHeartbeatInterval and presenceHeartbeat
// are set and a presence notifications are subsribed
// If the heartbeat is already running thenew request is ignored.
func (pub *Pubnub) runPresenceHeartbeat() {
	pub.RLock()
	isPresenceHeartbeatRunning := pub.isPresenceHeartbeatRunning
	pub.RUnlock()
	if isPresenceHeartbeatRunning {
		logMu.Lock()
		infoLogger.Println(fmt.Sprintf("Presence heartbeat already running"))
		logMu.Unlock()
		return
	}
	pub.Lock()
	pub.isPresenceHeartbeatRunning = true
	pub.Unlock()
	for {
		pub.RLock()
		l := len(pub.subscribeChannels)
		/*for i := range pub.subscribeChannels {
			fmt.Println("channel:" +i)
		}*/
		pub.RUnlock()
		presenceHeartbeatMu.RLock()
		presenceHeartbeatLoc := presenceHeartbeat
		presenceHeartbeatMu.RUnlock()
		if (l <= 0) || (pub.GetPresenceHeartbeatInterval() <= 0) || (presenceHeartbeatLoc <= 0) {
			pub.Lock()
			pub.isPresenceHeartbeatRunning = false
			pub.Unlock()
			logMu.Lock()
			infoLogger.Println(fmt.Sprintf("Breaking out of presence heartbeat loop"))
			logMu.Unlock()
			pub.closePresenceHeartbeatConnection()
			break
		}

		presenceHeartbeatURL := pub.createPresenceHeartbeatURL()
		//fmt.Println("presenceHeartbeatUrl ", presenceHeartbeatURL);

		value, responseCode, err := pub.httpRequest(presenceHeartbeatURL, presenceHeartbeatTrans)
		if (responseCode != 200) || (err != nil) {
			if err != nil {
				logMu.Lock()
				errorLogger.Println(fmt.Sprintf("presence heartbeat err %s", err.Error()))
				logMu.Unlock()
			} else {
				logMu.Lock()
				errorLogger.Println(fmt.Sprintf("presence heartbeat err responseCode %d", responseCode))
				logMu.Unlock()
			}
		} else if string(value) != "" {
			logMu.Lock()
			infoLogger.Println(fmt.Sprintf("Presence Heartbeat %s", string(value)))
			logMu.Unlock()
		}
		time.Sleep(time.Duration(pub.GetPresenceHeartbeatInterval()) * time.Second)
	}
}

// startSubscribeLoop starts a continuous loop that handles the reponse from pubnub
// subscribe/presence subscriptions.
//
// It creates subscribe request url and posts it.
// When the response is received it:
// Checks for errors and timeouts, closes the existing connections and continues the loop if true.
// else parses the response. stores the time token if it is a timeout from server.

// Checks For Timeout And Retries:
// If sent timetoken is 0 and the data is empty the connected response is sent back to the channel.
// If no error is received the response is sent to the presence or subscribe pubnub channels.
// if the channel name is suffixed with "-pnpres" it is a presence channel else subscribe channel
// and send the response the the respective channel.
//
// It accepts the following parameters:
// channels: channels to subscribe.
// errorChannel: Channel to send the error response to.
//
// TODO: Refactor
func (pub *Pubnub) startSubscribeLoop(channels string, errorChannel chan []byte) {
	pub.RLock()
	channelCount := len(pub.subscribedChannels)
	pub.RUnlock()

	channelsModified := false

	go pub.retryLoop(errorChannel)

	for {
		pub.RLock()
		modSubChannels := pub.subscribedChannels
		pub.RUnlock()
		if len(modSubChannels) > 0 {
			if len(modSubChannels) != channelCount {
				channelsModified = true
			}

			pub.RLock()
			sentTimeToken := pub.timeToken
			pub.RUnlock()
			subscribeURL, sentTimeToken := pub.createSubscribeURL(sentTimeToken)
			//fmt.Println("subscribeURL ", subscribeURL);
			value, responseCode, err := pub.httpRequest(subscribeURL, subscribeTrans)

			if (responseCode != 200) || (err != nil) {
				if err != nil {
					logMu.Lock()
					errorLogger.Println(fmt.Sprintf("%s, response code: %d:", err.Error(), responseCode))
					logMu.Unlock()
					bNonTimeout, bTimeOut := pub.checkForTimeoutAndRetries(err, errorChannel)
					if strings.Contains(err.Error(), connectionAborted) {
						pub.CloseExistingConnection()
						pub.sendResponseToChannel(nil, modSubChannels, responseAsIsError, err.Error(), strconv.Itoa(responseCode))
					} else if bNonTimeout {
						pub.CloseExistingConnection()
						if bTimeOut {
							_, returnTimeToken, _, errJSON := ParseJSON(value, pub.cipherKey)
							if errJSON == nil {
								pub.Lock()
								pub.timeToken = returnTimeToken
								pub.Unlock()
							}
						}
						if !resumeOnReconnect {
							pub.Lock()
							pub.resetTimeToken = true
							pub.Unlock()
						}
					} else {
						pub.CloseExistingConnection()
						pub.sendResponseToChannel(nil, modSubChannels, responseAsIsError, err.Error(), strconv.Itoa(responseCode))
						sleepForAWhile(true)
					}
				} else {
					logMu.Lock()
					errorLogger.Println(fmt.Sprintf("response code: %d:", responseCode))
					logMu.Unlock()
					if responseCode != 403 {
						pub.resetRetryAndSendResponse()
					}
					pub.CloseExistingConnection()
					pub.sendResponseToChannel(nil, modSubChannels, responseAsIsError, string(value), strconv.Itoa(responseCode))
					sleepForAWhile(false)
				}
				continue
			} else if string(value) != "" {
				logMu.Lock()
				infoLogger.Println(fmt.Sprintf("response value: %s", string(value)))
				logMu.Unlock()
				reconnected := pub.resetRetryAndSendResponse()
				if string(value) == "[]" {
					sleepForAWhile(false)
					continue
				}

				data, returnTimeToken, channelName, errJSON := ParseJSON(value, pub.cipherKey)
				pub.Lock()
				pub.timeToken = returnTimeToken
				pub.Unlock()
				if data == "[]" {
					if !channelsModified {

						channelsModified = false
					}
					if sentTimeToken == "0" {
						if !reconnected {
							pub.sendResponseToChannel(nil, modSubChannels, responseConnected, "", "")
						}
						pub.Lock()
						pub.newSubscribedChannels = ""
						pub.Unlock()
					}
					continue
				}
				pub.parseHTTPResponse(value, data, channelName, returnTimeToken, errJSON, errorChannel)
			}
		} else {
			break
		}
	}
}

// createSubscribeUrl creates a subscribe url to send to the origin
// If the resetTimeToken flag is true
// it sends 0 to init the subscription.
// Else sends the last timetoken.
//
// Accepts the sentTimeToken as a string parameter.
// retunrs the Url and the senttimetoken based on the logic above .
func (pub *Pubnub) createSubscribeURL(sentTimeToken string) (string, string) {
	var subscribeURLBuffer bytes.Buffer
	subscribeURLBuffer.WriteString("/subscribe")
	subscribeURLBuffer.WriteString("/")
	subscribeURLBuffer.WriteString(pub.subscribeKey)
	subscribeURLBuffer.WriteString("/")
	pub.Lock()
	defer pub.Unlock()
	subscribeURLBuffer.WriteString(queryEscapeMultiple(pub.subscribedChannels, ","))
	subscribeURLBuffer.WriteString("/0")

	if pub.resetTimeToken {
		logMu.Lock()
		infoLogger.Println("resetTimeToken=true")
		logMu.Unlock()
		subscribeURLBuffer.WriteString("/0")
		sentTimeToken = "0"
		pub.sentTimeToken = "0"
		pub.resetTimeToken = false
	} else {
		subscribeURLBuffer.WriteString("/")
		logMu.Lock()
		infoLogger.Println("resetTimeToken=false")
		logMu.Unlock()
		if strings.TrimSpace(pub.timeToken) == "" {
			pub.timeToken = "0"
			pub.sentTimeToken = "0"
		} else {
			pub.sentTimeToken = sentTimeToken
		}
		subscribeURLBuffer.WriteString(pub.timeToken)
	}

	subscribeURLBuffer.WriteString("?uuid=")
	subscribeURLBuffer.WriteString(pub.GetUUID())
	subscribeURLBuffer.WriteString(pub.addAuthParam(true))
	presenceHeartbeatMu.RLock()
	if presenceHeartbeat > 0 {
		subscribeURLBuffer.WriteString("&heartbeat=")
		subscribeURLBuffer.WriteString(strconv.Itoa(int(presenceHeartbeat)))
	}
	presenceHeartbeatMu.RUnlock()
	jsonSerialized, err := json.Marshal(pub.userState)
	if err != nil {
		logMu.Lock()
		errorLogger.Println(fmt.Sprintf("createSubscribeURL err: %s", err.Error()))
		logMu.Unlock()
	} else {
		userState := string(jsonSerialized)
		if (strings.TrimSpace(userState) != "") && (userState != "null") {
			subscribeURLBuffer.WriteString("&state=")
			subscribeURLBuffer.WriteString(url.QueryEscape(userState))
		}
	}
	subscribeURLBuffer.WriteString("&")
	subscribeURLBuffer.WriteString(sdkIdentificationParam)

	return subscribeURLBuffer.String(), sentTimeToken
}

// addAuthParamToQuery adds the authentication key to the URL
// and returns the new query
func (pub *Pubnub) addAuthParamToQuery(q url.Values) url.Values {
	if strings.TrimSpace(pub.authenticationKey) != "" {
		q.Set("auth", pub.authenticationKey)
		return q
	}
	return q
}

// addAuthParam return a string with authentication key based on the
// param queryStringInit
func (pub *Pubnub) addAuthParam(queryStringInit bool) string {
	if strings.TrimSpace(pub.authenticationKey) != "" {
		return fmt.Sprintf("%sauth=%s", checkQuerystringInit(queryStringInit), url.QueryEscape(pub.authenticationKey))
	}
	return ""
}

// checkQuerystringInit
// if queryStringInit is true then the query stirng already has the ?
// and the new query stirng val is appended with &
func checkQuerystringInit(queryStringInit bool) string {
	if queryStringInit {
		return "&"
	}
	return "?"
}

// parseHttpResponse parses the http response from the orgin for the subscribe resquest
// if errJson is not nil it sends an error response on the error channel.
// In case of subscribe response it parses the returned data and splits if multiple messages are received.
//
// Accespts the following parameters
// value: is the actual response.
// data: is the json deserialized string,
// channelName: the pubnub channel of the response
// returnTimeToken: return time token from the origin,
// errJson: error if received from server, can be nil.
// errorChannel: channel to send an error response to.
func (pub *Pubnub) parseHTTPResponse(value []byte, data string, channelName string, returnTimeToken string, errJSON error, errorChannel chan []byte) {
	if errJSON != nil {
		logMu.Lock()
		errorLogger.Println(fmt.Sprintf("%s", errJSON.Error()))
		logMu.Unlock()
		pub.sendResponseToChannel(nil, channelName, responseAsIsError, fmt.Sprintf("%s", errJSON), "")
		sleepForAWhile(false)
	} else {
		retryCountMu.Lock()
		retryCount = 0
		retryCountMu.Unlock()

		if channelName == "" {
			channelName = pub.subscribedChannels
		}
		pub.splitMessagesAndSendJSONResponse(data, returnTimeToken, channelName, errorChannel)
	}
}

// splitMessagesAndSendJSONResponse unmarshals the data and sends a response if the
// data type is a non array. Else calls the CreateAndSendJsonResponse to split the messages.
//
// parameters:
// data: the data to parse and split,
// returnTimeToken: the return timetoken in the response
// channels: pubnub channels in the response.
func (pub *Pubnub) splitMessagesAndSendJSONResponse(data string, returnTimeToken string, channels string, errorChannel chan []byte) {
	channelSlice := strings.Split(channels, ",")
	channelLen := len(channelSlice)
	isPresence := false
	if channelLen == 1 {
		isPresence = strings.Contains(channels, presenceSuffix)
	}

	if (channelLen == 1) && (isPresence) {
		pub.splitPresenceMessages([]byte(data), returnTimeToken, channelSlice[0], errorChannel)
	} else if (channelLen == 1) && (!isPresence) {
		pub.splitSubscribeMessages(data, returnTimeToken, channelSlice[0], errorChannel)
	} else {
		var returnedMessages interface{}
		errUnmarshalMessages := json.Unmarshal([]byte(data), &returnedMessages)

		if errUnmarshalMessages == nil {
			v := returnedMessages.(interface{})

			switch vv := v.(type) {
			case string:
				length := len(vv)
				if length > 0 {
					pub.sendJSONResponse(vv, returnTimeToken, channels)
				}
			case []interface{}:
				pub.createAndSendJSONResponse(vv, returnTimeToken, channels)
			}
		}
	}
}

// splitPresenceMessages splits the multiple messages
// unmarshals the data into the custom structure,
// calls the SendJsonResponse funstion to creates the json again.
//
// Parameters:
// data: data to unmarshal,
// returnTimeToken: the returned timetoken in the pubnub response,
// channel: pubnub channel,
// errorChannel: error channel to send a error response back.
func (pub *Pubnub) splitPresenceMessages(data []byte, returnTimeToken string, channel string, errorChannel chan []byte) {
	var occupants []struct {
		Action    string  `json:"action"`
		Uuid      string  `json:"uuid"`
		Timestamp float64 `json:"timestamp"`
		Occupancy int     `json:"occupancy"`
	}
	errUnmarshalMessages := json.Unmarshal(data, &occupants)
	if errUnmarshalMessages != nil {
		pub.sendResponseToChannel(nil, channel, responseAsIsError, invalidJSON, "")
	} else {
		for i := range occupants {
			intf := make([]interface{}, 1)
			intf[0] = occupants[i]
			pub.sendJSONResponse(intf, returnTimeToken, channel)
		}
	}
}

// splitSubscribeMessages splits the multiple messages
// unmarshals the data into the custom structure,
// calls the SendJsonResponse funstion to creates the json again.
//
// Parameters:
// data: data to unmarshal,
// returnTimeToken: the returned timetoken in the pubnub response,
// channel: pubnub channel,
// errorChannel: error channel to send a error response back.
func (pub *Pubnub) splitSubscribeMessages(data string, returnTimeToken string, channel string, errorChannel chan []byte) {
	var occupants []interface{}
	errUnmarshalMessages := json.Unmarshal([]byte(data), &occupants)
	if errUnmarshalMessages != nil {
		pub.sendResponseToChannel(nil, channel, responseAsIsError, invalidJSON, "")
	} else {
		for i := range occupants {
			intf := make([]interface{}, 1)
			intf[0] = occupants[i]
			pub.sendJSONResponse(intf, returnTimeToken, channel)
		}
	}
}

// createAndSendJSONResponse marshals the data for each split message and calls
// the SendJsonResponse multiple times to send response back to the channel
//
// Accepts:
// rawData: the data to parse and split,
// returnTimeToken: the return timetoken in the response
// channels: pubnub channels in the response.
func (pub *Pubnub) createAndSendJSONResponse(rawData interface{}, returnTimeToken string, channels string) {
	channelSlice := strings.Split(channels, ",")
	dataInterface := rawData.(interface{})
	switch vv := dataInterface.(type) {
	case []interface{}:
		for i, u := range vv {
			intf := make([]interface{}, 1)
			if reflect.TypeOf(u).Kind() == reflect.String {
				intf[0] = u
			} else {
				intf[0] = vv[i]
			}
			channel := ""

			if i <= len(channelSlice)-1 {
				channel = channelSlice[i]
			} else {
				channel = channelSlice[0]
			}

			pub.sendJSONResponse(intf, returnTimeToken, channel)
		}
	}
}

// sendJSONResponse creates a json response and sends back to the response channel
//
// Accepts:
// message: response to send back,
// returnTimeToken: the timetoken for the response,
// channelName: the pubnub channel for the response.
func (pub *Pubnub) sendJSONResponse(message interface{}, returnTimeToken string, channelName string) {

	if channelName != "" {
		response := []interface{}{message, fmt.Sprintf("%s", pub.timeToken), channelName}
		jsonData, err := json.Marshal(response)
		if err != nil {
			logMu.Lock()
			errorLogger.Println(fmt.Sprintf("%s", err.Error()))
			logMu.Unlock()
			pub.sendResponseToChannel(nil, channelName, responseAsIsError, invalidJSON, err.Error())
		}
		pub.sendResponseToChannel(nil, channelName, responseAsIs, string(jsonData), "")
	}
}

// getSubscribedChannelName is the struct Pubnub's instance method.
// In case of single subscribe request the channelname will be empty.
// This methos iterates through the pubnub SubscribedChannels to find the name of the channel.
func (pub *Pubnub) getSubscribedChannelName() string {
	channelArray := strings.Split(pub.subscribedChannels, ",")
	for i := 0; i < len(channelArray); i++ {
		if strings.Contains(channelArray[i], presenceSuffix) {
			continue
		} else {
			return channelArray[i]
		}
	}
	return ""
}

// CloseExistingConnection closes the open subscribe/presence connection.
func (pub *Pubnub) CloseExistingConnection() {
	subscribeTransportMu.Lock()
	defer subscribeTransportMu.Unlock()
	if subscribeConn != nil {
		logMu.Lock()
		infoLogger.Println(fmt.Sprintf("closing subscribe conn"))
		logMu.Unlock()
		subscribeConn.Close()
	}
}

// checkCallbackNil checks if the callback channel is nil
// if nil then the code wil panic as callbacks are mandatory
func checkCallbackNil(channelToCheck chan []byte, isErrChannel bool, funcName string) {
	if channelToCheck == nil {
		message2 := ""
		if isErrChannel {
			message2 = "Error "
		}
		message := fmt.Sprintf("%sCallback is nil for %s", message2, funcName)
		logMu.Lock()
		errorLogger.Println(message)
		logMu.Unlock()
		panic(message)
	}
}

// Subscribe is the struct Pubnub's instance method which checks for the InvalidChannels
// and returns if true.
// Initaiates the presence and subscribe response channels.
// It creates a map for callback and error response channels for
// each pubnub channel using the pubnub channel name as the key.
// If muliple channels are passed then the same callback or error channel is used.
//
// If there is no existing subscribe/presence loop running then it starts a
// new loop with the new pubnub channels.
// Else closes the existing connections and starts a new loop
//
// It accepts the following parameters:
// channels: comma separated pubnub channel list.
// timetoken: if timetoken is present the subscribe request is sent using this timetoken
// callbackChannel: Channel on which to send the response back.
// isPresenceSubscribe: tells the method that presence subscription is requested.
// errorChannel: channel to send an error response to.
//
// Both callbackChannel and errorChannel are mandatory. If either is nil the code will panic
func (pub *Pubnub) Subscribe(channels string, timetoken string, callbackChannel chan []byte, isPresenceSubscribe bool, errorChannel chan []byte) {
	checkCallbackNil(callbackChannel, false, "Subscribe")
	checkCallbackNil(errorChannel, true, "Subscribe")
	if invalidChannel(channels, callbackChannel) {
		return
	}
	subscribedChannels, newSubscribedChannels, channelsModified := pub.getSubscribedChannels(channels, callbackChannel, isPresenceSubscribe, errorChannel)
	pub.Lock()
	var channelArr = strings.Split(channels, ",")

	for i, u := range channelArr {
		if isPresenceSubscribe {
			pub.presenceChannels[u] = callbackChannel
			pub.presenceErrorChannels[u] = errorChannel
		} else {
			pub.subscribeChannels[u] = callbackChannel
			pub.subscribeErrorChannels[u] = errorChannel
		}
		i++
	}
	pub.newSubscribedChannels = newSubscribedChannels
	existingSubscribedChannels := pub.subscribedChannels
	isPresenceHeartbeatRunning := pub.isPresenceHeartbeatRunning
	pub.Unlock()
	if (!isPresenceSubscribe) && ((existingSubscribedChannels == "") || (!isPresenceHeartbeatRunning)) {
		go pub.runPresenceHeartbeat()
	}
	if existingSubscribedChannels == "" {
		pub.Lock()
		if strings.TrimSpace(timetoken) != "" {
			pub.timeToken = timetoken
			pub.resetTimeToken = false
		} else {
			pub.resetTimeToken = true
		}

		pub.subscribedChannels = subscribedChannels
		pub.Unlock()
		go pub.startSubscribeLoop(channels, errorChannel)
	} else if channelsModified {
		pub.CloseExistingConnection()

		pub.Lock()
		if strings.TrimSpace(timetoken) != "" {
			pub.timeToken = timetoken
			pub.resetTimeToken = false
		} else {
			pub.resetTimeToken = true
		}
		pub.subscribedChannels = subscribedChannels
		//fmt.Println("pub.subscribedChannels, ", pub.subscribedChannels)
		pub.Unlock()
	}
}

// sleepForAWhile pauses the subscribe/presence loop for the retryInterval.
func sleepForAWhile(retry bool) {
	if retry {
		retryCountMu.Lock()
		retryCount++
		retryCountMu.Unlock()
	}
	time.Sleep(time.Duration(retryInterval) * time.Second)
}

// notDuplicate is the struct Pubnub's instance method which checks for the channel name
// to check in the existing pubnub SubscribedChannels.
//
// It accepts the following parameters:
// channel: the Pubnub channel name to check in the existing pubnub SubscribedChannels.
//
// returns:
// true if the channel is found.
// false if not found.
func (pub *Pubnub) notDuplicate(channel string) (b bool) {
	pub.RLock()
	subChannels := pub.subscribedChannels
	pub.RUnlock()
	var channels = strings.Split(subChannels, ",")
	for i, u := range channels {
		if channel == u {
			return false
		}
		i++
	}
	return true
}

// removeFromSubscribeList is the struct Pubnub's instance method which checks for the
// channel name to check in the existing pubnub SubscribedChannels and removes it if found
//
// It accepts the following parameters:
// c: Channel on which to send the response back.
// channel: the pubnub channel name to check in the existing pubnub SubscribedChannels.
//
// returns:
// true if the channel is found and removed.
// false if not found.
func (pub *Pubnub) removeFromSubscribeList(c chan []byte, channel string) (b bool) {
	pub.RLock()
	subChannels := pub.subscribedChannels
	pub.RUnlock()
	var channels = strings.Split(subChannels, ",")
	newChannels := ""
	found := false
	for _, u := range channels {
		if channel == u {
			found = true
			pub.sendResponseToChannel(c, u, responseUnsubscribed, "", "")
		} else {
			if len(newChannels) > 0 {
				newChannels += ","
			}
			newChannels += u
		}
	}
	if found {
		pub.Lock()
		pub.subscribedChannels = newChannels
		pub.Unlock()
	}
	return found
}

// Unsubscribe is the struct Pubnub's instance method which unsubscribes a pubnub subscribe
// channel(s) from the subscribe loop.
//
// If all the pubnub channels are not removed the method StartSubscribeLoop will take care
// of it by starting a new loop.
// Closes the channel c when the processing is complete
//
// It accepts the following parameters:
// channels: the pubnub channel(s) in a comma separated string.
// callbackChannel: Channel on which to send the response back.
// errorChannel: channel to send an error response to.
//
// Both callbackChannel and errorChannel are mandatory. If either is nil the code will panic
func (pub *Pubnub) Unsubscribe(channels string, callbackChannel chan []byte, errorChannel chan []byte) {
	checkCallbackNil(callbackChannel, false, "Unsubscribe")
	checkCallbackNil(errorChannel, true, "Unsubscribe")

	channelArray := strings.Split(channels, ",")
	unsubscribeChannels := ""
	channelRemoved := false

	for i := 0; i < len(channelArray); i++ {
		if i > 0 {
			unsubscribeChannels += ","
		}
		channelToUnsub := strings.TrimSpace(channelArray[i])
		removed := pub.removeFromSubscribeList(callbackChannel, channelToUnsub)
		if !removed {
			pub.sendResponseToChannel(errorChannel, channelToUnsub, responseNotSubscribed, "", "")
		} else {
			unsubscribeChannels += channelToUnsub
			channelRemoved = true
		}
	}

	if channelRemoved {
		if strings.TrimSpace(unsubscribeChannels) != "" {
			value, _, err := pub.sendLeaveRequest(unsubscribeChannels)
			if err != nil {
				logMu.Lock()
				errorLogger.Println(fmt.Sprintf("%s", err.Error()))
				logMu.Unlock()
				pub.sendResponseToChannel(errorChannel, unsubscribeChannels, responseAsIsError, err.Error(), "")
			} else {
				pub.sendResponseToChannel(callbackChannel, unsubscribeChannels, responseAsIs, string(value), "")
			}
		}
		pub.Lock()
		for i := 0; i < len(channelArray); i++ {
			delete(pub.subscribeChannels, channelArray[i])
			delete(pub.subscribeErrorChannels, channelArray[i])
		}
		pub.Unlock()
		pub.CloseExistingConnection()
	}
}

// PresenceUnsubscribe is the struct Pubnub's instance method which unsubscribes a pubnub
// presence channel(s) from the subscribe loop.
//
// If all the pubnub channels are not removed the method StartSubscribeLoop will take care
// of it by starting a new loop.
// When the pubnub channel(s) are removed it creates and posts a leave request.
//
// It accepts the following parameters:
// channels: the pubnub channel(s) in a comma separated string.
// callbackChannel: Channel on which to send the response back.
// errorChannel: channel to send an error response to.
//
// Both callbackChannel and errorChannel are mandatory. If either is nil the code will panic
func (pub *Pubnub) PresenceUnsubscribe(channels string, callbackChannel chan []byte, errorChannel chan []byte) {
	checkCallbackNil(callbackChannel, false, "PresenceUnsubscribe")
	checkCallbackNil(errorChannel, true, "PresenceUnsubscribe")

	channelArray := strings.Split(channels, ",")
	presenceChannels := ""
	channelRemoved := false

	for i := 0; i < len(channelArray); i++ {
		if i > 0 {
			presenceChannels += ","
		}
		channelToUnsub := strings.TrimSpace(channelArray[i]) + presenceSuffix
		presenceChannels += channelToUnsub
		removed := pub.removeFromSubscribeList(callbackChannel, channelToUnsub)
		if !removed {
			pub.sendResponseToChannel(errorChannel, channelToUnsub, responseNotSubscribed, "", "")
		} else {
			channelRemoved = true
		}
	}

	if channelRemoved {
		if strings.TrimSpace(channels) != "" {
			value, _, err := pub.sendLeaveRequest(presenceChannels)
			if err != nil {
				logMu.Lock()
				errorLogger.Println(fmt.Sprintf("%s", err.Error()))
				logMu.Unlock()
				pub.sendResponseToChannel(errorChannel, channels, responseAsIsError, err.Error(), "")
			} else {
				pub.sendResponseToChannel(callbackChannel, channels, responseAsIs, string(value), "")
			}
		}
		pub.Lock()
		for i := 0; i < len(channelArray); i++ {
			delete(pub.presenceChannels, channelArray[i])
			delete(pub.presenceErrorChannels, channelArray[i])
		}
		pub.Unlock()
		pub.CloseExistingConnection()
	}
}

// sendLeaveRequest: Sends a leave request to the origin
//
// It accepts the following parameters:
// channels: Channels to leave
//
// returns:
// the HttpRequest response contents as byte array.
// response error code,
// error if any.
func (pub *Pubnub) sendLeaveRequest(channels string) ([]byte, int, error) {
	var subscribeURLBuffer bytes.Buffer
	subscribeURLBuffer.WriteString("/v2/presence")
	subscribeURLBuffer.WriteString("/sub-key/")
	subscribeURLBuffer.WriteString(pub.subscribeKey)
	subscribeURLBuffer.WriteString("/channel/")
	subscribeURLBuffer.WriteString(queryEscapeMultiple(channels, ","))
	subscribeURLBuffer.WriteString("/leave?uuid=")
	subscribeURLBuffer.WriteString(pub.GetUUID())
	subscribeURLBuffer.WriteString(pub.addAuthParam(true))
	presenceHeartbeatMu.RLock()
	if presenceHeartbeat > 0 {
		subscribeURLBuffer.WriteString("&heartbeat=")
		subscribeURLBuffer.WriteString(strconv.Itoa(int(presenceHeartbeat)))
	}
	presenceHeartbeatMu.RUnlock()
	subscribeURLBuffer.WriteString("&")
	subscribeURLBuffer.WriteString(sdkIdentificationParam)

	return pub.httpRequest(subscribeURLBuffer.String(), nonSubscribeTrans)
}

// History is the struct Pubnub's instance method which creates and post the History request
// for a single pubnub channel.
//
// It parses the response to get the data and return it to the channel.
//
// It accepts the following parameters:
// channel: a single value of the pubnub channel.
// limit: number of history messages to return.
// start: start time from where to begin the history messages.
// end: end time till where to get the history messages.
// reverse: to fetch the messages in ascending order
// callbackChannel on which to send the response.
// errorChannel on which the error response is sent.
//
// Both callbackChannel and errorChannel are mandatory. If either is nil the code will panic
func (pub *Pubnub) History(channel string, limit int, start int64, end int64, reverse bool, callbackChannel chan []byte, errorChannel chan []byte) {
	checkCallbackNil(callbackChannel, false, "History")
	checkCallbackNil(errorChannel, true, "History")

	pub.executeHistory(channel, limit, start, end, reverse, callbackChannel, errorChannel, 0)
}

// executeHistory is the struct Pubnub's instance method which creates and post the History request
// for a single pubnub channel.
//
// It parses the response to get the data and return it to the channel.
// In case we get an invalid json response the routine retries till the _maxRetries to get a valid
// response.
//
// It accepts the following parameters:
// channel: a single value of the pubnub channel.
// limit: number of history messages to return.
// start: start time from where to begin the history messages.
// end: end time till where to get the history messages.
// reverse: to fetch the messages in ascending order
// callbackChannel on which to send the response.
// errorChannel on which the error response is sent.
// retryCount to track the retry logic.
func (pub *Pubnub) executeHistory(channel string, limit int, start int64, end int64, reverse bool, callbackChannel chan []byte, errorChannel chan []byte, retryCount int) {
	count := retryCount
	if invalidChannel(channel, callbackChannel) {
		return
	}

	if limit < 0 {
		limit = 100
	}

	var parameters bytes.Buffer
	parameters.WriteString("&reverse=")
	parameters.WriteString(fmt.Sprintf("%t", reverse))

	if start > 0 {
		parameters.WriteString("&start=")
		parameters.WriteString(fmt.Sprintf("%d", start))
	}
	if end > 0 {
		parameters.WriteString("&end=")
		parameters.WriteString(fmt.Sprintf("%d", end))
	}
	parameters.WriteString(pub.addAuthParam(true))

	var historyURLBuffer bytes.Buffer
	historyURLBuffer.WriteString("/v2/history")
	historyURLBuffer.WriteString("/sub-key/")
	historyURLBuffer.WriteString(pub.subscribeKey)
	historyURLBuffer.WriteString("/channel/")
	historyURLBuffer.WriteString(url.QueryEscape(channel))
	historyURLBuffer.WriteString("?count=")
	historyURLBuffer.WriteString(fmt.Sprintf("%d", limit))
	historyURLBuffer.WriteString(parameters.String())
	historyURLBuffer.WriteString("&")
	historyURLBuffer.WriteString(sdkIdentificationParam)
	historyURLBuffer.WriteString("&uuid=")
	historyURLBuffer.WriteString(pub.GetUUID())

	value, _, err := pub.httpRequest(historyURLBuffer.String(), nonSubscribeTrans)

	if err != nil {
		logMu.Lock()
		errorLogger.Println(fmt.Sprintf("%s", err.Error()))
		logMu.Unlock()
		pub.sendResponseToChannel(errorChannel, channel, responseAsIsError, err.Error(), "")
	} else {
		data, returnOne, returnTwo, errJSON := ParseJSON(value, pub.cipherKey)
		if errJSON != nil && strings.Contains(errJSON.Error(), invalidJSON) {
			logMu.Lock()
			errorLogger.Println(fmt.Sprintf("%s", errJSON.Error()))
			logMu.Unlock()
			pub.sendResponseToChannel(errorChannel, channel, responseAsIsError, errJSON.Error(), "")
			if count < maxRetries {
				count++
				pub.executeHistory(channel, limit, start, end, reverse, callbackChannel, errorChannel, count)
			}
		} else {
			var buffer bytes.Buffer
			buffer.WriteString("[")
			buffer.WriteString(data)
			buffer.WriteString(",\"" + returnOne + "\",\"" + returnTwo + "\"]")

			callbackChannel <- []byte(fmt.Sprintf("%s", buffer.Bytes()))
		}
	}
}

// WhereNow is the struct Pubnub's instance method which creates and posts the wherenow
// request to get the connected users details.
//
// It accepts the following parameters:
// uuid: devcie uuid to pass to the wherenow query
// callbackChannel on which to send the response.
// errorChannel on which the error response is sent.
//
// Both callbackChannel and errorChannel are mandatory. If either is nil the code will panic
func (pub *Pubnub) WhereNow(uuid string, callbackChannel chan []byte, errorChannel chan []byte) {
	checkCallbackNil(callbackChannel, false, "WhereNow")
	checkCallbackNil(errorChannel, true, "WhereNow")

	pub.executeWhereNow(uuid, callbackChannel, errorChannel, 0)
}

// executeWhereNow  is the struct Pubnub's instance method that creates a wherenow request and sends back the
// response to the channel.
//
// In case we get an invalid json response the routine retries till the _maxRetries to get a valid
// response.
//
// uuid
// callbackChannel on which to send the response.
// errorChannel on which the error response is sent.
// retryCount to track the retry logic.
func (pub *Pubnub) executeWhereNow(uuid string, callbackChannel chan []byte, errorChannel chan []byte, retryCount int) {
	count := retryCount

	var whereNowURL bytes.Buffer
	whereNowURL.WriteString("/v2/presence")
	whereNowURL.WriteString("/sub-key/")
	whereNowURL.WriteString(pub.subscribeKey)
	whereNowURL.WriteString("/uuid/")
	if strings.TrimSpace(uuid) == "" {
		uuid = pub.GetUUID()
	} else {
		uuid = url.QueryEscape(uuid)
	}
	whereNowURL.WriteString(uuid)
	whereNowURL.WriteString("?")
	whereNowURL.WriteString(sdkIdentificationParam)
	whereNowURL.WriteString("&uuid=")
	whereNowURL.WriteString(pub.GetUUID())

	whereNowURL.WriteString(pub.addAuthParam(true))

	value, _, err := pub.httpRequest(whereNowURL.String(), nonSubscribeTrans)

	if err != nil {
		logMu.Lock()
		errorLogger.Println(fmt.Sprintf("%s", err.Error()))
		logMu.Unlock()
		pub.sendResponseToChannel(errorChannel, "", responseAsIsError, err.Error(), "")
	} else {
		//Parsejson
		_, _, _, errJSON := ParseJSON(value, pub.cipherKey)
		if errJSON != nil && strings.Contains(errJSON.Error(), invalidJSON) {
			logMu.Lock()
			errorLogger.Println(fmt.Sprintf("%s", errJSON.Error()))
			logMu.Unlock()
			pub.sendResponseToChannel(errorChannel, "", responseAsIsError, errJSON.Error(), "")
			if count < maxRetries {
				count++
				pub.executeWhereNow(uuid, callbackChannel, errorChannel, count)
			}
		} else {
			callbackChannel <- []byte(fmt.Sprintf("%s", value))
		}
	}
}

// GlobalHereNow is the struct Pubnub's instance method which creates and posts the globalherenow
// request to get the connected users details.
//
// It accepts the following parameters:
// showUuid: if true uuids of devices will be fetched in the respose
// includeUserState: if true the user states of devices will be fetched in the respose
// callbackChannel on which to send the response.
// errorChannel on which the error response is sent.
//
// Both callbackChannel and errorChannel are mandatory. If either is nil the code will panic
func (pub *Pubnub) GlobalHereNow(showUuid bool, includeUserState bool, callbackChannel chan []byte, errorChannel chan []byte) {
	checkCallbackNil(callbackChannel, false, "GlobalHereNow")
	checkCallbackNil(errorChannel, true, "GlobalHereNow")

	pub.executeGlobalHereNow(showUuid, includeUserState, callbackChannel, errorChannel, 0)
}

// executeGlobalHereNow  is the struct Pubnub's instance method that creates a globalhernow request and sends back the
// response to the channel.
//
// parameters:
// showUuid: if true uuids of devices will be fetched in the respose
// includeUserState: if true the user states of devices will be fetched in the respose
// callbackChannel on which to send the response.
// errorChannel on which the error response is sent.
// retryCount to track the retry logic.
func (pub *Pubnub) executeGlobalHereNow(showUuid bool, includeUserState bool, callbackChannel chan []byte, errorChannel chan []byte, retryCount int) {
	count := retryCount

	var hereNowURL bytes.Buffer
	hereNowURL.WriteString("/v2/presence")
	hereNowURL.WriteString("/sub-key/")
	hereNowURL.WriteString(pub.subscribeKey)

	showUuidParam := "1"
	if showUuid {
		showUuidParam = "0"
	}
	includeUserStateParam := "0"
	if includeUserState {
		includeUserStateParam = "1"
	}

	var params bytes.Buffer
	params.WriteString(fmt.Sprintf("?disable_uuids=%s&state=%s", showUuidParam, includeUserStateParam))

	hereNowURL.WriteString(params.String())

	hereNowURL.WriteString(pub.addAuthParam(true))
	hereNowURL.WriteString("&")
	hereNowURL.WriteString(sdkIdentificationParam)
	hereNowURL.WriteString("&uuid=")
	hereNowURL.WriteString(pub.GetUUID())

	value, _, err := pub.httpRequest(hereNowURL.String(), nonSubscribeTrans)

	if err != nil {
		logMu.Lock()
		errorLogger.Println(fmt.Sprintf("%s", err.Error()))
		logMu.Unlock()
		pub.sendResponseToChannel(errorChannel, "", responseAsIsError, err.Error(), "")
	} else {
		//Parsejson
		_, _, _, errJSON := ParseJSON(value, pub.cipherKey)
		if errJSON != nil && strings.Contains(errJSON.Error(), invalidJSON) {
			logMu.Lock()
			errorLogger.Println(fmt.Sprintf("%s", errJSON.Error()))
			logMu.Unlock()
			pub.sendResponseToChannel(errorChannel, "", responseAsIsError, errJSON.Error(), "")
			if count < maxRetries {
				count++
				pub.executeGlobalHereNow(showUuid, includeUserState, callbackChannel, errorChannel, count)
			}
		} else {
			callbackChannel <- []byte(fmt.Sprintf("%s", value))
		}
	}
}

// HereNow is the struct Pubnub's instance method which creates and posts the herenow
// request to get the connected users details.
//
// It accepts the following parameters:
// channel: a single value of the pubnub channel.
// callbackChannel on which to send the response.
// errorChannel on which the error response is sent.
//
// Both callbackChannel and errorChannel are mandatory. If either is nil the code will panic
func (pub *Pubnub) HereNow(channel string, showUuid bool, includeUserState bool, callbackChannel chan []byte, errorChannel chan []byte) {
	checkCallbackNil(callbackChannel, false, "HereNow")
	checkCallbackNil(errorChannel, true, "HereNow")

	pub.executeHereNow(channel, showUuid, includeUserState, callbackChannel, errorChannel, 0)
}

// executeHereNow  is the struct Pubnub's instance method that creates a time request and sends back the
// response to the channel.
//
// In case we get an invalid json response the routine retries till the _maxRetries to get a valid
// response.
//
// callbackChannel on which to send the response.
// errorChannel on which the error response is sent.
// retryCount to track the retry logic.
func (pub *Pubnub) executeHereNow(channel string, showUuid bool, includeUserState bool, callbackChannel chan []byte, errorChannel chan []byte, retryCount int) {
	count := retryCount

	if invalidChannel(channel, callbackChannel) {
		return
	}

	var hereNowURL bytes.Buffer
	hereNowURL.WriteString("/v2/presence")
	hereNowURL.WriteString("/sub-key/")
	hereNowURL.WriteString(pub.subscribeKey)
	hereNowURL.WriteString("/channel/")
	hereNowURL.WriteString(url.QueryEscape(channel))

	showUuidParam := "1"
	if showUuid {
		showUuidParam = "0"
	}
	includeUserStateParam := "0"
	if includeUserState {
		includeUserStateParam = "1"
	}

	var params bytes.Buffer
	params.WriteString(fmt.Sprintf("?disable_uuids=%s&state=%s", showUuidParam, includeUserStateParam))

	hereNowURL.WriteString(params.String())

	hereNowURL.WriteString(pub.addAuthParam(true))
	hereNowURL.WriteString("&")
	hereNowURL.WriteString(sdkIdentificationParam)
	hereNowURL.WriteString("&uuid=")
	hereNowURL.WriteString(pub.GetUUID())

	value, _, err := pub.httpRequest(hereNowURL.String(), nonSubscribeTrans)

	if err != nil {
		logMu.Lock()
		errorLogger.Println(fmt.Sprintf("%s", err.Error()))
		logMu.Unlock()
		pub.sendResponseToChannel(errorChannel, channel, responseAsIsError, err.Error(), "")
	} else {
		//Parsejson
		_, _, _, errJSON := ParseJSON(value, pub.cipherKey)
		if errJSON != nil && strings.Contains(errJSON.Error(), invalidJSON) {
			logMu.Lock()
			errorLogger.Println(fmt.Sprintf("%s", errJSON.Error()))
			logMu.Unlock()
			pub.sendResponseToChannel(errorChannel, channel, responseAsIsError, errJSON.Error(), "")
			if count < maxRetries {
				count++
				pub.executeHereNow(channel, showUuid, includeUserState, callbackChannel, errorChannel, count)
			}
		} else {
			callbackChannel <- []byte(fmt.Sprintf("%s", value))
		}
	}
}

// GetUserState is the struct Pubnub's instance method which creates and posts the GetUserState
// request to get the connected users details.
//
// It accepts the following parameters:
// channel: a single value of the pubnub channel.
// callbackChannel on which to send the response.
// errorChannel on which the error response is sent.
//
// Both callbackChannel and errorChannel are mandatory. If either is nil the code will panic
func (pub *Pubnub) GetUserState(channel string, callbackChannel chan []byte, errorChannel chan []byte) {
	checkCallbackNil(callbackChannel, false, "GetUserState")
	checkCallbackNil(errorChannel, true, "GetUserState")
	pub.executeGetUserState(channel, callbackChannel, errorChannel, 0)
}

// executeGetUserState  is the struct Pubnub's instance method that creates a executeGetUserState request and sends back the
// response to the channel.
//
// In case we get an invalid json response the routine retries till the _maxRetries to get a valid
// response.
//
// channel
// callbackChannel on which to send the response.
// errorChannel on which the error response is sent.
// retryCount to track the retry logic.
func (pub *Pubnub) executeGetUserState(channel string, callbackChannel chan []byte, errorChannel chan []byte, retryCount int) {
	count := retryCount

	var userStateURL bytes.Buffer
	userStateURL.WriteString("/v2/presence")
	userStateURL.WriteString("/sub-key/")
	userStateURL.WriteString(pub.subscribeKey)
	userStateURL.WriteString("/channel/")
	userStateURL.WriteString(url.QueryEscape(channel))
	userStateURL.WriteString("/uuid/")
	userStateURL.WriteString(pub.GetUUID())
	userStateURL.WriteString("?")
	userStateURL.WriteString(sdkIdentificationParam)
	userStateURL.WriteString("&uuid=")
	userStateURL.WriteString(pub.GetUUID())

	userStateURL.WriteString(pub.addAuthParam(true))

	value, _, err := pub.httpRequest(userStateURL.String(), nonSubscribeTrans)

	if err != nil {
		logMu.Lock()
		errorLogger.Println(fmt.Sprintf("%s", err.Error()))
		logMu.Unlock()
		pub.sendResponseToChannel(errorChannel, "", responseAsIsError, err.Error(), "")
	} else {
		//Parsejson
		_, _, _, errJSON := ParseJSON(value, pub.cipherKey)
		if errJSON != nil && strings.Contains(errJSON.Error(), invalidJSON) {
			logMu.Lock()
			errorLogger.Println(fmt.Sprintf("%s", errJSON.Error()))
			logMu.Unlock()
			pub.sendResponseToChannel(errorChannel, "", responseAsIsError, errJSON.Error(), "")
			if count < maxRetries {
				count++
				pub.executeGetUserState(channel, callbackChannel, errorChannel, count)
			}
		} else {
			callbackChannel <- []byte(fmt.Sprintf("%s", value))
		}
	}
}

// SetUserStateKeyVal is the struct Pubnub's instance method which creates and posts the userstate
// request using a key/val map
//
// It accepts the following parameters:
// channel: a single value of the pubnub channel.
// key: user states key
// value: user stated value
// callbackChannel on which to send the response.
// errorChannel on which the error response is sent.
//
// Both callbackChannel and errorChannel are mandatory. If either is nil the code will panic
func (pub *Pubnub) SetUserStateKeyVal(channel string, key string, val string, callbackChannel chan []byte, errorChannel chan []byte) {
	checkCallbackNil(callbackChannel, false, "SetUserState")
	checkCallbackNil(errorChannel, true, "SetUserState")

	pub.Lock()
	defer pub.Unlock()
	if pub.userState == nil {
		pub.userState = make(map[string]map[string]interface{})
	}
	if strings.TrimSpace(val) == "" {
		channelUserState := pub.userState[channel]
		if channelUserState != nil {
			delete(channelUserState, key)
			pub.userState[channel] = channelUserState
		}
	} else {
		channelUserState := pub.userState[channel]
		if channelUserState == nil {
			pub.userState[channel] = make(map[string]interface{})
			channelUserState = pub.userState[channel]
		}
		channelUserState[key] = val
		pub.userState[channel] = channelUserState
	}

	/*for k, v := range pub.userState {
		fmt.Println("userstate1", k, v)
		for k2, v2 := range v {
			fmt.Println("userstate1", k2, v2)
		}
	}*/

	jsonSerialized, err := json.Marshal(pub.userState[channel])
	if len(pub.userState[channel]) <= 0 {
		delete(pub.userState, channel)
	}

	if err != nil {
		logMu.Lock()
		errorLogger.Println(fmt.Sprintf("SetUserStateKeyVal err: %s", err.Error()))
		logMu.Unlock()
		pub.sendResponseToChannel(errorChannel, channel, responseAsIsError, invalidUserStateMap, err.Error())
		return
	}
	stateJSON := string(jsonSerialized)
	if stateJSON == "null" {
		stateJSON = "{}"
	}

	pub.executeSetUserState(channel, stateJSON, callbackChannel, errorChannel, 0)
}

// SetUserStateJSON is the struct Pubnub's instance method which creates and posts the User state
// request using JSON as input
//
// It accepts the following parameters:
// channel: a single value of the pubnub channel.
// jsonString: the user state in JSON format. If invalid an error will be thrown
// callbackChannel on which to send the response.
// errorChannel on which the error response is sent.
//
// Both callbackChannel and errorChannel are mandatory. If either is nil the code will panic
func (pub *Pubnub) SetUserStateJSON(channel string, jsonString string, callbackChannel chan []byte, errorChannel chan []byte) {
	checkCallbackNil(callbackChannel, false, "SetUserState")
	checkCallbackNil(errorChannel, true, "SetUserState")
	var s interface{}
	err := json.Unmarshal([]byte(jsonString), &s)
	if err != nil {
		pub.sendResponseToChannel(errorChannel, channel, responseAsIsError, invalidUserStateMap, err.Error())
		return
	}
	pub.Lock()
	defer pub.Unlock()

	if pub.userState == nil {
		pub.userState = make(map[string]map[string]interface{})
	}
	pub.userState[channel] = s.(map[string]interface{})
	pub.executeSetUserState(channel, jsonString, callbackChannel, errorChannel, 0)
}

// executeSetUserState  is the struct Pubnub's instance method that creates a user state request and sends back the
// response to the channel.
//
// In case we get an invalid json response the routine retries till the _maxRetries to get a valid
// response.
//
// channel: a single value of the pubnub channel.
// jsonString: the user state in JSON format.
// callbackChannel on which to send the response.
// errorChannel on which the error response is sent.
// retryCount to track the retry logic.
func (pub *Pubnub) executeSetUserState(channel string, jsonState string, callbackChannel chan []byte, errorChannel chan []byte, retryCount int) {
	count := retryCount

	var userStateURL bytes.Buffer
	userStateURL.WriteString("/v2/presence")
	userStateURL.WriteString("/sub-key/")
	userStateURL.WriteString(pub.subscribeKey)
	userStateURL.WriteString("/channel/")
	userStateURL.WriteString(url.QueryEscape(channel))
	userStateURL.WriteString("/uuid/")
	userStateURL.WriteString(pub.GetUUID())
	userStateURL.WriteString("/data")
	userStateURL.WriteString("?state=")
	userStateURL.WriteString(url.QueryEscape(jsonState))

	userStateURL.WriteString(pub.addAuthParam(true))

	userStateURL.WriteString("&")
	userStateURL.WriteString(sdkIdentificationParam)
	userStateURL.WriteString("&uuid=")
	userStateURL.WriteString(pub.GetUUID())

	value, _, err := pub.httpRequest(userStateURL.String(), nonSubscribeTrans)

	if err != nil {
		logMu.Lock()
		errorLogger.Println(fmt.Sprintf("%s", err.Error()))
		logMu.Unlock()
		pub.sendResponseToChannel(errorChannel, "", responseAsIsError, err.Error(), "")
	} else {
		//Parsejson
		_, _, _, errJSON := ParseJSON(value, pub.cipherKey)
		if errJSON != nil && strings.Contains(errJSON.Error(), invalidJSON) {
			logMu.Lock()
			errorLogger.Println(fmt.Sprintf("%s", errJSON.Error()))
			logMu.Unlock()
			pub.sendResponseToChannel(errorChannel, "", responseAsIsError, errJSON.Error(), "")
			if count < maxRetries {
				count++
				pub.executeSetUserState(channel, jsonState, callbackChannel, errorChannel, count)
			}
		} else {
			callbackChannel <- []byte(fmt.Sprintf("%s", value))
			pub.CloseExistingConnection()
		}
	}
}

// getData parses the interface data and decrypts the messages if the cipher key is provided.
//
// It accepts the following parameters:
// interface: the interface to parse.
// cipherKey: the key to decrypt the messages (can be empty).
//
// returns the decrypted and/or unescaped data json data as string.
func getData(rawData interface{}, cipherKey string) string {
	dataInterface := rawData.(interface{})
	switch vv := dataInterface.(type) {
	case string:
		jsonData, err := json.Marshal(fmt.Sprintf("%s", vv[0]))
		if err == nil {
			return string(jsonData)
		}
		logMu.Lock()
		errorLogger.Println(fmt.Sprintf("%s", err.Error()))
		logMu.Unlock()
		return fmt.Sprintf("%s", vv[0])
	case []interface{}:
		retval := parseInterface(vv, cipherKey)
		if retval != "" {
			return retval
		}
	}
	return fmt.Sprintf("%s", rawData)
}

// parseInterface umarshals the response data, marshals the data again in a
// different format and returns the json string. It also unescapes the data.
//
// parameters:
// vv: interface array to parse and extract data from.
// cipher key: used to decrypt data. cipher key can be empty.
//
// returns the json marshalled string.
func parseInterface(vv []interface{}, cipherKey string) string {
	for i, u := range vv {
		if reflect.TypeOf(u).Kind() == reflect.String {
			var intf interface{}

			if cipherKey != "" {
				intf = parseCipherInterface(u, cipherKey)
				var returnedMessages interface{}

				errUnmarshalMessages := json.Unmarshal([]byte(intf.(string)), &returnedMessages)

				if errUnmarshalMessages == nil {
					vv[i] = returnedMessages
				} else {
					vv[i] = intf
				}
			} else {
				intf = u
				unescapeVal, unescapeErr := url.QueryUnescape(intf.(string))
				if unescapeErr != nil {
					logMu.Lock()
					errorLogger.Println(fmt.Sprintf("unescape :%s", unescapeErr.Error()))
					logMu.Unlock()

					vv[i] = intf
				} else {
					vv[i] = unescapeVal
				}
				//vv[i] = intf
			}
		}
	}
	length := len(vv)
	if length > 0 {
		jsonData, err := json.Marshal(vv)
		if err == nil {
			return string(jsonData)
		}
		logMu.Lock()
		errorLogger.Println(fmt.Sprintf("parseInterface: %s", err.Error()))
		logMu.Unlock()

		return fmt.Sprintf("%s", vv)
	}
	return ""
}

// parseCipherInterface handles the decryption in case a cipher key is used
// in case of error it returns data as is.
//
// parameters
// data: the data to decrypt as interface.
// cipherKey: cipher key to use to decrypt.
//
// returns the decrypted data as interface.
func parseCipherInterface(data interface{}, cipherKey string) interface{} {
	var intf interface{}
	decrypted, errDecryption := DecryptString(cipherKey, data.(string))
	if errDecryption != nil {
		intf = data
	} else {
		intf = decrypted
	}
	return intf
}

// ParseJSON parses the json data.
// It extracts the actual data (value 0),
// Timetoken/from time in case of detailed history (value 1),
// pubnub channelname/timetoken/to time in case of detailed history (value 2).
//
// It accepts the following parameters:
// contents: the contents to parse.
// cipherKey: the key to decrypt the messages (can be empty).
//
// returns:
// data: as string.
// Timetoken/from time in case of detailed history as string.
// pubnub channelname/timetoken/to time in case of detailed history (value 2).
// error if any.
func ParseJSON(contents []byte, cipherKey string) (string, string, string, error) {
	var s interface{}
	returnData := ""
	returnOne := ""
	returnTwo := ""

	err := json.Unmarshal(contents, &s)

	if err == nil {
		v := s.(interface{})
		switch vv := v.(type) {
		case string:
			length := len(vv)
			if length > 0 {
				returnData = vv
			}
		case []interface{}:
			length := len(vv)
			if length > 0 {
				returnData = getData(vv[0], cipherKey)
			}
			if length > 1 {
				returnOne = ParseInterfaceData(vv[1])
			}
			if length > 2 {
				returnTwo = ParseInterfaceData(vv[2])
			}
		}
	} else {
		logMu.Lock()
		errorLogger.Println(fmt.Sprintf("Invalid json:%s", string(contents)))
		logMu.Unlock()
		err = fmt.Errorf(invalidJSON)
	}
	return returnData, returnOne, returnTwo, err
}

// ParseInterfaceData formats the data to string as per the type of the data.
//
// It accepts the following parameters:
// myInterface: the interface data to parse and convert to string.
//
// returns: the data in string format.
func ParseInterfaceData(myInterface interface{}) string {
	switch v := myInterface.(type) {
	case int:
		return strconv.Itoa(v)
	case float64:
		return strconv.FormatFloat(v, 'f', -1, 64)
	case string:
		return string(v)
	}
	return fmt.Sprintf("%s", myInterface)
}

// httpRequest is the struct Pubnub's instance method.
// It creates a connection to the pubnub origin by calling the Connect method which
// returns the response or the error while connecting.
//
// It accepts the following parameters:
// requestUrl: the url to connect to.
// action: any one of
//	subscribeTrans
//	nonSubscribeTrans
//	presenceHeartbeatTrans
//	retryTrans
//
// returns:
// the response contents as byte array.
// response error code if any.
// error if any.
func (pub *Pubnub) httpRequest(requestURL string, action int) ([]byte, int, error) {
	requrl := pub.origin + requestURL
	logMu.Lock()
	infoLogger.Println(fmt.Sprintf("url: %s", requrl))
	//fmt.Println(fmt.Sprintf("url: %s", requrl))
	logMu.Unlock()

	contents, responseStatusCode, err := pub.connect(requrl, action, requestURL)

	if err != nil {
		logMu.Lock()
		errorLogger.Println(fmt.Sprintf("httpRequest error: %s", err.Error()))
		//errorLogger.Println(fmt.Sprintf("httpRequest responseStatusCode: %d", responseStatusCode))
		logMu.Unlock()
		if strings.Contains(err.Error(), timeout) {
			return nil, responseStatusCode, fmt.Errorf(operationTimeout)
		} else if strings.Contains(fmt.Sprintf("%s", err.Error()), closedNetworkConnection) {
			return nil, responseStatusCode, fmt.Errorf(connectionAborted)
		} else if strings.Contains(fmt.Sprintf("%s", err.Error()), noSuchHost) {
			return nil, responseStatusCode, fmt.Errorf(networkUnavailable)
		} else if strings.Contains(fmt.Sprintf("%s", err.Error()), connectionResetByPeer) {
			return nil, responseStatusCode, fmt.Errorf(connectionResetByPeerU)
		} else {
			return nil, responseStatusCode, err
		}
	}

	return contents, responseStatusCode, err
}

// setOrGetTransport creates the transport and sets it for reuse
// based on the action parameter
// It accepts the following parameters:
// action: any one of
//	subscribeTrans
//	nonSubscribeTrans
//	presenceHeartbeatTrans
//	retryTrans
//
// returns:
// the transport.
func (pub *Pubnub) setOrGetTransport(action int) http.RoundTripper {
	var transport http.RoundTripper
	switch action {
	case subscribeTrans:
		subscribeTransportMu.RLock()
		transport = subscribeTransport
		subscribeTransportMu.RUnlock()
		if transport == nil {
			transport = pub.initTrans(action)
			subscribeTransportMu.Lock()
			subscribeTransport = transport
			subscribeTransportMu.Unlock()
		}
	case nonSubscribeTrans:
		nonSubscribeTransportMu.RLock()
		transport = nonSubscribeTransport
		nonSubscribeTransportMu.RUnlock()
		if transport == nil {
			transport = pub.initTrans(action)
			nonSubscribeTransportMu.Lock()
			nonSubscribeTransport = transport
			nonSubscribeTransportMu.Unlock()
		}
	case retryTrans:
		retryTransportMu.RLock()
		transport = retryTransport
		retryTransportMu.RUnlock()
		if transport == nil {
			transport = pub.initTrans(action)
			retryTransportMu.Lock()
			retryTransport = transport
			retryTransportMu.Unlock()
		}
	case presenceHeartbeatTrans:
		presenceHeartbeatTransportMu.RLock()
		transport = presenceHeartbeatTransport
		presenceHeartbeatTransportMu.RUnlock()
		if transport == nil {
			transport = pub.initTrans(action)
			presenceHeartbeatTransportMu.Lock()
			presenceHeartbeatTransport = transport
			presenceHeartbeatTransportMu.Unlock()
		}
	}
	return transport
}

// initTrans creates the transport and sets it for reuse.
// Creates a different transport for different requests.
// Also sets the proxy details if provided
// It sets the timeouts based on the different requests.
//
// It accepts the following parameters:
// action: any one of
//	subscribeTrans
//	nonSubscribeTrans
//	presenceHeartbeatTrans
//	retryTrans
//
// returns:
// the transport.
func (pub *Pubnub) initTrans(action int) http.RoundTripper {
	transport := &http.Transport{TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
		Dial: func(netw, addr string) (net.Conn, error) {
			c, err := net.DialTimeout(netw, addr, time.Duration(connectTimeout)*time.Second)

			if c != nil {
				switch action {
				case subscribeTrans:
					subscribeTransportMu.Lock()
					defer subscribeTransportMu.Unlock()
					deadline := time.Now().Add(time.Duration(subscribeTimeout) * time.Second)
					c.SetDeadline(deadline)
					subscribeConn = c
					logMu.Lock()
					infoLogger.Println(fmt.Sprintf("subscribeConn set"))
					logMu.Unlock()
				case nonSubscribeTrans:
					nonSubscribeTransportMu.Lock()
					defer nonSubscribeTransportMu.Unlock()
					deadline := time.Now().Add(time.Duration(nonSubscribeTimeout) * time.Second)
					c.SetDeadline(deadline)
					conn = c
					logMu.Lock()
					infoLogger.Println(fmt.Sprintf("non subscribeConn set"))
					logMu.Unlock()
				case retryTrans:
					retryTransportMu.Lock()
					defer retryTransportMu.Unlock()
					deadline := time.Now().Add(time.Duration(retryInterval) * time.Second)
					c.SetDeadline(deadline)
					retryConn = c
					logMu.Lock()
					infoLogger.Println(fmt.Sprintf("retry conn set"))
					logMu.Unlock()
				case presenceHeartbeatTrans:
					presenceHeartbeatTransportMu.Lock()
					defer presenceHeartbeatTransportMu.Unlock()
					deadline := time.Now().Add(time.Duration(pub.GetPresenceHeartbeatInterval()) * time.Second)
					c.SetDeadline(deadline)
					presenceHeartbeatConn = c
					logMu.Lock()
					infoLogger.Println(fmt.Sprintf("presenceHeartbeatConn set"))
					logMu.Unlock()
				}
			} else {
				err = fmt.Errorf("%s%s", errorInInitializing, err.Error())
				logMu.Lock()
				errorLogger.Println(fmt.Sprintf("httpRequest: %s", err.Error()))
				logMu.Unlock()
			}

			if err != nil {
				logMu.Lock()
				errorLogger.Println(fmt.Sprintf("err: %s", err.Error()))
				logMu.Unlock()
				return nil, err
			}

			return c, nil
		}}

	if proxyServerEnabled {
		proxyURL, err := url.Parse(fmt.Sprintf("http://%s:%s@%s:%d", proxyUser, proxyPassword, proxyServer, proxyPort))
		if err == nil {
			transport.Proxy = http.ProxyURL(proxyURL)
		} else {
			logMu.Lock()
			errorLogger.Println(fmt.Sprintf("Error in connecting to proxy: %s", err.Error()))
			logMu.Unlock()
		}
	}

	return transport
}

// createHttpClient creates the http.Client by creating or reusing the transport for
// different types of requests.
//
// It accepts the following parameters:
// action: any one of
//	subscribeTrans
//	nonSubscribeTrans
//	presenceHeartbeatTrans
//	retryTrans
//
// returns:
// the pointer to the http.Client
// error is any.
func (pub *Pubnub) createHTTPClient(action int) (*http.Client, error) {
	var transport http.RoundTripper
	transport = pub.setOrGetTransport(action)

	var err error
	var httpClient *http.Client
	if transport != nil {
		httpClient = &http.Client{Transport: transport, CheckRedirect: nil}
	} else {
		err = fmt.Errorf("error in initializating transport")
	}

	return httpClient, err
}

// connect creates a http request to the pubnub origin and returns the
// response or the error while connecting.
//
// It accepts the following parameters:
// requestUrl: the url to connect to.
// action: any one of
//	subscribeTrans
//	nonSubscribeTrans
//	presenceHeartbeatTrans
//	retryTrans
//
// returns:
// the response as byte array.
// response errorcode if any.
// error if any.
func (pub *Pubnub) connect(requestURL string, action int, opaqueURL string) ([]byte, int, error) {
	var contents []byte
	httpClient, err := pub.createHTTPClient(action)

	if err == nil {
		req, err := http.NewRequest("GET", requestURL, nil)
		scheme := "http"
		if pub.isSSL {
			scheme = "https"
		}
		req.URL = &url.URL{
			Scheme: scheme,
			Host:   origin,
			Opaque: fmt.Sprintf("//%s%s", origin, opaqueURL),
		}
		useragent := fmt.Sprintf("ua_string=(%s) PubNub-Go/3.6.3", runtime.GOOS)

		req.Header.Set("User-Agent", useragent)
		if err == nil {
			response, err := httpClient.Do(req)
			if err == nil {
				defer response.Body.Close()
				bodyContents, e := ioutil.ReadAll(response.Body)
				if e == nil {
					contents = bodyContents
					logMu.Lock()
					infoLogger.Println(fmt.Sprintf("opaqueURL %s", opaqueURL))
					infoLogger.Println(fmt.Sprintf("response: %s", string(contents)))
					logMu.Unlock()
					return contents, response.StatusCode, nil
				}
				return nil, response.StatusCode, e
			}
			if response != nil {
				logMu.Lock()
				errorLogger.Println(fmt.Sprintf("httpRequest: %s, response.StatusCode: %d", err.Error(), response.StatusCode))
				logMu.Unlock()
				return nil, response.StatusCode, err
			}
			logMu.Lock()
			errorLogger.Println(fmt.Sprintf("httpRequest: %s", err.Error()))
			logMu.Unlock()
			return nil, 0, err
		}
		logMu.Lock()
		errorLogger.Println(fmt.Sprintf("httpRequest: %s", err.Error()))
		logMu.Unlock()
		return nil, 0, err
	}

	return nil, 0, err
}

// padWithPKCS7 pads the data as per the PKCS7 standard
// It accepts the following parameters:
// data: data to pad as byte array.
// returns the padded data as byte array.
func padWithPKCS7(data []byte) []byte {
	blocklen := 16
	padlen := 1
	for ((len(data) + padlen) % blocklen) != 0 {
		padlen = padlen + 1
	}

	pad := bytes.Repeat([]byte{byte(padlen)}, padlen)
	return append(data, pad...)
}

// unpadPKCS7 unpads the data as per the PKCS7 standard
// It accepts the following parameters:
// data: data to unpad as byte array.
// returns the unpadded data as byte array.
func unpadPKCS7(data []byte) ([]byte, error) {
	blocklen := 16
	if len(data)%blocklen != 0 || len(data) == 0 {
		return nil, fmt.Errorf("invalid data len %d", len(data))
	}
	padlen := int(data[len(data)-1])
	if padlen > blocklen || padlen == 0 {
		return nil, fmt.Errorf("padding is invalid")
	}
	// check padding
	pad := data[len(data)-padlen:]
	for i := 0; i < padlen; i++ {
		if pad[i] != byte(padlen) {
			return nil, fmt.Errorf("padding is invalid")
		}
	}

	return data[:len(data)-padlen], nil
}

// getHmacSha256 creates the cipher key hashed against SHA256.
// It accepts the following parameters:
// secretKey: the secret key.
// input: input to hash.
//
// returns the hash.
func getHmacSha256(secretKey string, input string) string {
	hmacSha256 := hmac.New(sha256.New, []byte(secretKey))
	hmacSha256.Write([]byte(input))
	rawSig := base64.StdEncoding.EncodeToString(hmacSha256.Sum(nil))
	signature := strings.Replace(strings.Replace(rawSig, "+", "-", -1), "/", "_", -1)
	return signature
}

// GenUuid generates a unique UUID
// returns the unique UUID or error.
func GenUuid() (string, error) {
	uuid := make([]byte, 16)
	n, err := rand.Read(uuid)
	if n != len(uuid) || err != nil {
		return "", err
	}
	// TODO: verify the two lines implement RFC 4122 correctly
	uuid[8] = 0x80 // variant bits see page 5
	uuid[4] = 0x40 // version 4 Pseudo Random, see page 7

	return hex.EncodeToString(uuid), nil
}

// encodeNonAsciiChars creates unicode string of the non-ascii chars.
// It accepts the following parameters:
// message: to parse.
//
// returns the encoded string.
func encodeNonASCIIChars(message string) string {
	runeOfMessage := []rune(message)
	lenOfRune := len(runeOfMessage)
	encodedString := ""
	for i := 0; i < lenOfRune; i++ {
		intOfRune := uint16(runeOfMessage[i])
		if intOfRune > 127 {
			hexOfRune := strconv.FormatUint(uint64(intOfRune), 16)
			dataLen := len(hexOfRune)
			paddingNum := 4 - dataLen
			prefix := ""
			for i := 0; i < paddingNum; i++ {
				prefix += "0"
			}
			hexOfRune = prefix + hexOfRune
			encodedString += bytes.NewBufferString(`\u` + hexOfRune).String()
		} else {
			encodedString += string(runeOfMessage[i])
		}
	}
	return encodedString
}

// EncryptString creates the base64 encoded encrypted string using the cipherKey.
// It accepts the following parameters:
// cipherKey: cipher key to use to encrypt.
// message: to encrypted.
//
// returns the base64 encoded encrypted string.
func EncryptString(cipherKey string, message string) string {
	block, _ := aesCipher(cipherKey)
	message = encodeNonASCIIChars(message)
	value := []byte(message)
	value = padWithPKCS7(value)
	blockmode := cipher.NewCBCEncrypter(block, []byte(valIV))
	cipherBytes := make([]byte, len(value))
	blockmode.CryptBlocks(cipherBytes, value)

	return base64.StdEncoding.EncodeToString(cipherBytes)
}

// DecryptString decodes encrypted string using the cipherKey
//
// It accepts the following parameters:
// cipherKey: cipher key to use to decrypt.
// message: to encrypted.
//
// returns the unencoded encrypted string,
// error if any.
func DecryptString(cipherKey string, message string) (retVal interface{}, err error) {
	block, aesErr := aesCipher(cipherKey)
	if aesErr != nil {
		return "***decrypt error***", fmt.Errorf("decrypt error aes cipher: %s", aesErr)
	}

	value, decodeErr := base64.StdEncoding.DecodeString(message)
	if decodeErr != nil {
		return "***decrypt error***", fmt.Errorf("decrypt error on decode: %s", decodeErr)
	}
	decrypter := cipher.NewCBCDecrypter(block, []byte(valIV))
	//to handle decryption errors
	defer func() {
		if r := recover(); r != nil {
			retVal, err = "***decrypt error***", fmt.Errorf("decrypt error: %s", r)
		}
	}()
	decrypted := make([]byte, len(value))
	decrypter.CryptBlocks(decrypted, value)
	val, err := unpadPKCS7(decrypted)
	if err != nil {
		return "***decrypt error***", fmt.Errorf("decrypt error: %s", err)
	}
	return fmt.Sprintf("%s", string(val)), nil
}

// aesCipher returns the cipher block
//
// It accepts the following parameters:
// cipherKey: cipher key.
//
// returns the cipher block,
// error if any.
func aesCipher(cipherKey string) (cipher.Block, error) {
	key := encryptCipherKey(cipherKey)
	block, err := aes.NewCipher(key)
	if err != nil {
		return nil, err
	}
	return block, nil
}

// encryptCipherKey creates the 256 bit hex of the cipher key
//
// It accepts the following parameters:
// cipherKey: cipher key to use to decrypt.
//
// returns the 256 bit hex of the cipher key.
func encryptCipherKey(cipherKey string) []byte {
	hash := sha256.New()
	hash.Write([]byte(cipherKey))

	sha256String := hash.Sum(nil)[:16]
	return []byte(hex.EncodeToString(sha256String))
}
