package kitepinger

import (
	"errors"
	"fmt"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/koding/kite"
)

type fakePinger struct {
	ReturnStatus Status
}

func (p *fakePinger) Ping() Status {
	return p.ReturnStatus
}

func TestSubscribe(t *testing.T) {
	p := &PingTracker{
		nodata:      struct{}{},
		subscribers: map[chan<- ChangeSummary]struct{}{},
	}

	// broadcast with no subscribers, to make sure we don't panic/etc
	p.broadcastSummary(ChangeSummary{})

	a := make(chan ChangeSummary, 1)
	p.Subscribe(a)

	_, ok := p.subscribers[a]
	if !ok {
		t.Error("Expected Register to store channels")
	}
}

func TestUnsubscribe(t *testing.T) {
	p := &PingTracker{
		nodata:      struct{}{},
		subscribers: map[chan<- ChangeSummary]struct{}{},
		ticker:      time.NewTicker(time.Minute),
		pinging:     true,
	}

	// broadcast with no subscribers, to make sure we don't panic/etc
	p.broadcastSummary(ChangeSummary{})

	a := make(chan ChangeSummary, 1)
	b := make(chan ChangeSummary, 1)
	c := make(chan ChangeSummary, 1)
	p.Subscribe(a)
	p.Subscribe(b)
	p.Subscribe(c)

	p.Unsubscribe(b)

	_, ok := p.subscribers[b]
	if ok {
		t.Error("Expected Unregister to remove channels")
	}

	if len(p.subscribers) != 2 {
		t.Errorf(
			"Expected to leave existing channels alone. Wanted %d, have %d",
			2, len(p.subscribers),
		)
	}

	if p.pinging != true {
		t.Error("Expected Unsubscribe to not call Stop() if there are still subs")
	}

	p.Unsubscribe(a)
	p.Unsubscribe(c)

	if len(p.subscribers) != 0 {
		t.Errorf(
			"Expected to all subs to be gone. Wanted %d, have %d",
			0, len(p.subscribers),
		)
	}

	if p.pinging != false {
		t.Error("Expected Unsubscribe to call Stop() if there are no subs")
	}
}

