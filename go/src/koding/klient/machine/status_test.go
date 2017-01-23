package machine

import (
	"reflect"
	"testing"
	"time"
)

func TestMergeStatus(t *testing.T) {
	tests := map[string]struct {
		A        Status
		B        Status
		Expected Status
	}{
		"initialization": {
			A: Status{
				State:  StateUnknown,
				Reason: "",
				Since:  time.Time{},
			},
			B: Status{
				State:  StateOnline,
				Reason: "started by stack.apply",
				Since:  time.Date(2016, time.May, 1, 0, 0, 0, 0, time.UTC),
			},
			Expected: Status{
				State:  StateOnline,
				Reason: "started by stack.apply",
				Since:  time.Date(2016, time.May, 1, 0, 0, 0, 0, time.UTC),
			},
		},
		"edge case older time is newer": {
			A: Status{
				State:  StateOnline,
				Reason: "started by stack.apply",
				Since:  time.Date(2016, time.May, 1, 0, 0, 0, 0, time.UTC),
			},
			B: Status{
				State:  StateOffline,
				Reason: "",
				Since:  time.Date(2010, time.May, 1, 0, 0, 0, 0, time.UTC),
			},
			Expected: Status{
				State:  StateOnline,
				Reason: "started by stack.apply",
				Since:  time.Date(2016, time.May, 1, 0, 0, 0, 0, time.UTC),
			},
		},
		"newer time is equal to older": {
			A: Status{
				State:  StateConnected,
				Reason: "",
				Since:  time.Date(2016, time.May, 1, 0, 0, 0, 0, time.UTC),
			},
			B: Status{
				State:  StateOffline,
				Reason: "machine disabled",
				Since:  time.Date(2016, time.May, 1, 0, 0, 0, 0, time.UTC),
			},
			Expected: Status{
				State:  StateOffline,
				Reason: "machine disabled",
				Since:  time.Date(2016, time.May, 1, 0, 0, 0, 0, time.UTC),
			},
		},
		"same state get time from older": {
			A: Status{
				State:  StateConnected,
				Reason: "connected",
				Since:  time.Date(2010, time.May, 1, 0, 0, 0, 0, time.UTC),
			},
			B: Status{
				State:  StateConnected,
				Reason: "machine connected",
				Since:  time.Date(2016, time.May, 1, 0, 0, 0, 0, time.UTC),
			},
			Expected: Status{
				State:  StateConnected,
				Reason: "machine connected",
				Since:  time.Date(2010, time.May, 1, 0, 0, 0, 0, time.UTC),
			},
		},
		"same state newer has no reason": {
			A: Status{
				State:  StateConnected,
				Reason: "connected",
				Since:  time.Date(2010, time.May, 1, 0, 0, 0, 0, time.UTC),
			},
			B: Status{
				State:  StateConnected,
				Reason: "",
				Since:  time.Date(2016, time.May, 1, 0, 0, 0, 0, time.UTC),
			},
			Expected: Status{
				State:  StateConnected,
				Reason: "connected",
				Since:  time.Date(2010, time.May, 1, 0, 0, 0, 0, time.UTC),
			},
		},
		"a status is zero value": {
			A: Status{},
			B: Status{
				State:  StateConnected,
				Reason: "connected",
				Since:  time.Date(2016, time.May, 1, 0, 0, 0, 0, time.UTC),
			},
			Expected: Status{
				State:  StateConnected,
				Reason: "connected",
				Since:  time.Date(2016, time.May, 1, 0, 0, 0, 0, time.UTC),
			},
		},
		"b status is zero value": {
			A: Status{
				State:  StateConnected,
				Reason: "connected",
				Since:  time.Date(2016, time.May, 1, 0, 0, 0, 0, time.UTC),
			},
			B: Status{},
			Expected: Status{
				State:  StateConnected,
				Reason: "connected",
				Since:  time.Date(2016, time.May, 1, 0, 0, 0, 0, time.UTC),
			},
		},
		"non zero value of reason": {
			A: Status{
				Reason: "connected",
			},
			B: Status{},
			Expected: Status{
				Reason: "connected",
			},
		},
	}

	for name, test := range tests {
		// capture range variable here
		test := test
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			expected := MergeStatus(test.A, test.B)
			if !reflect.DeepEqual(expected, test.Expected) {
				t.Fatalf("want status: %s; got %s", test.Expected, expected)
			}
		})
	}
}
