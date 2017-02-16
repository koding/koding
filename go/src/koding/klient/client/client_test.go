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

// handlerWrapper is a kite Handler middle-ware that allows to check when
// handling function finished its execution.
func handlerWrapper(h kite.HandlerFunc) (<-chan struct{}, kite.HandlerFunc) {
	doneC := make(chan struct{}, 1)
	return doneC, kite.HandlerFunc(func(req *kite.Request) (interface{}, error) {
		result, err := h(req)
		select {
		case doneC <- struct{}{}:
		case <-time.After(5 * time.Second):
			panic("invalid number of handler callas")
		}

		return result, err
	})
}

// wait is a helper function that waits for an event from done channel or
// timeouts after specified timeout. This function must be called from main
// go-routine only.
func wait(doneC <-chan struct{}, timeout time.Duration) error {
	select {
	case <-doneC:
	case <-time.After(timeout):
		return fmt.Errorf("timed out after %v", timeout)
	}

	return nil
}

// getCopy gets subscriptions from PubSub structure. In order to avoid data
// races, it returns a copy of stored map.
func getCopy(ps *PubSub, name string) map[int]dnode.Function {
	ps.subMu.Lock()
	defer ps.subMu.Unlock()
	subs, ok := ps.Subscriptions[name]

	if !ok {
		return nil
	}

	subsCopy := make(map[int]dnode.Function)
	for key, val := range subs {
		subsCopy[key] = val
	}

	return subsCopy
}

