package kitepinger

import (
	"sync"
	"time"
)

var (
	defaultPingInterval     = time.Second * 10
	defaultStatusExpiration = time.Minute
)

type Pinger interface {
	// Ping the remote for this Pinger. This could be a kite, http endpoint, or
	// whatever the struct implements.
	Ping() Status
}

// PingTracker is an interface for using an internal Pinger at a set interval,
// and being notified when the ability to Ping successfully is interrupted and
// restored.
//type PingTracker interface {
//	// Like Pinger, a call to Ping() will ping the remote for the underlying Pinger.
//	//
//	// In addition to that, this should trigger a ChangeSummary if there ends up
//	// being a change.
//	//
//	// Note that manually calling Ping on a stopped KitePinger will likely result in
//	// unusable Duration times, despite the Status itself being accurate.
//	Pinger
//
//	// Start pinging the remote kite at whatever interval the KitePinger is
//	// set to.
//	Start()
//
//	// Stop the KitePinger from pinging.
//	Stop()
//
//	// Subscribe to *changes* of kitepinger status. Changes occur only if a ping was
//	// succeeding, and now failed - or if it was failing, and now succeeded.
//	Subscribe(chan<- ChangeSummary)
//
//	// Unsubscribe from ChangeSummary notifications.
//	Unsubscribe(chan<- ChangeSummary)
//
//	// Get the CurrentSummary of the previous pings.
//	GetSummary() CurrentSummary
//
//	// IsConnected returns if we are actively pinging and the last ping was success.
//	IsConnected() bool
//
//	// ConnectedAt returns the last time status was success, if ever.
//	ConnectedAt() time.Time
//}

// PingTracker is a struct for using an internal Pinger at a set interval,
// and being notified when the ability to Ping successfully is interrupted and
// restored.
//
type PingTracker struct {
	// The Pinger that this PingTracker will ping.
	pinger Pinger

	// The interval that PingTracker will ping at.
	interval time.Duration

	// The maximum duration of time that a Success Status will be considered valid.
	//
	// If the time since the last pingedAt value is larger than this value, PingTracker
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

	// The time the last successful status was encountered.
	successTime time.Time
}

// NewPingTracker returns a new PingTracker for the given Pinger.
func NewPingTracker(p Pinger) *PingTracker {
	return &PingTracker{
		pinger:           p,
		interval:         defaultPingInterval,
		statusExpiration: defaultStatusExpiration,
		nodata:           struct{}{},
		subscribers:      map[chan<- ChangeSummary]struct{}{},
	}
}

// broadcastSummary sends the given summary to any subscribers.
func (p *PingTracker) broadcastSummary(s ChangeSummary) {
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
func (p *PingTracker) SetInterval(i time.Duration) {
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
func (p *PingTracker) Start() {
	if p.pinging {
		return
	}

	p.ticker = time.NewTicker(p.interval)

	// Clear the lastStatus value and then ping. By doing this we ensure that any
	// pings after this are accurate to the current state (not from an hour ago,
	// for example)
	//
	// Do this on the same goroutine as the caller to avoid any subtle race condition.
	p.lastStatus = Unknown
	p.Ping()
	go p.startPinging(p.ticker.C)

	p.pinging = true
}

// Run a ping loop on the given time channel.
func (p *PingTracker) startPinging(c <-chan time.Time) {
	for t := range c {
		pingedAgo := time.Since(p.pingedAt)

		// If the last status was Success, but it was too long ago, the
		// Kite OS process itself may have been put to sleep. Because of this,
		// we need to inform the KitePinger user that we have *not* been successfully
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
func (p *PingTracker) Stop() {
	if p.pinging {
		p.ticker.Stop()
		p.pinging = false
	}
}

// Ping manually pings the kite. This will trigger a ChangeSummary broadcast if
// there ends up being a change.
func (p *PingTracker) Ping() {
	now := time.Now()
	p.pingedAt = now

	status := p.pinger.Ping()
	if status == Success {
		p.successTime = now
	}

	// If the "current" summary doesn't match our newly discovered summary,
	// write the new one and report it to any listeners
	if p.lastStatus != status {
		oldStatus := p.lastStatus
		oldStatusDur := time.Since(p.statusTime)
		p.statusTime = now
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
func (p *PingTracker) GetSummary() CurrentSummary {
	return CurrentSummary{
		Status:    p.lastStatus,
		StatusDur: time.Since(p.statusTime),
	}
}

// Subscribe to *changes* of kitepinger status. Changes occur only if a ping was
// succeeding, and now failed - or if it was failing, and now succeeded.
//
// It's worth noting that the given channel is unable to block the KitePinger if
// it is unable to receive. Any ChangeSummaries not being actively received (ie,
// waited for) will be dropped.
func (p *PingTracker) Subscribe(ch chan<- ChangeSummary) {
	p.lock.Lock()
	defer p.lock.Unlock()

	// There's no danger in replacing an existing channel, because the channel itself
	// is used as a key. The worst that happens is Subscribe() is called twice.
	p.subscribers[ch] = p.nodata
}

// Unsubscribe from ChangeSummary notifications, and close the channel.
func (p *PingTracker) Unsubscribe(ch chan<- ChangeSummary) {
	p.lock.Lock()
	defer p.lock.Unlock()

	if _, ok := p.subscribers[ch]; ok {
		delete(p.subscribers, ch)
		close(ch)
	}

	if len(p.subscribers) == 0 {
		p.Stop()
	}
}

// IsConnected returns if we are actively pinging and the last ping was success.
func (p *PingTracker) IsConnected() bool {
	if !p.IsPinging() {
		return false
	}

	return p.lastStatus == Success
}

// ConnectedAt returns when the last successful ping was, if ever.
func (p *PingTracker) ConnectedAt() time.Time {
	return p.successTime
}

// IsPinging returns whether or not this PingTracker is actively pinging or not.
func (p *PingTracker) IsPinging() bool {
	return p.pinging
}
