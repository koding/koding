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
				Net:     "ip",
				Val:     "52.254.159.36",
				Updated: time.Date(2012, time.May, 1, 0, 0, 0, 0, time.UTC),
			},
			Valid: true,
		},
		"machine 1 newer IP": {
			ID: "ID_1",
			Addr: machine.Addr{
				Net:     "ip",
				Val:     "52.254.159.123",
				Updated: time.Date(2014, time.May, 1, 0, 0, 0, 0, time.UTC),
			},
			Valid: true,
		},
		"machine 2 TCP": {
			ID: "ID_2",
			Addr: machine.Addr{
				Net:     "tcp",
				Val:     "127.0.0.1:80",
				Updated: time.Date(2009, time.May, 1, 0, 0, 0, 0, time.UTC),
			},
			Valid: true,
		},
		"unknown address": {
			ID: "ID_2",
			Addr: machine.Addr{
				Net:     "ip",
				Val:     "10.0.34.134",
				Updated: time.Date(2000, time.May, 1, 0, 0, 0, 0, time.UTC),
			},
			Valid: false,
		},
		"missing machine": {
			ID: "",
			Addr: machine.Addr{
				Net:     "ip",
				Val:     "10.0.34.23",
				Updated: time.Date(2020, time.May, 1, 0, 0, 0, 0, time.UTC),
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
		t.Run(name, func(t *testing.T) {
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
