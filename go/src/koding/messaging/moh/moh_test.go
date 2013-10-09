package moh

import (
	"bytes"
	"log"
	"testing"
	"time"
)

const addr = "127.0.0.1:18500"
const message = "cenk"

var data = []byte(message)

func TestRequestReply(t *testing.T) {
	log.Println("Creating new Replier")
	rep, _ := NewReplier(addr, echoHandler)
	defer rep.Close()

	log.Println("Creating new Requester")
	req := NewRequester(addr)
	defer rep.Close()

	log.Println("Making a request")
	reply, _ := req.Request(data)
	if bytes.Compare(reply, data) != 0 {
		t.Errorf("Invalid response: %s", reply)
	}
}

func TestPublishSubscibe(t *testing.T) {
	log.Println("Creating new Publisher")
	pub, err := NewPublisher(addr)
	if err != nil {
		t.Error(err)
	}
	defer pub.Close()

	ch := make(chan bool, 1)
	log.Println("Creating new Subscriber")
	sub, err := NewSubscriber(addr, withChan(echoHandler, ch))
	if err != nil {
		t.Error(err)
	}

	log.Println("Subscribing key")
	sub.Subscribe("asdf")

	// Wait for the subscribe request to be processed
	// Normally Subscribe() and Publish() will be called from seperate processes.
	// However, it the test we have to call them consequently from the same process.
	time.Sleep(100 * time.Millisecond)

	log.Println("Publishing a message")
	pub.Publish("asdf", data)

	log.Println("Waiting for a message")
	select {
	case <-ch:
	case <-time.After(1 * time.Second):
		t.Error("Handler is not called")
	}
}

func TestBroadcast(t *testing.T) {
	log.Println("Creating new Publisher")
	pub, err := NewPublisher(addr)
	if err != nil {
		t.Error(err)
	}
	defer pub.Close()

	ch := make(chan bool, 1)
	log.Println("Creating new Subscriber")
	_, err = NewSubscriber(addr, withChan(echoHandler, ch))
	if err != nil {
		t.Error(err)
	}

	// Explained in TestPublishSubscibe
	time.Sleep(100 * time.Millisecond)

	log.Println("Publishing a message")
	pub.Broadcast(data)

	log.Println("Waiting for a message")
	select {
	case <-ch:
	case <-time.After(1 * time.Second):
		t.Error("Handler is not called")
	}
}

// Since the echoHandler is called asynchronously from subscriber
// we need to put a message to the channel to understand if it's called.
func withChan(h MessageHandler, ch chan bool) MessageHandler {
	return func(message []byte) []byte {
		reply := h(message)
		ch <- true
		return reply
	}
}

func echoHandler(message []byte) []byte {
	return message
}