func TestBroadcastSummary(t *testing.T) {
	p := &PingTracker{
		nodata:      struct{}{},
		subscribers: map[chan<- ChangeSummary]struct{}{},
	}

	// broadcast with no subscribers, to make sure we don't panic/etc
	p.broadcastSummary(ChangeSummary{})

	a := make(chan ChangeSummary, 1)
	p.Subscribe(a)
	p.broadcastSummary(ChangeSummary{
		NewStatus: Success,
	})
	select {
	case s := <-a:
		// Just check if we get the proper value
		if s.NewStatus != Success {
			t.Errorf(
				"Expected broadcastSummary() to send the given Summary to a single channel. Wanted %s, Got %s",
				Success, s.NewStatus,
			)
		}
	case <-time.After(200 * time.Millisecond):
		t.Error("Expected broadcastSummary() to call a single channel.")
	}

	b := make(chan ChangeSummary, 1)
	p.Subscribe(b)

	// Use different data than above
	p.broadcastSummary(ChangeSummary{
		NewStatus: Failure,
	})

	aCount, bCount := 0, 0
	timeout := time.After(200 * time.Millisecond)
	for i := 0; i < 2; i++ {
		select {
		case s := <-a:
			aCount++
			if s.NewStatus != Failure {
				t.Errorf(
					"Expected broadcastSummary() to send the given Summary to a multiple channels. Wanted %s, Got %s",
					Failure, s.NewStatus,
				)
			}
		case s := <-b:
			bCount++
			if s.NewStatus != Failure {
				t.Errorf(
					"Expected broadcastSummary() to send the given Summary to a multiple channels. Wanted %s, Got %s",
					Failure, s.NewStatus,
				)
			}
		case <-timeout:
			t.Error("Timed out waiting for Notify() to call all channels")
		}
	}

	if aCount != 1 {
		t.Errorf(
			"Expected broadcastSummary to call each channel once. Wanted aCount of %d, got %d",
			1, aCount,
		)
	}

	if bCount != 1 {
		t.Errorf(
			"Expected broadcastSummary to call each channel once. Wanted bCount of %d, got %d",
			1, bCount,
		)
	}

	// Using a non-buffered channel here. Please see the explanation below
	// on the line that checks for:
	//
	//		if notBufferedCount != 0
	notBuffered := make(chan ChangeSummary)

	p.Subscribe(notBuffered)
	// Use different data than above
	p.broadcastSummary(ChangeSummary{
		NewStatus: Success,
	})

	aCount, bCount, notBufferedCount := 0, 0, 0
	timeout = time.After(200 * time.Millisecond)
	for i := 0; i < 2; i++ {
		select {
		case s := <-a:
			aCount++
			if s.NewStatus != Success {
				t.Errorf(
					"Expected broadcastSummary() to send the given Summary despite non-receiving channels. Wanted %s, Got %s",
					Success, s.NewStatus,
				)
			}
		case s := <-b:
			bCount++
			if s.NewStatus != Success {
				t.Errorf(
					"Expected broadcastSummary() to send the given Summary despite non-receiving channels. Wanted %s, Got %s",
					Success, s.NewStatus,
				)
			}
		case <-notBuffered:
			notBufferedCount++
		case <-timeout:
			t.Error("Timed out waiting for Notify() to call all channels")
		}
	}

	if aCount != 1 {
		t.Errorf(
			"Expected broadcastSummary to call each channel once. Wanted aCount of %d, got %d",
			1, aCount,
		)
	}

	if bCount != 1 {
		t.Errorf(
			"Expected broadcastSummary to call each channel once. Wanted bCount of %d, got %d",
			1, bCount,
		)
	}

	// Not buffered, means the broadcastSummary will be unable to send to the channel
	// because nothing is *currently* receiving from the channel when
	// broadcastSummary() occurs. broadcastSummary() should not block and wait for it.
	//
	// If broadcastSummary() does block, the receiver (in this test) will never get
	// a chance to listen either.. so really this shouldn't be possible..
	if notBufferedCount != 0 {
		t.Errorf("Expected broadcastSummary() to ignored the notBuffered channel because, at the time of sending, it was not receiving. Wanted %d, Got %d",
			0, notBufferedCount)
	}
}

