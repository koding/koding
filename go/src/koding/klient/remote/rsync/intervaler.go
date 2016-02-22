package rsync

import (
	"sync"
	"time"
)

type Intervaler interface {
	sync.Locker

	Start()
	Stop()
}

type SyncIntervaler interface {
	Intervaler

	SyncIntervalOpts() SyncIntervalOpts
}

type Syncer interface {
	Sync(SyncOpts) <-chan Progress
}

// syncInterval is a manager for the RSync Client to run various commands
type syncInterval struct {
	Syncer

	Opts SyncIntervalOpts

	sync.Mutex

	ticker *time.Ticker
}

func (i *syncInterval) Start() {
	go i.start()
}

func (s *syncInterval) start() {
	// If the ticker exists, it's already running. Duplicating the ticker
	// would also be bad, as we'd be unable to stop it.
	if s.ticker != nil {
		return
	}

	// This prevents a panic from NewTicker if the delay was never set.
	if s.Opts.Interval <= 0 {
		return
	}

	s.ticker = time.NewTicker(s.Opts.Interval)
	for range s.ticker.C {
		s.Lock()
		// We don't actually care about any of the progress results, error or otherwise,
		// from Sync. We only care that it is done. Once the channel is done, the inner
		// loop will end.
		for range s.Sync(s.Opts.SyncOpts) {
		}
		s.Unlock()
	}
}

func (s *syncInterval) Stop() {
	if s.ticker != nil {
		s.Lock()
		s.ticker.Stop()
		s.ticker = nil
		s.Unlock()
	}
}

func (s *syncInterval) SyncIntervalOpts() SyncIntervalOpts {
	return s.Opts
}
