package util

import (
	"bufio"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"net"
	"os"
	"runtime"
	"strings"
)

// TODO(rjeczalik): add support for darwin and windows.

// ErrNotImplemented is returned by ParseRoutes* function on
// platforms, where the methods are not implemented.
//
// Currently they are implemented for GOOS=linux only.
var ErrNotImplemented = errors.New("not implemented")

// Route represents a single routing entry.
type Route struct {
	Iface   string
	Dest    net.IP
	Gateway net.IP
}

// String implements the fmt.Stringer interface.
func (r *Route) String() string {
	return fmt.Sprintf("%s: %s -> %s", r.Iface, r.Dest, r.Gateway)
}

func ipFromHex(s string) (net.IP, error) {
	if s == "00000000" {
		return nil, nil
	}

	p, err := hex.DecodeString(s)
	if err != nil {
		return nil, err
	}

	return net.IPv4(p[3], p[2], p[1], p[0]), nil
}

// ParseRoutes reads system routing information and list gateway
// addresses for each available interface.
func ParseRoutes() ([]*Route, error) {
	if runtime.GOOS != "linux" {
		return nil, ErrNotImplemented
	}

	f, err := os.Open("/proc/net/route")
	if err != nil {
		return nil, err
	}
	defer f.Close()

	return ParseRoutesReader(f)
}

// ParseRoutesReader parses platform-specific routes information from r.
func ParseRoutesReader(r io.Reader) ([]*Route, error) {
	if runtime.GOOS != "linux" {
		return nil, ErrNotImplemented
	}

	var routes []*Route
	var err error

	scanner := bufio.NewScanner(r)
	for scanner.Scan() {
		s := strings.Fields(scanner.Text())
		if len(s) < 3 || s[0] == "Iface" || s[0] == "*" || len(s[1]) != 8 || len(s[2]) != 8 {
			continue
		}

		r := &Route{
			Iface: s[0],
		}

		if r.Dest, err = ipFromHex(s[1]); err != nil {
			continue
		}

		if r.Gateway, err = ipFromHex(s[2]); err != nil {
			continue
		}

		routes = append(routes, r)
	}

	if err := scanner.Err(); err != nil {
		return nil, err
	}

	return routes, nil
}
