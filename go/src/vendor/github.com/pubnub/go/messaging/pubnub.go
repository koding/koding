// Package messaging provides the implemetation to connect to pubnub api.
// Version: 3.14.0
// Build Date: Apr 18, 2017
package messaging

import (
	"bytes"
	//"context"
	"crypto/aes"
	"crypto/cipher"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"net/url"
	"reflect"
	"runtime"
	"strconv"
	"strings"
	"sync"
	"time"
)

const (
	// SDK_VERSION is the current SDK version
	SDK_VERSION = "3.14.0"
	// SDK_DATE is the version release date
	SDK_DATE = "Apr 18, 2017"
)

type responseStatus int

// Enums for send response.
const (
	responseAlreadySubscribed  responseStatus = 1 << iota //1
	responseNotSubscribed                                 //2
	responseAsIs                                          //4
	responseInternetConnIssues                            //8
	responseAbortMaxRetry                                 //16
	responseAsIsError                                     //32
	responseTimedOut                                      //64
)

type transportType int

// Enums for diff types of connections
const (
	subscribeTrans transportType = 1 << iota
	nonSubscribeTrans
	presenceHeartbeatTrans
	retryTrans
)

type subscribeLoopAction int

const (
	subscribeLoopStart subscribeLoopAction = 1 << iota
	subscribeLoopRestart
	subscribeLoopDoNothing
)

var (
	//Sdk Identification Param appended to each request
	sdkIdentificationParamKey = "pnsdk"
	sdkIdentificationParamVal = fmt.Sprintf("PubNub-Go/%s", SDK_VERSION)
)

const (
	// This string is appended to all presence channels
	// to differentiate from the subscribe requests.
	presenceSuffix = "-pnpres"

	// Suffix of wildcarded channels
	wildcardSuffix = ".*"

	// This string is used when the server returns a malformed or non-JSON response.
	invalidJSON = "Invalid JSON"

	// This string is returned as a message when the http request times out.
	operationTimeout = "Operation Timeout"

	// This string is returned as a message when the http request is aborted.
	connectionAborted = "Connection aborted"

	// This string is returned as a message when the http request is canceled
	connectionCanceled = "Connection canceled"

	// This string is encountered when the http request couldn't connect to the origin.
	noSuchHost = "no such host"

	// This string is returned as a message when network connection is not avaialbe.
	networkUnavailable = "Network unavailable"

	// This string is used when the http request faces connectivity issues.
	closedNetworkConnection = "closed network connection"

	// This string is used when the http request is closed manually
	requestCanceled = "request canceled"

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
	origin = "ps.pndsn.com"

	// The time after which the Subscribe/Presence request will timeout.
	// In seconds.
	subscribeTimeout uint16 = 310 //sec

	// Mutex to lock the operations on presenceHeartbeat ops
	presenceHeartbeatMu sync.RWMutex

	// Mutex to lock operations on resumeOnReconnect ops
	resumeOnReconnectMu sync.RWMutex

	// The time after which the server expects the contact from the client.
	// In seconds.
	// If the server doesn't get an heartbeat request within this time, it will send
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
)

var (
	// Global variable to reuse a commmon transport instance for retry requests.
	retryTransport http.RoundTripper

	// Mutux to lock the operations on retryTransport
	retryTransportMu sync.RWMutex

	// Global variable to reuse a commmon transport instance for presence heartbeat requests.
	presenceHeartbeatTransport http.RoundTripper

	// Mutux to lock the operations on presence heartbeat transport
	presenceHeartbeatTransportMu sync.RWMutex

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

	// Used to set the value of HTTP Transport's MaxIdleConnsPerHost.
	maxIdleConnsPerHost = 30

	//max concurrent go routines to send requests
	maxWorkers = 20
)

// VersionInfo returns the version of the this code along with the build date.
func VersionInfo() string {
	return fmt.Sprintf("PubNub Go client SDK Version: %s; Build Date: %s",
		SDK_VERSION, SDK_DATE)
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
// timeToken is the current value of the servertime. This will be used to appened in each request.
// sentTimeToken: This is the timetoken sent to the server with the request
// resetTimeToken: In case of a new request or an error this variable is set to true so that the
//     timeToken will be set to 0 in the next request.
// channels: container for channels
// groups: container for channels groups
// isPresenceHeartbeatRunning a variable to keep a check on the presence heartbeat's status
// Mutex to lock the operations on the instance
type Pubnub struct {
	origin            string
	publishKey        string
	subscribeKey      string
	secretKey         string
	cipherKey         string
	authenticationKey string
	isSSL             bool
	uuid              string
	timeToken         string
	sentTimeToken     string
	resetTimeToken    bool
	publishCounter    uint64

	channels subscriptionEntity
	groups   subscriptionEntity

	userState map[string]map[string]interface{}

	isPresenceHeartbeatRunning bool
	sync.RWMutex

	publishCounterMu     sync.Mutex
	subscribeSleeperMu   sync.Mutex
	retrySleeperMu       sync.Mutex
	subscribeAsleep      bool
	retryAsleep          bool
	shouldSubscribeSleep bool
	shouldRetrySleep     bool
	subscribeSleeper     chan struct{}
	retrySleeper         chan struct{}
	requestCloser        chan struct{}
	requestCloserMu      sync.RWMutex
	currentSubscribeReq  *http.Request
	filterExpression     string

	// TODO: expose setters
	subscribeWorker         *requestWorker
	presenceHeartbeatWorker *requestWorker
	nonSubscribeWorker      *requestWorker
	retryWorker             *requestWorker
	nonSubHTTPClient        *http.Client
	infoLogger              *log.Logger
	nonSubJobQueue          chan NonSubJob
	nonSubQueueProcessor    *NonSubQueueProcessor
}

// PubnubUnitTest structure used to expose some data for unit tests.
type PubnubUnitTest struct {
}

// SetSubscribeTransport a default subscribe transport for subscribe request workers.
// Will affect only on newly created Pubnub instances
// To set transport for an already existing instance use instance method with
// the same name
func SetSubscribeTransport(transport http.RoundTripper) {
	subscribeTransportMu.Lock()
	defer subscribeTransportMu.Unlock()

	subscribeTransport = transport
}

// SetNonSubscribeTransport a default non-subscribe transport for non-subscribe request workers.
// Will affect only on newly created Pubnub instances
// To set transport for an already existing instance use instance method with
// the same name
func SetNonSubscribeTransport(transport http.RoundTripper) {
	nonSubscribeTransportMu.Lock()
	defer nonSubscribeTransportMu.Unlock()

	nonSubscribeTransport = transport
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
// logger is a pointer to log.Logger. If it is set to nil logging is disabled.
//
// returns the pointer to Pubnub instance.
func NewPubnub(publishKey string, subscribeKey string, secretKey string, cipherKey string, sslOn bool, customUuid string, logger *log.Logger) *Pubnub {

	newPubnub := &Pubnub{}
	if logger == nil {
		logger = log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile)
	}
	newPubnub.infoLogger = logger
	newPubnub.infoLogger.Printf(fmt.Sprintf("Pubnub Init, %s", VersionInfo()))
	newPubnub.infoLogger.Printf(fmt.Sprintf("OS: %s", runtime.GOOS))
	newPubnub.infoLogger.Printf(fmt.Sprintf("Go Version: %s", runtime.Version()))

	newPubnub.origin = origin
	newPubnub.publishKey = publishKey
	newPubnub.subscribeKey = subscribeKey
	newPubnub.secretKey = secretKey
	newPubnub.cipherKey = cipherKey
	newPubnub.isSSL = sslOn
	newPubnub.uuid = ""
	newPubnub.resetTimeToken = true
	newPubnub.timeToken = "0"
	newPubnub.sentTimeToken = "0"

	newPubnub.channels = *newSubscriptionEntity()
	newPubnub.groups = *newSubscriptionEntity()

	newPubnub.isPresenceHeartbeatRunning = false

	if newPubnub.isSSL {
		newPubnub.origin = "https://" + newPubnub.origin
	} else {
		newPubnub.origin = "http://" + newPubnub.origin
	}

	newPubnub.infoLogger.Printf(fmt.Sprintf("Origin: %s", newPubnub.origin))
	//Generate the uuid is custmUuid is not provided
	newPubnub.SetUUID(customUuid)
	newPubnub.publishCounter = 0
	newPubnub.subscribeSleeper = make(chan struct{})
	newPubnub.retrySleeper = make(chan struct{})
	newPubnub.shouldSubscribeSleep = true
	newPubnub.shouldRetrySleep = true

	newPubnub.subscribeWorker = newRequestWorker("Subscribe", subscribeTransport,
		subscribeTimeout, newPubnub.infoLogger)
	newPubnub.nonSubscribeWorker = newRequestWorker("Non-Subscribe", nonSubscribeTransport,
		nonSubscribeTimeout, newPubnub.infoLogger)
	newPubnub.retryWorker = newRequestWorker("Retry", retryTransport, retryInterval, newPubnub.infoLogger)
	newPubnub.nonSubHTTPClient = newPubnub.createNonSubHTTPClient()
	newPubnub.nonSubJobQueue = make(chan NonSubJob)
	newPubnub.nonSubQueueProcessor = newPubnub.newNonSubQueueProcessor(maxWorkers)

	return newPubnub
}

/*func (pub *Pubnub) createNonSubHTTPClient() *http.Client {
	//TODO: Create a common implemetation to create transport for createNonSubHTTPClient and (w *requestWorker) Client()
	transport := &http.Transport{
		MaxIdleConnsPerHost: maxIdleConnsPerHost,
		Dial: (&net.Dialer{
			Timeout:   time.Duration(connectTimeout) * time.Second,
			KeepAlive: 30 * time.Minute,
		}).Dial,
		ResponseHeaderTimeout: time.Duration(nonSubscribeTimeout) * time.Second,
	}
	if proxyServerEnabled {
		proxyURL, err := url.Parse(fmt.Sprintf("http://%s:%s@%s:%d", proxyUser,
			proxyPassword, proxyServer, proxyPort))

		if err == nil {
			transport.Proxy = http.ProxyURL(proxyURL)
		} else {
			pub.infoLogger.Printf("ERROR: createNonSubHTTPClient: Proxy connection error: %s", err.Error())
		}
	}
	client := &http.Client{
		Transport: transport,
		Timeout:   time.Duration(nonSubscribeTimeout) * time.Second,
	}
	return client
}*/

// SetMaxIdleConnsPerHost is used to set the value of HTTP Transport's MaxIdleConnsPerHost.
// It restricts how many connections there are which are not actively serving requests, but which the client has not closed.
// Be careful when increasing MaxIdleConnsPerHost to a large number. It only makes sense to increase idle connections if you are seeing many connections in a short period from the same clients.
func SetMaxIdleConnsPerHost(maxIdleConnsPerHostVal int) {
	maxIdleConnsPerHost = maxIdleConnsPerHostVal
}

// SetMaxWorkers sets the number of concurrent Go Routines to send requests.
func SetMaxWorkers(maxWorkersVal int) {
	maxWorkers = maxWorkersVal
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
	resumeOnReconnectMu.Lock()
	defer resumeOnReconnectMu.Unlock()

	resumeOnReconnect = val
}

// GetResumeOnReconnect returns the value of resumeOnReconnect.
func GetResumeOnReconnect() bool {
	resumeOnReconnectMu.RLock()
	defer resumeOnReconnectMu.RUnlock()

	return resumeOnReconnect
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
			pub.uuid = fmt.Sprintf("pn-%s", url.QueryEscape(uuid))
		} else {
			pub.infoLogger.Printf("ERROR: %s", err.Error())
		}
	} else {
		pub.uuid = url.QueryEscape(val)
	}
}

// GetUUID returns the value of UUID
func (pub *Pubnub) GetUUID() string {
	return pub.uuid
}

// FilterExpression gets the value of the set filter expression
func (pub *Pubnub) FilterExpression() string {
	return pub.filterExpression
}

// SetFilterExpression sets the value of the filter expression
func (pub *Pubnub) SetFilterExpression(val string) {
	pub.filterExpression = val
	pub.CloseExistingConnection()
}

