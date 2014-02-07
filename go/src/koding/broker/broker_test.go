package main

///////////////////////////////////////////////////////////////
// Make sure authWorker is running before running the tests. //
// You can run it with the following command:                //
//   cd /opt/koding && cake -c vagrant authWorker            //
///////////////////////////////////////////////////////////////

import (
	"bytes"
	crand "crypto/rand"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"math/rand"
	"sync"
	"testing"
	"time"

	"code.google.com/p/go.net/websocket"
)

// sock.js protocol is described here:
// http://sockjs.github.io/sockjs-protocol/sockjs-protocol-0.3.3.html#section-36
const url = "ws://localhost:8008/subscribe/%d/%s/websocket"
const origin = "http://localhost/" // not checked on broker

// returna a new sockjs url for client
func newURL() string {
	return fmt.Sprintf(url, rand.Intn(1000), RandomStringLength(8))
}

// This global instance of broker is run once when the tests are run by init() function.
var broker *Broker

func init() {
	rand.Seed(time.Now().UnixNano())
	fmt.Println("staring broker")
	broker := NewBroker()
	broker.Start()
}

func check(err error) {
	if err != nil {
		panic(err)
	}
}

func TestPingPong(t *testing.T) {
	client, err := dialSockJS(newURL(), origin)
	if err != nil {
		t.Errorf(err.Error())
		return
	}

	go client.Run()
	defer client.Close()

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
}

func TestPubSub(t *testing.T) {
	// Run subscriber
	subscriber, err := dialSockJS(newURL(), origin)
	if err != nil {
		t.Errorf(err.Error())
		return
	}
	go subscriber.Run()
	defer subscriber.Close()
	msg, err := subscriber.ReadJSON()
	if err != nil {
		t.Errorf(err.Error())
		return
	}
	if msg["routingKey"].(string) != "broker.connected" {
		t.Errorf(err.Error())
		return
	}
	t.Log("subscriber is running")

	// Run publisher
	publisher, err := dialSockJS(newURL(), origin)
	if err != nil {
		t.Errorf(err.Error())
		return
	}
	go publisher.Run()
	defer publisher.Close()
	msg, err = publisher.ReadJSON()
	if err != nil {
		t.Errorf(err.Error())
		return
	}
	if msg["routingKey"].(string) != "broker.connected" {
		t.Errorf(err.Error())
		return
	}
	t.Log("publisher is running")

	// Subscribe
	err = subscriber.SendString(`{"action": "subscribe", "routingKeyPrefix": "client.foo"}`)
	if err != nil {
		t.Errorf(err.Error())
		return
	}
	str, err := subscriber.ReadString()
	if err != nil {
		t.Errorf(err.Error())
		return
	}
	if str != `{"routingKey":"broker.subscribed","payload":"client.foo"}` {
		t.Errorf("unexpected msg: %s", str)
		return
	}
	t.Log("subscribed")

	// Publish a message
	err = publisher.SendString(`{"action": "publish", "exchange": "broker", "routingKey": "client.foo", "payload": "{\"bar\": \"baz\"}"}`)
	if err != nil {
		t.Errorf(err.Error())
		return
	}
	t.Log("published a message")

	// Receive published message
	str, err = subscriber.ReadString()
	if err != nil {
		t.Errorf(err.Error())
		return
	}
	if str != `{"routingKey":"client.foo","payload":{"bar":"baz"}}` {
		t.Errorf("unexpected msg: %s", str)
		return
	}
}

func BenchmarkBroker_1_1(b *testing.B)     { benchmarkBroker(b, 1, 1) }
func BenchmarkBroker_10_10(b *testing.B)   { benchmarkBroker(b, 10, 10) }
func BenchmarkBroker_100_100(b *testing.B) { benchmarkBroker(b, 100, 100) }

