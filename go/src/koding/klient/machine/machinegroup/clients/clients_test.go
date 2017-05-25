package clients_test

import (
	"testing"
	"time"

	"koding/klient/machine"
	"koding/klient/machine/client"
	"koding/klient/machine/client/clienttest"
	"koding/klient/machine/machinegroup/clients"

	"golang.org/x/sync/errgroup"
)

// testOptions returns default Clients options used for testing purposes.
func testOptions(b client.Builder) *clients.ClientsOpts {
	return &clients.ClientsOpts{
		Builder:         b,
		DynAddrInterval: 10 * time.Millisecond,
		PingInterval:    50 * time.Millisecond,
	}
}

func TestClients(t *testing.T) {
	var (
		builder = clienttest.NewBuilder(nil)

		idA = machine.ID("servA")
		idB = machine.ID("servB")

		servA = &clienttest.Server{}
		servB = &clienttest.Server{}
	)

	cs, err := clients.New(testOptions(builder))
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer cs.Close()

	var g errgroup.Group
	create := map[machine.ID]client.DynamicAddrFunc{
		idA: servA.AddrFunc(),
		idB: servB.AddrFunc(),
		idA: servA.AddrFunc(), // duplicate.
		idA: servA.AddrFunc(), // duplicate.
	}

	for id, dynAddr := range create {
		id, dynAddr := id, dynAddr // Local copy for concurrency.
		g.Go(func() error {
			return cs.Create(id, dynAddr, func(_ machine.Addr) {})
		})
	}
	if err := g.Wait(); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	if regs := cs.Registered(); len(regs) != 2 {
		t.Fatalf("want clients count = 2; got %d", len(regs))
	}

	if _, err := cs.Client(idA); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	if err := cs.Drop(idA); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	if _, err := cs.Client(idA); err != machine.ErrMachineNotFound {
		t.Fatalf("want machine not found; got %v", err)
	}

	if regs := cs.Registered(); len(regs) != 1 {
		t.Fatalf("want clients count = 1; got %d", len(regs))
	}
}
