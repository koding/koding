package mount_test

import (
	"context"
	"reflect"
	"sync"
	"testing"

	"koding/klient/machine/index"
	"koding/klient/machine/mount"
	msync "koding/klient/machine/mount/sync"
)

func TestQueue(t *testing.T) {
	q := mount.NewQueue()
	if ev := q.Pop(); ev != nil {
		t.Errorf("want ev = nil; got %v", ev)
	}
	if s := q.Size(); s != 0 {
		t.Errorf("want size = 0; got %d", s)
	}

	c := index.NewChange(".", index.PriorityMedium, 0)
	q.Push(msync.NewEvent(context.Background(), nil, c))
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
		evC = make(chan *msync.Event)
		q   = mount.NewQueue()
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
		c := index.NewChange(".", index.PriorityMedium, 0)
		ev := msync.NewEvent(context.Background(), nil, c)
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
