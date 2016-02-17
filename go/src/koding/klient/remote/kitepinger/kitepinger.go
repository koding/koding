package kitepinger

import (
	"sync"
	"time"

	"github.com/koding/kite"
)

var (
	defaultPingInterval     = time.Second * 10
	defaultStatusExpiration = time.Minute
)

// KitePinger is an interface for pinging a kite at a set interval, and being
// notified when the ability to communicate to that kite is interrupted and
// restored.
//
// The difference between KitePinger and a Kite's normal OnDisconnect/OnConnect
// methods is the customizable frequency of notifications. With KitePinger, we
// determine if the actual communication with the Kite is failing, not the
// connection itself.
type KitePinger interface {
	// SetInterval is an optional method to set the interval of the pinging.
	SetInterval(time.Duration)

	// Start pinging the remote kite at whatever interval the KitePinger is
	// set to.
	Start()

	// Stop the KitePinger from pinging.
	Stop()

	// Manually ping the kite. This should trigger a ChangeSummary if there ends up
	// being a change.
	//
	// Note that manually calling Ping on a stopped KitePinger will likely result in
	// unusable Duration times, despite the Status itself being accurate.
	Ping()

	// Subscribe to *changes* of kitepinger status. Changes occur only if a ping was
	// succeeding, and now failed - or if it was failing, and now succedded.
	Subscribe(chan<- ChangeSummary)

	// Unsubscrube from ChangeSummary notifications.
	Unsubscribe(chan<- ChangeSummary)

	// Get the CurrentSummary of the previous pings.
	GetSummary() CurrentSummary
}

// PingKite implements the KitePinger interface.
type PingKite struct {
	// The client that this KitePinger will ping.
	client *kite.Client

	// The interval that PingKite will ping at.
	interval time.Duration

	// The maximum duration of time that a Success Status will be considered valid.
	//
	// If the time since the last pingedAt value is larger than this value, PingKite
	// will broadcast a Failure, to communicate a lapse in pings. This lapse may be
	// because the OS process itself was put to sleep, and was unable to ping
	// normally.
	//
	// This should be set to a greater value than the ping interval, or you
	// risk constantly invalidating Success statuses.
	statusExpiration time.Duration

	// The time that the last ping attempt took place.
	pingedAt time.Time

	// nodata is used as the value for every listener, since we don't
	// care about the value.
	nodata struct{}

	// A map of channels that have subscribed to KitePinger status changes. Note that
	// we're only using the map keys as a way to easily locate individual subscribers
	// in the event that they want to unsubscribe.
	subscribers map[chan<- ChangeSummary]struct{}

	lock sync.Mutex

	// Whether or not this KitePinger is actively pinging.
	pinging bool

	// The ticker for our pinging
	ticker *time.Ticker

	// The last known status
	lastStatus Status

	// The time the last known status was first set. Eg, if the network goes down and
	// status becomes Failure, statusTime == time.Now(). We then use this to measure
	// the length of time Failure has been the current status.
	statusTime time.Time
}

// NewKitePinger returns a new KitePinger, implemented by PingKite.
func NewKitePinger(c *kite.Client) KitePinger {
	return &PingKite{
		client:           c,
		interval:         defaultPingInterval,
		statusExpiration: defaultStatusExpiration,
		nodata:           struct{}{},
		subscribers:      map[chan<- ChangeSummary]struct{}{},
	}
}

// broadcastSummary sends the given summary to any subscribers.
func (p *PingKite) broadcastSummary(s ChangeSummary) {
	p.lock.Lock()
	defer p.lock.Unlock()

	for ch := range p.subscribers {
		// Select ensures that if the channel isn't able to receive, it
		// doesn't block forever. Instead, if a channel isn't waiting or
		// buffered then it will simply ignore it.
		select {
		case ch <- s:
		default:
		}
	}
}

// SetInterval is an optional method to set the interval of the pinging. In this
// implementation, SetInterval will actually restart the Pinging at the new interval.
func (p *PingKite) SetInterval(i time.Duration) {
	// If the internal interval and given interval are the same, there's no work
	// needed.
	if p.interval == i {
		return
	}

	p.interval = i

	// If we're actively pinging, we need to stop and start again.
	if p.pinging {
		p.Stop()
		p.Start()
	}
}

