package sync_test

import (
	"reflect"
	"strconv"
	"sync"
	"testing"
	"time"

	"koding/klient/machine/index"
	"koding/klient/machine/mount/mounttest"
	msync "koding/klient/machine/mount/sync"
)

func TestAnteroom(t *testing.T) {
	a := msync.NewAnteroom()
	defer a.Close()

	c := index.NewChange("a/test.txt", index.ChangeMetaAdd)
	ctx := a.Commit(c)

	items, queued := a.Status()
	if items != 1 {
		t.Errorf("want 1 item; got %d", items)
	}
	if queued != 1 {
		t.Errorf("want 1 queued event; got %d", queued)
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

	items, queued = a.Status()
	if items != 1 {
		t.Errorf("want 1 item; got %d", items)
	}
	if queued != 0 {
		t.Errorf("want 0 queued events; got %d", queued)
	}

	ev.Done()

	if err := mounttest.WaitForContextClose(ctx, time.Second); err != nil {
		t.Errorf("want err = nil; got %s", err)
	}

	items, queued = a.Status()
	if items != 0 {
		t.Errorf("want 0 items; got %d", items)
	}
	if queued != 0 {
		t.Errorf("want 0 queued events; got %d", queued)
	}
}

func TestAnteroomCoalescing(t *testing.T) {
	a := msync.NewAnteroom()
	defer a.Close()

	cs := [2]*index.Change{
		index.NewChange("a/test.txt", index.ChangeMetaAdd),
		index.NewChange("a/test.txt", index.ChangeMetaUpdate),
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
	items, queued := a.Status()
	if items != 1 {
		t.Errorf("want 1 items; got %d", items)
	}
	if queued != 0 {
		t.Errorf("want 0 queued events; got %d", queued)
	}
}

func TestAnteroomPopChange(t *testing.T) {
	a := msync.NewAnteroom()
	defer a.Close()

	var (
		cA = index.NewChange("a/test.txt", index.ChangeMetaAdd)
		cB = index.NewChange("a/test.txt", index.ChangeMetaRemove)
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
		t.Fatalf("want invalid valid event; got valid")
	}

	items, queued := a.Status()
	if items != 1 {
		t.Errorf("want 1 items; got %d", items)
	}
	if queued != 1 {
		t.Errorf("want 1 queued event; got %d", queued)
	}
}

func TestAnteroomMultiEvents(t *testing.T) {
	a := msync.NewAnteroom()
	defer a.Close()

	const eventsN = 1000
	sent := make(map[string]struct{})
	for i := 0; i < eventsN; i++ {
		path := "file" + strconv.Itoa(i) + ".txt"

		a.Commit(index.NewChange(path, index.ChangeMetaRemove))
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

	items, queued := a.Status()
	if items != eventsN {
		t.Errorf("want %d items; got %d", eventsN, items)
	}
	if queued != 0 {
		t.Errorf("want 0 queued events; got %d", queued)
	}

	if !reflect.DeepEqual(sent, got) {
		t.Fatalf("sent event paths are not equal to received ones")
	}
}
