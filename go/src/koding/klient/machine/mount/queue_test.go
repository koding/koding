package mount

import (
	"context"
	"reflect"
	"sync"
	"testing"
)

func TestQueue(t *testing.T) {
	q := NewQueue()
	if ev := q.Pop(); ev != nil {
		t.Errorf("want ev = nil; got %v", ev)
	}
	if s := q.Size(); s != 0 {
		t.Errorf("want size = 0; got %d", s)
	}

	q.Push(NewEvent(context.Background(), nil, nil))
	if s := q.Size(); s != 1 {
		t.Errorf("want size = 1; got %d", s)
	}
	if ev := q.Pop(); ev == nil {
		t.Errorf("want ev != nil; got nil")
	}
	if s := q.Size(); s != 0 {
		t.Errorf("want size = 0; got %d", s)
	}
}

func TestQueueConcurrent(t *testing.T) {
	const (
		workersN = 10
		eventsN  = 10000
	)

	var (
		mu  sync.Mutex
		got = make(map[uint64]struct{})
		wg  sync.WaitGroup
		evC = make(chan *Event)
		q   = NewQueue()
	)

	wg.Add(workersN)
	for i := 0; i < workersN; i++ {
		go func() {
			defer wg.Done()

			for ev := range evC {
				q.Push(ev)

				if ev := q.Pop(); ev != nil {
					mu.Lock()
					got[ev.ID()] = struct{}{}
					mu.Unlock()
				}
			}
		}()
	}

	send := make(map[uint64]struct{})
	for i := 0; i < eventsN; i++ {
		ev := NewEvent(context.Background(), nil, nil)
		send[ev.ID()] = struct{}{}
		evC <- ev
	}

	close(evC)
	wg.Wait()

	if s := q.Size(); s != 0 {
		t.Fatalf("want size = 0; got %d", s)
	}
	if l := len(got); eventsN != l {
		t.Fatalf("want send events count = %d; got %d", eventsN, l)
	}
	if !reflect.DeepEqual(send, got) {
		t.Fatalf("sent events set is not equal to got one")
	}
}