// Start pinging the remote kite at whatever interval the KitePinger is
// set to.
func (p *PingKite) Start() {
	if p.pinging {
		return
	}

	p.ticker = time.NewTicker(p.interval)

	// Clear the lastStatus value and then ping. By doing this we ensure that any
	// pings after this are accurate to the current state (not from an hour ago,
	// for example)
	//
	// Do this on the same goroutine as the caller to avoid any subtle race conditon.
	p.lastStatus = Unknown
	p.Ping()
	go p.startPinging(p.ticker.C)

	p.pinging = true
}

// Run a ping loop on the given time channel.
func (p *PingKite) startPinging(c <-chan time.Time) {
	for t := range c {
		pingedAgo := time.Since(p.pingedAt)

		// If the last status was Success, but it was too long ago, the
		// Kite OS process itself may have been put to sleep. Because of this,
		// we need to inform the KitePinger user that we have *not* been succesfully
		// pinging the entire time. We do that here.
		if p.lastStatus == Success && pingedAgo > p.statusExpiration {
			// Because the old status is invalid, we need to subtract the "invalid time"
			// from it.
			oldStatusDur := time.Since(p.statusTime) - pingedAgo
			oldStatus := p.lastStatus
			p.statusTime = p.pingedAt
			p.lastStatus = Failure

			go p.broadcastSummary(ChangeSummary{
				NewStatus:     p.lastStatus,
				NewStatusTime: p.statusTime,
				OldStatus:     oldStatus,
				OldStatusDur:  oldStatusDur,
			})

			// Manually set pingedAt, since this is effectively a fake ping.
			p.pingedAt = t
		} else {
			p.Ping()
		}
	}
}

// Stop the KitePinger from pinging.
func (p *PingKite) Stop() {
	if p.pinging {
		p.ticker.Stop()
		p.pinging = false
	}
}

// Ping manually pings the kite. This will trigger a ChangeSummary broadcast if
// there ends up being a change.
func (p *PingKite) Ping() {
	p.pingedAt = time.Now()

	// Default to success
	status := Success

	_, err := p.client.TellWithTimeout("kite.ping", time.Second*1)

	// If there is any error getting the response we consider it a failed ping. As such,
	// we set the status to false.
	if err != nil {
		status = Failure
	}

	// If the "current" summary doesn't match our newly discovered summary,
	// write the new one and report it to any listeners
	if p.lastStatus != status {
		oldStatus := p.lastStatus
		oldStatusDur := time.Since(p.statusTime)
		p.statusTime = time.Now()
		p.lastStatus = status

		if oldStatus != Unknown {
			go p.broadcastSummary(ChangeSummary{
				NewStatus:     p.lastStatus,
				NewStatusTime: p.statusTime,
				OldStatus:     oldStatus,
				OldStatusDur:  oldStatusDur,
			})
		}
	}
}

// GetSummary gets the CurrentSummary of the previous pings.
func (p *PingKite) GetSummary() CurrentSummary {
	return CurrentSummary{
		Status:    p.lastStatus,
		StatusDur: time.Since(p.statusTime),
	}
}

// Subscribe to *changes* of kitepinger status. Changes occur only if a ping was
// succeeding, and now failed - or if it was failing, and now succedded.
//
// It's worth noting that the given channel is unable to block the KitePinger if
// it is unable to receive. Any ChangeSummaries not being actively received (ie,
// waited for) will be dropped.
func (p *PingKite) Subscribe(ch chan<- ChangeSummary) {
	p.lock.Lock()
	defer p.lock.Unlock()

	// There's no danger in replacing an existing channel, because the channel itself
	// is used as a key. The worst that happens is Subscribe() is called twice.
	p.subscribers[ch] = p.nodata
}

// Unsubscribe from ChangeSummary notifications, and close the channel.
func (p *PingKite) Unsubscribe(ch chan<- ChangeSummary) {
	p.lock.Lock()
	defer p.lock.Unlock()

	if _, ok := p.subscribers[ch]; ok {
		delete(p.subscribers, ch)
		close(ch)
	}
}
