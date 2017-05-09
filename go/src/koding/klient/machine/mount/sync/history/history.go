package history

import (
	"container/ring"
	"fmt"
	"sync"
	"time"

	msync "koding/klient/machine/mount/sync"
)

// Record stores a single history record.
type Record struct {
	CreatedAt time.Time `json:"createdAt"`        // creation time.
	Message   string    `json:"message"`          // short summary.
	Details   string    `json:"detail,omitempty"` // detailed description.
}

// History gathers synchronization history of results produced by stored Syncer.
type History struct {
	s msync.Syncer // underlying Syncer.

	mu sync.Mutex
	r  *ring.Ring

	once  sync.Once
	stopC chan struct{} // channel used to close any opened exec streams.
}

// NewHistory creates a new History instance. Provided size defines the maximum
// length of history records.
func NewHistory(s msync.Syncer, size int) *History {
	return &History{
		s:     s,
		r:     ring.New(size),
		stopC: make(chan struct{}),
	}
}

// ExecStream wraps underlying execers with history gathering logic.
func (h *History) ExecStream(evC <-chan *msync.Event) <-chan msync.Execer {
	exhC := make(chan msync.Execer)

	go func() {
		defer close(exhC)

		exC := h.s.ExecStream(evC)
		for {
			select {
			case ex, ok := <-exC:
				if !ok {
					return
				}

				h.add(&Record{
					CreatedAt: time.Now().UTC(),
					Message:   "received: " + ex.String(),
				})

				exh := &histExec{
					ex:     ex,
					parent: h,
				}

				select {
				case exhC <- exh:
				case <-h.stopC:
					return
				}
			case <-h.stopC:
				return
			}
		}
	}()

	return exhC
}

// Close stops all created synchronization streams.
func (h *History) Close() error {
	h.once.Do(func() {
		close(h.stopC)
	})

	return nil
}

// Get gets recorded history. Returned slice length will not exceed history
// maximum size.
//
// If there's no history available, the method returns empty, non-nil slice.
func (h *History) Get() []*Record {
	var recs []*Record

	h.mu.Lock()
	defer h.mu.Unlock()
	h.r.Do(func(val interface{}) {
		if val == nil {
			return
		}

		rec, ok := val.(*Record)
		if !ok || rec == nil {
			panic(fmt.Sprintf("unknown history record: %#v", val))
		}

		recs = append(recs, rec)
	})

	return recs
}

// add adds new record to history.
func (h *History) add(rec *Record) {
	h.mu.Lock()
	h.r.Value = rec
	h.r = h.r.Next()
	h.mu.Unlock()
}

// histExec wraps Execer interface in order to track its invocation status.
type histExec struct {
	ex     msync.Execer
	parent *History
}

// Event returns base event which is going to be synchronized.
func (he *histExec) Event() *msync.Event {
	return he.ex.Event()
}

// Exec starts synchronization of stored syncing job.
func (he *histExec) Exec() (err error) {
	he.parent.add(&Record{
		CreatedAt: time.Now().UTC(),
		Message:   "started: " + he.ex.String(),
	})

	var msg string
	if err = he.ex.Exec(); err != nil {
		msg = "failed: " + he.ex.String() + "; err: " + err.Error()
	} else {
		msg = "succeeded: " + he.ex.String()
	}

	he.parent.add(&Record{
		CreatedAt: time.Now().UTC(),
		Message:   msg,
		Details:   he.ex.Debug(),
	})

	return
}

// Debug returns debug information about the execer.
func (he *histExec) Debug() string {
	return he.ex.Debug()
}

// fmt.Stringer defines human readable information about the event.
func (he *histExec) String() string {
	return he.ex.String()
}
