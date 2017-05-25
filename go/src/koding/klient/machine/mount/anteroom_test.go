package mount_test

import (
	"math/rand"
	"reflect"
	"strconv"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"koding/klient/machine/index"
	"koding/klient/machine/mount"
	"koding/klient/machine/mount/mounttest"
	msync "koding/klient/machine/mount/sync"
)

func TestAnteroom(t *testing.T) {
	a := mount.NewAnteroom()
	defer a.Close()

	c := index.NewChange("a/test.txt", index.PriorityLow, index.ChangeMetaAdd)
	ctx := a.Commit(c)

	items, synced := a.Status()
	if items != 1 {
		t.Errorf("want 1 item; got %d", items)
	}
	if synced != 0 {
		t.Errorf("want 0 synced events; got %d", synced)
	}

	var ev *msync.Event
	select {
	case ev = <-a.Events():
	case <-time.After(time.Second):
		t.Fatalf("timed out after %s", time.Second)
	}

	if err := mounttest.WaitForContextClose(ctx, 20*time.Millisecond); err == nil {
		t.Errorf("want err != nil; got nil")
	}

	items, synced = a.Status()
	if items != 1 {
		t.Errorf("want 1 item; got %d", items)
	}
	if synced != 1 {
		t.Errorf("want 1 synced event; got %d", synced)
	}

	ev.Done()

	if err := mounttest.WaitForContextClose(ctx, time.Second); err != nil {
		t.Errorf("want err = nil; got %s", err)
	}

	items, synced = a.Status()
	if items != 0 {
		t.Errorf("want 0 items; got %d", items)
	}
	if synced != 0 {
		t.Errorf("want 0 synced events; got %d", synced)
	}
}

func TestAnteroomCoalescing(t *testing.T) {
	a := mount.NewAnteroom()
	defer a.Close()

	cs := [2]*index.Change{
		index.NewChange("a/test.txt", index.PriorityLow, index.ChangeMetaAdd),
		index.NewChange("a/test.txt", index.PriorityLow, index.ChangeMetaUpdate),
	}

	// Add ChangeMetaAdd first - this will make all other events coalesce to
	// add change.
	a.Commit(cs[0])

	const workersN = 10
	var wg sync.WaitGroup

	wg.Add(workersN)
	for i := 0; i < workersN; i++ {
		go func() {
			defer wg.Done()

			for j := 0; j < 100; j++ {
				a.Commit(cs[j%2])
			}
		}()
	}

	select {
	case <-a.Events():
	case <-time.After(time.Second):
		t.Fatalf("timed out after %s", time.Second)
	}

	wg.Wait()

	// Coalesced event should not be added to the queue again.
	items, synced := a.Status()
	if items != 1 {
		t.Errorf("want 1 items; got %d", items)
	}
	if synced != 1 {
		t.Errorf("want 1 synced event; got %d", synced)
	}
}

func TestAnteroomPopChange(t *testing.T) {
	a := mount.NewAnteroom()
	defer a.Close()

	var (
		cA = index.NewChange("a/test.txt", index.PriorityLow, index.ChangeMetaAdd)
		cB = index.NewChange("a/test.txt", index.PriorityLow, index.ChangeMetaRemove)
	)

	a.Commit(cA)

	var ev *msync.Event
	select {
	case ev = <-a.Events():
	case <-time.After(time.Second):
		t.Fatalf("timed out after %s", time.Second)
	}

	if !ev.Valid() {
		t.Fatalf("want valid event; got invalid")
	}

	// Remove change meta invalidates dequeued event.
	a.Commit(cB)

	if ev.Valid() {
		t.Fatalf("want invalid event; got valid")
	}

	// All events either valid or not valid must went trough workers. They
	// will execute only valid ones but mark all of them as done.
	ev.Done()

	select {
	case <-a.Events(): // pop pending event.
	case <-time.After(time.Second):
		t.Fatalf("timed out after %s", time.Second)
	}

	items, synced := a.Status()
	if items != 1 {
		t.Errorf("want 1 items; got %d", items)
	}
	if synced != 1 {
		t.Errorf("want 1 synced event; got %d", synced)
	}
}

func TestAnteroomMultiEvents(t *testing.T) {
	a := mount.NewAnteroom()
	defer a.Close()

	const eventsN = 1000
	sent := make(map[string]struct{})
	for i := 0; i < eventsN; i++ {
		path := "file" + strconv.Itoa(i) + ".txt"

		a.Commit(index.NewChange(path, index.PriorityLow, index.ChangeMetaRemove))
		sent[path] = struct{}{}
	}

	got := make(map[string]struct{})
	for i := 0; i < eventsN; i++ {
		select {
		case ev := <-a.Events():
			if ev == nil {
				t.Fatalf("received nil event")
			}
			got[ev.Change().Path()] = struct{}{}
		case <-time.After(time.Second):
			t.Fatalf("timed out after %s", time.Second)
		}
	}

	// Check for excessive events.
	select {
	case ev := <-a.Events():
		t.Fatalf("received excessive event: %v", ev)
	case <-time.After(20 * time.Millisecond):
	}

	items, synced := a.Status()
	if items != eventsN {
		t.Errorf("want %d items; got %d", eventsN, items)
	}
	if synced != eventsN {
		t.Errorf("want %d synced events; got %d", eventsN, synced)
	}

	if !reflect.DeepEqual(sent, got) {
		t.Fatalf("sent event paths are not equal to received ones")
	}
}

func TestSequentialSync(t *testing.T) {
	a := mount.NewAnteroom()

	var wg sync.WaitGroup
	startC := make(chan struct{})

	// We need to use different changes since identical will be coalesced to no-op.
	changeMetas := []index.ChangeMeta{
		index.ChangeMetaAdd,
		index.ChangeMetaRemove,
		index.ChangeMetaUpdate,
		index.ChangeMetaAdd | index.ChangeMetaRemote,
		index.ChangeMetaRemove | index.ChangeMetaRemote,
		index.ChangeMetaUpdate | index.ChangeMetaRemote,
	}

	const eventsN = 10000
	// Feed anteroom with events some of them will be coleased.
	wg.Add(1)
	go func() {
		defer wg.Done()
		<-startC

		for i := 0; i < eventsN; i++ {
			changeMeta := changeMetas[rand.Intn(len(changeMetas))]
			a.Commit(index.NewChange("path.txt", index.PriorityLow, changeMeta))
			time.Sleep(100 * time.Millisecond / eventsN)
		}

		// Close anteroom which will close `Events` channel.
		a.Close()
	}()

	var want, got int64

	const workersN = 16
	// Add workers.
	wg.Add(workersN)
	for i := 0; i < workersN; i++ {
		go func() {
			defer wg.Done()
			<-startC

			for ev := range a.Events() {
				atomic.AddInt64(&want, 1) // How many events were processed.
				old := atomic.LoadInt64(&got)

				// Simulate event processing and then CAS with old value. If
				// there are other workers processing the event, CAS will fail.
				time.Sleep(100 * time.Millisecond * time.Duration(rand.Intn(workersN)+1) / eventsN)
				atomic.CompareAndSwapInt64(&got, old, old+1)

				ev.Done()
			}
		}()
	}

	// Start processing.
	close(startC)
	wg.Wait()

	if want != got {
		t.Errorf("changes not processed sequentially: (%d != %d)", want, got)
	}
}
