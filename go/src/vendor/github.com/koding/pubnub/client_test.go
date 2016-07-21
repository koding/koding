package pubnub

import (
	"os"
	"sync"
	"testing"
	"time"
)

func createClient(id string) *PubNubClient {
	cs := newClientSettings(id)

	return NewPubNubClient(cs)
}

func newClientSettings(id string) *ClientSettings {
	subscribeKey := os.Getenv("PUBNUB_SUBSCRIBE_KEY")
	publishKey := os.Getenv("PUBNUB_PUBLISH_KEY")
	secretKey := os.Getenv("PUBNUB_SECRET_KEY")

	cs := new(ClientSettings)
	if id == "" {
		uuid := os.Getenv("PUBNUB_UUID")
		cs.ID = uuid
	}

	cs.SubscribeKey = subscribeKey
	cs.PublishKey = publishKey
	cs.SecretKey = secretKey

	return cs
}

func createMessage(body string) map[string]string {
	return map[string]string{
		"eventName": "messageAdded",
		"body":      body,
	}
}

func TestSubscribe(t *testing.T) {
	pc := createClient("tester")
	defer pc.Close()
	_, err := pc.Subscribe("")

	if err != ErrChannelNotSet {
		t.Errorf("Expected channel is not set error but got %s", err)
	}

	channels := "testme"
	_, err = pc.Subscribe(channels)
	if err != nil {
		t.Errorf("Expected nil but got error while subscribing: %s", err)
	}
}

func TestPublish(t *testing.T) {
	pc := createClient("tester")
	defer pc.Close()

	message := createMessage("testing all together")
	err := pc.Push("tester1", message)
	if err != nil {
		t.Errorf("Expected nil but got error while publishing: %s", err)
	}
}

func TestMessageReception(t *testing.T) {
	sender := createClient("tester")
	receiver := createClient("receiver")

	defer func() {
		sender.Close()
		receiver.Close()
	}()

	channel, err := receiver.Subscribe("testme")
	if err != nil {
		t.Errorf("Expected nil but got error while subscribing: %s", err)
		t.FailNow()
	}

	var wg sync.WaitGroup
	go func() {
		wg.Add(1)
		defer wg.Done()
		select {
		case msg := <-channel.Consume():
			body, ok := msg.Body.(map[string]interface{})
			if !ok {
				t.Errorf("Wrong message body type")
				t.FailNow()
			}

			val, ok := body["eventName"]
			if !ok {
				t.Error("'eventName' field is expected in message but not found")
				t.Fail()
			} else {
				if val != "messageAdded" {
					t.Errorf("Expected messageAdded event in message but got %s", val)
				}
			}

			val, ok = body["body"]
			if !ok {
				t.Error("'body' field is expected in message but not found")
				t.Fail()
			} else {
				if val != "testing all together" {
					t.Errorf("Expected 'testing all together' as message body but got %s", val)
				}
			}

		case <-time.After(5 * time.Second):
			t.Errorf("Expected message but it is timedout")
			t.FailNow()
		}
	}()

	err = sender.Push("testme", createMessage("testing all together"))
	if err != nil {
		t.Errorf("Expected nil but got error while publishing: %s", err)
	}

	wg.Wait()

}

func TestMultipleMessageReception(t *testing.T) {
	sender := createClient("tester")
	receiver := createClient("receiver")

	defer func() {
		sender.Close()
		receiver.Close()
	}()

	// these subscriptions are added for checking if messages are received correctly
	// when we are subscribed to more than one channels
	channel1, err := receiver.Subscribe("channel1")
	if err != nil {
		t.Errorf("Expected nil but got got error while subscribing: %s", err)
		t.FailNow()
	}

	channel2, err := receiver.Subscribe("channel2")
	if err != nil {
		t.Errorf("Expected nil but got error while subscribing: %s", err)
		t.FailNow()
	}

	err = sender.Push("channel1", createMessage("message1"))
	if err != nil {
		t.Errorf("Expected nil but got error while publishing: %s", err)
		t.FailNow()
	}

	err = sender.Push("channel2", createMessage("message2"))
	if err != nil {
		t.Errorf("Expected nil but got error while publishing: %s", err)
		t.FailNow()
	}

	// TODO when we concurrently push message and subscribe to a channel, pushed message
	// is sometimes lost, due to reconnection process of current pubnub go-client
	// receiver.Subscribe("padme")

	testConsume := func(channel *Channel, messageBody string) {
		var wg sync.WaitGroup
		wg.Add(1)
		defer wg.Done()

		select {
		case msg := <-channel.Consume():
			body, ok := msg.Body.(map[string]interface{})
			if !ok {
				t.Errorf("Wrong message body type")
				t.FailNow()
			}

			val, ok := body["eventName"]
			if !ok {
				t.Error("'eventName' field is expected in message but not found")
				t.Fail()
			} else {
				if val != "messageAdded" {
					t.Errorf("Expected messageAdded event in message but got %s", val)
				}
			}

			val, ok = body["body"]
			if !ok {
				t.Error("'body' field is expected in message but not found")
				t.Fail()
			} else {
				if val != messageBody {
					t.Errorf("Expected '%s' as message body but got %s", messageBody, val)
				}
			}

		case <-time.After(5 * time.Second):
			t.Errorf("Expected message but it is timedout")
			t.FailNow()
		}
	}

	testConsume(channel1, "message1")
	testConsume(channel2, "message2")

}

func TestClosedChannel(t *testing.T) {
	client := createClient("tester")
	client.Close()

	if _, err := client.Subscribe("t"); err == nil {
		t.Errorf("Expected %s error but got nil", ErrConnectionClosed)
	}

	if err := client.Push("t", "e"); err == nil {
		t.Errorf("Expected %s error but got nil", ErrConnectionClosed)
	}

	if err := client.Grant(&AuthSettings{}); err == nil {
		t.Errorf("Expected %s error but got nil", ErrConnectionClosed)
	}
}
