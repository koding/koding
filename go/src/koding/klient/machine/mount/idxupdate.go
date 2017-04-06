package mount

import (
	"math/rand"
	"sync"
	"sync/atomic"
	"time"

	"koding/klient/machine"
	"koding/klient/machine/index"

	"github.com/koding/logging"
)

func init() {
	// initialize pseudo random number generator.
	rand.Seed(time.Now().UnixNano())
}

// IdxUpdate periodically dumps memory index to disk. Thus, it is responsible
// for keeping memory index and locally stored one synchronized as much as
// possible.
//
// Note that some changes may missing, this will not break syncing logic.
// However, it will unnecessary trigger synchronization for these ones.
// This type tries to minimize this effect.
type IdxUpdate struct {
	idx     *index.Index // synced index.
	idxPath string       // index file path

	flush time.Duration // flush interval.
	cN    int64         // number of changes to sync.

	once   sync.Once     // used for closing closeC chan.
	closeC chan struct{} // closed when update object is closed.

	log logging.Logger
}

// NewIdxUpdate creates a new index update instance.
func NewIdxUpdate(idxPath string, idx *index.Index, flush time.Duration, log logging.Logger) *IdxUpdate {
	iu := &IdxUpdate{
		idx:     idx,
		idxPath: idxPath,
		flush:   flush,
		closeC:  make(chan struct{}),
		log:     log,
	}

	if iu.log == nil {
		iu.log = machine.DefaultLogger.New("sync")
	}

	go iu.cron()
	return iu
}

// Update synchronizes internal index and increases index synced counter.
func (iu *IdxUpdate) Update(cacheDir string, c *index.Change) {
	iu.idx.Sync(cacheDir, c)
	atomic.AddInt64(&iu.cN, 1)
}

// ChangeN returns the number of changes which haven't been synchronized yet
func (iu *IdxUpdate) ChangeN() int64 {
	return atomic.LoadInt64(&iu.cN)
}

// Close stops index update process.
func (iu *IdxUpdate) Close() error {
	iu.once.Do(func() {
		close(iu.closeC)
	})

	return nil
}

func (iu *IdxUpdate) cron() {
	// Start cron goroutine after some portion of random time related to
	// flush interval. This will uniformly distribute index disk flushes form
	// many mounts.
	select {
	case <-time.After(iu.flush / 100 * time.Duration(rand.Intn(100))):
	case <-iu.closeC:
		return
	}

	var (
		minFlush   = iu.flush / 4
		last       = time.Now().Add(-minFlush - time.Second)
		updateTick = time.NewTicker(iu.flush / 3)
	)

	var flush = func() {
		cN := atomic.LoadInt64(&iu.cN)

		// Nothing to update
		if cN == 0 {
			return
		}

		// Save index always after flush interval or when we have a lot of changes.
		sinceUpdate := time.Since(last)
		if (sinceUpdate < iu.flush) && !(sinceUpdate > minFlush && cN > 100) {
			return
		}

		last = time.Now()
		if err := index.SaveIndex(iu.idx, iu.idxPath); err != nil {
			iu.log.Warning("Cannot update mount index file %s: %v", iu.idxPath, err)
		} else {
			atomic.AddInt64(&iu.cN, -cN)
		}
	}

	for {
		select {
		case <-updateTick.C:
			flush()
		case <-iu.closeC:
			flush()

			// Stop ticker.
			updateTick.Stop()
			return
		}
	}
}
