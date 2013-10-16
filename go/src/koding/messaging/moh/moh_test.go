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
	rep := NewReplier(echoHandler)

	srv := NewMessagingServer()
	srv.Handle("/", rep)
	go srv.ListenAndServe(addr)
	defer srv.Close()

	log.Println("Creating new Requester")
	req, _ := NewRequester("http://" + addr)

	log.Println("Making a request")
	reply, _ := req.Request(data)
	if bytes.Compare(reply, data) != 0 {
		t.Errorf("Invalid response: %s", reply)
	}
}

func TestPublishSubscibe(t *testing.T) {
	log.Println("Creating new Publisher")
	pub := NewPublisher()

	srv := NewMessagingServer()
	srv.Handle("/", pub)
	go srv.ListenAndServe(addr)
	defer srv.Close()

	ch := make(chan bool, 1)
	log.Println("Creating new Subscriber")
	sub, err := NewSubscriber("ws://"+addr, withChan(echoHandler, ch))
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

	// Lets test Unsubscribe method
	sub.Unsubscribe("asdf")
	// Allow the unsubscribe message to be processed on the server
	time.Sleep(100 * time.Millisecond)

	log.Println("Publishing another message, this should not be delivered")
	pub.Publish("asdf", data)

	log.Println("Waiting for a message")
	select {
	case <-ch:
		t.Error("Handler is called")
	case <-time.After(100 * time.Millisecond):
	}
}

func TestBroadcast(t *testing.T) {
	log.Println("Creating new Publisher")
	pub := NewPublisher()

	srv := NewMessagingServer()
	srv.Handle("/", pub)
	go srv.ListenAndServe(addr)
	defer srv.Close()

	ch := make(chan bool, 1)
	log.Println("Creating new Subscriber")
	_, err := NewSubscriber("ws://"+addr, withChan(echoHandler, ch))
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
func withChan(h func([]byte) []byte, ch chan bool) func([]byte) {
	return func(message []byte) {
		h(message)
		ch <- true
	}
}

func echoHandler(message []byte) []byte {
	return message
}
