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

	running bool
}

func (i *syncInterval) Start() {
	go i.start()
}

func (s *syncInterval) isRunning() bool {
	s.Lock()
	defer s.Unlock()
	return s.running
}

func (s *syncInterval) start() {
	if s.isRunning() {
		return
	}

	// This prevents spamming Sync.
	if s.Opts.Interval <= 0 {
		return
	}

	s.Lock()
	s.running = true
	s.Unlock()

	for s.isRunning() {
		s.Lock()
		// We don't actually care about any of the progress results, error or otherwise,
		// from Sync. We only care that it is done. Once the channel is done, the inner
		// loop will end.
		for range s.Sync(s.Opts.SyncOpts) {
		}
		s.Unlock()
		// Sleep after we run Sync. Helps prevent Sync from running back
		// to back.
		time.Sleep(s.Opts.Interval)
	}
}

func (s *syncInterval) Stop() {
	s.Lock()
	defer s.Unlock()
	s.running = false
}

func (s *syncInterval) SyncIntervalOpts() SyncIntervalOpts {
	return s.Opts
}
