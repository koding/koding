package addresses_test

import (
	"testing"
	"time"

	"koding/klient/machine"
	"koding/klient/machine/machinegroup/addresses"
)

func TestAddressesMachineID(t *testing.T) {
	tests := map[string]struct {
		ID    machine.ID
		Addr  machine.Addr
		Valid bool
	}{
		"machine 1 older IP": {
			ID: "ID_1",
			Addr: machine.Addr{
				Network:   "ip",
				Value:     "52.254.159.36",
				UpdatedAt: time.Date(2012, time.May, 1, 0, 0, 0, 0, time.UTC),
			},
			Valid: true,
		},
		"machine 1 newer IP": {
			ID: "ID_1",
			Addr: machine.Addr{
				Network:   "ip",
				Value:     "52.254.159.123",
				UpdatedAt: time.Date(2014, time.May, 1, 0, 0, 0, 0, time.UTC),
			},
			Valid: true,
		},
		"machine 2 TCP": {
			ID: "ID_2",
			Addr: machine.Addr{
				Network:   "tcp",
				Value:     "127.0.0.1:80",
				UpdatedAt: time.Date(2009, time.May, 1, 0, 0, 0, 0, time.UTC),
			},
			Valid: true,
		},
		"unknown address": {
			ID: "ID_2",
			Addr: machine.Addr{
				Network:   "ip",
				Value:     "10.0.34.134",
				UpdatedAt: time.Date(2000, time.May, 1, 0, 0, 0, 0, time.UTC),
			},
			Valid: false,
		},
		"missing machine": {
			ID: "",
			Addr: machine.Addr{
				Network:   "ip",
				Value:     "10.0.34.23",
				UpdatedAt: time.Date(2020, time.May, 1, 0, 0, 0, 0, time.UTC),
			},
			Valid: false,
		},
	}

	addrs := addresses.New()
	for name, test := range tests {
		if test.Valid {
			if err := addrs.Add(test.ID, test.Addr); err != nil {
				t.Fatalf("%s: want err = nil; got %v", name, err)
			}
		}
	}

	for name, test := range tests {
		// capture range variable here
		test := test
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			id, err := addrs.MachineID(test.Addr)
			if (err == nil) != test.Valid {
				t.Fatalf("want err == nil => %t; got err %v", test.Valid, err)
			}

			if err == nil && test.ID != id {
				t.Fatalf("want machine ID = %s; got %s", test.ID, id)
			}
		})
	}
}

func TestAddressesMachineIDDuplicated(t *testing.T) {
	makeAddr := func(updatedAt time.Time) machine.Addr {
		return machine.Addr{
			Network:   "ip",
			Value:     "52.254.159.36",
			UpdatedAt: updatedAt,
		}
	}

	machines := []struct {
		ID   machine.ID
		Addr machine.Addr
	}{
		{
			ID:   "ID_1",
			Addr: makeAddr(time.Date(2010, time.May, 1, 0, 0, 0, 0, time.UTC)),
		},
		{
			ID:   "ID_2",
			Addr: makeAddr(time.Date(2012, time.May, 1, 0, 0, 0, 0, time.UTC)),
		},
		{
			ID:   "ID_3",
			Addr: makeAddr(time.Date(2011, time.May, 1, 0, 0, 0, 0, time.UTC)),
		},
	}

	addrs := addresses.New()
	machineIDs := make(map[machine.ID]struct{})

	for i, machine := range machines {
		machineIDs[machine.ID] = struct{}{}
		if err := addrs.Add(machine.ID, machine.Addr); err != nil {
			t.Fatalf("want err = nil; got %v (i:%v)", err, i)
		}
	}

	if len(machineIDs) != len(addrs.Registered()) {
		t.Fatal("want %d machines; got %d", len(machineIDs), len(addrs.Registered()))
	}

	id, err := addrs.MachineID(makeAddr(time.Time{}))
	if err != nil {
		t.Errorf("want err = nil; got %v", err)
	}

	if wantID := machine.ID("ID_2"); wantID != id {
		t.Errorf("want machine ID = %v; got %v", wantID, id)
	}
}
