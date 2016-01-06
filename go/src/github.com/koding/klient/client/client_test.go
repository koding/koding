package client

import (
	"fmt"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite"
	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite/dnode"
	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/logging"
)

type mockCaller func(...interface{}) error

func (f mockCaller) Call(v ...interface{}) error {
	return f(v)
}

func TestSubscribe(t *testing.T) {
	ps := NewPubSub(logging.NewLogger("testing"))
	s := kite.New("s", "0.0.0")
	s.Config.DisableAuthentication = true
	s.HandleFunc("client.Subscribe", ps.Subscribe)
	ts := httptest.NewServer(s)

	c1 := kite.New("c1", "0.0.0").NewClient(fmt.Sprintf("%s/kite", ts.URL))
	c2 := kite.New("c2", "0.0.0").NewClient(fmt.Sprintf("%s/kite", ts.URL))

	err := c1.Dial()
	if err != nil {
		t.Fatal("Failed to connect to testing Kite", err)
	}
	err = c2.Dial()
	if err != nil {
		t.Fatal("Failed to connect to testing Kite", err)
	}

	// Should require arguments
	_, err = c1.Tell("client.Subscribe")
	if err == nil {
		t.Error("client.Subscribe should require args")
	}

	// Should require eventName
	_, err = c1.Tell("client.Subscribe", struct {
		Data      string
		OnPublish dnode.Function
	}{
		Data:      "foo",
		OnPublish: dnode.Callback(func(f *dnode.Partial) {}),
	})
	if err == nil {
		t.Error("client.Subscribe should require EventName")
	}

	// Should require onPublish
	_, err = c1.Tell("client.Subscribe", struct {
		eventName string
		Data      string
	}{
		eventName: "foo",
		Data:      "bar",
	})
	if err == nil {
		t.Error("client.Subscribe should require OnPublish")
	}

	// Should require valid onPublish func
	_, err = c1.Tell("client.Subscribe", struct {
		eventName string
		onPublish string
	}{
		eventName: "foo",
		onPublish: "bar",
	})
	if err == nil {
		t.Error("client.Subscribe should require a valid OnPublish func")
	}

	// Should subscribe to any given event name
	_, err = c1.Tell("client.Subscribe", struct {
		EventName string
		OnPublish dnode.Function
	}{
		EventName: "test",
		OnPublish: dnode.Callback(func(f *dnode.Partial) {}),
	})
	if err != nil {
		t.Error(err)
	}

	_, ok := ps.Subscriptions["test"]
	if !ok {
		t.Fatal("client.Subscribe should create a map for new event types")
	}

	if len(ps.Subscriptions["test"]) != 1 {
		t.Fatal("client.Subscribe should store a single onPublish callback")
	}

	// Should store the proper callback
	success := make(chan bool)
	_, err = c1.Tell("client.Subscribe", struct {
		EventName string
		OnPublish dnode.Function
	}{
		EventName: "test",
		OnPublish: dnode.Callback(func(f *dnode.Partial) { success <- true }),
	})

	if err != nil {
		t.Fatal(err)
	}

	if len(ps.Subscriptions["test"]) != 2 {
		t.Fatal("client.Subscribe should store multiple onPublish callbacks")
	}

	ps.Subscriptions["test"][1].Call()
	select {
	case <-success:
	case <-time.After(1 * time.Second):
		t.Error("client.Subscribe should store a call-able callback.",
			"Attempt timed out.")
	}

	// Should allow multiple clients to subscribe
	_, err = c2.Tell("client.Subscribe", struct {
		EventName string
		OnPublish dnode.Function
	}{
		EventName: "test",
		OnPublish: dnode.Callback(func(f *dnode.Partial) {}),
	})
	if err != nil {
		t.Error(err)
	}

	_, ok = ps.Subscriptions["test"]
	if !ok {
		t.Fatal("client.Subscribe should create a map for new event types")
	}

	if len(ps.Subscriptions["test"]) != 3 {
		t.Fatal("client.Subscribe should allow multiple clients to Sub")
	}

	// Should remove onPublish func after the client disconnects
	c1.Close()

	// Using a timer here, because c.OnDisconnect is called before the
	// sub is actually removed. I do not know how to ensure the
	// removeSubscription() func as called, this without the Sleep.
	time.Sleep(1 * time.Millisecond)

	if len(ps.Subscriptions["test"]) != 1 {
		t.Error("client.Subscribe",
			"should remove all of a clients callbacks on Disconnect")
	}

	// Should remove the map, when all clients disconnect
	c2.Close()
	time.Sleep(1 * time.Millisecond)

	_, ok = ps.Subscriptions["test"]
	if ok {
		t.Error("client.Subscribe",
			"should remove the event map when all clients disconnect")
	}

}

func TestPublish(t *testing.T) {
	ps := NewPubSub(logging.NewLogger("testing"))
	s := kite.New("s", "0.0.0")
	s.Config.DisableAuthentication = true
	s.HandleFunc("client.Publish", ps.Publish)
	s.HandleFunc("client.Subscribe", ps.Subscribe)
	ts := httptest.NewServer(s)

	k := kite.New("c", "0.0.0")
	c := k.NewClient(fmt.Sprintf("%s/kite", ts.URL))

	err := c.Dial()
	if err != nil {
		t.Fatal("Failed to connect to testing Kite", err)
	}

	// Should require args
	_, err = c.Tell("client.Publish")
	if err == nil {
		t.Error("client.Publish should require args")
	}

	// Should require eventName
	_, err = c.Tell("client.Publish", struct {
		Random string
		Data   string
	}{
		Random: "foo",
		Data:   "bar",
	})
	if err == nil {
		t.Error("client.Publish should require EventName")
	}

	// Should require subscriptions for the given event
	_, err = c.Tell("client.Publish", struct {
		EventName string
	}{
		EventName: "foo",
	})
	if err == nil {
		t.Error("client.Publish should return an error, without any subs")
	}

	// Should call onPublish callbacks
	callbackCount := 0
	ps.Subscriptions["test"] = map[int]dnode.Function{
		0: dnode.Function{mockCaller(func(v ...interface{}) error {
			callbackCount += 1
			return nil
		})},
		1: dnode.Function{mockCaller(func(v ...interface{}) error {
			callbackCount += 2
			return nil
		})},
	}

	_, err = c.Tell("client.Publish", struct {
		EventName string
	}{
		EventName: "test",
	})
	if err != nil {
		t.Fatal("client.Publish should call onPublish callbacks without error.", err)
	}

	if callbackCount != 3 {
		t.Fatal("client.Publish should call onPublish callbacks")
	}

	// Should publish arbitrary data
	var b []byte
	ps.Subscriptions["other"] = map[int]dnode.Function{
		0: dnode.Function{mockCaller(func(v ...interface{}) error {
			b = v[0].([]interface{})[0].(*dnode.Partial).Raw
			return nil
		})},
	}

	_, err = c.Tell("client.Publish", struct {
		EventName string
		CountData int
		ListData  []string
	}{
		EventName: "other",
		CountData: 42,
		ListData:  []string{"life", "universe", "everything"},
	})
	if err != nil {
		t.Fatal("client.Publish should publish data without error", err)
	}

	// This might be a faulty check, because the order of the data may
	// change. If it does, we'll just unmarshall and compare.
	expected := `{"EventName":"other","CountData":42,"ListData":["life","universe","everything"]}`
	if string(b) != expected {
		t.Error("client.Publish should publish arbitrary")
	}
}