// ResetPublishCounter resets the publish counter
func (pub *Pubnub) ResetPublishCounter() {
	pub.publishCounterMu.Lock()
	pub.publishCounter = 0
	pub.publishCounterMu.Unlock()
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

// SetSubscribeTransport custom subscribe transport for a subscribe worker
func (pub *Pubnub) SetSubscribeTransport(trans http.RoundTripper) {
	pub.subscribeWorker.SetTransport(trans)
}

// SetNonSubscribeTransport custom non-subscribe transport for a subscribe worker
func (pub *Pubnub) SetNonSubscribeTransport(trans http.RoundTripper) {
	pub.nonSubscribeWorker.SetTransport(trans)
}

// GetSubscribeTransport a reference to the current subscribe transport used by a subscribe worker
func (pub *Pubnub) GetSubscribeTransport() http.RoundTripper {
	return pub.subscribeWorker.GetTransport()
}

// GetNonSubscribeTransport a reference to the current non-subscribe transport used by
// a non-subscribe worker
func (pub *Pubnub) GetNonSubscribeTransport() http.RoundTripper {
	return pub.nonSubscribeWorker.GetTransport()
}

// Abort is the struct Pubnub's instance method that closes the open connections for both subscribe
// and non-subscribe requests.
//
// It also sends a leave request for all the subscribed channel and
// resets both channel and group collections to break the loop in the func StartSubscribeLoop
func (pub *Pubnub) Abort() {
	subscribedChannels := pub.channels.ConnectedNamesString()
	subscribedGroups := pub.groups.ConnectedNamesString()

	if subscribedChannels != "" || subscribedGroups != "" {
		value, _, err := pub.sendLeaveRequest(subscribedChannels, subscribedGroups)

		if err != nil {
			pub.infoLogger.Printf("ERROR: Request aborted error:%s", err.Error())

			pub.sendSubscribeError(subscribedChannels, subscribedGroups,
				err.Error(), responseAsIsError)
		} else {
			pub.sendSuccessResponse(subscribedChannels, subscribedGroups, value)
		}

		pub.infoLogger.Printf("INFO: Request aborted for channels: %s", subscribedChannels)

		pub.Lock()
		pub.channels.Abort(pub.infoLogger)
		pub.groups.Abort(pub.infoLogger)
		pub.Unlock()
	}

	pub.subscribeWorker.Cancel()
	pub.nonSubscribeWorker.Cancel()
	pub.cancelPresenceHeartbeatWorker()
	pub.retryWorker.Cancel()
	pub.nonSubQueueProcessor.Close()
}

// GrantSubscribe is used to give a subscribe channel read, write permissions
// and set TTL values for it. To grant a permission set read or write as true
// to revoke all perms set read and write false and ttl as -1
//
// ttl values:
//		-1: do not include ttl param to query, use default (60 minutes)
//		 0: permissions will never expire
//		1..525600: from 1 minute to 1 year(in minutes)
//
// channel is options and if not provided will set the permissions at subkey level
//
// Both callbackChannel and errorChannel are mandatory. If either is nil the code will panic
func (pub *Pubnub) GrantSubscribe(channel string, read, write bool,
	ttl int, authKey string, callbackChannel, errorChannel chan []byte) {
	pub.checkCallbackNil(callbackChannel, false, "GrantSubscribe")
	pub.checkCallbackNil(errorChannel, true, "GrantSubscribe")

	requestURL := pub.pamGenerateParamsForChannel("grant", channel, read, write,
		ttl, authKey)

	pub.executePam(channel, requestURL, callbackChannel, errorChannel)
}

// AuditSubscribe will make a call to display the permissions for a channel or subkey
//
// channel is options and if not provided will set the permissions at subkey level
//
// Both callbackChannel and errorChannel are mandatory. If either is nil the code will panic
func (pub *Pubnub) AuditSubscribe(channel, authKey string,
	callbackChannel, errorChannel chan []byte) {
	pub.checkCallbackNil(callbackChannel, false, "AuditSubscribe")
	pub.checkCallbackNil(errorChannel, true, "AuditSubscribe")

	requestURL := pub.pamGenerateParamsForChannel("audit", channel, false, false, -1,
		authKey)

	pub.executePam(channel, requestURL, callbackChannel, errorChannel)
}

// GrantPresence is used to give a presence channel read, write permissions
// and set TTL values for it. To grant a permission set read or write as true
// to revoke all perms set read and write false and ttl as -1
//
// ttl values:
//		-1: do not include ttl param to query, use default (60 minutes)
//		 0: permissions will never expire
//		1..525600: from 1 minute to 1 year(in minutes)
//
// channel is options and if not provided will set the permissions at subkey level
//
// Both callbackChannel and errorChannel are mandatory. If either is nil the code will panic
func (pub *Pubnub) GrantPresence(channel string, read, write bool, ttl int,
	authKey string, callbackChannel, errorChannel chan []byte) {
	pub.checkCallbackNil(callbackChannel, false, "GrantPresence")
	pub.checkCallbackNil(errorChannel, true, "GrantPresence")

	channel2 := convertToPresenceChannel(channel)

	requestURL := pub.pamGenerateParamsForChannel("grant", channel2, read, write,
		ttl, authKey)

	pub.executePam(channel2, requestURL, callbackChannel, errorChannel)
}

// AuditPresence will make a call to display the permissions for a channel or subkey
//
// channel is options and if not provided will set the permissions at subkey level
//
// Both callbackChannel and errorChannel are mandatory. If either is nil the code will panic
func (pub *Pubnub) AuditPresence(channel, authKey string,
	callbackChannel, errorChannel chan []byte) {
	pub.checkCallbackNil(callbackChannel, false, "AuditPresence")
	pub.checkCallbackNil(errorChannel, true, "AuditPresence")

	channel2 := convertToPresenceChannel(channel)

	requestURL := pub.pamGenerateParamsForChannel("audit", channel2, false, false, -1,
		authKey)

	pub.executePam(channel2, requestURL, callbackChannel, errorChannel)
}

// GrantChannelGroup is used to give a channel group read or manage permissions
// and set TTL values for it.
//
// ttl values:
//		-1: do not include ttl param to query, use default (60 minutes)
//		 0: permissions will never expire
//		1..525600: from 1 minute to 1 year(in minutes)
func (pub *Pubnub) GrantChannelGroup(group string, read, manage bool,
	ttl int, authKey string, callbackChannel, errorChannel chan []byte) {
	pub.checkCallbackNil(callbackChannel, false, "GrantChannelGroup")
	pub.checkCallbackNil(errorChannel, true, "GrantChannelGroup")

	requestURL := pub.pamGenerateParamsForChannelGroup("grant", group, read, manage,
		ttl, authKey)

	pub.executePam(group, requestURL, callbackChannel, errorChannel)
}

// AuditChannelGroup will make a call to display the permissions for a channel
// group or subkey
func (pub *Pubnub) AuditChannelGroup(group, authKey string,
	callbackChannel, errorChannel chan []byte) {
	pub.checkCallbackNil(callbackChannel, false, "AuditChannelGroup")
	pub.checkCallbackNil(errorChannel, true, "AuditChannelGroup")

	requestURL := pub.pamGenerateParamsForChannelGroup("audit", group, false, false,
		-1, authKey)

	pub.executePam(group, requestURL, callbackChannel, errorChannel)
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

//  generate params string for channels pam request
func (pub *Pubnub) pamGenerateParamsForChannel(action, channel string,
	read, write bool, ttl int, authKey string) string {

	var pamURLBuffer bytes.Buffer
	var params bytes.Buffer

	authParam := ""
	channelParam := ""
	noChannel := true
	readParam := ""
	writeParam := ""
	timestampParam := ""
	ttlParam := ""
	filler := "&"
	isAudit := action == "audit"

	if strings.TrimSpace(channel) != "" {
		if isAudit {
			channelParam = fmt.Sprintf("channel=%s", url.QueryEscape(channel))
		} else {
			channelParam = fmt.Sprintf("channel=%s&", url.QueryEscape(channel))
		}
		noChannel = false
	}

	if strings.TrimSpace(authKey) != "" {
		if isAudit && noChannel {
			authParam = fmt.Sprintf("auth=%s", url.QueryEscape(authKey))
		} else {
			authParam = fmt.Sprintf("auth=%s&", url.QueryEscape(authKey))
		}
	}

	if (noChannel) && (strings.TrimSpace(authKey) == "") {
		filler = ""
	}

	timestampParam = fmt.Sprintf("timestamp=%s", getUnixTimeStamp())

	if !isAudit {
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

	if isAudit {
		params.WriteString(fmt.Sprintf("%s%s%s%s&%s%s&uuid=%s%s", authParam,
			channelParam, filler, sdkIdentificationParam, readParam,
			timestampParam, pub.GetUUID(), writeParam))

	} else if !isAudit && ttl != -1 {
		params.WriteString(fmt.Sprintf("%s%s%s&%s%s&%s&uuid=%s%s", authParam,
			channelParam, sdkIdentificationParam, readParam, timestampParam,
			ttlParam, pub.GetUUID(), writeParam))

	} else {
		params.WriteString(fmt.Sprintf("%s%s%s&%s%s&uuid=%s%s", authParam,
			channelParam, sdkIdentificationParam, readParam, timestampParam,
			pub.GetUUID(), writeParam))
	}

	raw := fmt.Sprintf("%s\n%s\n%s\n%s", pub.subscribeKey, pub.publishKey,
		action, params.String())
	signature := getHmacSha256(pub.secretKey, raw)

	pamURLBuffer.WriteString("/v1/auth/")
	pamURLBuffer.WriteString(action)
	pamURLBuffer.WriteString("/sub-key/")
	pamURLBuffer.WriteString(pub.subscribeKey)
	pamURLBuffer.WriteString("?")
	pamURLBuffer.WriteString(params.String())
	pamURLBuffer.WriteString("&")
	pamURLBuffer.WriteString("signature=")
	pamURLBuffer.WriteString(signature)

	return pamURLBuffer.String()
}

//  generate params string for channel groups pam request
func (pub *Pubnub) pamGenerateParamsForChannelGroup(action, channelGroup string,
	read, manage bool, ttl int, authKey string) string {

	var pamURLBuffer bytes.Buffer
	var params bytes.Buffer

	authParam := ""
	channelGroupParam := ""
	noChannelGroup := true
	readParam := ""
	manageParam := ""
	timestampParam := ""
	ttlParam := ""
	filler := "&"
	isAudit := action == "audit"

	if strings.TrimSpace(channelGroup) != "" {
		if isAudit {
			channelGroupParam = fmt.Sprintf("channel-group=%s",
				url.QueryEscape(channelGroup))
		} else {
			channelGroupParam = fmt.Sprintf("channel-group=%s&",
				url.QueryEscape(channelGroup))
		}
		noChannelGroup = false
	}

	if strings.TrimSpace(authKey) != "" {
		if isAudit && noChannelGroup {
			authParam = fmt.Sprintf("auth=%s", url.QueryEscape(authKey))
		} else {
			authParam = fmt.Sprintf("auth=%s&", url.QueryEscape(authKey))
		}
	}

	if (noChannelGroup) && (strings.TrimSpace(authKey) == "") {
		filler = ""
	}

	timestampParam = fmt.Sprintf("timestamp=%s", getUnixTimeStamp())

	if !isAudit {
		if read {
			readParam = "r=1&"
		} else {
			readParam = "r=0&"
		}

		if manage {
			manageParam = "m=1"
		} else {
			manageParam = "m=0"
		}

		if ttl != -1 {
			if isAudit {
				ttlParam = fmt.Sprintf("&ttl=%s", strconv.Itoa(ttl))
			} else {
				ttlParam = fmt.Sprintf("ttl=%s", strconv.Itoa(ttl))
			}
		}
	}

	if isAudit {
		params.WriteString(fmt.Sprintf("%s%s%s%s%s&%s%s&uuid=%s", authParam,
			channelGroupParam, filler, manageParam, sdkIdentificationParam, readParam,
			timestampParam, pub.GetUUID()))

	} else if !isAudit && ttl != -1 {
		params.WriteString(fmt.Sprintf("%s%s%s&%s&%s%s&%s&uuid=%s", authParam,
			channelGroupParam, manageParam, sdkIdentificationParam, readParam,
			timestampParam, ttlParam, pub.GetUUID()))

	} else {
		params.WriteString(fmt.Sprintf("%s%s%s&%s&%s%s&uuid=%s", authParam,
			channelGroupParam, manageParam, sdkIdentificationParam, readParam,
			timestampParam, pub.GetUUID()))
	}

	raw := fmt.Sprintf("%s\n%s\n%s\n%s", pub.subscribeKey, pub.publishKey,
		action, params.String())
	signature := getHmacSha256(pub.secretKey, raw)

	pamURLBuffer.WriteString("/v1/auth/")
	pamURLBuffer.WriteString(action)
	pamURLBuffer.WriteString("/sub-key/")
	pamURLBuffer.WriteString(pub.subscribeKey)
	pamURLBuffer.WriteString("?")
	pamURLBuffer.WriteString(params.String())
	pamURLBuffer.WriteString("&")
	pamURLBuffer.WriteString("signature=")
	pamURLBuffer.WriteString(signature)

	return pamURLBuffer.String()
}

// executePam is the main method which is called for all PAM requests
func (pub *Pubnub) executePam(entity, requestURL string,
	callbackChannel, errorChannel chan []byte) {

	message := "Secret key is required"

	if strings.TrimSpace(pub.secretKey) == "" {
		if strings.TrimSpace(entity) == "" {
			pub.sendResponseWithoutChannel(errorChannel, message)
		} else {
			pub.sendErrorResponse(errorChannel, entity, message)
		}
		return
	}

	pub.infoLogger.Printf("INFO: queuing: %s", requestURL)

	pamMessage := NonSubJob{
		Channel:         entity,
		NonSubURL:       requestURL,
		ErrorChannel:    errorChannel,
		CallbackChannel: callbackChannel,
		NonSubMsgType:   messageTypePAM,
	}
	pub.nonSubJobQueue <- pamMessage

	//value, responseCode, err := pub.httpRequest(requestURL, nonSubscribeTrans)
	//pub.handlePAMResponse(entity, value, responseCode, err, callbackChannel, errorChannel)
}

func (pub *Pubnub) handlePAMResponse(entity string, value []byte, responseCode int, err error, callbackChannel, errorChannel chan []byte) {
	if (responseCode != 200) || (err != nil) {
		var message = ""

		if err != nil {
			message = err.Error()
			pub.infoLogger.Printf("ERROR: PAM Error: %s", message)
		} else {
			message = fmt.Sprintf("%s", value)
			pub.infoLogger.Printf("ERROR: PAM Error: responseCode %d, message %s", responseCode, message)
		}

		if strings.TrimSpace(entity) == "" {
			pub.sendResponseWithoutChannel(errorChannel, message)
		} else {
			pub.sendErrorResponse(errorChannel, entity, message)
		}
	} else {
		callbackChannel <- value
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
	pub.checkCallbackNil(callbackChannel, false, "GetTime")
	pub.checkCallbackNil(errorChannel, true, "GetTime")

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
		pub.infoLogger.Printf("ERROR: Time Error: %s", err.Error())
		pub.sendResponseWithoutChannel(errorChannel, err.Error())
	} else {
		_, _, _, errJSON := pub.ParseJSON(value, pub.cipherKey)
		if errJSON != nil && strings.Contains(errJSON.Error(), invalidJSON) {
			pub.infoLogger.Printf("ERROR: Time Error: %s", errJSON.Error())
			pub.sendResponseWithoutChannel(errorChannel, err.Error())
			if count < maxRetries {
				count++
				pub.executeTime(callbackChannel, errorChannel, count)
			}
		} else {
			callbackChannel <- value
		}
	}
}

// encodeJSONAsPathComponent properly encodes serialized JSON
// for placement within a URI path
func encodeJSONAsPathComponent(jsonBytes string) string {
	u := &url.URL{Path: jsonBytes}
	encodedPath := u.String()

	// Go 1.8 inserts a ./ per RFC 3986 §4.2. Previous versions
	// will be unaffected by this under the assumption that jsonBytes
	// represents valid JSON
	return strings.TrimLeft(encodedPath, "./")
}

func (pub *Pubnub) checkSecretKeyAndAddSignature(opURL, requestURL string) string {
	if len(pub.secretKey) > 0 {
		timestamp := getUnixTimeStamp()
		opURL = fmt.Sprintf("%s&timestamp=%s", opURL, timestamp)

		var signatureBuffer bytes.Buffer
		signatureBuffer.WriteString(pub.subscribeKey)
		signatureBuffer.WriteString("\n")
		signatureBuffer.WriteString(pub.publishKey)
		signatureBuffer.WriteString("\n")
		signatureBuffer.WriteString(requestURL)
		signatureBuffer.WriteString("\n")

		var reqURL *url.URL
		reqURL, urlErr := url.Parse(opURL)
		if urlErr != nil {
			pub.infoLogger.Printf("ERROR: Url encoding error: %s", urlErr.Error())
			return opURL
		}
		rawQuery := reqURL.RawQuery

		//sort query
		query, _ := url.ParseQuery(rawQuery)
		encodedAndSortedQuery := query.Encode()

		pub.infoLogger.Printf("INFO: query: %s", encodedAndSortedQuery)
		signatureBuffer.WriteString(encodedAndSortedQuery)

		pub.infoLogger.Printf("INFO: signatureBuffer: %s", signatureBuffer.String())
		signature := getHmacSha256(pub.secretKey, signatureBuffer.String())
		opURL = fmt.Sprintf("%s&signature=%s", opURL, signature)
		return opURL
	}
	return opURL
}

// sendPublishRequest is the struct Pubnub's instance method that posts a publish request and
// sends back the response to the channel.
//
// It accepts the following parameters:
// channel: pubnub channel to publish to
// publishUrlString: The url to which the message is to be appended.
// storeInHistory
// replicate: if replicate is passed as false, append `norep` query param as true (norep=true) when publishing a message
// jsonBytes: the message to be sent.
// metaBytes: meta message
// callbackChannel: Channel on which to send the response.
// errorChannel on which the error response is sent.
func (pub *Pubnub) sendPublishRequest(channel, publishURLString string,
	storeInHistory, replicate bool, jsonBytes string, metaBytes []byte, ttl int,
	callbackChannel, errorChannel chan []byte) {

	encodedPath := encodeJSONAsPathComponent(jsonBytes)
	pub.infoLogger.Printf("INFO: Publish: json: %s, encoded: %s", jsonBytes, encodedPath)
	publishURL := fmt.Sprintf("%s%s", publishURLString, encodedPath)
	requestURL := publishURL

	publishURL = fmt.Sprintf("%s?%s&uuid=%s%s", publishURL,
		sdkIdentificationParam, pub.GetUUID(), pub.addAuthParam(true))

	if storeInHistory == false {
		publishURL = fmt.Sprintf("%s&store=0", publishURL)
	}

	if !replicate {
		publishURL = fmt.Sprintf("%s&norep=true", publishURL)
	}

	if ttl >= 0 {
		publishURL = fmt.Sprintf("%s&ttl=%d", publishURL, ttl)
	}

	pub.publishCounterMu.Lock()
	pub.publishCounter++
	counter := strconv.FormatUint(pub.publishCounter, 10)
	pub.publishCounterMu.Unlock()

	pub.infoLogger.Printf("INFO: Publish counter: %s", counter)

	publishURL = fmt.Sprintf("%s&seqn=%s", publishURL, counter)

	if metaBytes != nil {
		metaEncodedPath := encodeJSONAsPathComponent(string(metaBytes))
		publishURL = fmt.Sprintf("%s&meta=%s", publishURL, metaEncodedPath)
	}

	publishURL = pub.checkSecretKeyAndAddSignature(publishURL, requestURL)

	pub.infoLogger.Printf("INFO: queuing: %s", publishURL)

	publishMessage := NonSubJob{
		Channel:         channel,
		NonSubURL:       publishURL,
		ErrorChannel:    errorChannel,
		CallbackChannel: callbackChannel,
		NonSubMsgType:   messageTypePublish,
	}
	pub.nonSubJobQueue <- publishMessage

}

func (pub *Pubnub) readPublishResponseAndCallSendResponse(channel string, value []byte, responseCode int, err error, callbackChannel, errorChannel chan []byte) {
	if (responseCode != 200) || (err != nil) {
		if (value != nil) && (responseCode > 0) {
			var s []interface{}
			errJSON := json.Unmarshal(value, &s)

			if (errJSON == nil) && (len(s) > 0) {
				//fmt.Println("len(s)", len(s))
				if message, ok := s[0].(string); ok {
					pub.sendErrorResponseExtended(errorChannel, channel, message, strconv.Itoa(responseCode))
				} else {
					pub.sendErrorResponseExtended(errorChannel, channel, string(value), strconv.Itoa(responseCode))
				}
			} else if errJSON != nil {
				pub.infoLogger.Printf("ERROR: Publish Error: %s", errJSON.Error())
				pub.sendErrorResponseExtended(errorChannel, channel, string(value), strconv.Itoa(responseCode))
			} else {
				pub.infoLogger.Printf("ERROR: Publish Error 2: %s", string(value))
				pub.sendErrorResponseExtended(errorChannel, channel, string(value), strconv.Itoa(responseCode))
			}
		} else if (err != nil) && (responseCode > 0) {
			pub.infoLogger.Printf("ERROR: Publish Failed: %s, ResponseCode: %d", err.Error(), responseCode)
			pub.sendErrorResponseExtended(errorChannel, channel, err.Error(), strconv.Itoa(responseCode))
		} else if err != nil {
			pub.infoLogger.Printf("ERROR: Publish Failed: %s", err.Error())
			pub.sendErrorResponse(errorChannel, channel, err.Error())
		} else {
			pub.infoLogger.Printf("ERROR: Publish Failed: ResponseCode: %d", responseCode)
			pub.sendErrorResponseExtended(errorChannel, channel, publishFailed, strconv.Itoa(responseCode))
		}
	} else {
		_, _, _, errJSON := pub.ParseJSON(value, pub.cipherKey)
		if errJSON != nil && strings.Contains(errJSON.Error(), invalidJSON) {
			pub.infoLogger.Printf("ERROR: Publish Error: %s", errJSON.Error())
			pub.sendErrorResponse(errorChannel, channel, errJSON.Error())
		} else {
			callbackChannel <- value
		}
	}
}

func (pub *Pubnub) encodeURL(urlString string) string {
	var reqURL *url.URL
	reqURL, urlErr := url.Parse(urlString)
	if urlErr != nil {
		pub.infoLogger.Printf("ERROR: Url encoding error: %s", urlErr.Error())
		return urlString
	}
	q := reqURL.Query()
	reqURL.RawQuery = q.Encode()
	return reqURL.String()
}

// pub.invalidMessage takes the message in form of a interface and checks if the message is nil or empty.
// Returns true if the message is nil or empty.
// Returns false is the message is acceptable.
func (pub *Pubnub) invalidMessage(message interface{}) bool {
	if message == nil {
		pub.infoLogger.Printf("WARN: Message nil")
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

// pub.invalidChannel takes the Pubnub channel and the channel as parameters.
// Multiple Pubnub channels are accepted separated by comma.
// It splits the Pubnub channel string by a comma and checks if the channel empty.
// Returns true if any one of the channel is empty. And sends a response on the Pubnub channel stating
// that there is an "Invalid Channel".
// Returns false if all the channels is acceptable.
func (pub *Pubnub) invalidChannel(channel string, c chan<- []byte) bool {
	if strings.TrimSpace(channel) == "" {
		return true
	}
	channelArray := strings.Split(channel, ",")

	for i := 0; i < len(channelArray); i++ {
		if strings.TrimSpace(channelArray[i]) == "" {
			pub.infoLogger.Printf("WARN: Channel empty")
			c <- []byte(fmt.Sprintf("Invalid Channel: %s", channel))
			return true
		}
	}
	return false
}

func (pub *Pubnub) invalidChannelV2(channel string, statusChannel chan *PNStatus, isChannelGroup bool) bool {
	if strings.TrimSpace(channel) == "" {
		return true
	}
	channelArray := strings.Split(channel, ",")
	var failedChannels []string
	bFail := false

	for i := 0; i < len(channelArray); i++ {
		if strings.TrimSpace(channelArray[i]) == "" {
			failedChannels = append(failedChannels, channelArray[i])
			bFail = true
		}
	}
	if bFail {
		var groupText = ""
		var affectedChannels, affectedChannelGroups []string
		if isChannelGroup {
			affectedChannelGroups = failedChannels
			groupText = " Group(s)"
		} else {
			affectedChannels = failedChannels
			groupText = "(s)"
		}
		message := fmt.Sprintf("Invalid Channel%s: %s", groupText, channel)

		status := createPNStatus(true, message, nil, 0, affectedChannels, affectedChannelGroups)
		if statusChannel != nil {
			statusChannel <- status
		}
		return true
	}

	return false
}

// Fire is the struct Pubnub's instance method that creates a publish request and calls
// sendPublishRequest to post the request.
//
// It calls the pub.invalidChannel and pub.invalidMessage methods to validate the Pubnub channels and message.
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
// Sends storeInHistory as false and replicate as false.
func (pub *Pubnub) Fire(channel string, message interface{}, doNotSerialize bool,
	callbackChannel, errorChannel chan []byte) {
	pub.PublishExtendedWithMetaAndReplicate(channel, message, nil, false, doNotSerialize, false, callbackChannel, errorChannel)
}

// Publish is the struct Pubnub's instance method that creates a publish request and calls
// sendPublishRequest to post the request.
//
// It calls the pub.invalidChannel and pub.invalidMessage methods to validate the Pubnub channels and message.
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
func (pub *Pubnub) Publish(channel string, message interface{},
	callbackChannel, errorChannel chan []byte) {

	pub.PublishExtendedWithMeta(channel, message, nil, true, false, callbackChannel, errorChannel)
}

// PublishExtended is the struct Pubnub's instance method that creates a publish request and calls
// sendPublishRequest to post the request.
//
// It calls the pub.invalidChannel and pub.invalidMessage methods to validate the Pubnub channels and message.
// Calls the GetHmacSha256 to generate a signature if a secretKey is to be used.
// Creates the publish url
// Calls json marshal
// Calls the EncryptString method is the cipherkey is used and calls json marshal
// Closes the channel after the response is received
//
// It accepts the following parameters:
// channel: The Pubnub channel to which the message is to be posted.
// message: message to be posted.
// storeInHistory: Message will be persisted in Storage & Playback db
// doNotSerialize: Set this option to true if you use your own serializer. In
// this case passed-in message should be a string or []byte
// callbackChannel: Channel on which to send the response back.
// errorChannel on which the error response is sent.
//
// Both callbackChannel and errorChannel are mandatory. If either is nil the code will panic
func (pub *Pubnub) PublishExtended(channel string, message interface{},
	storeInHistory, doNotSerialize bool,
	callbackChannel, errorChannel chan []byte) {
	pub.PublishExtendedWithMeta(channel, message, nil, storeInHistory, doNotSerialize, callbackChannel, errorChannel)
}

// PublishExtendedWithMeta is the struct Pubnub's instance method that creates a publish request and calls
// sendPublishRequest to post the request.
//
// It calls the pub.invalidChannel and pub.invalidMessage methods to validate the Pubnub channels and message.
// Calls the GetHmacSha256 to generate a signature if a secretKey is to be used.
// Creates the publish url
// Calls json marshal
// Calls the EncryptString method is the cipherkey is used and calls json marshal
// Closes the channel after the response is received
//
// It accepts the following parameters:
// channel: The Pubnub channel to which the message is to be posted.
// message: message to be posted.
// meta: meta data for message filtering
// storeInHistory: Message will be persisted in Storage & Playback db
// doNotSerialize: Set this option to true if you use your own serializer. In
// this case passed-in message should be a string or []byte
// callbackChannel: Channel on which to send the response back.
// errorChannel on which the error response is sent.
//
// Both callbackChannel and errorChannel are mandatory. If either is nil the code will panic
func (pub *Pubnub) PublishExtendedWithMeta(channel string, message, meta interface{},
	storeInHistory, doNotSerialize bool,
	callbackChannel, errorChannel chan []byte) {
	pub.PublishExtendedWithMetaAndReplicate(channel, message, meta, storeInHistory, doNotSerialize, true, callbackChannel, errorChannel)
}

// PublishExtendedWithMetaAndReplicate is the struct Pubnub's instance method that creates a publish request and calls
// sendPublishRequest to post the request.
//
// It calls the pub.invalidChannel and pub.invalidMessage methods to validate the Pubnub channels and message.
// Calls the GetHmacSha256 to generate a signature if a secretKey is to be used.
// Creates the publish url
// Calls json marshal
// Calls the EncryptString method is the cipherkey is used and calls json marshal
// Closes the channel after the response is received
//
// It accepts the following parameters:
// channel: The Pubnub channel to which the message is to be posted.
// message: message to be posted.
// meta: meta data for message filtering
// storeInHistory: Message will be persisted in Storage & Playback db
// doNotSerialize: Set this option to true if you use your own serializer. In
// this case passed-in message should be a string or []byte
// callbackChannel: Channel on which to send the response back.
// errorChannel on which the error response is sent.
//
// Both callbackChannel and errorChannel are mandatory. If either is nil the code will panic
func (pub *Pubnub) PublishExtendedWithMetaAndReplicate(channel string, message, meta interface{},
	storeInHistory, doNotSerialize, replicate bool,
	callbackChannel, errorChannel chan []byte) {
	pub.PublishExtendedWithMetaReplicateAndTTL(channel, message, meta, storeInHistory, doNotSerialize, replicate, -1, callbackChannel, errorChannel)
}

// PublishExtendedWithMetaReplicateAndTTL is the struct Pubnub's instance method that creates a publish request and calls
// sendPublishRequest to post the request.
//
// It calls the pub.invalidChannel and pub.invalidMessage methods to validate the Pubnub channels and message.
// Calls the GetHmacSha256 to generate a signature if a secretKey is to be used.
// Creates the publish url
// Calls json marshal
// Calls the EncryptString method is the cipherkey is used and calls json marshal
// Closes the channel after the response is received
//
// It accepts the following parameters:
// channel: The Pubnub channel to which the message is to be posted.
// message: message to be posted.
// meta: meta data for message filtering
// storeInHistory: Message will be persisted in Storage & Playback db
// doNotSerialize: Set this option to true if you use your own serializer. In
// this case passed-in message should be a string or []byte
// callbackChannel: Channel on which to send the response back.
// errorChannel on which the error response is sent.
//
// Both callbackChannel and errorChannel are mandatory. If either is nil the code will panic
func (pub *Pubnub) PublishExtendedWithMetaReplicateAndTTL(channel string, message, meta interface{},
	storeInHistory, doNotSerialize, replicate bool, ttl int,
	callbackChannel, errorChannel chan []byte) {

	var publishURLBuffer bytes.Buffer
	var err, errMeta error
	var jsonSerialized, jsonSerializedMeta []byte

	pub.checkCallbackNil(callbackChannel, false, "Publish")
	pub.checkCallbackNil(errorChannel, true, "Publish")

	if pub.publishKey == "" {
		pub.infoLogger.Printf("WARN: Publish key empty")
		pub.sendErrorResponse(errorChannel, channel, "Publish key required.")
		return
	}

	if pub.invalidChannel(channel, callbackChannel) {
		return
	}

	if pub.invalidMessage(message) {
		pub.sendErrorResponse(errorChannel, channel, "Invalid Message.")
		return
	}

	signature := ""
	if pub.secretKey != "" {
		signature = getHmacSha256(pub.secretKey, fmt.Sprintf("%s/%s/%s/%s/%s", pub.publishKey, pub.subscribeKey, pub.secretKey, channel, message))
	} else {
		signature = "0"
	}

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

	if meta != nil {
		jsonSerializedMeta, errMeta = json.Marshal(meta)
		if errMeta != nil {
			panic(fmt.Sprintf("error in serializing meta: %s", errMeta))
		}
	}

	if doNotSerialize {
		switch t := message.(type) {
		case string:
			jsonSerialized = []byte(message.(string))
		case []byte:
			jsonSerialized = message.([]byte)
		default:
			panic(fmt.Sprintf("Unable to send unserialized value of type %s", t))
		}
	} else {
		jsonSerialized, err = json.Marshal(message)
	}

	if err != nil {
		pub.sendErrorResponse(errorChannel, channel, fmt.Sprintf("error in serializing: %s", err))
	} else {
		if pub.cipherKey != "" {
			//Encrypt and Serialize
			encrypted := EncryptString(pub.cipherKey, fmt.Sprintf("%s", jsonSerialized))
			jsonEncBytes, errEnc := json.Marshal(encrypted)
			if errEnc != nil {
				pub.infoLogger.Printf("ERROR: Publish error: %s", errEnc.Error())
				pub.sendErrorResponse(errorChannel, channel, fmt.Sprintf("error in serializing: %s", errEnc))
			} else {
				pub.sendPublishRequest(channel, publishURLBuffer.String(),
					storeInHistory, replicate, string(jsonEncBytes), jsonSerializedMeta, ttl, callbackChannel, errorChannel)
			}
		} else {
			//messageStr := strings.Replace(string(jsonSerialized), "/", "%2F", -1)

			pub.sendPublishRequest(channel, publishURLBuffer.String(), storeInHistory, replicate,
				string(jsonSerialized), jsonSerializedMeta, ttl, callbackChannel, errorChannel)
		}
	}
}

// sendSubscribeResponse is the struct Pubnub's instance method that sends
// a response to subsribed channels or groups
//
// It accepts the following parameters:
// channel: Channel on which to send the response back.
// source: Channel Group or Wildcard Channel on which to send the response back.
// tp: response type
// action: additional information about action
// msg: message as subscribeMessage
func (pub *Pubnub) sendSubscribeResponse(channel, source, timetoken string,
	tp responseType, action responseStatus, msg subscribeMessage) {
	pub.infoLogger.Printf("INFO: sendSubscribeResponse, ")
	var (
		item       *subscriptionItem
		found      bool
		itemName   string
		isPresence bool
	)

	channel = strings.TrimSpace(channel)
	source = strings.TrimSpace(source)

	if len(channel) == 0 {
		pub.infoLogger.Printf("ERROR: RESPONSE: Empty channel value: %s", channel)
	}

	isPresence = strings.HasSuffix(channel, presenceSuffix)

	switch tp {
	case channelResponse:
		item, found = pub.channels.Get(channel)
		itemName = channel
	case channelGroupResponse:
		item, found = pub.groups.Get(source)
		itemName = source
	case wildcardResponse:
		item, found = pub.channels.Get(source)
		itemName = source
	default:
		panic(fmt.Sprintf("Response type #%d is unknown", tp))
	}

	if !found {
		pub.infoLogger.Printf("ERROR: Subscription item for %s response not found: %s\n", tp, itemName)
		return
	}

	if item.IsV2 {
		pub.infoLogger.Printf("INFO: RESPONSE V2: Subscription to %s '%s'\n", tp, itemName)
		if isPresence {
			item.PresenceChannel <- msg.getPresenceMessageResponse(pub)
		} else {
			item.MessageChannel <- msg.getMessageResponse()
		}
	} else {
		response := pub.extractMessage(msg)
		pub.infoLogger.Printf("INFO: RESPONSE: Subscription to %s '%s', message %s\n", tp, itemName, response)
		item.SuccessChannel <- successResponse{
			Data:      response,
			Channel:   channel,
			Source:    source,
			Timetoken: timetoken,
			Type:      tp,
			Presence:  isPresence,
		}.Bytes()
	}
}

// Used only in Abort() method
func (pub *Pubnub) sendSuccessResponse(channels, groups string, response []byte) {
	for _, itemName := range splitItems(channels) {
		channel, found := pub.channels.Get(itemName)
		if !found {
			pub.infoLogger.Printf("ERROR: Channel '%s' not found\n", itemName)
		}

		channel.SuccessChannel <- response
	}

	for _, itemName := range splitItems(groups) {
		group, found := pub.channels.Get(itemName)
		if !found {
			pub.infoLogger.Printf("ERROR: Group '%s' not found\n", itemName)
		}

		group.SuccessChannel <- response
	}
}

// Sender for specific go channel
func (pub *Pubnub) sendSuccessResponseToChannel(channel chan<- []byte, items,
	response string) {
	ln := len(splitItems(items))

	value := strings.Replace(response, presenceSuffix, "", -1)

	pub.infoLogger.Printf("INFO: Response value without channel: %s", value)

	for i := 0; i < ln; i++ {
		if channel != nil {
			channel <- []byte(value)
		}
	}
}

// Response not related to channel or group
func (pub *Pubnub) sendResponseWithoutChannel(channel chan<- []byte, response string) {
	value := fmt.Sprintf("[0, \"%s\"]", response)

	pub.infoLogger.Printf("INFO: Response value without channel: %s", value)

	if channel != nil {
		channel <- []byte(value)
	}
}

func (pub *Pubnub) sendConnectionEventToChannelOrChannelGroups(channelsOrChannelGroups string, isChannelGroup bool, action connectionAction) {
	channelsOrChannelGroupsArray := splitItems(channelsOrChannelGroups)
	var item *subscriptionItem
	var found bool
	for _, channel := range channelsOrChannelGroupsArray {
		var affectedChannels []string
		var affectedChannelGroups []string
		if isChannelGroup {
			item, found = pub.groups.Get(channel)
		} else {
			item, found = pub.channels.Get(channel)
		}
		if found {

			if item.IsV2 {
				if isChannelGroup {
					affectedChannelGroups = append(affectedChannelGroups, channel)
				} else {
					affectedChannels = append(affectedChannels, channel)
				}
				if item.StatusChannel != nil {
					item.StatusChannel <- createPNStatus(false, "", nil, PNConnectedCategory, affectedChannels, affectedChannelGroups)
				}
			} else {
				if isChannelGroup {
					connEve := connectionEvent{
						Source: item.Name,
						Action: action,
						Type:   channelGroupResponse,
					}
					if item.SuccessChannel != nil {
						item.SuccessChannel <- connEve.Bytes()
					}

				} else {
					connEve := connectionEvent{
						Channel: item.Name,
						Action:  action,
						Type:    channelResponse,
					}
					if item.SuccessChannel != nil {
						item.SuccessChannel <- connEve.Bytes()
					}
				}
			}
		} else {
			pub.infoLogger.Printf("INFO: sendConnectionEventToChannelOrChannelGroups, Channel not found : %s, %t", channel, isChannelGroup)
		}
	}

}

func (pub *Pubnub) sendConnectionEvent(channels, groups string,
	action connectionAction) {

	pub.sendConnectionEventToChannelOrChannelGroups(channels, false, action)
	pub.sendConnectionEventToChannelOrChannelGroups(groups, true, action)

}

func (pub *Pubnub) sendConnectionEventTo(channel chan []byte,
	source string, tp responseType, action connectionAction) {

	for _, item := range splitItems(source) {
		switch tp {
		case channelResponse:
			fallthrough
		case wildcardResponse:
			channel <- newConnectionEventForChannel(item, action).Bytes()
		case channelGroupResponse:
			channel <- newConnectionEventForChannelGroup(item, action).Bytes()
		}
	}
}

// Error sender for non-subscribe requests without 3rd element
func (pub *Pubnub) sendErrorResponseSimplified(errorChannel chan<- []byte, message string) {

	value := fmt.Sprintf("[0, \"%s\"]", message)

	pub.infoLogger.Printf("INFO: SEND ERROR: simplified: %s", value)

	if errorChannel != nil {
		errorChannel <- []byte(value)
	}
}

// Error sender for non-subscribe requests
func (pub *Pubnub) sendErrorResponse(errorChannel chan<- []byte, items, message string) {

	for _, item := range splitItems(items) {
		value := fmt.Sprintf("[0, \"%s\", \"%s\"]", message, item)

		pub.infoLogger.Printf("INFO: SEND ERROR: regular: %s", value)

		if errorChannel != nil {
			errorChannel <- []byte(value)
		}
	}
}

// Detailed error sender for non-subscribe requests
func (pub *Pubnub) sendErrorResponseExtended(errorChannel chan<- []byte, items, message,
	details string) {

	for _, item := range splitItems(items) {
		value := fmt.Sprintf("[0, \"%s\", %s, \"%s\"]", message, details, item)

		pub.infoLogger.Printf("INFO: SEND ERROR: extended: %s", value)

		if errorChannel != nil {
			errorChannel <- []byte(value)
		}
	}
}

// Error sender for subscribe requests
func (pub *Pubnub) sendClientSideErrorAboutSources(statusChannel chan *PNStatus, errorChannel chan<- []byte,
	tp responseType, sources []string, status responseStatus) {
	for _, source := range sources {
		if errorChannel != nil {
			pub.infoLogger.Printf("INFO: SEND ERROR: errorChannel: %s", status)
			errorChannel <- errorResponse{
				Reason: status,
				Type:   tp,
			}.BytesForSource(source)
		}
		if statusChannel != nil {
			pub.infoLogger.Printf("INFO: SEND ERROR: statusChannel: %s", status)
			errResp := errorResponse{
				Reason: status,
				Type:   tp,
			}.StringForSource(source)
			if tp == channelResponse {
				if statusChannel != nil {
					statusChannel <- createPNStatus(true, errResp, nil, PNUnknownCategory, sources, nil)
				}
			} else if tp == channelGroupResponse {
				if statusChannel != nil {
					statusChannel <- createPNStatus(true, errResp, nil, PNUnknownCategory, nil, sources)
				}
			} else {
				if statusChannel != nil {
					statusChannel <- createPNStatus(true, errResp, nil, PNUnknownCategory, nil, nil)
				}
			}

		}
	}
}

func (pub *Pubnub) sendSubscribeError(channels, groups, message string,
	reason responseStatus) {

	pub.sendSubscribeErrorHelper(channels, groups, errorResponse{
		Message: message,
		Reason:  reason,
	})
}

func (pub *Pubnub) sendSubscribeErrorExtended(channels, groups,
	message, detailedMessage string, reason responseStatus) {

	pub.sendSubscribeErrorHelper(channels, groups, errorResponse{
		Message:         message,
		Reason:          reason,
		DetailedMessage: detailedMessage,
	})
}

func (pub *Pubnub) sendSubscribeErrorHelper(channels, groups string,
	errResp errorResponse) {

	var (
		item  *subscriptionItem
		found bool
	)

	errResp.Type = channelResponse
	err := errors.New(errResp.Message)
	var affectedChannels = splitItems(channels)
	for _, channel := range affectedChannels {
		if item, found = pub.channels.Get(channel); found {
			if item.IsV2 {
				if item.StatusChannel != nil {
					item.StatusChannel <- createPNStatus(true, errResp.Message, err, PNUnknownCategory, affectedChannels, nil)
				}
			} else {
				if item.ErrorChannel != nil {
					item.ErrorChannel <- errResp.BytesForSource(channel)
				}
			}
		}
	}

	errResp.Type = channelGroupResponse
	var affectedChannelGroups = splitItems(groups)
	for _, group := range affectedChannelGroups {
		if item, found = pub.groups.Get(group); found {
			if item.IsV2 {
				if item.StatusChannel != nil {
					item.StatusChannel <- createPNStatus(true, errResp.Message, err, PNUnknownCategory, nil, affectedChannelGroups)
				}
			} else {
				if item.ErrorChannel != nil {
					item.ErrorChannel <- errResp.BytesForSource(group)
				}
			}
		}
	}
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
func (pub *Pubnub) checkForTimeoutAndRetries(err error) (bool, bool) {
	bRet := false
	bTimeOut := false

	retryCountMu.RLock()
	retryCountLocal := retryCount
	retryCountMu.RUnlock()

	pub.RLock()
	subChannels := pub.channels.ConnectedNamesString()
	subChannelGroups := pub.groups.ConnectedNamesString()
	pub.RUnlock()

	errorInitConn := strings.Contains(err.Error(), errorInInitializing)

	if errorInitConn {
		pub.sleepForAWhile(true)
		message := fmt.Sprintf("Error %s, Retry count: %s", err.Error(), strconv.Itoa(retryCountLocal))

		pub.infoLogger.Printf("ERROR: %s", message)

		pub.sendSubscribeErrorExtended(subChannels, subChannelGroups,
			err.Error(), message, responseAsIsError)
		bRet = true
	} else if strings.Contains(err.Error(), timeoutU) {
		pub.sleepForAWhile(false)
		message := strconv.Itoa(retryCountLocal)

		pub.infoLogger.Printf("ERROR: %s %s:", err.Error(), message)

		pub.sendSubscribeError(subChannels, subChannelGroups, message, responseTimedOut)

		bRet = true
		bTimeOut = true
	} else if strings.Contains(err.Error(), noSuchHost) || strings.Contains(err.Error(), networkUnavailable) {
		pub.sleepForAWhile(true)
		message := strconv.Itoa(retryCountLocal)

		pub.infoLogger.Printf("ERROR: %s %s:", err.Error(), message)

		pub.sendSubscribeError(subChannels, subChannelGroups, message, responseInternetConnIssues)
		bRet = true
	}
	// TODO: probably another cases exists

	if retryCountLocal >= maxRetries {
		// TODO: verify generated message
		pub.sendSubscribeError(subChannels, subChannelGroups, "", responseAbortMaxRetry)

		pub.Lock()
		pub.channels.ResetConnected(pub.infoLogger)
		pub.groups.ResetConnected(pub.infoLogger)
		pub.Unlock()

		retryCountLocal = 0
		retryCountMu.Lock()
		defer retryCountMu.Unlock()
		retryCount = 0
	}

	return bRet, bTimeOut
}

// resetRetryAndSendResponse resets the retryCount and sends the reconnection
// message to all the channels
func (pub *Pubnub) resetRetryAndSendResponse() bool {
	retryCountMu.Lock()
	defer retryCountMu.Unlock()

	if retryCount > 0 {
		pub.sendConnectionEvent(pub.channels.ConnectedNamesString(),
			pub.groups.ConnectedNamesString(), connectionReconnected)

		retryCount = 0
		return true
	}
	return false
}

func (pub *Pubnub) resetRetry() {
	retryCountMu.Lock()
	defer retryCountMu.Unlock()

	if retryCount > 0 {
		pub.sendConnectionEvent(pub.channels.ConnectedNamesString(),
			pub.groups.ConnectedNamesString(), connectionReconnected)

		retryCount = 0
	}
}

// retryLoop checks for the internet connection and intiates the rety logic of
// connection fails
func (pub *Pubnub) retryLoop() {
	for {
		pub.retrySleeperMu.Lock()
		pub.shouldRetrySleep = true
		pub.retrySleeperMu.Unlock()

		pub.RLock()
		subChannels := pub.channels.NamesString()
		subChannelsGroups := pub.groups.NamesString()
		pub.RUnlock()

		if len(subChannels) > 0 || len(subChannelsGroups) > 0 {
			_, responseCode, err := pub.httpRequest("", retryTrans)

			retryCountMu.RLock()
			retryCountLocal := retryCount
			retryCountMu.RUnlock()

			if (err != nil) && (responseCode != 403) && (retryCountLocal <= 0) {
				pub.infoLogger.Printf("ERROR: %s, response code: %d:", err.Error(), responseCode)

				pub.checkForTimeoutAndRetries(err)
				pub.CloseExistingConnection()
			} else if (err == nil) && (retryCountLocal > 0) {
				pub.resetRetryAndSendResponse()
			}
			pub.sleepForAWhileRetry(false)
		} else {
			pub.retryWorker.Cancel()
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
	if !pub.channels.Empty() {
		presenceURLBuffer.WriteString(queryEscapeMultiple(
			pub.channels.NamesString(), ","))
	} else {
		presenceURLBuffer.WriteString(",")
	}

	presenceURLBuffer.WriteString("/heartbeat")
	presenceURLBuffer.WriteString("?")

	if !pub.groups.Empty() {
		presenceURLBuffer.WriteString("channel-group=")
		presenceURLBuffer.WriteString(
			queryEscapeMultiple(pub.groups.NamesString(), ","))
		presenceURLBuffer.WriteString("&")
	}
	pub.RUnlock()

	presenceURLBuffer.WriteString("uuid=")
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
		pub.infoLogger.Printf("ERROR: createPresenceHeartbeatURL %s", err.Error())
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
	pub.presenceHeartbeatWorker = newRequestWorker("Presence Heartbeat",
		presenceHeartbeatTransport, presenceHeartbeatInterval, pub.infoLogger)

	pub.RLock()
	isPresenceHeartbeatRunning := pub.isPresenceHeartbeatRunning
	pub.RUnlock()

	if isPresenceHeartbeatRunning {
		pub.infoLogger.Printf("INFO: Presence heartbeat already running")

		return
	}

	pub.Lock()
	pub.isPresenceHeartbeatRunning = true
	pub.Unlock()

	for {
		pub.RLock()
		l := pub.channels.Length()
		cgl := pub.groups.Length()
		pub.RUnlock()

		presenceHeartbeatMu.RLock()
		presenceHeartbeatLoc := presenceHeartbeat
		presenceHeartbeatMu.RUnlock()

		if (l <= 0 && cgl <= 0) || (pub.GetPresenceHeartbeatInterval() <= 0) || (presenceHeartbeatLoc <= 0) {
			pub.Lock()
			pub.isPresenceHeartbeatRunning = false
			pub.Unlock()

			pub.infoLogger.Printf("INFO: Breaking out of presence heartbeat loop")

			pub.cancelPresenceHeartbeatWorker()
			break
		}

		presenceHeartbeatURL := pub.createPresenceHeartbeatURL()

		value, responseCode, err := pub.httpRequest(presenceHeartbeatURL, presenceHeartbeatTrans)

		if (responseCode != 200) || (err != nil) {
			if err != nil {
				pub.infoLogger.Printf("ERROR: presence heartbeat err %s", err.Error())
			} else {
				pub.infoLogger.Printf("ERROR: presence heartbeat err responseCode %d", responseCode)
			}
		} else if string(value) != "" {
			pub.infoLogger.Printf("INFO: Presence Heartbeat %s", string(value))
		}
		time.Sleep(time.Duration(pub.GetPresenceHeartbeatInterval()) * time.Second)
	}
}

func (pub *Pubnub) cancelPresenceHeartbeatWorker() {
	if pub.presenceHeartbeatWorker != nil {
		pub.presenceHeartbeatWorker.Cancel()
	}
}

// startSubscribeLoop starts a continuous loop that handles the response from pubnub
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
// groups: channel groups to subscribe.
// errorChannel: Channel to send the error response to.
func (pub *Pubnub) startSubscribeLoop(channels, groups string) {

	go pub.retryLoop()

	var region string

	for {
		pub.RLock()
		alreadySubscribedChannels := pub.channels.NamesString()
		alreadySubscribedChannelGroups := pub.groups.NamesString()
		pub.RUnlock()

		if len(alreadySubscribedChannels) > 0 || len(alreadySubscribedChannelGroups) > 0 {
			pub.subscribeSleeperMu.Lock()
			pub.shouldSubscribeSleep = true
			pub.subscribeSleeperMu.Unlock()

			pub.RLock()
			sentTimeToken := pub.timeToken
			pub.RUnlock()

			subscribeURL, sentTimeToken := pub.createSubscribeURL(sentTimeToken, region)

			value, responseCode, err := pub.httpRequest(subscribeURL, subscribeTrans)

			// if network error, for ex.
			// - closed network connection/connection aborted
			if err != nil {
				pub.infoLogger.Printf("ERROR: SUBSCRIPTION: Network Error: %s, response code: %d:", err.Error(), responseCode)

				// not! Means CloseExistingConnection() was called
				isConnAbortedError := strings.Contains(err.Error(), connectionAborted)
				isConnCanceled := strings.Contains(err.Error(), connectionCanceled)

				if isConnAbortedError {
					pub.sendSubscribeError(alreadySubscribedChannels,
						alreadySubscribedChannelGroups, err.Error(), responseAsIsError)

					pub.Lock()
					pub.channels.ApplyAbort(pub.infoLogger)
					pub.groups.ApplyAbort(pub.infoLogger)
					pub.Unlock()
					continue
				}

				if isConnCanceled {
					pub.Lock()
					pub.channels.ApplyAbort(pub.infoLogger)
					pub.groups.ApplyAbort(pub.infoLogger)
					pub.Unlock()
					continue
				}

				isConnError, isConnTimeoutError := pub.checkForTimeoutAndRetries(err)

				if isConnError {
					if isConnTimeoutError {
						_, returnTimeToken, _, errJSON := pub.ParseJSON(value, pub.cipherKey)
						if errJSON == nil {
							pub.Lock()
							pub.timeToken = returnTimeToken
							pub.Unlock()
						}
					}

					if !GetResumeOnReconnect() {
						pub.Lock()
						pub.resetTimeToken = true
						pub.Unlock()
					}
					// Another error, for ex.:
					// - EOF
					// - Get {url}: http: error connecting to proxy http://127.0.0.1:34341:
					//   dial tcp 127.0.0.1:34341: getsockopt: connection refused
					// - Get {url}: net/http: HTTP/1 transport connection broken:
					//	 readLoopPeekFailLocked: EOF
				} else {
					pub.CloseExistingConnection()

					pub.sendSubscribeError(alreadySubscribedChannels,
						alreadySubscribedChannelGroups, err.Error(), responseAsIsError)

					pub.sleepForAWhile(true)
				}
				continue
				// if server error. for ex.
				// - 400/cg doesn't exist
				// - 403/no permissions
			} else if responseCode != 200 {
				pub.infoLogger.Printf("ERROR: Server Error. Response code: %d:", responseCode)

				if responseCode != 403 && responseCode != 400 {
					pub.resetRetryAndSendResponse()
				}

				pub.closeSubscribe()

				pub.sendSubscribeError(alreadySubscribedChannels,
					alreadySubscribedChannelGroups, string(value), responseAsIsError)

				pub.sleepForAWhile(false)
				continue
				// if server error. for ex.
			} else if string(value) != "" {
				pub.infoLogger.Printf("INFO: SUBSCRIPTION: Handling response")
				region = pub.handleSubscribeResponse(value, sentTimeToken,
					alreadySubscribedChannels, alreadySubscribedChannelGroups)
			} else {
				pub.infoLogger.Printf("INFO: SUBSCRIPTION: Empty subscribe response")
				// TODO: handle else case (send error and sleepForAWhile(true))
			}
		} else {
			pub.infoLogger.Printf("INFO: SUBSCRIPTION: Stop")
			break
		}
	}
	pub.infoLogger.Printf("INFO: SUBSCRIPTION: breaking out")
}

// createSubscribeUrl creates a subscribe url to send to the origin
// If the resetTimeToken flag is true
// it sends 0 to init the subscription.
// Else sends the last timetoken.
//
// Accepts the sentTimeToken as a string parameter.
// retunrs the Url and the senttimetoken based on the logic above .
func (pub *Pubnub) createSubscribeURL(sentTimeToken, region string) (string, string) {
	var subscribeURLBuffer bytes.Buffer
	subscribeURLBuffer.WriteString("/v2")
	subscribeURLBuffer.WriteString("/subscribe")
	subscribeURLBuffer.WriteString("/")
	subscribeURLBuffer.WriteString(pub.subscribeKey)
	subscribeURLBuffer.WriteString("/")

	pub.Lock()
	defer pub.Unlock()

	if !pub.channels.Empty() {
		subscribeURLBuffer.WriteString(queryEscapeMultiple(
			pub.channels.NamesString(), ","))
	} else {
		subscribeURLBuffer.WriteString(",")
	}

	subscribeURLBuffer.WriteString("/0")
	requestURL := subscribeURLBuffer.String()

	subscribeURLBuffer.WriteString("?")

	if !pub.groups.Empty() {
		subscribeURLBuffer.WriteString("channel-group=")
		subscribeURLBuffer.WriteString(
			queryEscapeMultiple(pub.groups.NamesString(), ","))
		subscribeURLBuffer.WriteString("&")
	}

	subscribeURLBuffer.WriteString("uuid=")
	subscribeURLBuffer.WriteString(pub.GetUUID())
	subscribeURLBuffer.WriteString(pub.addAuthParam(true))

	subscribeURLBuffer.WriteString("&tt=")
	if pub.resetTimeToken {
		pub.infoLogger.Printf("INFO: SUBSCRIPTION: resetTimeToken=true")

		sentTimeToken = "0"
		pub.sentTimeToken = "0"
		pub.resetTimeToken = false
		subscribeURLBuffer.WriteString("0")
	} else {
		pub.infoLogger.Printf("INFO: SUBSCRIPTION: resetTimeToken=false")
		if strings.TrimSpace(pub.timeToken) == "" {
			pub.timeToken = "0"
			pub.sentTimeToken = "0"
		} else {
			pub.sentTimeToken = sentTimeToken
		}
		subscribeURLBuffer.WriteString(pub.timeToken)
	}

	if region != "" {
		subscribeURLBuffer.WriteString("&tr=")
		subscribeURLBuffer.WriteString(url.QueryEscape(region))
	}
	if pub.FilterExpression() != "" {
		subscribeURLBuffer.WriteString("&filter-expr=")
		encodedPath := url.QueryEscape(pub.FilterExpression())
		encodedPathWithPlusReplaced := strings.Replace(encodedPath, "+", "%20", -1)
		pub.infoLogger.Printf("INFO: FilterExpression: %s, encoded: %s, enc2: %s", pub.FilterExpression(), encodedPath, encodedPathWithPlusReplaced)

		subscribeURLBuffer.WriteString(encodedPathWithPlusReplaced)
	}

	presenceHeartbeatMu.RLock()
	if presenceHeartbeat > 0 {
		subscribeURLBuffer.WriteString("&heartbeat=")
		subscribeURLBuffer.WriteString(strconv.Itoa(int(presenceHeartbeat)))
	}
	presenceHeartbeatMu.RUnlock()

	jsonSerialized, err := json.Marshal(pub.userState)
	if err != nil {
		pub.infoLogger.Printf("ERROR: createSubscribeURL err: %s", err.Error())
	} else {
		userState := string(jsonSerialized)
		if (strings.TrimSpace(userState) != "") && (userState != "null") {
			subscribeURLBuffer.WriteString("&state=")
			subscribeURLBuffer.WriteString(url.QueryEscape(userState))
		}
	}

	subscribeURLBuffer.WriteString("&")
	subscribeURLBuffer.WriteString(sdkIdentificationParam)

	subscribeUrl := pub.checkSecretKeyAndAddSignature(subscribeURLBuffer.String(), requestURL)

	return subscribeUrl, sentTimeToken
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

func (pub *Pubnub) handleSubscribeResponse(response []byte,
	sentTimetoken string, subscribedChannels, subscribedGroups string) string {

	pub.resetRetry()
	reconnected := false

	if bytes.Equal(response, []byte("[]")) {
		pub.sleepForAWhile(false)
		return ""
	}

	subEnvelope, newTimetoken, region, errJSON :=
		pub.ParseSubscribeResponse(response, pub.cipherKey)

	pub.Lock()
	pub.timeToken = newTimetoken
	pub.Unlock()

	if len(subEnvelope.Messages) == 0 {
		if sentTimetoken == "0" {
			pub.Lock()
			changedChannels := pub.channels.SetConnected(pub.infoLogger)
			changedGroups := pub.groups.SetConnected(pub.infoLogger)
			pub.Unlock()

			if !reconnected {
				if len(changedChannels) > 0 {
					pub.sendConnectionEvent(strings.Join(changedChannels, ","),
						"", connectionConnected)
				}

				if len(changedGroups) > 0 {
					pub.sendConnectionEvent("", strings.Join(changedGroups, ","),
						connectionConnected)
				}
			}
		}
	} else if errJSON != nil {
		pub.infoLogger.Printf("ERROR: %s", errJSON.Error())
		channelNames, channelGroupNames := subEnvelope.getChannelsAndGroups(pub)
		chNames := ""
		if len(channelNames) > 0 {
			chNames = strings.Join(channelNames, ",")
		}

		chGroupNames := ""
		if len(channelNames) > 0 {
			chGroupNames = strings.Join(channelGroupNames, ",")
		}

		pub.infoLogger.Printf("INFO: chNames=%s\nchGroupNames=%s", chNames, chGroupNames)

		pub.sendSubscribeError(chNames, chGroupNames, fmt.Sprintf("%s", errJSON),
			responseAsIsError)

		pub.sleepForAWhile(false)
	} else {
		retryCountMu.Lock()
		retryCount = 0
		retryCountMu.Unlock()
		pub.infoLogger.Printf("INFO: handleSubscribeResponse, ")
		if subEnvelope.Messages != nil {
			count := 0
			for _, msg := range subEnvelope.Messages {
				count++
				msg.writeMessageLog(count, pub)
				pub.parseMessagesAndSendCallbacks(msg, newTimetoken)
			}
		}
	}

	return region
}

func (pub *Pubnub) extractMessage(msg subscribeMessage) []byte {
	var message []byte
	var intf interface{}
	if pub.cipherKey != "" {
		//message = []byte(pub.getData(msg.Payload, pub.cipherKey))
		msgKind := reflect.TypeOf(msg.Payload).Kind()
		if msgKind == reflect.String {
			//pub.infoLogger.Printf("INFO: intf nil: %s, %s", msgKind, msg.Payload)
			intf = pub.parseCipherInterface(msg.Payload, pub.cipherKey)
			var returnedMessages interface{}
			errUnmarshalMessages := json.Unmarshal([]byte(intf.(string)), &returnedMessages)

			if errUnmarshalMessages == nil {
				intf = returnedMessages
			}

			if intf == nil {
				intf = msg.Payload
				pub.infoLogger.Printf("ERROR: intf nil: %s, %s", msgKind, msg.Payload)
			}
		} else {
			pub.infoLogger.Printf("INFO: non string intf :%s, payload: %s", msgKind, msg.Payload)
			intf = msg.Payload
		}
	} else {
		intf = msg.Payload
	}

	if reflect.TypeOf(intf).Kind() == reflect.String {
		unescapeVal, unescapeErr := url.QueryUnescape(intf.(string))
		if unescapeErr != nil {
			pub.infoLogger.Printf("ERROR: unescape :%s", unescapeErr.Error())
		} else {
			intf = unescapeVal
		}
	}

	//messageTemp, errMrshal := json.Marshal(msg.Payload)
	messageTemp, errMrshal := json.Marshal(intf)
	if errMrshal != nil {
		strPayload, _ := msg.Payload.(string)
		errMsg := fmt.Sprintf("Error marshalling received payload, %s\nMessage: %s", errMrshal.Error(), strPayload)
		pub.infoLogger.Printf("ERROR: %s", errMsg)
		message = []byte(errMsg)
	} else {
		message = messageTemp
	}
	return message
}

func (pub *Pubnub) parseMessagesAndSendCallbacks(msg subscribeMessage, timetoken string) {
	channel := msg.Channel

	if (len(strings.TrimSpace(msg.SubscriptionMatch)) <= 0) || (channel == msg.SubscriptionMatch) {
		//channel
		msg.SubscriptionMatch = ""
		pub.sendSubscribeResponse(channel, "", timetoken, channelResponse, responseAsIs, msg)
	} else if strings.HasSuffix(msg.SubscriptionMatch, wildcardSuffix) && (strings.Contains(msg.SubscriptionMatch, presenceSuffix)) {
		//wildcard presence channel
		pub.sendSubscribeResponse(channel, msg.SubscriptionMatch, timetoken, wildcardResponse, responseAsIs, msg)
	} else if strings.HasSuffix(msg.SubscriptionMatch, wildcardSuffix) {
		//wildcard channel
		pub.sendSubscribeResponse(channel, msg.SubscriptionMatch, timetoken, wildcardResponse, responseAsIs, msg)
	} else {
		//ce will be the cg and subscriptionMatch will have the cg name
		pub.sendSubscribeResponse(channel, msg.SubscriptionMatch, timetoken, channelGroupResponse, responseAsIs, msg)
	}
}

// CloseExistingConnection closes the open subscribe/presence connection.
func (pub *Pubnub) CloseExistingConnection() {
	subscribeTransportMu.Lock()
	if pub.subscribeWorker != nil {
		pub.subscribeWorker.Cancel()
	}
	subscribeTransportMu.Unlock()

	presenceHeartbeatTransportMu.Lock()
	if pub.presenceHeartbeatWorker != nil {
		pub.presenceHeartbeatWorker.Cancel()
	}
	presenceHeartbeatTransportMu.Unlock()
}

// pub.checkCallbackNil checks if the callback channel is nil
// if nil then the code wil panic as callbacks are mandatory
func (pub *Pubnub) checkCallbackNil(channelToCheck chan<- []byte, isErrChannel bool, funcName string) {
	if channelToCheck == nil {
		message2 := ""
		if isErrChannel {
			message2 = "Error "
		}
		message := fmt.Sprintf("%sCallback is nil for %s", message2, funcName)
		pub.infoLogger.Printf("ERROR: %s", message)
		panic(message)
	}
}

// pub.checkCallbackNil2 checks if the callback channels are nil
// if nil then the code wil panic as callbacks are mandatory
func (pub *Pubnub) checkCallbackNilV2(statusChannel chan *PNStatus,
	messageChannel chan *PNMessageResult,
	presenceChannel chan *PNPresenceEventResult, funcName string, withPresence bool) {
	if statusChannel == nil {
		message := fmt.Sprintf("PNStatus Callback is nil for function %s", funcName)
		pub.infoLogger.Printf("ERROR: %s", message)
		panic(message)
	}
	if messageChannel == nil {
		message := fmt.Sprintf("PNMessageResult Callback is nil for function %s", funcName)
		pub.infoLogger.Printf("ERROR: %s", message)
		panic(message)
	}
	if withPresence && (presenceChannel == nil) {
		message := fmt.Sprintf("PNPresenceEventResult Callback is nil for function %s", funcName)
		pub.infoLogger.Printf("ERROR: %s", message)
		panic(message)
	}
}

func (pub *Pubnub) checkAlreadySubscribedChannelsOrChannelGroups(channelsOrChannelGroups []string,
	errorChannel chan<- []byte, statusChannel chan *PNStatus, isChannelGroup bool) ([]string, int, bool) {
	alreadySubscribedChannelOrChannelGroups := []string{}
	var subscribedChannelsOrChannelGroups string
	if isChannelGroup {
		subscribedChannelsOrChannelGroups = pub.groups.ConnectedNamesString()
	} else {
		subscribedChannelsOrChannelGroups = pub.channels.ConnectedNamesString()
	}
	channelsOrGroupsModified := false

	for i := 0; i < len(channelsOrChannelGroups); i++ {
		channelToSub := strings.TrimSpace(channelsOrChannelGroups[i])
		channelOrGroupExists := false
		if isChannelGroup {
			channelOrGroupExists = pub.groups.Exist(channelToSub)
		} else {
			channelOrGroupExists = pub.channels.Exist(channelToSub)
		}
		if !channelOrGroupExists {
			if len(subscribedChannelsOrChannelGroups) > 0 {
				subscribedChannelsOrChannelGroups += ","
			}
			subscribedChannelsOrChannelGroups += channelToSub

			channelsOrGroupsModified = true
		} else {
			alreadySubscribedChannelOrChannelGroups = append(alreadySubscribedChannelOrChannelGroups, channelToSub)
		}
	}

	alreadySubscribedChannelsLen := len(alreadySubscribedChannelOrChannelGroups)
	pub.infoLogger.Printf("INFO: alreadySubscribedChannelsLen %d", alreadySubscribedChannelsLen)
	if alreadySubscribedChannelsLen > 0 {
		var tp responseType
		if isChannelGroup {
			tp = channelGroupResponse
		} else {
			tp = channelResponse
		}
		pub.infoLogger.Printf("INFO: already subscribed %s", alreadySubscribedChannelOrChannelGroups)
		pub.sendClientSideErrorAboutSources(statusChannel, errorChannel, tp,
			alreadySubscribedChannelOrChannelGroups, responseAlreadySubscribed)
	}
	return alreadySubscribedChannelOrChannelGroups, alreadySubscribedChannelsLen, channelsOrGroupsModified
}

func (pub *Pubnub) getSubscribeLoopAction(channels, groups string,
	errorChannel chan<- []byte, statusChannel chan *PNStatus) subscribeLoopAction {

	pub.RLock()
	defer pub.RUnlock()

	newChannels := splitItems(channels)
	newGroups := splitItems(groups)
	alreadySubscribedChannels := []string{}
	alreadySubscribedChannelGroups := []string{}

	pub.RLock()
	existingChannelsEmpty := pub.channels.Empty()
	existingGroupsEmpty := pub.groups.Empty()
	pub.RUnlock()

	alreadySubscribedChannels, alreadySubscribedChannelsLen, channelsModified := pub.checkAlreadySubscribedChannelsOrChannelGroups(newChannels, errorChannel, statusChannel, false)
	alreadySubscribedChannelGroups, alreadySubscribedGroupsLen, groupsModified := pub.checkAlreadySubscribedChannelsOrChannelGroups(newGroups, errorChannel, statusChannel, true)

	modified := channelsModified || groupsModified
	existingEmpty := existingChannelsEmpty && existingGroupsEmpty
	alreadySubscribed := alreadySubscribedChannelsLen > 0 && alreadySubscribedGroupsLen > 0

	onlyAlreadySubscribed := alreadySubscribed &&
		(len(alreadySubscribedChannels) == len(newChannels) &&
			len(alreadySubscribedChannelGroups) == len(newGroups))

	var returnAction subscribeLoopAction

	if existingEmpty && modified {
		returnAction = subscribeLoopStart
	} else if modified && !alreadySubscribed {
		returnAction = subscribeLoopRestart
	} else if modified && alreadySubscribed && onlyAlreadySubscribed {
		returnAction = subscribeLoopDoNothing
	} else {
		returnAction = subscribeLoopDoNothing
	}

	pub.infoLogger.Printf("INFO: SUBSCRIPTION: Loop %s", returnAction)

	return returnAction
}

// ChannelGroupSubscribe subscribes to a channel group
func (pub *Pubnub) ChannelGroupSubscribe(groups string,
	callbackChannel chan<- []byte, errorChannel chan<- []byte) {
	pub.ChannelGroupSubscribeWithTimetoken(groups, "", callbackChannel,
		errorChannel)
}

// ChannelGroupSubscribeWithTimetoken subscribes to a channel group with a timetoken
func (pub *Pubnub) ChannelGroupSubscribeWithTimetoken(groups, timetoken string,
	callbackChannel chan<- []byte, errorChannel chan<- []byte) {
	pub.checkCallbackNil(callbackChannel, false, "ChanelGroupSubscribe")
	pub.checkCallbackNil(errorChannel, true, "ChanelGroupSubscribe")

	loopAction := pub.getSubscribeLoopAction("", groups, errorChannel, nil)

	timetokenIsZero := timetoken == "" || timetoken == "0"

	pub.Lock()
	var groupsArr = strings.Split(groups, ",")

	for _, u := range groupsArr {
		if timetokenIsZero {
			pub.groups.Add(u, callbackChannel, errorChannel, pub.infoLogger)
		} else {
			pub.groups.AddConnected(u, callbackChannel, errorChannel, pub.infoLogger)
		}
	}

	isPresenceHeartbeatRunning := pub.isPresenceHeartbeatRunning
	pub.Unlock()

	if hasNonPresenceChannels(groups) &&
		(!pub.channels.HasConnected() && !pub.groups.HasConnected() ||
			!isPresenceHeartbeatRunning) {
		go pub.runPresenceHeartbeat()
	}

	switch loopAction {
	case subscribeLoopStart:
		pub.Lock()
		if strings.TrimSpace(timetoken) != "" {
			pub.timeToken = timetoken
			pub.resetTimeToken = false
		} else {
			pub.resetTimeToken = true
		}
		pub.Unlock()

		go pub.startSubscribeLoop("", groups)
	case subscribeLoopRestart:
		pub.closeSubscribe()

		pub.Lock()
		if strings.TrimSpace(timetoken) != "" {
			pub.timeToken = timetoken
			pub.resetTimeToken = false
		} else {
			pub.resetTimeToken = true
		}

		pub.Unlock()
	case subscribeLoopDoNothing:
		// do nothing
	}
}

func (pub *Pubnub) addChannelsOrChannelGroups(channelOrChannelGroups string, isChannelGroup bool, timetoken string,
	statusChannel chan *PNStatus,
	messageChannel chan *PNMessageResult,
	presenceChannel chan *PNPresenceEventResult) {

	var channelOrChannelGroupsArr = strings.Split(channelOrChannelGroups, ",")
	timetokenIsZero := timetoken == "" || timetoken == "0"

	for _, u := range channelOrChannelGroupsArr {
		if len(u) > 0 {
			if timetokenIsZero {
				if isChannelGroup {
					pub.groups.AddV2(u, statusChannel, messageChannel, presenceChannel, pub.infoLogger)
				} else {
					pub.channels.AddV2(u, statusChannel, messageChannel, presenceChannel, pub.infoLogger)
				}
			} else {
				if isChannelGroup {
					pub.groups.AddConnectedV2(u, statusChannel, messageChannel, presenceChannel, pub.infoLogger)
				} else {
					pub.channels.AddConnectedV2(u, statusChannel, messageChannel, presenceChannel, pub.infoLogger)
				}
			}
		}
	}
}

func addPresenceChannels(channelOrChannelGroups string, withPresence bool) string {
	var chBuffer bytes.Buffer
	chBuffer.WriteString(channelOrChannelGroups)
	presenceChannels := ""

	if withPresence {
		presenceChannels = convertToPresenceChannel(channelOrChannelGroups)
		chBuffer.WriteString(",")
		chBuffer.WriteString(presenceChannels)
	}
	return chBuffer.String()
}

// SubscribeV2 is the struct Pubnub's instance method which checks for the pub.invalidChannelsV2
// and returns if true.
// Initaiates the presence and subscribe response channels.
//
// If there is no existing subscribe/presence loop running then it starts a
// new loop with the new pubnub channels.
// Else closes the existing connections and starts a new loop
//
// It accepts the following parameters:
// channels: comma separated pubnub channel list.
// channelGroups: comma separated pubnub channel list.
// timetoken: if timetoken is present the subscribe request is sent using this timetoken
// withPresence: if true subscribes to the presence channel(s)
// statusChannel: Channel to send the status
// messageChannel: Channel to send channel messages.
// presenceChannel: Channel to send presence messages.
func (pub *Pubnub) SubscribeV2(channels, channelGroups, timetoken string, withPresence bool,
	statusChannel chan *PNStatus,
	messageChannel chan *PNMessageResult,
	presenceChannel chan *PNPresenceEventResult) {

	if pub.invalidChannelV2(channels, statusChannel, false) && pub.invalidChannelV2(channelGroups, statusChannel, true) {
		message := "Either 'channel' or 'channel groups', or both should be provided."
		pub.infoLogger.Printf(message)
		status := createPNStatus(true, message, nil, 0, nil, nil)
		if statusChannel != nil {
			statusChannel <- status
		}
		return
	}

	pub.checkCallbackNilV2(statusChannel, messageChannel, presenceChannel, "SubscribeV2", withPresence)

	channels = addPresenceChannels(channels, withPresence)
	channelGroups = addPresenceChannels(channelGroups, withPresence)

	loopAction := pub.getSubscribeLoopAction(channels, channelGroups, nil, statusChannel)
	pub.infoLogger.Printf("in loopAction %s", loopAction)

	pub.Lock()
	pub.addChannelsOrChannelGroups(channels, false, timetoken, statusChannel, messageChannel, presenceChannel)
	pub.addChannelsOrChannelGroups(channelGroups, true, timetoken, statusChannel, messageChannel, presenceChannel)

	isPresenceHeartbeatRunning := pub.isPresenceHeartbeatRunning
	pub.Unlock()

	if (hasNonPresenceChannels(channelGroups) || hasNonPresenceChannels(channels)) &&
		(!pub.channels.HasConnected() && !pub.groups.HasConnected() ||
			!isPresenceHeartbeatRunning) {
		go pub.runPresenceHeartbeat()
	}

	switch loopAction {
	case subscribeLoopStart:
		pub.Lock()
		if strings.TrimSpace(timetoken) != "" {
			pub.timeToken = timetoken
			pub.resetTimeToken = false
		} else {
			pub.resetTimeToken = true
		}
		pub.Unlock()

		go pub.startSubscribeLoop(channels, channelGroups)
	case subscribeLoopRestart:
		pub.closeSubscribe()

		pub.Lock()
		if strings.TrimSpace(timetoken) != "" {
			pub.timeToken = timetoken
			pub.resetTimeToken = false
		} else {
			pub.resetTimeToken = true
		}

		pub.Unlock()
	case subscribeLoopDoNothing:
		// do nothing
	}
}

// Subscribe is the struct Pubnub's instance method which checks for the pub.invalidChannels
// and returns if true.
// Initaiates the presence and subscribe response channels.
//
// If there is no existing subscribe/presence loop running then it starts a
// new loop with the new pubnub channels.
// Else closes the existing connections and starts a new loop
//
// It accepts the following parameters:
// channels: comma separated pubnub channel list.
// timetoken: if timetoken is present the subscribe request is sent using this timetoken
// successChannel: Channel on which to send the success response back.
// errorChannel: channel to send an error response to.
// eventsChannel: Channel on which to send events like connect/disconnect/reconnect.
func (pub *Pubnub) Subscribe(channels, timetoken string,
	callbackChannel chan<- []byte, isPresence bool, errorChannel chan<- []byte) {

	if pub.invalidChannel(channels, callbackChannel) {
		return
	}

	pub.checkCallbackNil(callbackChannel, false, "Subscribe")
	pub.checkCallbackNil(errorChannel, true, "Subscribe")

	if isPresence {
		channels = convertToPresenceChannel(channels)
	}

	loopAction := pub.getSubscribeLoopAction(channels, "", errorChannel, nil)

	timetokenIsZero := timetoken == "" || timetoken == "0"

	pub.Lock()
	var channelArr = strings.Split(channels, ",")

	for _, u := range channelArr {
		if timetokenIsZero {
			pub.channels.Add(u, callbackChannel, errorChannel, pub.infoLogger)
		} else {
			pub.channels.AddConnected(u, callbackChannel, errorChannel, pub.infoLogger)
		}
	}

	isPresenceHeartbeatRunning := pub.isPresenceHeartbeatRunning
	pub.Unlock()

	if hasNonPresenceChannels(channels) &&
		(!pub.channels.HasConnected() && !pub.groups.HasConnected() ||
			!isPresenceHeartbeatRunning) {
		go pub.runPresenceHeartbeat()
	}

	switch loopAction {
	case subscribeLoopStart:
		pub.Lock()
		if strings.TrimSpace(timetoken) != "" {
			pub.timeToken = timetoken
			pub.resetTimeToken = false
		} else {
			pub.resetTimeToken = true
		}
		pub.Unlock()

		go pub.startSubscribeLoop(channels, "")
	case subscribeLoopRestart:
		pub.closeSubscribe()

		pub.Lock()
		if strings.TrimSpace(timetoken) != "" {
			pub.timeToken = timetoken
			pub.resetTimeToken = false
		} else {
			pub.resetTimeToken = true
		}

		pub.Unlock()
	case subscribeLoopDoNothing:
		// do nothing
	default:
		// do nothing
	}
}

func (pub *Pubnub) sleepForAWhile(retry bool) {
	if retry {
		retryCountMu.Lock()
		retryCount++
		retryCountMu.Unlock()
	}

	pub.subscribeSleeperMu.Lock()
	pub.subscribeAsleep = true
	shouldSubscribeSleep := pub.shouldSubscribeSleep
	pub.subscribeSleeperMu.Unlock()

	if shouldSubscribeSleep {
		select {
		case <-time.After(time.Duration(retryInterval) * time.Second):
		case <-pub.subscribeSleeper:
		}
	}

	pub.subscribeSleeperMu.Lock()
	pub.subscribeAsleep = false
	pub.subscribeSleeperMu.Unlock()
}

func (pub *Pubnub) sleepForAWhileRetry(retry bool) {
	if retry {
		retryCountMu.Lock()
		retryCount++
		retryCountMu.Unlock()
	}

	pub.retrySleeperMu.Lock()
	pub.retryAsleep = true
	shouldRetrySleep := pub.shouldRetrySleep
	pub.retrySleeperMu.Unlock()

	if shouldRetrySleep {
		select {
		case <-time.After(time.Duration(retryInterval) * time.Second):
		case <-pub.retrySleeper:
		}
	}

	pub.retrySleeperMu.Lock()
	pub.retryAsleep = false
	pub.retrySleeperMu.Unlock()
}

func (pub *Pubnub) closeSubscribe() {
	pub.requestCloserMu.Lock()
	defer pub.requestCloserMu.Unlock()

	pub.subscribeWorker.CancelToResubscribe()
}

func (pub *Pubnub) wakeUpSubscribe() {
	pub.subscribeSleeperMu.Lock()
	defer pub.subscribeSleeperMu.Unlock()

	pub.shouldSubscribeSleep = false
	if pub.subscribeAsleep {
		pub.subscribeSleeper <- struct{}{}
	}
}

func (pub *Pubnub) wakeUpRetry() {
	pub.retrySleeperMu.Lock()
	defer pub.retrySleeperMu.Unlock()

	if pub.retryAsleep {
		pub.subscribeSleeper <- struct{}{}
		pub.shouldRetrySleep = false
	}
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
func (pub *Pubnub) Unsubscribe(channels string, callbackChannel, errorChannel chan []byte) {

	pub.checkCallbackNil(callbackChannel, false, "Unsubscribe")
	pub.checkCallbackNil(errorChannel, true, "Unsubscribe")

	channelArray := strings.Split(channels, ",")
	unsubscribeChannels := ""
	channelRemoved := false

	for i := 0; i < len(channelArray); i++ {
		if i > 0 {
			unsubscribeChannels += ","
		}

		channelToUnsub := strings.TrimSpace(channelArray[i])

		if pub.channels.Exist(channelToUnsub) {
			pub.sendConnectionEventTo(callbackChannel, channelToUnsub, channelResponse,
				connectionUnsubscribed)

			pub.Lock()
			pub.channels.Remove(channelToUnsub, pub.infoLogger)
			pub.Unlock()

			unsubscribeChannels += channelToUnsub
			channelRemoved = true
		} else {
			pub.sendClientSideErrorAboutSources(nil, errorChannel, channelResponse,
				splitItems(channelToUnsub), responseNotSubscribed)
		}
	}

	if channelRemoved {
		if strings.TrimSpace(unsubscribeChannels) != "" {
			go pub.closeSubscribe()
			go pub.wakeUpSubscribe()
			go pub.wakeUpRetry()

			value, statusCode, err := pub.sendLeaveRequest(unsubscribeChannels, "")
			if err != nil {
				pub.infoLogger.Printf("ERROR: %s", err.Error())

				pub.sendErrorResponse(errorChannel, unsubscribeChannels, err.Error())
			} else if statusCode != 200 {
				errorString := string(value)

				pub.infoLogger.Printf("ERROR: %s", errorString)

				pub.sendErrorResponse(errorChannel, unsubscribeChannels, errorString)
			} else {
				pub.sendSuccessResponseToChannel(callbackChannel, unsubscribeChannels, string(value))
			}
		}
	}
}

// ChannelGroupUnsubscribe unsubscribes from a channel group
func (pub *Pubnub) ChannelGroupUnsubscribe(groups string, callbackChannel,
	errorChannel chan []byte) {

	pub.checkCallbackNil(callbackChannel, false, "ChannelGroupUnsubscribe")
	pub.checkCallbackNil(errorChannel, true, "ChannelGroupUnsubscribe")

	groupsArray := strings.Split(groups, ",")
	unsubscribeGroups := ""
	groupRemoved := false

	for i := 0; i < len(groupsArray); i++ {
		if i > 0 {
			unsubscribeGroups += ","
		}

		groupToUnsub := strings.TrimSpace(groupsArray[i])

		if pub.groups.Exist(groupToUnsub) {
			pub.sendConnectionEventTo(callbackChannel, groupToUnsub, channelGroupResponse,
				connectionUnsubscribed)

			pub.Lock()
			pub.groups.Remove(groupToUnsub, pub.infoLogger)
			pub.Unlock()

			unsubscribeGroups += groupToUnsub
			groupRemoved = true
		} else {
			pub.sendClientSideErrorAboutSources(nil, errorChannel, channelGroupResponse,
				splitItems(groupToUnsub), responseNotSubscribed)
		}
	}

	if groupRemoved {
		if strings.TrimSpace(unsubscribeGroups) != "" {
			go pub.closeSubscribe()
			go pub.wakeUpSubscribe()
			go pub.wakeUpRetry()

			value, statusCode, err := pub.sendLeaveRequest("", unsubscribeGroups)
			if err != nil {
				pub.infoLogger.Printf("ERROR: %s", err.Error())

				pub.sendErrorResponse(errorChannel, unsubscribeGroups, err.Error())
			} else if statusCode != 200 {
				errorString := string(value)

				pub.infoLogger.Printf("ERROR: %s", errorString)

				pub.sendErrorResponse(errorChannel, unsubscribeGroups, errorString)
			} else {
				pub.sendSuccessResponseToChannel(callbackChannel, unsubscribeGroups, string(value))
			}
		}
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
func (pub *Pubnub) PresenceUnsubscribe(channels string, callbackChannel,
	errorChannel chan []byte) {

	pub.Unsubscribe(addPnpresToString(channels), callbackChannel,
		errorChannel)
}

// sendLeaveRequest: Sends a leave request to the origin
//
// It accepts the following parameters:
// channels: Channels to leave
// groups: Channel Groups to leave
//
// returns:
// the HttpRequest response contents as byte array.
// response error code,
// error if any.
func (pub *Pubnub) sendLeaveRequest(channels, groups string) ([]byte, int, error) {
	var subscribeURLBuffer bytes.Buffer
	subscribeURLBuffer.WriteString("/v2/presence")
	subscribeURLBuffer.WriteString("/sub-key/")
	subscribeURLBuffer.WriteString(pub.subscribeKey)
	subscribeURLBuffer.WriteString("/channel/")

	if len(channels) > 0 {
		subscribeURLBuffer.WriteString(queryEscapeMultiple(channels, ","))
	} else {
		subscribeURLBuffer.WriteString(",")
	}

	subscribeURLBuffer.WriteString("/leave")
	requestURL := subscribeURLBuffer.String()
	subscribeURLBuffer.WriteString("?uuid=")
	subscribeURLBuffer.WriteString(pub.GetUUID())

	if len(groups) > 0 {
		subscribeURLBuffer.WriteString("&channel-group=")
		subscribeURLBuffer.WriteString(queryEscapeMultiple(groups, ","))
	}

	subscribeURLBuffer.WriteString(pub.addAuthParam(true))
	presenceHeartbeatMu.RLock()
	if presenceHeartbeat > 0 {
		subscribeURLBuffer.WriteString("&heartbeat=")
		subscribeURLBuffer.WriteString(strconv.Itoa(int(presenceHeartbeat)))
	}
	presenceHeartbeatMu.RUnlock()
	subscribeURLBuffer.WriteString("&")
	subscribeURLBuffer.WriteString(sdkIdentificationParam)

	subscribeUrl := pub.checkSecretKeyAndAddSignature(subscribeURLBuffer.String(), requestURL)

	return pub.httpRequest(subscribeUrl, nonSubscribeTrans)
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
// includeToken: to receive a timetoken for each history message
// callbackChannel on which to send the response.
// errorChannel on which the error response is sent.
//
// Both callbackChannel and errorChannel are mandatory. If either is nil the code will panic
func (pub *Pubnub) History(channel string, limit int, start, end int64,
	reverse, includeToken bool, callbackChannel, errorChannel chan []byte) {
	pub.checkCallbackNil(callbackChannel, false, "History")
	pub.checkCallbackNil(errorChannel, true, "History")

	pub.executeHistory(channel, limit, start, end, reverse, includeToken,
		callbackChannel, errorChannel, 0)
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
// includeToken: to receive a timetoken for each history message
// callbackChannel on which to send the response.
// errorChannel on which the error response is sent.
// retryCount to track the retry logic.
func (pub *Pubnub) executeHistory(channel string, limit int, start, end int64,
	reverse, includeToken bool, callbackChannel, errorChannel chan []byte,
	retryCount int) {

	count := retryCount
	if pub.invalidChannel(channel, callbackChannel) {
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

	parameters.WriteString("&include_token=")
	if includeToken == true {
		parameters.WriteString("true")
	} else {
		parameters.WriteString("false")
	}

	parameters.WriteString(pub.addAuthParam(true))

	var historyURLBuffer bytes.Buffer
	historyURLBuffer.WriteString("/v2/history")
	historyURLBuffer.WriteString("/sub-key/")
	historyURLBuffer.WriteString(pub.subscribeKey)
	historyURLBuffer.WriteString("/channel/")
	historyURLBuffer.WriteString(url.QueryEscape(channel))
	requestURL := historyURLBuffer.String()
	historyURLBuffer.WriteString("?count=")
	historyURLBuffer.WriteString(fmt.Sprintf("%d", limit))
	historyURLBuffer.WriteString(parameters.String())
	historyURLBuffer.WriteString("&")
	historyURLBuffer.WriteString(sdkIdentificationParam)
	historyURLBuffer.WriteString("&uuid=")
	historyURLBuffer.WriteString(pub.GetUUID())

	historyURL := pub.checkSecretKeyAndAddSignature(historyURLBuffer.String(), requestURL)

	value, responseCode, err := pub.httpRequest(historyURL, nonSubscribeTrans)

	if err != nil {
		pub.infoLogger.Printf("ERROR: %s", err.Error())
		pub.sendErrorResponse(errorChannel, channel, err.Error())
	} else if responseCode != 200 {
		message := fmt.Sprintf("%s", value)
		pub.infoLogger.Printf("ERROR: History Error: responseCode %d, message %s", responseCode, message)
		pub.sendErrorResponse(errorChannel, channel, message)
	} else {
		pub.infoLogger.Printf("INFO: %s", string(value))
		data, returnOne, returnTwo, errJSON := pub.ParseJSON(value, pub.cipherKey)
		pub.infoLogger.Printf("INFO: %s\n%s\n%s", data, returnOne, returnTwo)
		if errJSON != nil && strings.Contains(errJSON.Error(), invalidJSON) {
			pub.infoLogger.Printf("ERROR: %s", errJSON.Error())
			pub.sendErrorResponse(errorChannel, channel, errJSON.Error())
			if count < maxRetries {
				count++
				pub.executeHistory(channel, limit, start, end, reverse, includeToken,
					callbackChannel, errorChannel, count)
			}
		} else {
			var buffer bytes.Buffer
			buffer.WriteString("[")
			buffer.WriteString(data)
			buffer.WriteString(",\"" + returnOne + "\",\"" + returnTwo + "\"]")

			callbackChannel <- buffer.Bytes()
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
	pub.checkCallbackNil(callbackChannel, false, "WhereNow")
	pub.checkCallbackNil(errorChannel, true, "WhereNow")

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

	var whereNowURLBuffer bytes.Buffer
	whereNowURLBuffer.WriteString("/v2/presence")
	whereNowURLBuffer.WriteString("/sub-key/")
	whereNowURLBuffer.WriteString(pub.subscribeKey)
	whereNowURLBuffer.WriteString("/uuid/")
	if strings.TrimSpace(uuid) == "" {
		uuid = pub.GetUUID()
	} else {
		uuid = url.QueryEscape(uuid)
	}
	whereNowURLBuffer.WriteString(uuid)
	requestURL := whereNowURLBuffer.String()
	whereNowURLBuffer.WriteString("?")
	whereNowURLBuffer.WriteString(sdkIdentificationParam)
	whereNowURLBuffer.WriteString("&uuid=")
	whereNowURLBuffer.WriteString(pub.GetUUID())

	whereNowURLBuffer.WriteString(pub.addAuthParam(true))

	whereNowURL := pub.checkSecretKeyAndAddSignature(whereNowURLBuffer.String(), requestURL)

	value, responseCode, err := pub.httpRequest(whereNowURL, nonSubscribeTrans)

	if err != nil {
		pub.infoLogger.Printf("ERROR: WHERE NOW: Connection error: %s", err.Error())
		pub.sendErrorResponse(errorChannel, uuid, err.Error())
	} else if responseCode != 200 {
		message := fmt.Sprintf("%s", value)
		pub.infoLogger.Printf("ERROR: Where Now Error: responseCode %d, message %s", responseCode, message)
		pub.sendErrorResponse(errorChannel, uuid, message)
	} else {
		_, _, _, errJSON := pub.ParseJSON(value, pub.cipherKey)
		if errJSON != nil && strings.Contains(errJSON.Error(), invalidJSON) {
			pub.infoLogger.Printf("ERROR: WHERE NOW: JSON parsing error: %s", errJSON.Error())
			pub.sendErrorResponse(errorChannel, uuid, errJSON.Error())
			if count < maxRetries {
				count++
				pub.executeWhereNow(uuid, callbackChannel, errorChannel, count)
			}
		} else {
			callbackChannel <- value
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
	pub.checkCallbackNil(callbackChannel, false, "GlobalHereNow")
	pub.checkCallbackNil(errorChannel, true, "GlobalHereNow")

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

	var hereNowURLBuffer bytes.Buffer
	hereNowURLBuffer.WriteString("/v2/presence")
	hereNowURLBuffer.WriteString("/sub-key/")
	hereNowURLBuffer.WriteString(pub.subscribeKey)

	requestURL := hereNowURLBuffer.String()

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

	hereNowURLBuffer.WriteString(params.String())

	hereNowURLBuffer.WriteString(pub.addAuthParam(true))
	hereNowURLBuffer.WriteString("&")
	hereNowURLBuffer.WriteString(sdkIdentificationParam)
	hereNowURLBuffer.WriteString("&uuid=")
	hereNowURLBuffer.WriteString(pub.GetUUID())

	hereNowURL := pub.checkSecretKeyAndAddSignature(hereNowURLBuffer.String(), requestURL)

	value, responseCode, err := pub.httpRequest(hereNowURL, nonSubscribeTrans)

	if err != nil {
		pub.infoLogger.Printf("ERROR: %s", err.Error())
		pub.sendErrorResponseSimplified(errorChannel, err.Error())
	} else if responseCode != 200 {
		message := fmt.Sprintf("%s", value)
		pub.infoLogger.Printf("ERROR: Global here Now Error: responseCode %d, message %s", responseCode, message)
		pub.sendErrorResponseSimplified(errorChannel, message)
	} else {
		_, _, _, errJSON := pub.ParseJSON(value, pub.cipherKey)
		if errJSON != nil && strings.Contains(errJSON.Error(), invalidJSON) {
			pub.infoLogger.Printf("ERROR: %s", errJSON.Error())
			pub.sendErrorResponseSimplified(errorChannel, errJSON.Error())
			if count < maxRetries {
				count++
				pub.executeGlobalHereNow(showUuid, includeUserState, callbackChannel, errorChannel, count)
			}
		} else {
			callbackChannel <- value
		}
	}
}

// HereNow is the struct Pubnub's instance method which creates and posts the herenow
// request to get the connected users details.
//
// It accepts the following parameters:
// channel: a single channel or a channels list.
// channelGroup group: a single channel group or a channel groups list.
// callbackChannel on which to send the response.
// errorChannel on which the error response is sent.
//
// Both callbackChannel and errorChannel are mandatory. If either is nil the code will panic
func (pub *Pubnub) HereNow(channel, channelGroup string,
	showUuid, includeUserState bool, callbackChannel, errorChannel chan []byte) {

	pub.checkCallbackNil(callbackChannel, false, "HereNow")
	pub.checkCallbackNil(errorChannel, true, "HereNow")

	pub.executeHereNow(channel, channelGroup, showUuid, includeUserState, callbackChannel, errorChannel, 0)
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
func (pub *Pubnub) executeHereNow(channel, channelGroup string, showUuid,
	includeUserState bool, callbackChannel, errorChannel chan []byte, retryCount int) {
	count := retryCount

	if pub.invalidChannel(channel, callbackChannel) {
		return
	}

	var hereNowURLBuffer bytes.Buffer
	hereNowURLBuffer.WriteString("/v2/presence")
	hereNowURLBuffer.WriteString("/sub-key/")
	hereNowURLBuffer.WriteString(pub.subscribeKey)
	hereNowURLBuffer.WriteString("/channel/")
	hereNowURLBuffer.WriteString(url.QueryEscape(channel))

	requestURL := hereNowURLBuffer.String()

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

	hereNowURLBuffer.WriteString(params.String())

	hereNowURLBuffer.WriteString(pub.addAuthParam(true))

	if len(channelGroup) > 0 {
		hereNowURLBuffer.WriteString("&channel-group=")
		hereNowURLBuffer.WriteString(url.QueryEscape(channelGroup))
	}

	hereNowURLBuffer.WriteString("&")
	hereNowURLBuffer.WriteString(sdkIdentificationParam)
	hereNowURLBuffer.WriteString("&uuid=")
	hereNowURLBuffer.WriteString(pub.GetUUID())

	hereNowURL := pub.checkSecretKeyAndAddSignature(hereNowURLBuffer.String(), requestURL)

	value, responseCode, err := pub.httpRequest(hereNowURL, nonSubscribeTrans)

	if err != nil {
		pub.infoLogger.Printf("ERROR: %s", err.Error())
		pub.sendErrorResponse(errorChannel, channel, err.Error())
	} else if responseCode != 200 {
		message := fmt.Sprintf("%s", value)
		pub.infoLogger.Printf("ERROR: Here now Error: responseCode %d, message %s", responseCode, message)
		pub.sendErrorResponse(errorChannel, channel, message)
	} else {
		_, _, _, errJSON := pub.ParseJSON(value, pub.cipherKey)
		if errJSON != nil && strings.Contains(errJSON.Error(), invalidJSON) {
			pub.infoLogger.Printf("ERROR: %s", errJSON.Error())
			pub.sendErrorResponse(errorChannel, channel, errJSON.Error())
			if count < maxRetries {
				count++
				pub.executeHereNow(channel, channelGroup, showUuid, includeUserState,
					callbackChannel, errorChannel, count)
			}
		} else {
			callbackChannel <- value
		}
	}
}

// GetUserState is the struct Pubnub's instance method which creates and posts the GetUserState
// request to get the connected users details.
//
// It accepts the following parameters:
// channel: a single value of the pubnub channel.
// uuid: uuid of user to get state on or an empty string.
// callbackChannel on which to send the response.
// errorChannel on which the error response is sent.
//
// Both callbackChannel and errorChannel are mandatory. If either is nil the code will panic
func (pub *Pubnub) GetUserState(channel, uuid string,
	callbackChannel, errorChannel chan []byte) {

	pub.checkCallbackNil(callbackChannel, false, "GetUserState")
	pub.checkCallbackNil(errorChannel, true, "GetUserState")

	pub.executeGetUserState(channel, uuid, callbackChannel, errorChannel, 0)
}

// executeGetUserState  is the struct Pubnub's instance method that creates a executeGetUserState request and sends back the
// response to the channel.
//
// In case we get an invalid json response the routine retries till the _maxRetries to get a valid
// response.
//
// channel
// uuid: uuid of user to get state on or an empty string.
// callbackChannel on which to send the response.
// errorChannel on which the error response is sent.
// retryCount to track the retry logic.
func (pub *Pubnub) executeGetUserState(channel, uuid string,
	callbackChannel, errorChannel chan []byte, retryCount int) {

	count := retryCount

	if uuid == "" {
		uuid = pub.GetUUID()
	}

	var userStateURLBuffer bytes.Buffer
	userStateURLBuffer.WriteString("/v2/presence")
	userStateURLBuffer.WriteString("/sub-key/")
	userStateURLBuffer.WriteString(pub.subscribeKey)
	userStateURLBuffer.WriteString("/channel/")
	userStateURLBuffer.WriteString(url.QueryEscape(channel))
	userStateURLBuffer.WriteString("/uuid/")
	userStateURLBuffer.WriteString(uuid)
	requestURL := userStateURLBuffer.String()
	userStateURLBuffer.WriteString("?")
	userStateURLBuffer.WriteString(sdkIdentificationParam)
	userStateURLBuffer.WriteString("&uuid=")
	userStateURLBuffer.WriteString(pub.GetUUID())

	userStateURLBuffer.WriteString(pub.addAuthParam(true))

	userStateURL := pub.checkSecretKeyAndAddSignature(userStateURLBuffer.String(), requestURL)

	value, responseCode, err := pub.httpRequest(userStateURL, nonSubscribeTrans)

	if err != nil {
		pub.infoLogger.Printf("ERROR: %s", err.Error())
		pub.sendErrorResponse(errorChannel, channel, err.Error())
	} else if responseCode != 200 {
		message := fmt.Sprintf("%s", value)
		pub.infoLogger.Printf("ERROR: Get User state Error: responseCode %d, message %s", responseCode, message)
		pub.sendErrorResponse(errorChannel, channel, message)
	} else {
		_, _, _, errJSON := pub.ParseJSON(value, pub.cipherKey)
		if errJSON != nil && strings.Contains(errJSON.Error(), invalidJSON) {
			pub.infoLogger.Printf("ERROR: %s", errJSON.Error())
			pub.sendErrorResponse(errorChannel, channel, errJSON.Error())
			if count < maxRetries {
				count++
				pub.executeGetUserState(channel, uuid, callbackChannel, errorChannel, count)
			}
		} else {
			callbackChannel <- value
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
func (pub *Pubnub) SetUserStateKeyVal(channel, key, val string,
	callbackChannel, errorChannel chan []byte) {

	pub.checkCallbackNil(callbackChannel, false, "SetUserState")
	pub.checkCallbackNil(errorChannel, true, "SetUserState")

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

	jsonSerialized, err := json.Marshal(pub.userState[channel])
	if len(pub.userState[channel]) <= 0 {
		delete(pub.userState, channel)
	}

	if err != nil {
		pub.infoLogger.Printf("ERROR: SetUserStateKeyVal err: %s", err.Error())
		pub.sendErrorResponseExtended(errorChannel, channel, invalidUserStateMap, err.Error())
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
func (pub *Pubnub) SetUserStateJSON(channel, jsonString string,
	callbackChannel, errorChannel chan []byte) {

	pub.checkCallbackNil(callbackChannel, false, "SetUserState")
	pub.checkCallbackNil(errorChannel, true, "SetUserState")
	var s interface{}
	err := json.Unmarshal([]byte(jsonString), &s)
	if err != nil {
		pub.sendErrorResponseExtended(errorChannel, channel, invalidUserStateMap, err.Error())
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
func (pub *Pubnub) executeSetUserState(channel, jsonState string,
	callbackChannel, errorChannel chan []byte, retryCount int) {

	count := retryCount

	uuid := pub.GetUUID()

	var userStateURLBuffer bytes.Buffer
	userStateURLBuffer.WriteString("/v2/presence")
	userStateURLBuffer.WriteString("/sub-key/")
	userStateURLBuffer.WriteString(pub.subscribeKey)
	userStateURLBuffer.WriteString("/channel/")
	userStateURLBuffer.WriteString(url.QueryEscape(channel))
	userStateURLBuffer.WriteString("/uuid/")
	userStateURLBuffer.WriteString(uuid)
	userStateURLBuffer.WriteString("/data")
	requestURL := userStateURLBuffer.String()
	userStateURLBuffer.WriteString("?state=")
	userStateURLBuffer.WriteString(url.QueryEscape(jsonState))

	userStateURLBuffer.WriteString(pub.addAuthParam(true))

	userStateURLBuffer.WriteString("&")
	userStateURLBuffer.WriteString(sdkIdentificationParam)
	userStateURLBuffer.WriteString("&uuid=")
	userStateURLBuffer.WriteString(pub.GetUUID())

	userStateURL := pub.checkSecretKeyAndAddSignature(userStateURLBuffer.String(), requestURL)

	value, responseCode, err := pub.httpRequest(userStateURL, nonSubscribeTrans)

	if err != nil {
		pub.infoLogger.Printf("ERROR: %s", err.Error())
		pub.sendErrorResponse(errorChannel, channel, err.Error())
	} else if responseCode != 200 {
		message := fmt.Sprintf("%s", value)
		pub.infoLogger.Printf("ERROR: Set User state Error: responseCode %d, message %s", responseCode, message)
		pub.sendErrorResponse(errorChannel, channel, message)
	} else {
		_, _, _, errJSON := pub.ParseJSON(value, pub.cipherKey)
		if errJSON != nil && strings.Contains(errJSON.Error(), invalidJSON) {
			pub.infoLogger.Printf("ERROR: %s", errJSON.Error())
			pub.sendErrorResponse(errorChannel, channel, errJSON.Error())
			if count < maxRetries {
				count++
				pub.executeSetUserState(channel, jsonState, callbackChannel,
					errorChannel, count)
			}
		} else {
			callbackChannel <- value
			pub.closeSubscribe()
		}
	}
}

// ChannelGroupAddChannel adds channel to a channel group
func (pub *Pubnub) ChannelGroupAddChannel(group, channel string,
	callbackChannel, errorChannel chan []byte) {
	pub.checkCallbackNil(callbackChannel, false, "ChannelGroupAddChannel")
	pub.checkCallbackNil(errorChannel, true, "ChannelGroupAddChannel")

	pub.executeChannelGroup("add", group, channel, callbackChannel, errorChannel)
}

// ChannelGroupRemoveChannel removes channel from a channel group
func (pub *Pubnub) ChannelGroupRemoveChannel(group, channel string,
	callbackChannel, errorChannel chan []byte) {
	pub.checkCallbackNil(callbackChannel, false, "ChannelGroupRemoveChannel")
	pub.checkCallbackNil(errorChannel, true, "ChannelGroupRemoveChannel")

	pub.executeChannelGroup("remove", group, channel, callbackChannel, errorChannel)
}

// ChannelGroupListChannels lists channels of a channel group
func (pub *Pubnub) ChannelGroupListChannels(group string,
	callbackChannel, errorChannel chan []byte) {
	pub.checkCallbackNil(callbackChannel, false, "ChannelGroupListChannels")
	pub.checkCallbackNil(errorChannel, true, "ChannelGroupListChannels")

	pub.executeChannelGroup("list_group", group, "", callbackChannel, errorChannel)
}

// ChannelGroupRemoveGroup removes channels from a channel group
func (pub *Pubnub) ChannelGroupRemoveGroup(group string,
	callbackChannel, errorChannel chan []byte) {
	pub.checkCallbackNil(callbackChannel, false, "ChannelGroupRemoveGroup")
	pub.checkCallbackNil(errorChannel, true, "ChannelGroupRemoveGroup")

	pub.executeChannelGroup("remove_group", group, "", callbackChannel, errorChannel)
}

func (pub *Pubnub) generateStringforCGRequest(action, group,
	channel string) (requestURL bytes.Buffer) {
	params := url.Values{}

	requestURL.WriteString("/v1/channel-registration")
	requestURL.WriteString("/sub-key/")
	requestURL.WriteString(pub.subscribeKey)
	requestURL.WriteString("/channel-group/")
	requestURL.WriteString(group)

	switch action {
	case "add":
		fallthrough
	case "remove":
		params.Add(action, channel)
	case "remove_group":
		requestURL.WriteString("/remove")
	}

	requestURLForSig := requestURL.String()

	if strings.TrimSpace(pub.authenticationKey) != "" {
		params.Set("auth", pub.authenticationKey)
	}

	params.Set("uuid", pub.GetUUID())
	params.Set(sdkIdentificationParamKey, sdkIdentificationParamVal)

	requestURL.WriteString("?")
	requestURL.WriteString(params.Encode())

	requestURLWithSig := pub.checkSecretKeyAndAddSignature(requestURL.String(), requestURLForSig)
	requestURL.Reset()
	requestURL.WriteString(requestURLWithSig)

	return requestURL
}

func (pub *Pubnub) executeChannelGroup(action, group, channel string,
	callbackChannel, errorChannel chan []byte) {

	requestURL := pub.generateStringforCGRequest(action, group, channel)

	value, responseCode, err := pub.httpRequest(requestURL.String(), nonSubscribeTrans)

	if err != nil {
		pub.infoLogger.Printf("ERROR: %s", err.Error())
		pub.sendErrorResponse(errorChannel, group, err.Error())
	} else if responseCode != 200 {
		message := fmt.Sprintf("%s", value)
		pub.infoLogger.Printf("ERROR: CG Error: responseCode %d, message %s", responseCode, message)
		pub.sendErrorResponse(errorChannel, group, message)
	} else {
		_, _, _, errJSON := pub.ParseJSON(value, pub.cipherKey)
		if errJSON != nil && strings.Contains(errJSON.Error(), invalidJSON) {
			pub.infoLogger.Printf("ERROR: %s", errJSON.Error())
			pub.sendErrorResponse(errorChannel, group, errJSON.Error())
		} else {
			callbackChannel <- value
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
func (pub *Pubnub) getData(rawData interface{}, cipherKey string) string {
	dataInterface := rawData.(interface{})
	switch vv := dataInterface.(type) {
	case string:
		jsonData, err := json.Marshal(fmt.Sprintf("%s", vv[0]))
		if err == nil {
			pub.infoLogger.Printf("INFO: returning jsonData %s", jsonData)
			return string(jsonData)
		}
		pub.infoLogger.Printf("ERROR: %s", err.Error())
		return fmt.Sprintf("%s", vv[0])
	case []interface{}:
		retval := pub.parseInterface(vv, cipherKey)
		if retval != "" {
			pub.infoLogger.Printf("INFO: returning []interface, %s", retval)
			return retval
		}
	}
	pub.infoLogger.Printf("INFO: returning rawdata, %s", rawData)
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
func (pub *Pubnub) parseInterface(vv []interface{}, cipherKey string) string {
	for i, u := range vv {
		if reflect.TypeOf(u).Kind() == reflect.String {
			var intf interface{}

			if cipherKey != "" {
				intf = pub.parseCipherInterface(u, cipherKey)
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
					pub.infoLogger.Printf("ERROR: unescape :%s", unescapeErr.Error())

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
		pub.infoLogger.Printf("ERROR: parseInterface: %s", err.Error())

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
func (pub *Pubnub) parseCipherInterface(data interface{}, cipherKey string) interface{} {
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
func (pub *Pubnub) ParseJSON(contents []byte,
	cipherKey string) (string, string, string, error) {

	var s interface{}

	returnData := ""
	returnOne := ""
	returnTwo := ""

	err := json.Unmarshal(contents, &s)

	if err == nil {
		v := s.(interface{})
		pub.infoLogger.Printf("ERROR:  v: %s", v)
		switch vv := v.(type) {
		case string:
			length := len(vv)
			if length > 0 {
				returnData = vv
			}
		case []interface{}:
			length := len(vv)
			if length > 0 {
				returnData = pub.getData(vv[0], cipherKey)
			}
			if length > 1 {
				returnOne = pub.ParseInterfaceData(vv[1])
			}
			if length > 2 {
				returnTwo = pub.ParseInterfaceData(vv[2])
			}
		}
	} else {
		pub.infoLogger.Printf("ERROR: JSON PARSER: Bad JSON: %s", contents)
		err = fmt.Errorf(invalidJSON)
	}
	return returnData, returnOne, returnTwo, err
}

// ParseSubscribeResponse extracts the actual data (value 0),
// Timetoken/from time in case of detailed history (value 1),
// pubnub channelname/timetoken/to time in case of detailed history (value 2).
func (pub *Pubnub) ParseSubscribeResponse(rawResponse []byte, cipherKey string) (
	subEnv subscribeEnvelope, timetoken, region string, err error) {

	res := subscribeEnvelope{}
	if err := json.Unmarshal(rawResponse, &res); err != nil {
		pub.infoLogger.Printf("ERROR: Invalid JSON:%s, err %s", string(rawResponse), err.Error())
	} else {
		pub.infoLogger.Printf("INFO: res.Messages count, %d", len(res.Messages))
		pub.infoLogger.Printf("INFO: TimetokenMeta Region, %d", res.TimetokenMeta.Region)
		pub.infoLogger.Printf("INFO: TimetokenMeta Timestamp: %s", res.TimetokenMeta.Timetoken)
		timetoken = string(res.TimetokenMeta.Timetoken)
		region = strconv.Itoa(res.TimetokenMeta.Region)

	}
	return res, timetoken, region, err
}

// ParseInterfaceData formats the data to string as per the type of the data.
//
// It accepts the following parameters:
// myInterface: the interface data to parse and convert to string.
//
// returns: the data in string format.
func (pub *Pubnub) ParseInterfaceData(myInterface interface{}) string {
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
// tType: transport type
//
// returns:
// the response contents as byte array.
// response error code if any.
// error if any.
func (pub *Pubnub) httpRequest(requestURL string, tType transportType) (
	[]byte, int, error) {

	contents, responseStatusCode, err := pub.connect(tType, requestURL)

	if err != nil {
		if strings.Contains(err.Error(), timeout) {
			return nil, responseStatusCode, fmt.Errorf(operationTimeout)
		} else if strings.Contains(fmt.Sprintf("%s", err.Error()), closedNetworkConnection) {
			return nil, responseStatusCode, fmt.Errorf(connectionAborted)
			// Connection canceled supported since go1.5
		} else if strings.Contains(fmt.Sprintf("%s", err.Error()), requestCanceled) {
			return nil, responseStatusCode, fmt.Errorf(connectionCanceled)
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

func (pub *Pubnub) validateRequestAndAddHeaders(requestURL string) (*http.Request, error) {
	reqURL := pub.origin + requestURL

	req, err := http.NewRequest("GET", reqURL, nil)
	if err != nil {
		pub.infoLogger.Printf("ERROR: HTTP REQUEST: Error while creating request: %s", err.Error())
		return nil, err
	}

	scheme := "http"
	if pub.isSSL {
		scheme = "https"
	}

	req.URL = &url.URL{
		Scheme: scheme,
		Host:   origin,
		Opaque: fmt.Sprintf("//%s%s", origin, requestURL),
	}

	useragent := fmt.Sprintf("ua_string=(%s) PubNub-Go/%s", runtime.GOOS,
		SDK_VERSION)

	req.Header.Set("User-Agent", useragent)
	return req, nil
}

func (pub *Pubnub) nonSubHTTPRequest(requestURL string) (
	[]byte, int, error) {

	req, errReq := pub.validateRequestAndAddHeaders(requestURL)
	if errReq != nil {
		return nil, 0, errReq
	}

	pub.infoLogger.Printf("INFO: nonSubHTTPRequest calling nonSubHTTPClient.do%s", requestURL)
	response, err := pub.nonSubHTTPClient.Do(req)
	if err != nil && response == nil {
		pub.infoLogger.Printf("ERROR: NonSub HTTP REQUEST: Error while sending request: %s", err.Error())
		return nil, 0, err
	}

	//defer
	body, err := ioutil.ReadAll(response.Body)
	pub.infoLogger.Printf("INFO: nonSubHTTPRequest readall %s", requestURL)
	if err != nil {
		pub.infoLogger.Printf("ERROR: NonSub HTTP REQUEST: Error while parsing body: %+v", err.Error())
		response.Body.Close()
		return nil, response.StatusCode, err
	}
	io.Copy(ioutil.Discard, response.Body)

	response.Body.Close()
	return body, response.StatusCode, nil
}

// connect creates a http request to the pubnub origin and returns the
// response or the error while connecting.
//
// It accepts the following parameters:
// requestUrl: the url to connect to.
// tType: transport type

// returns:
// the response as byte array.
// response errorcode if any.
// error if any.
// TODO: merge with httpRequest function
func (pub *Pubnub) connect(tType transportType,
	opaqueURL string) ([]byte, int, error) {

	req, errReq := pub.validateRequestAndAddHeaders(opaqueURL)
	if errReq != nil {
		return nil, 0, errReq
	}

	switch tType {
	case subscribeTrans:
		pub.requestCloserMu.RLock()
		// req.Cancel = pub.requestCloser
		pub.currentSubscribeReq = req
		pub.requestCloserMu.RUnlock()

		defer func() {
			pub.requestCloserMu.Lock()
			// pub.requestCloser = nil
			pub.currentSubscribeReq = nil
			pub.requestCloserMu.Unlock()
		}()

		return pub.subscribeWorker.Handle(req)
	case nonSubscribeTrans:
		return pub.nonSubscribeWorker.Handle(req)
	case retryTrans:
		return pub.retryWorker.Handle(req)
	case presenceHeartbeatTrans:
		return pub.presenceHeartbeatWorker.Handle(req)
	default:
		return nil, 0, errors.New("HTTP REQUEST: Wrong transport type")
	}
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
	encodedString := bytes.NewBuffer(make([]byte, 0, lenOfRune))
	for i := 0; i < lenOfRune; i++ {
		intOfRune := uint16(runeOfMessage[i])
		if intOfRune > 127 {
			hexOfRune := strconv.FormatUint(uint64(intOfRune), 16)
			dataLen := len(hexOfRune)
			paddingNum := 4 - dataLen
			encodedString.WriteString(`\u`)
			for i := 0; i < paddingNum; i++ {
				encodedString.WriteString("0")
			}
			encodedString.WriteString(hexOfRune)
		} else {
			encodedString.WriteString(string(runeOfMessage[i]))
		}
	}
	return encodedString.String()
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
