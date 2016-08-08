package client

import (
	"fmt"
	"net/http/httptest"
	"reflect"
	"sync"
	"testing"
	"time"

	"github.com/koding/kite"
	"github.com/koding/kite/dnode"
	"github.com/koding/logging"
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
	pRes, err := c1.Tell("client.Subscribe", SubscribeRequest{
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

	// Should return the subIndex
	var res SubscribeResponse
	if err = pRes.Unmarshal(&res); err != nil {
		t.Errorf("client.Subscribe should return a valid response struct. err:%s", err)
	}

	if expected := 1; res.ID != expected {
		t.Errorf(
			"client.Subscribe should return the response id. Wanted:%d, Got:%d",
			expected, res.ID,
		)
	}

	// Should store the proper callback
	success := make(chan bool)
	pRes, err = c1.Tell("client.Subscribe", SubscribeRequest{
		EventName: "test",
		OnPublish: dnode.Callback(func(f *dnode.Partial) { success <- true }),
	})

	if err != nil {
		t.Fatal(err)
	}

	if len(ps.Subscriptions["test"]) != 2 {
		t.Fatal("client.Subscribe should store multiple onPublish callbacks")
	}

	ps.Subscriptions["test"][2].Call()
	select {
	case <-success:
	case <-time.After(1 * time.Second):
		t.Error("client.Subscribe should store a call-able callback.",
			"Attempt timed out.")
	}

	if err = pRes.Unmarshal(&res); err != nil {
		t.Errorf("client.Subscribe should return a valid response struct. err:%s", err)
	}

	if expected := 2; res.ID != expected {
		t.Errorf(
			"client.Subscribe should return the response id. Wanted:%d, Got:%d",
			expected, res.ID,
		)
	}

	// Should allow multiple clients to subscribe
	pRes, err = c2.Tell("client.Subscribe", SubscribeRequest{
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

	if err = pRes.Unmarshal(&res); err != nil {
		t.Errorf("client.Subscribe should return a valid response struct. err:%s", err)
	}

	if expected := 3; res.ID != expected {
		t.Errorf(
			"client.Subscribe should return the response id. Wanted:%d, Got:%d",
			expected, res.ID,
		)
	}

	// Should remove onPublish func after the client disconnects
	c1.Close()

	// Using a timer here, because c.OnDisconnect is called before the
	// sub is actually removed. I do not know how to ensure the
	// removeSubscription() func as called, this without the Sleep.
	//
	// TODO(rjeczalik): we could use testHooks* like in
	// golang.org/x/net/context/ctxhttp package and wait on
	// testHookSubRemove call.
	time.Sleep(2 * time.Second)

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
	_, err = c.Tell("client.Publish", PublishRequest{
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

	_, err = c.Tell("client.Publish", PublishRequest{
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

func TestUnsubscribe(t *testing.T) {
	ps := NewPubSub(logging.NewLogger("testing"))
	s := kite.New("s", "0.0.0")
	s.Config.DisableAuthentication = true
	s.HandleFunc("client.Publish", ps.Publish)
	s.HandleFunc("client.Subscribe", ps.Subscribe)
	s.HandleFunc("client.Unsubscribe", ps.Unsubscribe)
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

	// Track the calls to our subs.
	calls := map[string]bool{}
	var wg sync.WaitGroup
	wg.Add(3)

	// Setup our event, sub index 1
	_, err = c1.Tell("client.Subscribe", SubscribeRequest{
		EventName: "test",
		OnPublish: dnode.Callback(func(f *dnode.Partial) {
			calls["c1:1"] = true
			wg.Done()
		}),
	})
	if err != nil {
		t.Fatal(err)
	}

	// Setup our event, sub index 2
	_, err = c2.Tell("client.Subscribe", SubscribeRequest{
		EventName: "test",
		OnPublish: dnode.Callback(func(f *dnode.Partial) {
			calls["c2:2"] = true
			wg.Done()
		}),
	})
	if err != nil {
		t.Fatal(err)
	}

	// Setup our event, sub index 3
	_, err = c2.Tell("client.Subscribe", SubscribeRequest{
		EventName: "test",
		OnPublish: dnode.Callback(func(f *dnode.Partial) {
			calls["c2:3"] = true
			wg.Done()
		}),
	})
	if err != nil {
		t.Fatal(err)
	}

	// Setup our event, sub index 4
	_, err = c1.Tell("client.Subscribe", SubscribeRequest{
		EventName: "test",
		OnPublish: dnode.Callback(func(f *dnode.Partial) {
			calls["c1:4"] = true
			wg.Done()
		}),
	})
	if err != nil {
		t.Fatal(err)
	}

	// Should remove subs from client
	_, err = c2.Tell("client.Unsubscribe", UnsubscribeRequest{
		EventName: "test",
		ID:        2,
	})
	if err != nil {
		t.Fatal(err)
	}

	if expected := 3; len(ps.Subscriptions["test"]) != expected {
		t.Errorf(
			"client.Unsubscribe should remove callbacks. Wanted:%d, Got:%d",
			expected, len(ps.Subscriptions["test"]),
		)
	}

	// Should publish to the expected methods. The above check should
	// work for this, but just to be safe lets actually publish and make sure
	// the subs work like we expect.
	_, err = c1.Tell("client.Publish", PublishRequest{
		EventName: "test",
	})

	// Block, waiting for the goroutines to call the callbacks.
	wg.Wait()

	expected := map[string]bool{"c1:1": true, "c2:3": true, "c1:4": true}
	if !reflect.DeepEqual(expected, calls) {
		t.Errorf(
			"client.Unsubscribe should prevent callbacks from receving calls. Wanted:%s, Got:%s",
			expected, calls,
		)
	}
	// Reset call order
	calls = map[string]bool{}
	wg.Add(2)

	// Should allow any kite to unsub given an ID (ie, not just it's own subs)
	_, err = c2.Tell("client.Unsubscribe", UnsubscribeRequest{
		EventName: "test",
		ID:        4,
	})
	if err != nil {
		t.Fatal(err)
	}

	// Should publish to the expected methods.
	_, err = c1.Tell("client.Publish", PublishRequest{
		EventName: "test",
	})

	// Block, waiting for the goroutines to call the callbacks.
	wg.Wait()

	expected = map[string]bool{"c1:1": true, "c2:3": true}
	if !reflect.DeepEqual(expected, calls) {
		t.Errorf(
			"client.Unsubscribe should prevent callbacks from receving calls. Wanted:%s, Got:%s",
			expected, calls,
		)
	}

	// Should return ErrSubNotFound if the id does not exist.
	_, err = c2.Tell("client.Unsubscribe", UnsubscribeRequest{
		EventName: "test",
		ID:        7,
	})
	if err == nil || err.Error() != ErrSubNotFound.Error() {
		t.Errorf(
			"client.Unsubscribe: Should return the proper error when the sub is not found. Wanted:%s, Got:%s",
			ErrSubNotFound, err,
		)
	}

	// Should return ErrSubNotFound if the event does not exist.
	_, err = c2.Tell("client.Unsubscribe", UnsubscribeRequest{
		EventName: "fakeEvent",
		ID:        10,
	})
	if err == nil || err.Error() != ErrSubNotFound.Error() {
		t.Errorf(
			"client.Unsubscribe: Should return the proper error when the sub is not found. Wanted:%s, Got:%s",
			ErrSubNotFound, err,
		)
	}

	// Should remove the event map if no subs are left.
	_, err = c2.Tell("client.Unsubscribe", UnsubscribeRequest{
		EventName: "test",
		ID:        1,
	})
	if err != nil {
		t.Fatal(err)
	}
	_, err = c2.Tell("client.Unsubscribe", UnsubscribeRequest{
		EventName: "test",
		ID:        3,
	})
	if err != nil {
		t.Fatal(err)
	}

	if _, ok := ps.Subscriptions["test"]; ok {
		t.Errorf(
			"client.Unsubscribe should remove the sub map if no subs are left, it did not.",
		)
	}
}
