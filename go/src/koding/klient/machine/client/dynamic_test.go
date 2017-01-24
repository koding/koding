package client_test

import (
	"errors"
	"testing"
	"time"

	"koding/klient/machine"
	"koding/klient/machine/client"
	"koding/klient/machine/client/clienttest"

	"golang.org/x/sync/errgroup"
)

func TestDynamicClientOnOff(t *testing.T) {
	var (
		serv    = &clienttest.Server{}
		builder = clienttest.NewBuilder(nil)
	)

	dc, err := client.NewDynamic(clienttest.DynamicOpts(serv, builder))
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer dc.Close()

	// Server is in unknown state.
	if status := dc.Status(); status.State != machine.StateUnknown {
		t.Fatalf("want state = %s; got %s", machine.StateUnknown, status.State)
	}

	// Server starts responding.
	ctx := dc.Client().Context()
	serv.TurnOn()
	if err := builder.WaitForBuild(time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if n := builder.BuildsCount(); n != 1 {
		t.Fatalf("want builds count = 1; got %d", n)
	}
	if err := clienttest.WaitForContextClose(ctx, time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if status := dc.Status(); status.State != machine.StateOnline {
		t.Fatalf("want state = %s; got %s", machine.StateOnline, status.State)
	}

	// Stop server.
	ctx = dc.Client().Context()
	serv.TurnOff()
	if err := builder.WaitForBuild(time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if n := builder.BuildsCount(); n != 2 {
		t.Fatalf("want builds count = 2; got %d", n)
	}
	if err := clienttest.WaitForContextClose(ctx, time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if status := dc.Status(); status.State != machine.StateOffline {
		t.Fatalf("want state = %s; got %s", machine.StateOffline, status.State)
	}
}

func TestDynamicClientContext(t *testing.T) {
	var (
		serv    = &clienttest.Server{}
		builder = clienttest.NewBuilder(nil)
	)

	dc, err := client.NewDynamic(clienttest.DynamicOpts(serv, builder))
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer dc.Close()

	ctx := dc.Client().Context()
	serv.TurnOn()
	if err := clienttest.WaitForContextClose(ctx, time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	const ContextWorkers = 10

	var g errgroup.Group
	for i := 0; i < ContextWorkers; i++ {
		g.Go(func() error {
			select {
			case <-dc.Client().Context().Done():
				return errors.New("context closed unexpectedly")
			case <-time.After(50 * time.Millisecond):
				return nil
			}
		})
	}
	// Machine is on so dynamic client should not close its context.
	if err := g.Wait(); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	ctx = dc.Client().Context()
	serv.TurnOff()
	for i := 0; i < ContextWorkers; i++ {
		g.Go(func() error {
			select {
			case <-ctx.Done():
				return nil
			case <-time.After(time.Second):
				return errors.New("timed out")
			}
		})
	}
	// Machine is off so its context channel should be closed by dynamic client.
	if err := g.Wait(); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
}
