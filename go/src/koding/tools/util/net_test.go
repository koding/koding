package util_test

import (
	"net"
	"reflect"
	"runtime"
	"strings"
	"testing"

	"koding/tools/util"
)

const vagrantProcNetRoute = `
Iface	Destination	Gateway 	Flags	RefCnt	Use	Metric	Mask		MTU	Window	IRTT
eth0	00000000	0202000A	0003	0	0	0	00000000	0	0	0
eth0	0002000A	00000000	0001	0	0	0	00FFFFFF	0	0	0
`

const ubuntuProcNetRoute = `
Iface	Destination	Gateway 	Flags	RefCnt	Use	Metric	Mask		MTU	Window	IRTT
eth0	00000000	0100F00A	0003	0	0	0	00000000	0	0	0
lxcbr0	0003000A	00000000	0001	0	0	0	00FFFFFF	0	0	0
eth0	0100F00A	00000000	0005	0	0	0	FFFFFFFF	0	0	0
*	FEA9FEA9	00000000	0205	0	0	0	FFFFFFFF	0	0	0
docker0	000011AC	00000000	0001	0	0	0	0000FFFF	0	0	0
`

func TestRoutesReader(t *testing.T) {
	if _, err := util.ParseRoutesReader(strings.NewReader("")); err == util.ErrNotImplemented {
		t.Skipf("util.ParseRoutes is not implemented for %s", runtime.GOOS)
	}

	cases := []struct {
		raw    string
		routes []*util.Route
	}{{ // i=0
		vagrantProcNetRoute,
		[]*util.Route{{
			Iface:   "eth0",
			Gateway: net.IPv4(10, 0, 2, 2),
		}, {
			Iface: "eth0",
			Dest:  net.IPv4(10, 0, 2, 0),
		}},
	}, { // i=1
		ubuntuProcNetRoute,
		[]*util.Route{{
			Iface:   "eth0",
			Gateway: net.IPv4(10, 240, 0, 1),
		}, {
			Iface: "lxcbr0",
			Dest:  net.IPv4(10, 0, 3, 0),
		}, {
			Iface: "eth0",
			Dest:  net.IPv4(10, 240, 0, 1),
		}, {
			Iface: "docker0",
			Dest:  net.IPv4(172, 17, 0, 0),
		}},
	}}

	for i, cas := range cases {
		routes, err := util.ParseRoutesReader(strings.NewReader(cas.raw))
		if err != nil {
			t.Errorf("%d: ParseRoutesReader()=%s", i, err)
			continue
		}

		if !reflect.DeepEqual(routes, cas.routes) {
			t.Errorf("%d: got %# v, want %# v", i, routes, cas.routes)
		}
	}
}

func TestRoutesUnique(t *testing.T) {
	r, err := util.ParseRoutes()
	if err == util.ErrNotImplemented {
		t.Skipf("util.ParseRoutes is not implemented for %s", runtime.GOOS)
	}
	if err != nil {
		t.Fatal(err)
	}

	if len(r) == 0 {
		t.Fatal("no routes parsed")
	}

	gateways := make(map[string]struct{})

	for _, r := range r {
		if r.Gateway != nil {
			gateways[r.Gateway.String()] = struct{}{}
		}
	}

	addrs, err := net.InterfaceAddrs()
	if err != nil {
		t.Fatal(err)
	}

	for i, a := range addrs {
		ipnet, ok := a.(*net.IPNet)
		if !ok {
			t.Errorf("%d: want %v to be %T, was %T", i, a, (*net.IPNet)(nil), a)
			continue
		}

		if _, ok = gateways[ipnet.IP.String()]; ok {
			t.Errorf("%d: %s is not a gateway, but was parsed by routes", i, ipnet.IP)
		}
	}
}
