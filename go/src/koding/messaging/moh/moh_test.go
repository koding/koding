package moh

import (
	"bytes"
	"log"
	"net/http"
	"testing"
	"time"
)

const (
	testAddr    = "127.0.0.1:18500"
	testMessage = "cenk"
	testWait    = 10 * time.Millisecond
)

var testData = []byte(testMessage)

func TestRequestReply(t *testing.T) {
	log.Println("Creating new Replier")
	srv := NewMessagingServer(echoReplier)
	go srv.ListenAndServe(testAddr)
	defer srv.Close()

	log.Println("Creating new Requester")
	cl := NewMessagingClient(testAddr, nil)

	log.Println("Making a request")
	reply, _ := cl.Request(testData)
	if bytes.Compare(reply, testData) != 0 {
		t.Errorf("Invalid response: %s", reply)
	}
}

func TestPublishSubscibe(t *testing.T) {
	log.Println("Creating new Publisher")
	srv := NewMessagingServer(nil)
	go srv.ListenAndServe(testAddr)
	defer srv.Close()

	log.Println("Creating new Subscriber")
	ch := make(chan bool, 1)
	cl := NewMessagingClient(testAddr, withChan(echoHandler, ch))
	cl.Connect()

	log.Println("Subscribing key")
	cl.Subscribe("asdf")

	// Wait for the subscribe request to be processed
	// Normally Subscribe() and Publish() will be called from seperate processes.
	// However, it the test we have to call them consequently from the same process.
	time.Sleep(testWait)

	log.Println("Publishing a message")
	srv.Publish("asdf", testData)

	log.Println("Waiting for a message")
	select {
	case <-ch:
	case <-time.After(1 * time.Second):
		t.Error("Handler is not called")
	}

	// Lets test Unsubscribe method
	cl.Unsubscribe("asdf")
	// Allow the unsubscribe message to be processed on the server
	time.Sleep(testWait)

	log.Println("Publishing another message, this should not be delivered")
	srv.Publish("asdf", testData)

	log.Println("Waiting for a message")
	select {
	case <-ch:
		t.Error("Handler is called")
	case <-time.After(testWait):
	}
}

func TestBroadcast(t *testing.T) {
	log.Println("Creating new Publisher")
	srv := NewMessagingServer(nil)
	go srv.ListenAndServe(testAddr)
	defer srv.Close()

	log.Println("Creating new Subscriber")
	ch := make(chan bool, 1)
	cl := NewMessagingClient(testAddr, withChan(echoHandler, ch))
	cl.Connect()

	// Explained in TestPublishSubscibe
	time.Sleep(testWait)

	log.Println("Publishing a message")
	srv.Broadcast(testData)

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

func echoReplier(r *http.Request, message []byte) ([]byte, error) {
	return message, nil
}
