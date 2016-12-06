package machine

import (
	"encoding/json"
	"testing"
	"time"
)

func TestAddrBookAddHas(t *testing.T) {
	tests := map[string]struct {
		Has  bool
		Addr Addr
	}{
		"local IP empty time": {
			Has: false,
			Addr: Addr{
				Network:   "ip",
				Value:     "127.0.0.231",
				UpdatedAt: time.Time{},
			},
		},
		"local IP time after 2012": {
			Has: false,
			Addr: Addr{
				Network:   "ip",
				Value:     "127.0.0.13",
				UpdatedAt: time.Date(2012, time.May, 1, 0, 0, 0, 0, time.UTC),
			},
		},
		"local IP time after 2016": {
			Has: true,
			Addr: Addr{
				Network:   "ip",
				Value:     "127.0.0.1",
				UpdatedAt: time.Date(2016, time.May, 1, 0, 0, 0, 0, time.UTC),
			},
		},
		"local TCP address": {
			Has: true,
			Addr: Addr{
				Network:   "tcp",
				Value:     "127.0.0.1:8080",
				UpdatedAt: time.Time{},
			},
		},
	}

	ab := &AddrBook{}

	for _, test := range tests {
		if test.Has {
			ab.Add(test.Addr)
		}
	}

	for name, test := range tests {
		test := test // capture range variable.
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			if has := ab.Has(test.Addr); has != test.Has {
				t.Fatalf("want has = %t; got %t", test.Has, has)
			}
		})
	}
}

func TestAddrLatest(t *testing.T) {
	addrs := []Addr{
		{
			Network:   "ip",
			Value:     "127.0.0.1",
			UpdatedAt: time.Time{},
		},
		{
			Network:   "ip",
			Value:     "127.0.0.1",
			UpdatedAt: time.Date(2012, time.May, 1, 0, 0, 0, 0, time.UTC),
		},
		{
			Network:   "ip",
			Value:     "127.0.0.1",
			UpdatedAt: time.Time{},
		},
		{
			Network:   "tcp",
			Value:     "127.0.0.1:80",
			UpdatedAt: time.Date(2009, time.May, 1, 0, 0, 0, 0, time.UTC),
		},
	}

	tests := map[string]struct {
		UpdatedAt time.Time
		Addr      Addr
	}{
		"latest IP": {
			UpdatedAt: time.Date(2012, time.May, 1, 0, 0, 0, 0, time.UTC),
			Addr: Addr{
				Network: "ip",
				Value:   "127.0.0.1",
			},
		},
		"latest TCP": {
			UpdatedAt: time.Date(2009, time.May, 1, 0, 0, 0, 0, time.UTC),
			Addr: Addr{
				Network: "tcp",
				Value:   "127.0.0.1:80",
			},
		},
	}

	ab := &AddrBook{}

	for _, addr := range addrs {
		ab.Add(addr)
	}

	for name, test := range tests {
		test := test // capture range variable.
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			addr, err := ab.Latest(test.Addr.Network)
			if err != nil {
				t.Fatalf("want err = nil; got %v", err)
			}

			if !addr.UpdatedAt.Equal(test.UpdatedAt) {
				t.Fatalf("want updated = %v; got %v", test.UpdatedAt, addr.UpdatedAt)
			}
		})
	}
}

func TestAddrBookJSON(t *testing.T) {
	addrs := []Addr{
		{
			Network:   "ip",
			Value:     "127.0.0.1",
			UpdatedAt: time.Time{},
		},
		{
			Network:   "tcp",
			Value:     "127.0.0.1:80",
			UpdatedAt: time.Date(2009, time.May, 1, 0, 0, 0, 0, time.UTC),
		},
	}

	ab := &AddrBook{}

	for _, addr := range addrs {
		ab.Add(addr)
	}

	data, err := json.Marshal(ab)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	ab = &AddrBook{}
	if err = json.Unmarshal(data, ab); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	for i, addr := range addrs {
		a, err := ab.Latest(addr.Network)
		if err != nil {
			t.Fatalf("want err = nil; got %v (i:%d)", err, i)
		}

		if !addr.UpdatedAt.Equal(a.UpdatedAt) {
			t.Fatalf("want updated = %v; got %v (i:%d)", addr.UpdatedAt, a.UpdatedAt, i)
		}
	}
}
