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
				Net:     "ip",
				Val:     "127.0.0.231",
				Updated: time.Time{},
			},
		},
		"local IP time after 2012": {
			Has: false,
			Addr: Addr{
				Net:     "ip",
				Val:     "127.0.0.13",
				Updated: time.Date(2012, time.May, 1, 0, 0, 0, 0, time.UTC),
			},
		},
		"local IP time after 2016": {
			Has: true,
			Addr: Addr{
				Net:     "ip",
				Val:     "127.0.0.1",
				Updated: time.Date(2016, time.May, 1, 0, 0, 0, 0, time.UTC),
			},
		},
		"local TCP address": {
			Has: true,
			Addr: Addr{
				Net:     "tcp",
				Val:     "127.0.0.1:8080",
				Updated: time.Time{},
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
			Net:     "ip",
			Val:     "127.0.0.1",
			Updated: time.Time{},
		},
		{
			Net:     "ip",
			Val:     "127.0.0.1",
			Updated: time.Date(2012, time.May, 1, 0, 0, 0, 0, time.UTC),
		},
		{
			Net:     "ip",
			Val:     "127.0.0.1",
			Updated: time.Time{},
		},
		{
			Net:     "tcp",
			Val:     "127.0.0.1:80",
			Updated: time.Date(2009, time.May, 1, 0, 0, 0, 0, time.UTC),
		},
	}

	tests := map[string]struct {
		Updated time.Time
		Addr    Addr
	}{
		"latest IP": {
			Updated: time.Date(2012, time.May, 1, 0, 0, 0, 0, time.UTC),
			Addr: Addr{
				Net: "ip",
				Val: "127.0.0.1",
			},
		},
		"latest TCP": {
			Updated: time.Date(2009, time.May, 1, 0, 0, 0, 0, time.UTC),
			Addr: Addr{
				Net: "tcp",
				Val: "127.0.0.1:80",
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
			addr, err := ab.Latest(test.Addr.Net)
			if err != nil {
				t.Fatalf("want err = nil; got %v", err)
			}

			if !addr.Updated.Equal(test.Updated) {
				t.Fatalf("want updated = %v; got %v", test.Updated, addr.Updated)
			}
		})
	}
}

func TestAddrBookJSON(t *testing.T) {
	addrs := []Addr{
		{
			Net:     "ip",
			Val:     "127.0.0.1",
			Updated: time.Time{},
		},
		{
			Net:     "tcp",
			Val:     "127.0.0.1:80",
			Updated: time.Date(2009, time.May, 1, 0, 0, 0, 0, time.UTC),
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
		a, err := ab.Latest(addr.Net)
		if err != nil {
			t.Fatalf("want err = nil; got %v (i:%d)", err, i)
		}

		if !addr.Updated.Equal(a.Updated) {
			t.Fatalf("want updated = %v; got %v (i:%d)", addr.Updated, a.Updated, i)
		}
	}
}
