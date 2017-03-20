package client_test

import (
	"strings"
	"testing"
	"time"

	"koding/klient/machine/client"
	"koding/klient/machine/client/clienttest"
)

func TestCached(t *testing.T) {
	tests := map[string]struct {
		Method    func(int, client.Client) error
		Arguments bool
	}{
		"current user": {
			Method: func(_ int, c client.Client) (err error) {
				_, err = c.CurrentUser()
				return
			},
			Arguments: false,
		},
		"ssh add keys": {
			Method: func(i int, c client.Client) (err error) {
				return c.SSHAddKeys(strings.Repeat("s", i))
			},
			Arguments: true,
		},
		"mount head index": {
			Method: func(i int, c client.Client) (err error) {
				_, _, _, err = c.MountHeadIndex(strings.Repeat("s", i))
				return
			},
			Arguments: true,
		},
		"mount get index": {
			Method: func(i int, c client.Client) (err error) {
				_, err = c.MountGetIndex(strings.Repeat("s", i))
				return
			},
			Arguments: true,
		},
	}

	const callsN = 100
	for name, test := range tests {
		test := test // Capture local variable.
		t.Run(name, func(t *testing.T) {
			t.Parallel()

			// Cache for long time, should not invoke counter client more than
			// once.
			cached := client.NewCached(&clienttest.Counter{}, time.Hour)
			for i := 0; i < callsN; i++ {
				err := test.Method(1, cached)
				if count := clienttest.CallCount(err); count != 1 {
					t.Fatalf("want call counts = 1; got %d", count)
				}
			}

			// Cache with zero interval, should always invoke counter client.
			cached = client.NewCached(&clienttest.Counter{}, 0)
			for i := 0; i < callsN; i++ {
				err := test.Method(1, cached)
				if count := clienttest.CallCount(err); count != (i + 1) {
					t.Fatalf("want call counts = %d; got %d", (i + 1), count)
				}
			}

			// Cache with mutated arguments, should always invoke counter client.
			if test.Arguments {
				cached = client.NewCached(&clienttest.Counter{}, time.Hour)
				for i := 0; i < callsN; i++ {
					err := test.Method(i, cached)
					if count := clienttest.CallCount(err); count != (i + 1) {
						t.Fatalf("want call counts = %d; got %d", (i + 1), count)
					}
				}
			}
		})
	}
}
