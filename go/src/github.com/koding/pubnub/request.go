package pubnub

import (
	"encoding/json"
	"errors"
	"fmt"
	"sync"
	"time"
)

var (
	ErrRecvMessage = errors.New("message not received")
	ErrInvalidKey  = errors.New("invalid key")
)

// PubNubRequest is used for each PubNub api call
type PubNubRequest struct {
	// request timeout value in second
	Timeout int
	// connected channel name
	channelName string
	// used for pubnub success responses
	successCh chan []byte
	// used for pubnub errors
	errorCh chan []byte
	// used for connection initialization
	done chan error
	// used for closing response handler
	closeCh chan struct{}
	// used for received channel messages
	messages chan<- Message
	// used for parsed errors
	errors chan<- error

	once sync.Once
}

func NewPubNubRequest(channelName string, messages chan<- Message, errors chan<- error) *PubNubRequest {
	return &PubNubRequest{
		successCh:   make(chan []byte),
		errorCh:     make(chan []byte),
		done:        make(chan error),
		closeCh:     make(chan struct{}),
		errors:      errors,
		messages:    messages,
		channelName: channelName,
		Timeout:     5,
	}
}

func (pr *PubNubRequest) Do() error {
	select {
	case err := <-pr.done:
		return err
	case <-time.After(time.Duration(pr.Timeout) * time.Second):
		return ErrTimeout
	}
}

func (pr *PubNubRequest) Close() {
	pr.closeCh <- struct{}{}
}

func (pr *PubNubRequest) handleResponse() {
	for {
		select {
		case response := <-pr.successCh:
			pr.parseResponse(response)
		case failure := <-pr.errorCh:
			pr.parseErrorResponse(failure)
		case <-pr.closeCh:
			return
		}
	}
}

func (pr *PubNubRequest) parseResponse(response []byte) {
	var r interface{}
	err := json.Unmarshal(response, &r)
	if err != nil {
		pr.sendError(err)
	}

	// another awkward handler
	// pubnub client send two different types of response
	// 1- grant successful response is a map
	// 2- publish/subscription responses are array
	// lovely world
	switch r.(type) {
	case []interface{}:
		rp := r.([]interface{})
		// response array is empty
		if len(rp) < 2 {
			return
		}

		// success response from pubnub
		if rp[0] == float64(1) {
			pr.parseSuccessResponse(rp)
			return
		}

		pr.parseMessageResponse(rp)
	case map[string]interface{}:
		// this is an http response
		pr.parseGrantResponse(r.(map[string]interface{}))
	}

}

func (pr *PubNubRequest) parseGrantResponse(response map[string]interface{}) {
	isError, ok := response["error"].(bool)

	message, ok := response["message"].(string)
	if !ok {
		return
	}

	if !isError && message == "Success" {
		pr.initialize(nil)
		return
	}

	if message != "" {
		pr.sendError(errors.New(message))
	}
}

func (pr *PubNubRequest) parseErrorResponse(response []byte) {
	// TODO if you are receiving a `invalid character 's' after array element`
	// error, probably subscription key is wrong. Actual response is as following:
	// [0, "{"status":400,"service":"Access Manager","error":true,"message":"Invalid Subscribe Key","payload":{"channels":["testme"]}}"
	// and we are not able to unmarshal it. Damn you broccoli
	var r []interface{}
	err := json.Unmarshal(response, &r)
	if err != nil {
		pr.sendError(errors.New(string(response)))
		return
	}

	// response array is empty
	responseLength := len(r)
	if responseLength < 3 {
		return
	}

	// error connection response
	if r[0] != float64(0) {
		return
	}

	switch r[1] {
	// with each subscription pubnub client resubscribes to the channels
	case "Connection aborted":
	case "Subscription to channel aborted due to max retry limit":
		pr.sendError(ErrConnectionAbort)
	case "Invalid Key":
		pr.sendError(ErrInvalidKey)
	default:
		// get message from response and send it as error
		errStr, ok := r[1].(string)
		if !ok {
			return
		}

		if responseLength == 4 {
			if v, ok := r[2].(string); ok {
				errStr = v
			}
		}

		if errStr == "" {
			return
		}

		pr.sendError(errors.New(errStr))
	}
}

func (pr *PubNubRequest) sendError(err error) {
	pr.initialize(err)

	select {
	case pr.errors <- err:
	default:
	}
}

// Sorry for this awkward response parse, but successful responses of pubnub:
// Subsciption: [1, "Subscription to channel 'channelname' connected", "channelname"]
// Publish    : [1, "Sent", {timestamp}]
func (pr *PubNubRequest) parseSuccessResponse(response []interface{}) {
	if response[1] == fmt.Sprintf("Subscription to channel '%s' connected", pr.channelName) || response[1] == "Sent" {
		pr.initialize(nil)
		return
	}
	// TODO reconnected response must be handled
	// fmt.Println("unhandled success response", r[1])
}

func (pr *PubNubRequest) initialize(err error) {
	pr.once.Do(func() {
		pr.done <- err
	})
}

func (pr *PubNubRequest) parseMessageResponse(response []interface{}) {
	if pr.messages == nil {
		return
	}

	messages, ok := response[0].([]interface{})
	if !ok {
		pr.sendError(ErrRecvMessage)
		return
	}

	for _, value := range messages {
		m := Message{
			Body: value,
		}

		pr.messages <- m
	}
}

/////////////// Message //////////////////
type Message struct {
	Body interface{}
}