func benchmarkBroker(b *testing.B, nClient, nKey int) {
	var err error
	var wg sync.WaitGroup

	fmt.Printf("connecting with %d clients\n", nClient)
	clients := make([]*sockJSClient, nClient)
	for i := 0; i < nClient; i++ {
		clients[i], err = dialSockJS(newURL(), origin)
		check(err)
		go clients[i].Run()
		defer clients[i].Close()

		// discard "broker.connected" message
		msg, err := clients[i].ReadJSON()
		check(err)
		if msg["routingKey"].(string) != "broker.connected" {
			b.Errorf("invalid key: %s", msg["routingKey"].(string))
			return
		}
	}

	fmt.Printf("generating %d keys\n", nKey)
	keys := make([]string, nKey)
	for i := 0; i < nKey; i++ {
		keys[i] = "client." + RandomStringLength(32)
	}

	fmt.Printf("each client subscribes %d keys\n", nKey)
	for _, client := range clients {
		for _, key := range keys {
			// subscribe to key
			err := client.SendString(fmt.Sprintf(`{"action": "subscribe", "routingKeyPrefix": "%s"}`, key))
			check(err)

			// discard "broker.subscribed" message
			msg, err := client.ReadJSON()
			check(err)
			if msg["routingKey"].(string) != "broker.subscribed" {
				b.Errorf("invalid key: %s", msg["routingKey"].(string))
				return
			}
		}
	}

	// read all messages
	for _, client := range clients {
		// read all messages for all clients
		go func(client *sockJSClient) {
			for {
				_, err := client.Read()
				if err != nil {
					return
				}
				wg.Done()
			}
		}(client)
	}

	fmt.Printf("publishing %d random messages to random keys\n", b.N)
	body := fmt.Sprintf(`{"action": "publish", "exchange": "broker", "routingKey": "%s", "payload": "{\"random\": \"%s\"}"}`, keys[rand.Intn(nKey)], RandomStringLength(8))

	b.ResetTimer()
	wg.Add(b.N * nClient)
	for i := 0; i < b.N; i++ {
		go func() {
			err := clients[rand.Intn(nClient)].SendString(body)
			check(err)
		}()
	}

	fmt.Println("--- waiting for messages")
	wg.Wait()
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
		c.didMessage(data)
	}
}

func (c *sockJSClient) Close() {
	c.ws.Close()
}

// Send a []byte message to server
func (c *sockJSClient) Send(data []byte) error {
	return websocket.Message.Send(c.ws, data)
}

// Send a string message to server
func (c *sockJSClient) SendString(s string) error {
	return websocket.Message.Send(c.ws, s)
}

// adapted from: https://github.com/sockjs/sockjs-client/blob/master/lib/sockjs.js#L146
func (c *sockJSClient) didMessage(data []byte) error {
	queue := func(data []byte) {
		// fmt.Printf("- msg: %+v\n", string(data))
		c.messages <- data
	}

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
			queue(msg)
		}
	case "m":
		data = data[1:]
		var msg json.RawMessage
		err := json.Unmarshal(data, &msg)
		if err != nil {
			return err
		}
		queue(msg)
	case "c":
		// var payload = JSON.parse(data.slice(1) || "[]")
		// that._didClose(payload[0], payload[1])
	case "h":
		// that._dispatchHeartbeat()
	}

	return nil
}

// Get next JSON message from server as map[string]interface{}
func (c *sockJSClient) ReadJSON() (map[string]interface{}, error) {
	msg, err := c.Read()
	if err != nil {
		return nil, err
	}
	m := make(map[string]interface{})
	err = json.Unmarshal(msg, &m)
	if err != nil {
		return nil, err
	}
	return m, nil
}

// Get next message from server as string
func (c *sockJSClient) ReadString() (string, error) {
	msg, err := c.Read()
	if err != nil {
		return "", err
	}
	return string(msg), nil
}

// Get next message from server as []byte
func (c *sockJSClient) Read() ([]byte, error) {
	select {
	case msg, ok := <-c.messages:
		if !ok {
			return nil, errors.New("closed")
		}
		return msg, nil
	case <-time.After(10e9):
		return nil, errors.New("timeout")
	}
}

// send a string and expect reply
func (c *sockJSClient) SendAndExpectString(sent, expected string) error {
	return c.SendAndExpect([]byte(sent), []byte(expected))
}

// send a []byte and expect reply
func (c *sockJSClient) SendAndExpect(sent []byte, expected []byte) error {
	err := c.Send(sent)
	if err != nil {
		return err
	}

	for {
		msg, err := c.Read()
		if err != nil {
			return err
		}
		if bytes.Compare(msg, expected) == 0 {
			return nil
		}
	}

	return nil
}

func RandomStringLength(length int) string {
	r := make([]byte, length*6/8)
	crand.Read(r)
	return base64.URLEncoding.EncodeToString(r)
}
