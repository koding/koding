package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"testing"
	"time"

	"code.google.com/p/go.net/websocket"
)

// sock.js protocol is described here:
// http://sockjs.github.io/sockjs-protocol/sockjs-protocol-0.3.3.html#section-36
const url = "ws://localhost:8008/subscribe/0/0/websocket"
const origin = "http://localhost/"

func init() {
	// Start broker before tests
	go main()
	time.Sleep(1e9)
}

func TestBroker(t *testing.T) {
	client, err := dialSockJS(url, origin)
	if err != nil {
		t.Errorf(err.Error())
		return
	}

	go client.Run()

	type testCase struct{ send, expect string }
	cases := []testCase{
		testCase{`{"action": "ping"}`, `{"routingKey":"broker.pong","payload":null}`},
	}

	for _, tc := range cases {
		err = client.SendAndExpectString(tc.send, tc.expect)
		if err != nil {
			t.Errorf(err.Error())
			return
		}
	}

	client.Close()
}

// cheap imitation of sockjs-client js library
type sockJSClient struct {
	ws       *websocket.Conn
	messages chan []byte
}

func dialSockJS(url, origin string) (*sockJSClient, error) {
	ws, err := websocket.Dial(url, "", origin)
	if err != nil {
		return nil, err
	}
	return newSockJSClient(ws), nil
}

func newSockJSClient(ws *websocket.Conn) *sockJSClient {
	return &sockJSClient{
		ws:       ws,
		messages: make(chan []byte),
	}
}

// read messages from websocket and put it to the channel
func (c *sockJSClient) Run() error {
	defer close(c.messages)
	for {
		var data []byte
		err := websocket.Message.Receive(c.ws, &data)
		if err != nil {
			return err
		}
		fmt.Printf("--- read data: %+v\n", string(data))
		c.didMessage(data)
	}
}

func (c *sockJSClient) Close() {
	c.ws.Close()
}

// adapted from: https://github.com/sockjs/sockjs-client/blob/master/lib/sockjs.js#L146
func (c *sockJSClient) didMessage(data []byte) error {
	switch string(data[:1]) {
	case "o":
		// that._dispatchOpen();
	case "a":
		data := data[1:]
		var messages []json.RawMessage
		err := json.Unmarshal(data, &messages)
		if err != nil {
			return err
		}
		for _, msg := range messages {
			c.messages <- msg
		}
	case "m":
		data = data[1:]
		var msg json.RawMessage
		err := json.Unmarshal(data, &msg)
		if err != nil {
			return err
		}
		c.messages <- msg
	case "c":
		// var payload = JSON.parse(data.slice(1) || "[]")
		// that._didClose(payload[0], payload[1])
	case "h":
		// that._dispatchHeartbeat()
	}

	return nil
}

// send a string and expect reply
func (c *sockJSClient) SendAndExpectString(sent, expected string) error {
	return c.SendAndExpect([]byte(sent), []byte(expected))
}

// send a []byte and expect reply
func (c *sockJSClient) SendAndExpect(sent []byte, expected []byte) error {
	err := websocket.Message.Send(c.ws, sent)
	if err != nil {
		return err
	}
	fmt.Printf("--- sent data: %+v\n", string(sent))

	for {
		select {
		case msg := <-c.messages:
			fmt.Printf("--- msg: %+v\n", string(msg))

			if bytes.Compare(msg, expected) == 0 {
				return nil
			}
		case <-time.After(1e9):
			return errors.New("timeout")
		}
	}

	return nil
}
