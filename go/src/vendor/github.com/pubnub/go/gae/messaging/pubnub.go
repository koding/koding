// Package messaging provides the implemetation to connect to pubnub api on google appengine.
// Build Date: Nov 25, 2016
// Version: 3.11.0
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
	"encoding/base64"
	"encoding/gob"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"github.com/gorilla/sessions"
	"golang.org/x/net/context"
	"google.golang.org/appengine/log"
	"google.golang.org/appengine/urlfetch"
	"io/ioutil"
	"net"
	"net/http"
	"net/url"
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
	sdkIdentificationParamVal = "PubNub-Go-GAE/3.11.0"

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

// Store for storing a ref of CookieStore
var Store *sessions.CookieStore

var (
	//sdkIdentificationParam = fmt.Sprintf("%s=%s", sdkIdentificationParamKey, url.QueryEscape(sdkIdentificationParamVal))
	sdkIdentificationParam = sdkIdentificationParamKey + "=" + url.QueryEscape(sdkIdentificationParamVal)
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
)

var (
	// Global variable to store connection instance for retry requests.
	retryConn net.Conn

	// Mutux to lock the operations on retryTransport
	retryTransportMu sync.RWMutex

	// Global variable to store connection instance for presence heartbeat requests.
	presenceHeartbeatConn net.Conn

	// Mutux to lock the operations on presence heartbeat transport
	presenceHeartbeatTransportMu sync.RWMutex

	// Global variable to store connection instance for non subscribe requests
	// Publish/HereNow/DetailedHitsory/Unsubscribe/UnsibscribePresence/Time.
	conn net.Conn

	// Global variable to store connection instance for Subscribe/Presence requests.
	subscribeConn net.Conn

	// Mutux to lock the operations on subscribeTransport
	subscribeTransportMu sync.RWMutex

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
	return "PubNub Go GAE client SDK Version: 3.11.0; Build Date: Nov 25, 2016;"
}

// initStore initializes the cookie store using the secret key
func initStore(secKey string) {
	if Store == nil {
		Store = sessions.NewCookieStore([]byte(secKey))
	}
}

// SetSessionKeys initializes the Pubnub instance using the new Pubnub key.
// This is similar to New but in used to change the keys once the pubnub instance has been initialized
// it accepts
//  context.Context
//  http.ResponseWriter
//  *http.Request
//  publishKey
//  subscribeKey
//  secretKey
//  cipher
//  ssl
//  uuid
func SetSessionKeys(context context.Context, w http.ResponseWriter, r *http.Request, pubKey string, subKey string, secKey string, cipher string, ssl bool, uuid string) {
	initStore(secKey)
	session, err := Store.Get(r, "user-session")

	if err == nil {
		pubInstance := NewPubnub(context, w, r, pubKey, subKey, secKey, cipher, ssl, uuid)
		writeSession(context, w, r, pubInstance, session)
	} else {
		log.Errorf(context, "error in set session , %s", err.Error())
	}
}

// DeleteSession deletes the session that stores the pubInstance
// it accepts
//  context.Context
//  http.ResponseWriter
//  *http.Request
//  secret Key
func DeleteSession(context context.Context, w http.ResponseWriter, r *http.Request, secKey string) {
	initStore(secKey)
	session, err := Store.Get(r, "user-session")
	if err == nil &&
		session != nil &&
		session.Values["pubInstance"] != nil {
		session.Values["pubInstance"] = ""
		session.Options = GetSessionsOptionsObject(-1)
		session.Save(r, w)
		log.Infof(context, "Deleted Session %s")
	}
}

// GetSessionsOptionsObject sets common Path, Age and HttpOnly options for the sessions.
// It returns the *sessions.Options object
func GetSessionsOptionsObject(age int) *sessions.Options {
	return &sessions.Options{
		Path:     "/",
		MaxAge:   age,
		HttpOnly: true,
	}
}

// New initializes the Session and the Pubnub instance.
// It accepts:
//  context.Context
//  uuid
//  http.ResponseWriter
//  *http.Request
//  publishKey
//  subscribeKey
//  secretKey
//  cipher
//  ssl
// It returns the Pubnub Instance
func New(context context.Context, uuid string, w http.ResponseWriter, r *http.Request, publishKey string, subscribeKey string, secretKey string, cipher string, ssl bool) *Pubnub {

	initStore(secretKey)

	session, err := Store.Get(r, "user-session")

	var pubInstance *Pubnub
	gob.Register(pubInstance)

	if err == nil &&
		session != nil &&
		session.Values["pubInstance"] != nil {
		if val, ok := session.Values["pubInstance"].(*Pubnub); ok {
			pubInstance = val
			uuidn1 := pubInstance.GetUUID()
			log.Infof(context, "retrieved instance %s", uuidn1)
		}
	} else {
		if err != nil {
			log.Errorf(context, "Session error: %s", err.Error())
		}
		if session == nil {
			log.Errorf(context, "Session nil")
		}
		if session.Values["pubInstance"] == nil {
			log.Errorf(context, "pubInstance nil")
		}
	}

	if pubInstance == nil {
		pubKey := publishKey
		subKey := subscribeKey
		secKey := secretKey
		log.Infof(context, "Creating NEW session")
		pubInstance = NewPubnub(context, w, r, pubKey, subKey, secKey, cipher, ssl, uuid)
		writeSession(context, w, r, pubInstance, session)
	}

	return pubInstance
}

func writeSession(context context.Context, w http.ResponseWriter, r *http.Request, pubInstance *Pubnub, session *sessions.Session) {
	session.Values["pubInstance"] = pubInstance
	session.Options = GetSessionsOptionsObject(60 * 20)
	gob.Register(pubInstance)
	gob.Register(pubInstance.UserState)
	err := session.Save(r, w)
	if err != nil {
		log.Errorf(context, "error in saving session, %s", err.Error())
	}
}

