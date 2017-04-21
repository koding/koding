package machine

import (
	"encoding/json"
	"reflect"
	"testing"
	"time"
)

func TestAddrBookAdd(t *testing.T) {
	tests := map[string]struct {
		Arg      Addr
		Expected []Addr
	}{
		"zero value": {
			Arg: Addr{
				Network: "",
				Value:   "127.0.0.1",
			},
			Expected: nil,
		},
		"zero value of network": {
			Arg: Addr{
				Network: "",
				Value:   "127.0.0.1",
			},
			Expected: nil,
		},
		"zero value of value": {
			Arg: Addr{
				Network: "",
				Value:   "127.0.0.1",
			},
			Expected: nil,
		},
		"tcp address": {
			Arg: Addr{
				Network: "tcp",
				Value:   "127.0.0.1:8080",
			},
			Expected: []Addr{
				{
					Network: "tcp",
					Value:   "127.0.0.1:8080",
				},
			},
		},
		"ip valid address": {
			Arg: Addr{
				Network: "ip",
				Value:   "127.0.0.1",
			},
			Expected: []Addr{
				{
					Network: "ip",
					Value:   "127.0.0.1",
				},
			},
		},
		"ip address with port": {
			Arg: Addr{
				Network: "ip",
				Value:   "127.0.0.1:56789",
			},
			Expected: []Addr{
				{
					Network: "ip",
					Value:   "127.0.0.1",
				},
				{
					Network: "tcp",
					Value:   "127.0.0.1:56789",
				},
			},
		},
		"tunnel address": {
			Arg: Addr{
				Network: "ip",
				Value:   "urjn784c4563.ppknap.1d54476f2.dev.koding.me",
			},
			Expected: []Addr{
				{
					Network: "tunnel",
					Value:   "urjn784c4563.ppknap.1d54476f2.dev.koding.me",
				},
			},
		},
	}

	for name, test := range tests {
		// capture range variable here
		test := test
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			ab := &AddrBook{}
			ab.Add(test.Arg)

			if len(ab.All()) != len(test.Expected) {
				t.Fatalf("want len(ab) = %d; got %d", len(test.Expected), len(ab.All()))
			}

			for _, addr := range test.Expected {
				if _, err := ab.Updated(addr); err != nil {
					t.Fatalf("want addr: %v to be in address book; it is not", addr)
				}
			}
		})
	}
}

func TestAddrBookAddUpdated(t *testing.T) {
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
			updated, err := ab.Updated(test.Addr)
			if (err == nil) != test.Has {
				t.Fatalf("want err = nil to be %t; got %v", !test.Has, err)
			}

			if test.Has && !updated.Equal(test.Addr.UpdatedAt) {
				t.Fatalf("want updated = %v; got %v", test.Addr.UpdatedAt, updated)
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
			UpdatedAt: time.Date(2011, time.May, 1, 0, 0, 0, 0, time.UTC),
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

	if l := len(ab.All()); l != 2 {
		t.Fatalf("want addresses count = 2; got %d", l)
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

func TestAddrMaxSize(t *testing.T) {
	addrs := []Addr{
		{
			Network:   "ip",
			Value:     "127.0.0.0",
			UpdatedAt: time.Time{},
		},
		{
			Network:   "ip",
			Value:     "127.0.0.1",
			UpdatedAt: time.Date(2012, time.May, 1, 0, 0, 0, 0, time.UTC),
		},
		{
			Network:   "ip",
			Value:     "127.0.0.2",
			UpdatedAt: time.Date(2011, time.May, 1, 0, 0, 0, 0, time.UTC),
		},
		{
			Network:   "ip",
			Value:     "127.0.0.4",
			UpdatedAt: time.Date(2009, time.May, 1, 0, 0, 0, 0, time.UTC),
		},
		{
			Network:   "tunnel",
			Value:     "urjn784c4563.aaaaaa.1d54476f2.dev.koding.me",
			UpdatedAt: time.Date(1997, time.May, 1, 0, 0, 0, 0, time.UTC),
		},
		{
			Network:   "tunnel",
			Value:     "urjn784c4563.bbbbb.1d54476f2.dev.koding.me",
			UpdatedAt: time.Date(2000, time.May, 1, 0, 0, 0, 0, time.UTC),
		},
		{
			Network:   "tunnel",
			Value:     "urjn784c4563.ccccc.1d54476f2.dev.koding.me",
			UpdatedAt: time.Date(1900, time.May, 1, 0, 0, 0, 0, time.UTC),
		},
	}

	want := []Addr{
		{
			Network:   "ip",
			Value:     "127.0.0.1",
			UpdatedAt: time.Date(2012, time.May, 1, 0, 0, 0, 0, time.UTC),
		},
		{
			Network:   "ip",
			Value:     "127.0.0.2",
			UpdatedAt: time.Date(2011, time.May, 1, 0, 0, 0, 0, time.UTC),
		},
		{
			Network:   "tunnel",
			Value:     "urjn784c4563.aaaaaa.1d54476f2.dev.koding.me",
			UpdatedAt: time.Date(1997, time.May, 1, 0, 0, 0, 0, time.UTC),
		},
		{
			Network:   "tunnel",
			Value:     "urjn784c4563.bbbbb.1d54476f2.dev.koding.me",
			UpdatedAt: time.Date(2000, time.May, 1, 0, 0, 0, 0, time.UTC),
		},
	}

	ab := &AddrBook{
		MaxSize: 2,
	}

	for _, addr := range addrs {
		ab.Add(addr)
	}

	if l := len(ab.All()); l != 4 {
		t.Fatalf("want addresses count = 4; got %d", l)
	}

	if got := ab.All(); !reflect.DeepEqual(got, want) {
		t.Fatalf("want addrs = %#v\n; got\n%#v", want, got)
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
