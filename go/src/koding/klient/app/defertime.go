package app

import "time"

// DeferTime allows to invoke registered function after provided duration. It
// can cancel deferred function call even if internal timer was already started.
type DeferTime struct {
	d time.Duration
	f func()

	startC chan struct{}
	stopC  chan struct{}
	closeC chan struct{}
}

// NewDeferTime creates a new DeferTime instance and runs internal worker
// go-routine. It is not possible to stop internal loop since it is meant to
// run during the entire application's life cycle.
func NewDeferTime(d time.Duration, f func()) *DeferTime {
	dt := &DeferTime{
		d:      d,
		f:      f,
		startC: make(chan struct{}, 1),
		stopC:  make(chan struct{}, 1),
		closeC: make(chan struct{}, 1),
	}

	go dt.loop()

	return dt
}

// Start runs registered function after `d` duration. If this method is called
// multiple times before `d` duration pass, each call will reset the timer.
// Calling Start method after registered function is invoked, will repeat the
// process. This method is thread safe.
func (dt *DeferTime) Start() {
	select {
	case dt.startC <- struct{}{}:
	default:
	}
}

// Stop prevents DeferTime from calling registered function even if it was
// already scheduled by Start method. It is no-op when Start method was not
// called. It is safe to call Stop method from multiple go-routines.
func (dt *DeferTime) Stop() {
	select {
	case dt.stopC <- struct{}{}:
	default:
	}
}

// Close stops differed timer. It doesn't not invoke registered function.
func (dt *DeferTime) Close() {
	select {
	case dt.closeC <- struct{}{}:
	default:
	}
}

func (dt *DeferTime) loop() {
	var (
		timer    *time.Timer      = nil
		c        <-chan time.Time = nil
		sawTimer                  = false
	)

	for {
		select {
		case <-c:
			sawTimer = true
			dt.f()
			timer, c = nil, nil
		case <-dt.stopC:
			if timer != nil && !timer.Stop() && !sawTimer {
				<-timer.C // drain previous timer since it was not triggered.
			}
			timer, c = nil, nil
		case <-dt.startC:
			if timer != nil {
				if !timer.Stop() {
					<-timer.C
				}
				timer.Reset(dt.d)
			} else {
				timer = time.NewTimer(dt.d)
			}
			c, sawTimer = timer.C, false
		case <-dt.closeC:
			if timer != nil && !timer.Stop() && !sawTimer {
				<-timer.C
			}
			return
		}
	}
}