func saveSession(context context.Context, w http.ResponseWriter, r *http.Request, pubInstance *Pubnub) {

	initStore(pubInstance.SecretKey)
	gob.Register(pubInstance)
	session, err := Store.Get(r, "user-session")
	if err == nil &&
		session != nil {
		session.Values["pubInstance"] = pubInstance
		writeSession(context, w, r, pubInstance, session)
	} else {
		if err != nil {
			log.Errorf(context, "Session error save session : %s", err.Error())
		}
		if session == nil {
			log.Errorf(context, "Session nil")
		}
	}
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
	Origin             string
	PublishKey         string
	SubscribeKey       string
	SecretKey          string
	CipherKey          string
	AuthenticationKey  string
	IsSSL              bool
	Uuid               string
	subscribedChannels string
	TimeToken          string
	SentTimeToken      string
	ResetTimeToken     bool
	UserState          map[string]map[string]interface{}
	publishCounter     uint64
	publishCounterMu   sync.Mutex
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
func NewPubnub(context context.Context, w http.ResponseWriter, r *http.Request, publishKey string, subscribeKey string, secretKey string, cipherKey string, sslOn bool, customUuid string) *Pubnub {
	log.Infof(context, fmt.Sprintf("Pubnub Init, %s", VersionInfo()))
	log.Infof(context, fmt.Sprintf("OS: %s", runtime.GOOS))

	newPubnub := &Pubnub{}
	newPubnub.Origin = origin
	newPubnub.PublishKey = publishKey
	newPubnub.SubscribeKey = subscribeKey
	newPubnub.SecretKey = secretKey
	newPubnub.CipherKey = cipherKey
	newPubnub.IsSSL = sslOn
	newPubnub.Uuid = ""
	newPubnub.subscribedChannels = ""
	newPubnub.ResetTimeToken = true
	newPubnub.TimeToken = "0"
	newPubnub.SentTimeToken = "0"

	if newPubnub.IsSSL {
		newPubnub.Origin = "https://" + newPubnub.Origin
	} else {
		newPubnub.Origin = "http://" + newPubnub.Origin
	}

	log.Infof(context, fmt.Sprintf("Origin: %s", newPubnub.Origin))
	//Generate the uuid is custmUuid is not provided
	newPubnub.SetUUID(context, w, r, customUuid)

	return newPubnub
}

// SetResumeOnReconnect sets the value of resumeOnReconnect.
func SetResumeOnReconnect(val bool) {
	resumeOnReconnect = val
}

// SetAuthenticationKey sets the value of authentication key
func (pub *Pubnub) SetAuthenticationKey(context context.Context, w http.ResponseWriter, r *http.Request, val string) {
	pub.AuthenticationKey = val
	saveSession(context, w, r, pub)
}

// GetAuthenticationKey gets the value of authentication key
func (pub *Pubnub) GetAuthenticationKey() string {
	return pub.AuthenticationKey
}

// SetUUID sets the value of UUID
func (pub *Pubnub) SetUUID(context context.Context, w http.ResponseWriter, r *http.Request, val string) {
	if strings.TrimSpace(val) == "" {
		uuid, err := GenUuid()
		if err == nil {
			pub.Uuid = fmt.Sprintf("pn-%s", url.QueryEscape(uuid))
		} else {
			log.Errorf(context, err.Error())
		}
	} else {
		pub.Uuid = url.QueryEscape(val)
	}
	saveSession(context, w, r, pub)
}

// GetUUID returns the value of UUID
func (pub *Pubnub) GetUUID() string {
	return pub.Uuid
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
	return pub.SentTimeToken
}

// GetTimeToken returns the latest timetoken received from the server, is used only for unit tests
func (pubtest *PubnubUnitTest) GetTimeToken(pub *Pubnub) string {
	return pub.TimeToken
}

// closePresenceHeartbeatConnection closes the presence heartbeat connection
func (pub *Pubnub) closePresenceHeartbeatConnection() {
	presenceHeartbeatTransportMu.Lock()
	if presenceHeartbeatConn != nil {
		presenceHeartbeatConn.Close()
	}
	presenceHeartbeatTransportMu.Unlock()
}

// closeRetryConnection closes the retry connection
func (pub *Pubnub) closeRetryConnection() {
	retryTransportMu.Lock()
	if retryConn != nil {
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
func (pub *Pubnub) GrantSubscribe(context context.Context,
	w http.ResponseWriter, r *http.Request, channel string, read, write bool,
	ttl int, authKey string, callbackChannel, errorChannel chan []byte) {

	checkCallbackNil(callbackChannel, false, "GrantSubscribe")
	checkCallbackNil(errorChannel, true, "GrantSubscribe")

	pub.pamValidateSecretKey(channel, errorChannel)

	requestURL := pub.pamGenerateParamsForChannel("grant", channel, read, write,
		ttl, authKey)

	pub.executePam(context, w, r, channel, requestURL,
		callbackChannel, errorChannel)
}

// AuditSubscribe will make a call to display the permissions for a channel or subkey
//
// channel is options and if not provided will set the permissions at subkey level
//
// Both callbackChannel and errorChannel are mandatory. If either is nil the code will panic
func (pub *Pubnub) AuditSubscribe(context context.Context,
	w http.ResponseWriter, r *http.Request, channel, authKey string,
	callbackChannel, errorChannel chan []byte) {

	checkCallbackNil(callbackChannel, false, "AuditSubscribe")
	checkCallbackNil(errorChannel, true, "AuditSubscribe")

	pub.pamValidateSecretKey(channel, errorChannel)

	requestURL := pub.pamGenerateParamsForChannel("audit", channel, false, false,
		-1, authKey)

	pub.executePam(context, w, r, channel, requestURL,
		callbackChannel, errorChannel)
}

// GrantPresence is used to give a presence channel read, write permissions
// and set TTL values for it. To grant a permission set read or write as true
// to revoke all perms set read and write false and ttl as -1
//
// channel is options and if not provided will set the permissions at subkey level
//
// Both callbackChannel and errorChannel are mandatory. If either is nil the code will panic
func (pub *Pubnub) GrantPresence(context context.Context,
	w http.ResponseWriter, r *http.Request, channel string, read, write bool,
	ttl int, authKey string, callbackChannel, errorChannel chan []byte) {

	checkCallbackNil(callbackChannel, false, "GrantPresence")
	checkCallbackNil(errorChannel, true, "GrantPresence")

	channel2 := convertToPresenceChannel(channel)

	pub.pamValidateSecretKey(channel2, errorChannel)

	requestURL := pub.pamGenerateParamsForChannel("grant", channel2, read, write,
		ttl, authKey)

	pub.executePam(context, w, r, channel2, requestURL,
		callbackChannel, errorChannel)
}

// AuditPresence will make a call to display the permissions for a channel or subkey
//
// channel is options and if not provided will set the permissions at subkey level
//
// Both callbackChannel and errorChannel are mandatory. If either is nil the code will panic
func (pub *Pubnub) AuditPresence(context context.Context,
	w http.ResponseWriter, r *http.Request, channel, authKey string,
	callbackChannel, errorChannel chan []byte) {
	checkCallbackNil(callbackChannel, false, "AuditPresence")
	checkCallbackNil(errorChannel, true, "AuditPresence")

	channel2 := convertToPresenceChannel(channel)

	pub.pamValidateSecretKey(channel2, errorChannel)

	requestURL := pub.pamGenerateParamsForChannel("audit", channel2, false, false,
		-1, authKey)

	pub.executePam(context, w, r, channel2, requestURL,
		callbackChannel, errorChannel)
}

// GrantChannelGroup is used to give a channel group read or manage permissions
// and set TTL values for it.
func (pub *Pubnub) GrantChannelGroup(context context.Context,
	w http.ResponseWriter, r *http.Request, group string, read, manage bool,
	ttl int, authKey string, callbackChannel, errorChannel chan []byte) {
	checkCallbackNil(callbackChannel, false, "GrantChannelGroup")
	checkCallbackNil(errorChannel, true, "GrantChannelGroup")

	pub.pamValidateSecretKey(group, errorChannel)

	requestURL := pub.pamGenerateParamsForChannelGroup("grant", group, read, manage,
		ttl, authKey)

	pub.executePam(context, w, r, group, requestURL,
		callbackChannel, errorChannel)
}

// AuditChannelGroup will make a call to display the permissions
// for a channel
// group or subkey
func (pub *Pubnub) AuditChannelGroup(context context.Context,
	w http.ResponseWriter, r *http.Request, group, authKey string,
	callbackChannel, errorChannel chan []byte) {
	checkCallbackNil(callbackChannel, false, "AuditChannelGroup")
	checkCallbackNil(errorChannel, true, "AuditChannelGroup")

	pub.pamValidateSecretKey(group, errorChannel)

	requestURL := pub.pamGenerateParamsForChannelGroup("audit", group, false, false,
		-1, authKey)

	pub.executePam(context, w, r, group, requestURL,
		callbackChannel, errorChannel)
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

func (pub *Pubnub) pamValidateSecretKey(entity string, errorChannel chan []byte) {
	message := "Secret key is required"

	if strings.TrimSpace(pub.SecretKey) == "" {
		if strings.TrimSpace(entity) == "" {
			pub.sendResponseToChannel(errorChannel, "", responseWithoutChannel, message, "")
		} else {
			pub.sendResponseToChannel(errorChannel, entity, responseAsIsError, message, "")
		}
	}
}

//  generate params string for channels pam request
func (pub *Pubnub) pamGenerateParamsForChannel(action, channel string,
	read, write bool, ttl int, authKey string) string {
	authParam := ""
	channelParam := ""
	noChannel := true
	readParam := ""
	writeParam := ""
	timestampParam := ""
	ttlParam := ""
	filler := "&"
	isAudit := action == "audit"

	var params bytes.Buffer
	var pamURLBuffer bytes.Buffer

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

	raw := fmt.Sprintf("%s\n%s\n%s\n%s", pub.SubscribeKey, pub.PublishKey,
		action, params.String())
	signature := getHmacSha256(pub.SecretKey, raw)

	pamURLBuffer.WriteString("/v1/auth/")
	pamURLBuffer.WriteString(action)
	pamURLBuffer.WriteString("/sub-key/")
	pamURLBuffer.WriteString(pub.SubscribeKey)
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

	authParam := ""
	channelGroupParam := ""
	noChannelGroup := true
	readParam := ""
	manageParam := ""
	timestampParam := ""
	ttlParam := ""
	filler := "&"
	isAudit := action == "audit"

	var params bytes.Buffer
	var pamURLBuffer bytes.Buffer

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

	raw := fmt.Sprintf("%s\n%s\n%s\n%s", pub.SubscribeKey, pub.PublishKey,
		action, params.String())
	signature := getHmacSha256(pub.SecretKey, raw)

	pamURLBuffer.WriteString("/v1/auth/")
	pamURLBuffer.WriteString(action)
	pamURLBuffer.WriteString("/sub-key/")
	pamURLBuffer.WriteString(pub.SubscribeKey)
	pamURLBuffer.WriteString("?")
	pamURLBuffer.WriteString(params.String())
	pamURLBuffer.WriteString("&")
	pamURLBuffer.WriteString("signature=")
	pamURLBuffer.WriteString(signature)

	return pamURLBuffer.String()
}

// executePam is the main method which is called for all PAM requests
//
// for audit request the isAudit parameter should be true
func (pub *Pubnub) executePam(context context.Context, w http.ResponseWriter,
	r *http.Request, entity, requestURL string,
	callbackChannel, errorChannel chan []byte) {

	value, responseCode, err := pub.httpRequest(context, w, r, requestURL, nonSubscribeTrans)
	if (responseCode != 200) || (err != nil) {
		var message = ""
		if err != nil {
			message = err.Error()
			log.Errorf(context, fmt.Sprintf("PAM Error: %s", message))
		} else {
			message = fmt.Sprintf("%s", value)
			log.Errorf(context, fmt.Sprintf("PAM Error: responseCode %d, message %s", responseCode, message))
		}
		if strings.TrimSpace(entity) == "" {
			pub.sendResponseToChannel(errorChannel, "", responseWithoutChannel, message, "")
		} else {
			pub.sendResponseToChannel(errorChannel, entity, responseAsIsError, message, "")
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
func (pub *Pubnub) GetTime(context context.Context, w http.ResponseWriter, r *http.Request, callbackChannel chan []byte, errorChannel chan []byte) {
	checkCallbackNil(callbackChannel, false, "GetTime")
	checkCallbackNil(errorChannel, true, "GetTime")

	pub.executeTime(context, w, r, callbackChannel, errorChannel, 0)
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
func (pub *Pubnub) executeTime(context context.Context, w http.ResponseWriter, r *http.Request, callbackChannel chan []byte, errorChannel chan []byte, retryCount int) {
	//context := appengine.NewContext(r)

	count := retryCount

	timeURL := ""
	timeURL += "/time"
	timeURL += "/0"

	timeURL += "?"
	timeURL += sdkIdentificationParam
	timeURL += "&uuid="
	timeURL += pub.GetUUID()

	value, _, err := pub.httpRequest(context, w, r, timeURL, nonSubscribeTrans)

	if err != nil {
		log.Errorf(context, fmt.Sprintf("Time Error: %s", err.Error()))
		pub.sendResponseToChannel(errorChannel, "", responseWithoutChannel, err.Error(), "")
	} else {
		_, _, _, errJSON := ParseJSON(value, pub.CipherKey)
		if errJSON != nil && strings.Contains(errJSON.Error(), invalidJSON) {
			log.Errorf(context, fmt.Sprintf("Time Error: %s", errJSON.Error()))
			pub.sendResponseToChannel(errorChannel, "", responseWithoutChannel, errJSON.Error(), "")
			if count < maxRetries {
				count++
				pub.executeTime(context, w, r, callbackChannel, errorChannel, count)
			}
		} else {
			log.Infof(context, fmt.Sprintf("Time: %s", value))
			callbackChannel <- []byte(fmt.Sprintf("%s", value))
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
func (pub *Pubnub) sendPublishRequest(context context.Context,
	w http.ResponseWriter, r *http.Request, channel, publishURLString string,
	storeInHistory, replicate bool, jsonBytes string, metaBytes []byte,
	callbackChannel, errorChannel chan []byte) {

	encodedPath := encodeJSONAsPathComponent(jsonBytes)
	log.Infof(context, fmt.Sprintf("Publish: json: %s, encoded: %s", string(jsonBytes), encodedPath))

	publishURL := fmt.Sprintf("%s%s", publishURLString, encodedPath)
	publishURL = fmt.Sprintf("%s?%s&uuid=%s%s", publishURL,
		sdkIdentificationParam, pub.GetUUID(), pub.addAuthParam(true))

	if storeInHistory == false {
		publishURL = fmt.Sprintf("%s&store=0", publishURL)
	}

	if !replicate {
		publishURL = fmt.Sprintf("%s&norep=true", publishURL)
	}

	pub.publishCounterMu.Lock()
	pub.publishCounter++
	counter := strconv.FormatUint(pub.publishCounter, 10)
	pub.publishCounterMu.Unlock()

	log.Infof(context, fmt.Sprintf("INFO: Publish counter: %s", counter))

	publishURL = fmt.Sprintf("%s&seqn=%s", publishURL, counter)

	if metaBytes != nil {
		metaEncodedPath := encodeJSONAsPathComponent(string(metaBytes))
		publishURL = fmt.Sprintf("%s&meta=%s", publishURL, metaEncodedPath)
	}

	value, responseCode, err := pub.httpRequest(context, w, r, publishURL, nonSubscribeTrans)
	pub.readPublishResponseAndCallSendResponse(context, w, r, channel, value, responseCode, err, callbackChannel, errorChannel)
}

func (pub *Pubnub) readPublishResponseAndCallSendResponse(context context.Context,
	w http.ResponseWriter, r *http.Request, channel string, value []byte, responseCode int, err error, callbackChannel, errorChannel chan []byte) {
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
				log.Infof(context, fmt.Sprintf("ERROR: Publish Error: %s", errJSON.Error()))
				pub.sendResponseToChannel(errorChannel, channel, responseAsIsError, string(value), strconv.Itoa(responseCode))
			}
		} else if (err != nil) && (responseCode > 0) {
			log.Infof(context, fmt.Sprintf("ERROR: Publish Failed: %s, ResponseCode: %d", err.Error(), responseCode))
			pub.sendResponseToChannel(errorChannel, channel, responseAsIsError, err.Error(), strconv.Itoa(responseCode))
		} else if err != nil {
			log.Infof(context, fmt.Sprintf("ERROR: Publish Failed: %s", err.Error()))
			pub.sendResponseToChannel(errorChannel, channel, responseAsIsError, err.Error(), "")
		} else {
			log.Infof(context, fmt.Sprintf("ERROR: Publish Failed: ResponseCode: %d", responseCode))
			pub.sendResponseToChannel(errorChannel, channel, responseAsIsError, publishFailed, strconv.Itoa(responseCode))
		}
	} else {
		_, _, _, errJSON := ParseJSON(value, pub.CipherKey)
		if errJSON != nil && strings.Contains(errJSON.Error(), invalidJSON) {
			log.Infof(context, fmt.Sprintf("ERROR: Publish Error: %s", errJSON.Error()))
			pub.sendResponseToChannel(errorChannel, channel, responseAsIsError, errJSON.Error(), "")
		} else {
			callbackChannel <- value
		}
	}
}

func encodeURL(urlString string) string {
	var reqURL *url.URL
	reqURL, urlErr := url.Parse(urlString)
	if urlErr != nil {
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
			c <- []byte(fmt.Sprintf("Invalid Channel: %s", channel))
			return true
		}
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
func (pub *Pubnub) Fire(context context.Context, w http.ResponseWriter,
	r *http.Request, channel string, message interface{}, doNotSerialize bool,
	callbackChannel, errorChannel chan []byte) {
	pub.PublishExtendedWithMetaAndReplicate(context, w, r, channel, message, nil, false, doNotSerialize, false, callbackChannel, errorChannel)
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
func (pub *Pubnub) Publish(context context.Context, w http.ResponseWriter,
	r *http.Request, channel string, message interface{},
	callbackChannel, errorChannel chan []byte) {

	pub.PublishExtendedWithMeta(context, w, r, channel, message, nil, true, false, callbackChannel, errorChannel)
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
func (pub *Pubnub) PublishExtended(context context.Context, w http.ResponseWriter,
	r *http.Request, channel string, message interface{},
	storeInHistory, doNotSerialize bool,
	callbackChannel, errorChannel chan []byte) {
	pub.PublishExtendedWithMeta(context, w, r, channel, message, nil, storeInHistory, doNotSerialize, callbackChannel, errorChannel)
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
func (pub *Pubnub) PublishExtendedWithMeta(context context.Context, w http.ResponseWriter,
	r *http.Request, channel string, message, meta interface{},
	storeInHistory, doNotSerialize bool,
	callbackChannel, errorChannel chan []byte) {
	pub.PublishExtendedWithMetaAndReplicate(context, w, r, channel, message, meta, storeInHistory, doNotSerialize, true, callbackChannel, errorChannel)
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
func (pub *Pubnub) PublishExtendedWithMetaAndReplicate(context context.Context, w http.ResponseWriter,
	r *http.Request, channel string, message, meta interface{},
	storeInHistory, doNotSerialize, replicate bool,
	callbackChannel, errorChannel chan []byte) {

	var publishURLBuffer bytes.Buffer
	var err, errMeta error
	var jsonSerialized, jsonSerializedMeta []byte

	checkCallbackNil(callbackChannel, false, "Publish")
	checkCallbackNil(errorChannel, true, "Publish")

	if pub.PublishKey == "" {
		log.Warningf(context, fmt.Sprintf("Publish key empty"))
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
	if pub.SecretKey != "" {
		signature = getHmacSha256(pub.SecretKey, fmt.Sprintf("%s/%s/%s/%s/%s", pub.PublishKey, pub.SubscribeKey, pub.SecretKey, channel, message))
	} else {
		signature = "0"
	}

	publishURLBuffer.WriteString("/publish")
	publishURLBuffer.WriteString("/")
	publishURLBuffer.WriteString(pub.PublishKey)
	publishURLBuffer.WriteString("/")
	publishURLBuffer.WriteString(pub.SubscribeKey)
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
		pub.sendResponseToChannel(errorChannel, channel, responseAsIsError, fmt.Sprintf("error in serializing: %s", err), "")
	} else {

		if pub.CipherKey != "" {
			//Encrypt and Serialize
			encrypted := EncryptString(pub.CipherKey, fmt.Sprintf("%s", jsonSerialized))
			jsonEncBytes, errEnc := json.Marshal(encrypted)
			if errEnc != nil {
				log.Errorf(context, fmt.Sprintf("Publish error: %s", errEnc.Error()))
				pub.sendResponseToChannel(errorChannel, channel, responseAsIsError, fmt.Sprintf("error in serializing: %s", errEnc), "")
			} else {
				pub.sendPublishRequest(context, w, r, channel, publishURLBuffer.String(),
					storeInHistory, replicate, string(jsonEncBytes), jsonSerializedMeta, callbackChannel, errorChannel)
			}
		} else {
			//messageStr := strings.Replace(string(jsonSerialized), "/", "%2F", -1)

			pub.sendPublishRequest(context, w, r, channel, publishURLBuffer.String(), storeInHistory, replicate,
				string(jsonSerialized), jsonSerializedMeta, callbackChannel, errorChannel)
		}
	}
}

// sendResponseToChannel is the struct Pubnub's instance method that sends a response on the channel
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
				//responseChannel, isPresence = pub.getChannelForPubnubChannel(channel, true)
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

			if responseChannel != nil {
				responseChannel <- []byte(value)
			}
		} else {
			isPresence := false
			if responseChannel == nil {
				//responseChannel, isPresence = pub.getChannelForPubnubChannel(channel, false)
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
			if responseChannel != nil {
				responseChannel <- []byte(value)
			}
		}
	}
	if errorWithoutChannel {
		responseChannel := c
		value = fmt.Sprintf("[%s, \"%s\"]", intResponse, response)
		if responseChannel != nil {
			responseChannel <- []byte(value)
		}
	}
}

// addAuthParamToQuery adds the authentication key to the URL
// and returns the new query
func (pub *Pubnub) addAuthParamToQuery(q url.Values) url.Values {
	if strings.TrimSpace(pub.AuthenticationKey) != "" {
		q.Set("auth", pub.AuthenticationKey)
		return q
	}
	return q
}

// addAuthParam return a string with authentication key based on the
// param queryStringInit
func (pub *Pubnub) addAuthParam(queryStringInit bool) string {
	if strings.TrimSpace(pub.AuthenticationKey) != "" {
		return fmt.Sprintf("%sauth=%s", checkQuerystringInit(queryStringInit), url.QueryEscape(pub.AuthenticationKey))
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

// parseHttpResponse parses the http response from the origin for the subscribe resquest
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
		pub.sendResponseToChannel(nil, channelName, responseAsIsError, fmt.Sprintf("%s", errJSON), "")
		sleepForAWhile(false)
	} else {
		retryCountMu.Lock()
		retryCount = 0
		retryCountMu.Unlock()

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
		response := []interface{}{message, fmt.Sprintf("%s", pub.TimeToken), channelName}
		jsonData, err := json.Marshal(response)
		if err != nil {
			pub.sendResponseToChannel(nil, channelName, responseAsIsError, invalidJSON, err.Error())
		}
		pub.sendResponseToChannel(nil, channelName, responseAsIs, string(jsonData), "")
	}
}

// CloseExistingConnection closes the open subscribe/presence connection.
func (pub *Pubnub) CloseExistingConnection() {
	subscribeTransportMu.Lock()
	defer subscribeTransportMu.Unlock()
	if subscribeConn != nil {
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
		panic(message)
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

// sendLeaveRequest: Sends a leave request to the origin
//
// It accepts the following parameters:
// channels: Channels to leave
//
// returns:
// the HttpRequest response contents as byte array.
// response error code,
// error if any.
func (pub *Pubnub) sendLeaveRequest(context context.Context, w http.ResponseWriter, r *http.Request, channels string) ([]byte, int, error) {
	var subscribeURLBuffer bytes.Buffer
	subscribeURLBuffer.WriteString("/v2/presence")
	subscribeURLBuffer.WriteString("/sub-key/")
	subscribeURLBuffer.WriteString(pub.SubscribeKey)
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

	return pub.httpRequest(context, w, r, subscribeURLBuffer.String(), nonSubscribeTrans)
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
func (pub *Pubnub) History(context context.Context, w http.ResponseWriter, r *http.Request, channel string, limit int, start int64, end int64, reverse bool, callbackChannel chan []byte, errorChannel chan []byte) {
	checkCallbackNil(callbackChannel, false, "History")
	checkCallbackNil(errorChannel, true, "History")

	pub.executeHistory(context, w, r, channel, limit, start, end, reverse, callbackChannel, errorChannel, 0)
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
func (pub *Pubnub) executeHistory(context context.Context, w http.ResponseWriter, r *http.Request, channel string, limit int, start int64, end int64, reverse bool, callbackChannel chan []byte, errorChannel chan []byte, retryCount int) {
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
	historyURLBuffer.WriteString(pub.SubscribeKey)
	historyURLBuffer.WriteString("/channel/")
	historyURLBuffer.WriteString(url.QueryEscape(channel))
	historyURLBuffer.WriteString("?count=")
	historyURLBuffer.WriteString(fmt.Sprintf("%d", limit))
	historyURLBuffer.WriteString(parameters.String())
	historyURLBuffer.WriteString("&")
	historyURLBuffer.WriteString(sdkIdentificationParam)
	historyURLBuffer.WriteString("&uuid=")
	historyURLBuffer.WriteString(pub.GetUUID())

	value, _, err := pub.httpRequest(context, w, r, historyURLBuffer.String(), nonSubscribeTrans)

	if err != nil {
		log.Errorf(context, fmt.Sprintf("%s", err.Error()))

		pub.sendResponseToChannel(errorChannel, channel, responseAsIsError, err.Error(), "")
	} else {
		data, returnOne, returnTwo, errJSON := ParseJSON(value, pub.CipherKey)
		if errJSON != nil && strings.Contains(errJSON.Error(), invalidJSON) {
			log.Errorf(context, fmt.Sprintf("%s", errJSON.Error()))
			pub.sendResponseToChannel(errorChannel, channel, responseAsIsError, errJSON.Error(), "")
			if count < maxRetries {
				count++
				pub.executeHistory(context, w, r, channel, limit, start, end, reverse, callbackChannel, errorChannel, count)
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
func (pub *Pubnub) WhereNow(context context.Context, w http.ResponseWriter, r *http.Request, uuid string, callbackChannel chan []byte, errorChannel chan []byte) {
	checkCallbackNil(callbackChannel, false, "WhereNow")
	checkCallbackNil(errorChannel, true, "WhereNow")

	pub.executeWhereNow(context, w, r, uuid, callbackChannel, errorChannel, 0)
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
func (pub *Pubnub) executeWhereNow(context context.Context, w http.ResponseWriter, r *http.Request, uuid string, callbackChannel chan []byte, errorChannel chan []byte, retryCount int) {
	count := retryCount

	var whereNowURL bytes.Buffer
	whereNowURL.WriteString("/v2/presence")
	whereNowURL.WriteString("/sub-key/")
	whereNowURL.WriteString(pub.SubscribeKey)
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

	value, _, err := pub.httpRequest(context, w, r, whereNowURL.String(), nonSubscribeTrans)

	if err != nil {
		log.Errorf(context, fmt.Sprintf("%s", err.Error()))
		pub.sendResponseToChannel(errorChannel, "", responseAsIsError, err.Error(), "")
	} else {
		//Parsejson
		_, _, _, errJSON := ParseJSON(value, pub.CipherKey)
		if errJSON != nil && strings.Contains(errJSON.Error(), invalidJSON) {
			log.Errorf(context, fmt.Sprintf("%s", errJSON.Error()))
			pub.sendResponseToChannel(errorChannel, "", responseAsIsError, errJSON.Error(), "")
			if count < maxRetries {
				count++
				pub.executeWhereNow(context, w, r, uuid, callbackChannel, errorChannel, count)
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
func (pub *Pubnub) GlobalHereNow(context context.Context, w http.ResponseWriter, r *http.Request, showUuid bool, includeUserState bool, callbackChannel chan []byte, errorChannel chan []byte) {
	checkCallbackNil(callbackChannel, false, "GlobalHereNow")
	checkCallbackNil(errorChannel, true, "GlobalHereNow")

	pub.executeGlobalHereNow(context, w, r, showUuid, includeUserState, callbackChannel, errorChannel, 0)
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
func (pub *Pubnub) executeGlobalHereNow(context context.Context, w http.ResponseWriter, r *http.Request, showUuid bool, includeUserState bool, callbackChannel chan []byte, errorChannel chan []byte, retryCount int) {
	count := retryCount

	var hereNowURL bytes.Buffer
	hereNowURL.WriteString("/v2/presence")
	hereNowURL.WriteString("/sub-key/")
	hereNowURL.WriteString(pub.SubscribeKey)

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

	value, _, err := pub.httpRequest(context, w, r, hereNowURL.String(), nonSubscribeTrans)

	if err != nil {
		log.Errorf(context, fmt.Sprintf("%s", err.Error()))
		pub.sendResponseToChannel(errorChannel, "", responseAsIsError, err.Error(), "")
	} else {
		//Parsejson
		_, _, _, errJSON := ParseJSON(value, pub.CipherKey)
		if errJSON != nil && strings.Contains(errJSON.Error(), invalidJSON) {
			log.Errorf(context, fmt.Sprintf("%s", errJSON.Error()))
			pub.sendResponseToChannel(errorChannel, "", responseAsIsError, errJSON.Error(), "")
			if count < maxRetries {
				count++
				pub.executeGlobalHereNow(context, w, r, showUuid, includeUserState, callbackChannel, errorChannel, count)
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
func (pub *Pubnub) HereNow(context context.Context, w http.ResponseWriter, r *http.Request, channel string, showUuid bool, includeUserState bool, callbackChannel chan []byte, errorChannel chan []byte) {
	checkCallbackNil(callbackChannel, false, "HereNow")
	checkCallbackNil(errorChannel, true, "HereNow")

	pub.executeHereNow(context, w, r, channel, showUuid, includeUserState, callbackChannel, errorChannel, 0)
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
func (pub *Pubnub) executeHereNow(context context.Context, w http.ResponseWriter, r *http.Request, channel string, showUuid bool, includeUserState bool, callbackChannel chan []byte, errorChannel chan []byte, retryCount int) {
	count := retryCount

	if invalidChannel(channel, callbackChannel) {
		return
	}

	var hereNowURL bytes.Buffer
	hereNowURL.WriteString("/v2/presence")
	hereNowURL.WriteString("/sub-key/")
	hereNowURL.WriteString(pub.SubscribeKey)
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

	value, _, err := pub.httpRequest(context, w, r, hereNowURL.String(), nonSubscribeTrans)

	if err != nil {
		log.Errorf(context, fmt.Sprintf("%s", err.Error()))
		pub.sendResponseToChannel(errorChannel, channel, responseAsIsError, err.Error(), "")
	} else {
		//Parsejson
		_, _, _, errJSON := ParseJSON(value, pub.CipherKey)
		if errJSON != nil && strings.Contains(errJSON.Error(), invalidJSON) {

			log.Errorf(context, fmt.Sprintf("%s", errJSON.Error()))

			pub.sendResponseToChannel(errorChannel, channel, responseAsIsError, errJSON.Error(), "")
			if count < maxRetries {
				count++
				pub.executeHereNow(context, w, r, channel, showUuid, includeUserState, callbackChannel, errorChannel, count)
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
func (pub *Pubnub) GetUserState(context context.Context, w http.ResponseWriter, r *http.Request, channel string, callbackChannel chan []byte, errorChannel chan []byte) {
	checkCallbackNil(callbackChannel, false, "GetUserState")
	checkCallbackNil(errorChannel, true, "GetUserState")
	pub.executeGetUserState(context, w, r, channel, callbackChannel, errorChannel, 0)
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
func (pub *Pubnub) executeGetUserState(context context.Context, w http.ResponseWriter, r *http.Request, channel string, callbackChannel chan []byte, errorChannel chan []byte, retryCount int) {
	count := retryCount

	var userStateURL bytes.Buffer
	userStateURL.WriteString("/v2/presence")
	userStateURL.WriteString("/sub-key/")
	userStateURL.WriteString(pub.SubscribeKey)
	userStateURL.WriteString("/channel/")
	userStateURL.WriteString(url.QueryEscape(channel))
	userStateURL.WriteString("/uuid/")
	userStateURL.WriteString(pub.GetUUID())
	userStateURL.WriteString("?")
	userStateURL.WriteString(sdkIdentificationParam)
	userStateURL.WriteString("&uuid=")
	userStateURL.WriteString(pub.GetUUID())

	userStateURL.WriteString(pub.addAuthParam(true))

	value, _, err := pub.httpRequest(context, w, r, userStateURL.String(), nonSubscribeTrans)

	if err != nil {
		log.Errorf(context, fmt.Sprintf("%s", err.Error()))
		pub.sendResponseToChannel(errorChannel, "", responseAsIsError, err.Error(), "")
	} else {
		//Parsejson
		_, _, _, errJSON := ParseJSON(value, pub.CipherKey)
		if errJSON != nil && strings.Contains(errJSON.Error(), invalidJSON) {
			log.Errorf(context, fmt.Sprintf("%s", errJSON.Error()))
			pub.sendResponseToChannel(errorChannel, "", responseAsIsError, errJSON.Error(), "")
			if count < maxRetries {
				count++
				pub.executeGetUserState(context, w, r, channel, callbackChannel, errorChannel, count)
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
func (pub *Pubnub) SetUserStateKeyVal(context context.Context, w http.ResponseWriter, r *http.Request, channel string, key string, val string, callbackChannel chan []byte, errorChannel chan []byte) {
	checkCallbackNil(callbackChannel, false, "SetUserState")
	checkCallbackNil(errorChannel, true, "SetUserState")

	if pub.UserState == nil {
		pub.UserState = make(map[string]map[string]interface{})
	}
	if strings.TrimSpace(val) == "" {
		channelUserState := pub.UserState[channel]
		if channelUserState != nil {
			delete(channelUserState, key)
			pub.UserState[channel] = channelUserState
		}
	} else {
		channelUserState := pub.UserState[channel]
		if channelUserState == nil {
			pub.UserState[channel] = make(map[string]interface{})
			channelUserState = pub.UserState[channel]
		}
		channelUserState[key] = val
		pub.UserState[channel] = channelUserState
	}

	jsonSerialized, err := json.Marshal(pub.UserState[channel])
	if len(pub.UserState[channel]) <= 0 {
		delete(pub.UserState, channel)
	}

	if err != nil {
		log.Errorf(context, fmt.Sprintf("SetUserStateKeyVal err: %s", err.Error()))
		pub.sendResponseToChannel(errorChannel, channel, responseAsIsError, invalidUserStateMap, err.Error())
		return
	}
	stateJSON := string(jsonSerialized)
	if stateJSON == "null" {
		stateJSON = "{}"
	}
	log.Infof(context, fmt.Sprintf("SetUserStateKeyVal jsonSerialized: %s %s", jsonSerialized, stateJSON))
	saveSession(context, w, r, pub)
	pub.executeSetUserState(context, w, r, channel, stateJSON, callbackChannel, errorChannel, 0)
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
func (pub *Pubnub) SetUserStateJSON(context context.Context, w http.ResponseWriter, r *http.Request, channel string, jsonString string, callbackChannel chan []byte, errorChannel chan []byte) {
	checkCallbackNil(callbackChannel, false, "SetUserState")
	checkCallbackNil(errorChannel, true, "SetUserState")
	var s interface{}
	err := json.Unmarshal([]byte(jsonString), &s)
	if err != nil {
		pub.sendResponseToChannel(errorChannel, channel, responseAsIsError, invalidUserStateMap, err.Error())
		return
	}

	if pub.UserState == nil {
		pub.UserState = make(map[string]map[string]interface{})
	}
	pub.UserState[channel] = s.(map[string]interface{})
	saveSession(context, w, r, pub)
	pub.executeSetUserState(context, w, r, channel, jsonString, callbackChannel, errorChannel, 0)
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
func (pub *Pubnub) executeSetUserState(context context.Context, w http.ResponseWriter, r *http.Request, channel string, jsonState string, callbackChannel chan []byte, errorChannel chan []byte, retryCount int) {
	count := retryCount

	var userStateURL bytes.Buffer
	userStateURL.WriteString("/v2/presence")
	userStateURL.WriteString("/sub-key/")
	userStateURL.WriteString(pub.SubscribeKey)
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

	value, _, err := pub.httpRequest(context, w, r, userStateURL.String(), nonSubscribeTrans)

	if err != nil {
		log.Errorf(context, fmt.Sprintf("%s", err.Error()))
		pub.sendResponseToChannel(errorChannel, "", responseAsIsError, err.Error(), "")
	} else {
		//Parsejson
		_, _, _, errJSON := ParseJSON(value, pub.CipherKey)
		if errJSON != nil && strings.Contains(errJSON.Error(), invalidJSON) {
			log.Errorf(context, fmt.Sprintf("%s", errJSON.Error()))
			pub.sendResponseToChannel(errorChannel, "", responseAsIsError, errJSON.Error(), "")
			if count < maxRetries {
				count++
				pub.executeSetUserState(context, w, r, channel, jsonState, callbackChannel, errorChannel, count)
			}
		} else {
			callbackChannel <- []byte(fmt.Sprintf("%s", value))
			pub.CloseExistingConnection()
		}
	}
}

func (pub *Pubnub) ChannelGroupAddChannel(context context.Context,
	w http.ResponseWriter, r *http.Request, group, channel string,
	callbackChannel, errorChannel chan []byte) {

	checkCallbackNil(callbackChannel, false, "ChannelGroupAddChannel")
	checkCallbackNil(errorChannel, true, "ChannelGroupAddChannel")

	pub.executeChannelGroup(context, w, r, "add", group, channel,
		callbackChannel, errorChannel)
}

func (pub *Pubnub) ChannelGroupRemoveChannel(context context.Context,
	w http.ResponseWriter, r *http.Request, group, channel string,
	callbackChannel, errorChannel chan []byte) {

	checkCallbackNil(callbackChannel, false, "ChannelGroupRemoveChannel")
	checkCallbackNil(errorChannel, true, "ChannelGroupRemoveChannel")

	pub.executeChannelGroup(context, w, r, "remove", group, channel,
		callbackChannel, errorChannel)
}

func (pub *Pubnub) ChannelGroupListChannels(context context.Context,
	w http.ResponseWriter, r *http.Request, group string,
	callbackChannel, errorChannel chan []byte) {

	checkCallbackNil(callbackChannel, false, "ChannelGroupListChannels")
	checkCallbackNil(errorChannel, true, "ChannelGroupListChannels")

	pub.executeChannelGroup(context, w, r, "list_group", group, "",
		callbackChannel, errorChannel)
}

func (pub *Pubnub) ChannelGroupRemoveGroup(context context.Context,
	w http.ResponseWriter, r *http.Request, group string,
	callbackChannel, errorChannel chan []byte) {

	checkCallbackNil(callbackChannel, false, "ChannelGroupRemoveGroup")
	checkCallbackNil(errorChannel, true, "ChannelGroupRemoveGroup")

	pub.executeChannelGroup(context, w, r, "remove_group", group, "",
		callbackChannel, errorChannel)
}

func (pub *Pubnub) generateStringforCGRequest(action, group,
	channel string) (requestURL bytes.Buffer) {
	params := url.Values{}

	requestURL.WriteString("/v1/channel-registration")
	requestURL.WriteString("/sub-key/")
	requestURL.WriteString(pub.SubscribeKey)
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

	if strings.TrimSpace(pub.AuthenticationKey) != "" {
		params.Set("auth", pub.AuthenticationKey)
	}

	params.Set("uuid", pub.GetUUID())
	params.Set(sdkIdentificationParamKey, sdkIdentificationParamVal)

	requestURL.WriteString("?")
	requestURL.WriteString(params.Encode())

	return requestURL
}

func (pub *Pubnub) executeChannelGroup(context context.Context,
	w http.ResponseWriter, r *http.Request, action, group, channel string,
	callbackChannel, errorChannel chan []byte) {

	requestURL := pub.generateStringforCGRequest(action, group, channel)

	value, _, err := pub.httpRequest(context, w, r,
		requestURL.String(), nonSubscribeTrans)

	if err != nil {
		log.Errorf(context, fmt.Sprintf("%s", err.Error()))
		pub.sendResponseToChannel(errorChannel, "", responseAsIsError,
			err.Error(), "")
	} else {
		_, _, _, errJSON := ParseJSON(value, pub.CipherKey)
		if errJSON != nil && strings.Contains(errJSON.Error(), invalidJSON) {
			log.Errorf(context, fmt.Sprintf("%s", errJSON.Error()))
			pub.sendResponseToChannel(errorChannel, "", responseAsIsError,
				errJSON.Error(), "")
			pub.executeChannelGroup(context, w, r, action, group, channel,
				callbackChannel, errorChannel)
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
		jsonData, err := json.Marshal(fmt.Sprintf("%v", vv[0]))
		if err == nil {
			return string(jsonData)
		}
		return fmt.Sprintf("%v", vv[0])
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
					vv[i] = intf
				} else {
					vv[i] = unescapeVal
				}
			}
		}
	}
	length := len(vv)
	if length > 0 {
		jsonData, err := json.Marshal(vv)
		if err == nil {
			return string(jsonData)
		}

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
func (pub *Pubnub) httpRequest(context context.Context, w http.ResponseWriter, r *http.Request, requestURL string, action int) ([]byte, int, error) {
	requrl := pub.Origin + requestURL

	log.Infof(context, fmt.Sprintf("url: %s", requrl))

	contents, responseStatusCode, err := pub.connect(context, w, r, requrl, action, requestURL)

	if err != nil {
		log.Errorf(context, fmt.Sprintf("httpRequest error: %s", err.Error()))
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
	//log.Infof(context, fmt.Sprintf("contents2 %s", contents))
	return contents, responseStatusCode, err
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
func (pub *Pubnub) initTrans(ctx context.Context, w http.ResponseWriter, r *http.Request, action int) http.RoundTripper {
	deadline := time.Duration(connectTimeout) * time.Second
	switch action {
	case subscribeTrans:
		deadline = time.Duration(subscribeTimeout) * time.Second
	case nonSubscribeTrans:
		deadline = time.Duration(nonSubscribeTimeout) * time.Second
	case retryTrans:
		deadline = time.Duration(retryInterval) * time.Second
	case presenceHeartbeatTrans:
		deadline = time.Duration(pub.GetPresenceHeartbeatInterval()) * time.Second
	}

	newCtx, _ := context.WithTimeout(ctx, deadline)
	transport := &urlfetch.Transport{
		Context: newCtx,
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
func (pub *Pubnub) createHTTPClient(context context.Context, w http.ResponseWriter, r *http.Request, action int) (*http.Client, error) {
	var transport http.RoundTripper
	transport = pub.initTrans(context, w, r, action)
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
func (pub *Pubnub) connect(context context.Context, w http.ResponseWriter, r *http.Request, requestURL string, action int, opaqueURL string) ([]byte, int, error) {
	var contents []byte
	httpClient, err := pub.createHTTPClient(context, w, r, action)

	if err == nil {
		req, err := http.NewRequest("GET", requestURL, nil)
		scheme := "http"
		if pub.IsSSL {
			scheme = "https"
		}
		req.URL = &url.URL{
			Scheme: scheme,
			Host:   origin,
			Opaque: fmt.Sprintf("//%s%s", origin, opaqueURL),
		}
		useragent := fmt.Sprintf("ua_string=(%s) PubNub-Go-GAE/3.11.0", runtime.GOOS)

		req.Header.Set("User-Agent", useragent)
		if err == nil {
			if req == nil {
				log.Errorf(context, fmt.Sprintf("req nil: %s", requestURL))
			}
			if httpClient == nil {
				log.Errorf(context, fmt.Sprintf("httpClient nil"))
			}
			if context == nil {
				log.Errorf(context, fmt.Sprintf("context nil"))
			}
			if httpClient.Transport == nil {
				log.Errorf(context, fmt.Sprintf("httpClient Transport nil"))
			}
			response, err2 := httpClient.Do(req)
			if err2 == nil {
				defer response.Body.Close()
				bodyContents, e := ioutil.ReadAll(response.Body)
				if e == nil {
					contents = bodyContents
					//log.Infof(context, fmt.Sprintf("opaqueURL %s", opaqueURL))
					//log.Infof(context, fmt.Sprintf("response: %s", string(contents)))
					//log.Infof(context, fmt.Sprintf("contents %s", contents))
					return contents, response.StatusCode, nil
				}
				log.Errorf(context, fmt.Sprintf("err %s", e.Error()))

				return nil, response.StatusCode, e
			}
			log.Errorf(context, fmt.Sprintf("err %s", err2.Error()))

			if response != nil {
				log.Errorf(context, fmt.Sprintf("httpRequest: %s, response.StatusCode: %d", err2.Error(), response.StatusCode))
				return nil, response.StatusCode, err2
			}
			log.Errorf(context, fmt.Sprintf("httpRequest: %s", err2.Error()))
			return nil, 0, err2
		}
		log.Errorf(context, fmt.Sprintf("httpRequest: %s", err.Error()))
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