func TestPing(t *testing.T) {
	r := kite.New("remote", "0.0.0")
	r.Config.DisableAuthentication = true
	ts := httptest.NewServer(r)

	var (
		shouldError bool
		pingCount   int
	)

	r.HandleFunc("kite.ping", func(req *kite.Request) (interface{}, error) {
		pingCount++

		if shouldError {
			return nil, errors.New("Told to error")
		}

		return "pong", nil
	})

	l := kite.New("local", "0.0.0").NewClient(fmt.Sprintf("%s/kite", ts.URL))

	// Connect the local client to the remote
	err := l.Dial()
	if err != nil {
		t.Fatal("Failed to connect to testing Kite", err)
	}

	p := &PingTracker{
		pinger:      NewKitePinger(l),
		nodata:      struct{}{},
		subscribers: map[chan<- ChangeSummary]struct{}{},
	}

	p.Ping()

	if pingCount != 1 {
		t.Errorf(
			"Expected Ping() to ping the remote client. Wanted a PingCount of %d, Got %d",
			1, pingCount,
		)
	}

	// Tell the handler to return an error
	shouldError = true
	p.Ping()
	sFailure := p.GetSummary()

	// Tell the handler to not return an error
	shouldError = false
	p.Ping()
	sSuccess := p.GetSummary()

	if pingCount != 3 {
		t.Errorf(
			"Expected Ping() to ping the remote client. Wanted a PingCount of %d, Got %d",
			3, pingCount,
		)
	}

	if sFailure.Status != Failure {
		t.Errorf(
			"Expected Ping() to return the correct status. Wanted %s, Got %s",
			Failure, sFailure.Status,
		)
	}

	if sSuccess.Status != Success {
		t.Errorf(
			"Expected Ping() to return the correct status. Wanted %s, Got %s",
			Success, sSuccess.Status,
		)
	}

	// Sleeping will increase the time that Ping has held the same status, ie
	// the CurrentSummary.StatusDur duration.
	time.Sleep(time.Millisecond * 100)
	p.Ping()

	// Allow for a 10ms variation in reported runtime.
	msDur := p.GetSummary().StatusDur.Nanoseconds() / 1000000
	if msDur < 90 || msDur > 120 {
		t.Errorf(
			"Expected CurrentSummary.StatusDur to be similar to the elapsed time. Wanted larger than %d and less than %d, Got %d",
			90, 120, msDur,
		)
	}

	// Record the value that KitePinger thinks it pinged at, for a future test
	lastPingedAt := p.pingedAt

	// Make a new subscriber and subscribe, then cause a failed ping
	a := make(chan ChangeSummary, 1)
	p.Subscribe(a)

	shouldError = true
	p.Ping()

	var summaryFromChan ChangeSummary
	select {
	case summaryFromChan = <-a:
	case <-time.After(100 * time.Millisecond):
		t.Error("Expected broadcastSummary() to call a single channel.")
	}

	if summaryFromChan.NewStatus != Failure {
		t.Errorf(
			"Expected Ping() to return the new status. Wanted %s, Got %s",
			Success, summaryFromChan.NewStatus,
		)
	}

	if summaryFromChan.OldStatus != Success {
		t.Errorf(
			"Expected Ping() to return the new status. Wanted %s, Got %s",
			Success, summaryFromChan.NewStatus,
		)
	}

	msSince := time.Since(summaryFromChan.NewStatusTime).Nanoseconds() / 1000000
	if msSince > 10 {
		t.Errorf(
			"Expected the new status time to me from a X ms ago. Wanted %dms, Got %dms",
			10, msSince,
		)
	}

	if p.pingedAt == lastPingedAt {
		t.Errorf(
			"Expected pingedAt to be set with each new ping. Wanted %s, Got %s",
			p.pingedAt, lastPingedAt,
		)
	}
}

func TestStartPinging(t *testing.T) {
	// Used as a reference point to test with time values and keep consistent
	// relative to this single point in time.
	now := time.Now()

	p := &PingTracker{
		nodata:      struct{}{},
		subscribers: map[chan<- ChangeSummary]struct{}{},
	}

	// Manually add our subscriber
	sCh := make(chan ChangeSummary, 1)
	p.subscribers[sCh] = p.nodata

	// Set the date values, such as pingedAt and expiration, so that our startPinging
	// call has to invalidate the success
	p.statusExpiration = time.Second
	p.pingedAt = now.Add(-(time.Second * 2))
	p.lastStatus = Success

	tCh := make(chan time.Time, 1)
	go p.startPinging(tCh)
	tCh <- now

	select {
	case s := <-sCh:
		if s.NewStatus != Failure {
			t.Errorf(
				"Expected startPinging() to broadcast a the fake Status. Wanted %s, Got %s",
				Failure, s.NewStatus,
			)
		}

		if s.NewStatusTime != now.Add(-(time.Second * 2)) {
			t.Errorf(
				"Expected startPinging() to broadcast an offset time. Wanted %s, Got %s",
				now.Add(-(time.Second * 2)), s.NewStatusTime,
			)
		}

	case <-time.After(200 * time.Millisecond):
		t.Error("Expected startPinging() to broadcast in the test. Channel timed out.")
	}

	if p.pingedAt != now {
		t.Errorf(
			"Expected startPinging() to set the pingedAt to the tick time. Wanted %s, Got %s",
			now, p.pingedAt,
		)
	}
}