func TestSubscribe(t *testing.T) {
	ps := NewPubSub(logging.NewLogger("testing"))

	s := kite.New("s", "0.0.0")
	s.Config.DisableAuthentication = true

	doneC, subscribe := handlerWrapper(ps.Subscribe)
	s.HandleFunc("client.Subscribe", subscribe)

	ts := httptest.NewServer(s)
	defer ts.Close()

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
	if err = wait(doneC, time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
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
	if err = wait(doneC, time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
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
	if err = wait(doneC, time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
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
	if err = wait(doneC, time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// Should subscribe to any given event name
	pRes, err := c1.Tell("client.Subscribe", SubscribeRequest{
		EventName: "test",
		OnPublish: dnode.Callback(func(f *dnode.Partial) {}),
	})
	if err != nil {
		t.Error(err)
	}
	if err = wait(doneC, time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	subs := getCopy(ps, "test")
	if len(subs) != 1 {
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
	successC := make(chan struct{}, 1)
	pRes, _ = c1.Tell("client.Subscribe", SubscribeRequest{
		EventName: "test",
		OnPublish: dnode.Callback(func(f *dnode.Partial) {
			select {
			case successC <- struct{}{}:
			case <-time.After(time.Second): // Don't leak go-routines.
			}
		}),
	})
	if err = wait(doneC, time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	if err != nil {
		t.Fatal(err)
	}

	subs = getCopy(ps, "test")
	if len(subs) != 2 {
		t.Fatal("client.Subscribe should store multiple onPublish callbacks")
	}

	subs[2].Call()
	if err = wait(successC, time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
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
		OnPublish: dnode.Callback(func(_ *dnode.Partial) {}),
	})
	if err != nil {
		t.Error(err)
	}
	if err = wait(doneC, time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	subs = getCopy(ps, "test")
	if len(subs) != 3 {
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

	// disconnectFunc will be added to kite's OnDisconnect callback slice.
	// Since kite callbacks are synchronous, we will provide synchronization
	// with Subscriptions map.
	disconnectedC := make(chan struct{})
	s.OnDisconnect(func(_ *kite.Client) {
		select {
		case disconnectedC <- struct{}{}:
		case <-time.After(time.Second):
		}
	})

	// Should remove onPublish func after the client disconnects
	c1.Close()
	if err = wait(disconnectedC, 2*time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	subs = getCopy(ps, "test")
	if len(subs) != 1 {
		t.Error("client.Subscribe",
			"should remove all of a clients callbacks on Disconnect")
	}

	// Should remove the map, when all clients disconnect
	c2.Close()
	if err = wait(disconnectedC, 2*time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	subs = getCopy(ps, "test")
	if subs != nil {
		t.Error("client.Subscribe",
			"should remove the event map when all clients disconnect")
	}
}

func TestPublish(t *testing.T) {
	ps := NewPubSub(logging.NewLogger("testing"))
	s := kite.New("s", "0.0.0")
	s.Config.DisableAuthentication = true

	doneC, publish := handlerWrapper(ps.Publish)
	s.HandleFunc("client.Publish", publish)

	ts := httptest.NewServer(s)
	defer ts.Close()

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
	if err = wait(doneC, time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
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
	if err = wait(doneC, time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// Should require subscriptions for the given event
	_, err = c.Tell("client.Publish", PublishRequest{
		EventName: "foo",
	})
	if err == nil {
		t.Error("client.Publish should return an error, without any subs")
	}
	if err = wait(doneC, time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// Should call onPublish callbacks
	callbackCount := 0
	ps.Subscriptions["test"] = map[int]dnode.Function{
		0: {mockCaller(func(v ...interface{}) error {
			callbackCount += 1
			return nil
		})},
		1: {mockCaller(func(v ...interface{}) error {
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
	if err = wait(doneC, time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	if callbackCount != 3 {
		t.Fatal("client.Publish should call onPublish callbacks")
	}

	// Should publish arbitrary data
	var b []byte
	updatedC := make(chan struct{}, 1)
	ps.Subscriptions["other"] = map[int]dnode.Function{
		0: {mockCaller(func(v ...interface{}) error {
			b = v[0].([]interface{})[0].(*dnode.Partial).Raw
			select {
			case updatedC <- struct{}{}:
			case <-time.After(time.Second):
			}
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
	if err = wait(doneC, time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// callback is called by another go-routine. we need to synchronize it.
	if err = wait(updatedC, time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
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

	donePubC, publish := handlerWrapper(ps.Publish)
	s.HandleFunc("client.Publish", publish)

	doneSubC, subscribe := handlerWrapper(ps.Subscribe)
	s.HandleFunc("client.Subscribe", subscribe)

	doneUnsubC, unsubscribe := handlerWrapper(ps.Unsubscribe)
	s.HandleFunc("client.Unsubscribe", unsubscribe)

	ts := httptest.NewServer(s)
	defer ts.Close()

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
	callsMu := sync.Mutex{} // protects calls map.
	calls := map[string]bool{}
	var wg sync.WaitGroup
	wg.Add(3)

	// Setup our event, sub index 1
	_, err = c1.Tell("client.Subscribe", SubscribeRequest{
		EventName: "test",
		OnPublish: dnode.Callback(func(f *dnode.Partial) {
			defer wg.Done()

			callsMu.Lock()
			defer callsMu.Unlock()
			calls["c1:1"] = true
		}),
	})
	if err != nil {
		t.Fatal(err)
	}
	if err = wait(doneSubC, time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// Setup our event, sub index 2
	_, err = c2.Tell("client.Subscribe", SubscribeRequest{
		EventName: "test",
		OnPublish: dnode.Callback(func(f *dnode.Partial) {
			defer wg.Done()

			callsMu.Lock()
			defer callsMu.Unlock()
			calls["c2:2"] = true
		}),
	})
	if err != nil {
		t.Fatal(err)
	}
	if err = wait(doneSubC, time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// Setup our event, sub index 3
	_, err = c2.Tell("client.Subscribe", SubscribeRequest{
		EventName: "test",
		OnPublish: dnode.Callback(func(f *dnode.Partial) {
			defer wg.Done()

			callsMu.Lock()
			defer callsMu.Unlock()
			calls["c2:3"] = true
		}),
	})
	if err != nil {
		t.Fatal(err)
	}
	if err = wait(doneSubC, time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// Setup our event, sub index 4
	_, err = c1.Tell("client.Subscribe", SubscribeRequest{
		EventName: "test",
		OnPublish: dnode.Callback(func(f *dnode.Partial) {
			defer wg.Done()

			callsMu.Lock()
			defer callsMu.Unlock()
			calls["c1:4"] = true
		}),
	})
	if err != nil {
		t.Fatal(err)
	}
	if err = wait(doneSubC, time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// Should remove subs from client
	_, err = c2.Tell("client.Unsubscribe", UnsubscribeRequest{
		EventName: "test",
		ID:        2,
	})
	if err != nil {
		t.Fatal(err)
	}
	if err = wait(doneUnsubC, time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	subs := getCopy(ps, "test")
	if expected := 3; len(subs) != expected {
		t.Fatalf(
			"client.Unsubscribe should remove callbacks. Wanted:%d, Got:%d",
			expected, len(subs),
		)
	}

	// Should publish to the expected methods. The above check should
	// work for this, but just to be safe lets actually publish and make sure
	// the subs work like we expect.
	_, err = c1.Tell("client.Publish", PublishRequest{
		EventName: "test",
	})
	if err = wait(donePubC, time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// Block, waiting for the goroutines to call the callbacks.
	wg.Wait()

	expected := map[string]bool{"c1:1": true, "c2:3": true, "c1:4": true}
	if !reflect.DeepEqual(expected, calls) {
		t.Errorf(
			"client.Unsubscribe should prevent callbacks from receiving calls. Wanted:%s, Got:%s",
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
	if err = wait(doneUnsubC, time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// Should publish to the expected methods.
	_, err = c1.Tell("client.Publish", PublishRequest{
		EventName: "test",
	})
	if err = wait(donePubC, time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// Block, waiting for the goroutines to call the callbacks.
	wg.Wait()

	expected = map[string]bool{"c1:1": true, "c2:3": true}
	if !reflect.DeepEqual(expected, calls) {
		t.Errorf(
			"client.Unsubscribe should prevent callbacks from receiving calls. Wanted:%s, Got:%s",
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
	if err = wait(doneUnsubC, time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
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
	if err = wait(doneUnsubC, time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// Should remove the event map if no subs are left.
	_, err = c2.Tell("client.Unsubscribe", UnsubscribeRequest{
		EventName: "test",
		ID:        1,
	})
	if err != nil {
		t.Fatal(err)
	}
	if err = wait(doneUnsubC, time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	_, err = c2.Tell("client.Unsubscribe", UnsubscribeRequest{
		EventName: "test",
		ID:        3,
	})
	if err != nil {
		t.Fatal(err)
	}
	if err = wait(doneUnsubC, time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	if subs := getCopy(ps, "test"); subs != nil {
		t.Errorf(
			"client.Unsubscribe should remove the sub map if no subs are left, it did not.",
		)
	}
}
