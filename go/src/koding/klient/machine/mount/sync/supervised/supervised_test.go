package supervised_test

import (
	"context"
	"errors"
	"fmt"
	"testing"
	"time"

	"koding/klient/machine/client"
	"koding/klient/machine/client/clienttest"
	"koding/klient/machine/index"
	msync "koding/klient/machine/mount/sync"
	"koding/klient/machine/mount/sync/discard"
	"koding/klient/machine/mount/sync/supervised"
	"koding/klient/machine/mount/sync/synctest"
)

func TestSupervised(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	opts := &msync.BuildOpts{
		ClientFunc: func() (client.Client, error) {
			c := clienttest.NewClient()
			c.SetContext(ctx)
			return c, nil
		},
	}

	change := index.NewChange("a", index.PriorityMedium, 0)
	tb := &testBuilder{
		buildC: make(chan struct{}, 1),
		times:  1,
	}

	s := supervised.NewSupervised(tb, opts, 2*time.Second)
	defer s.Close()

	if err := synctest.ExecChange(s, change, time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	if err := waitBuildC(tb.buildC, time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	cancel()

	// Client closed its context. This means that it changed.
	if err := waitBuildC(tb.buildC, time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	if err := synctest.ExecChange(s, change, 50*time.Millisecond); err == nil {
		t.Fatalf("want err != nil; got nil")
	}

}

// testBuilder triggers client function.
type testBuilder struct {
	buildC chan struct{}
	times  int
}

func (tb *testBuilder) Build(opts *msync.BuildOpts) (msync.Syncer, error) {
	opts.ClientFunc()
	tb.buildC <- struct{}{}
	if tb.times--; tb.times >= 0 {
		return discard.NewDiscard(), nil
	} else {
		return nil, errors.New("cannot build")
	}
}

func waitBuildC(buildC <-chan struct{}, timeout time.Duration) error {
	select {
	case <-buildC:
		return nil
	case <-time.After(timeout):
		return fmt.Errorf("timed out after %s", timeout)
	}
}
