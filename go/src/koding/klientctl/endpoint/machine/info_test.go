package machine

import (
	"reflect"
	"sort"
	"testing"
	"time"

	"koding/klient/machine"
)

func TestInfoSliceSort(t *testing.T) {
	tests := map[string]struct {
		Provided []*Info
		Expected []*Info
	}{
		"sort by state": {
			Provided: []*Info{
				testInfo("coconut", machine.StateUnknown),
				testInfo("apple", machine.StateOffline),
				testInfo("pear", machine.StateOnline),
				testInfo("date", machine.StateOnline),
				testInfo("grapefruit", machine.StateOffline),
				testInfo("orange", machine.StateOffline),
				testInfo("banana", machine.StateOffline),
				testInfo("squash", machine.StateConnected),
				testInfo("kiwi", machine.StateOnline),
				testInfo("jackfruit", machine.StateConnected),
			},
			Expected: []*Info{
				testInfo("jackfruit", machine.StateConnected),
				testInfo("squash", machine.StateConnected),
				testInfo("date", machine.StateOnline),
				testInfo("kiwi", machine.StateOnline),
				testInfo("pear", machine.StateOnline),
				testInfo("apple", machine.StateOffline),
				testInfo("banana", machine.StateOffline),
				testInfo("grapefruit", machine.StateOffline),
				testInfo("orange", machine.StateOffline),
				testInfo("coconut", machine.StateUnknown),
			},
		},
	}

	getNames := func(is []*Info) (names []string) {
		for _, info := range is {
			names = append(names, info.Alias)
		}
		return
	}

	for name, test := range tests {
		// capture range variable here
		test := test
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			sort.Sort(InfoSlice(test.Provided))

			provided, expected := getNames(test.Provided), getNames(test.Expected)
			if !reflect.DeepEqual(provided, expected) {
				t.Errorf("want %v; got %v", expected, provided)
			}
		})
	}
}

func testInfo(alias string, state machine.State) *Info {
	return &Info{
		Alias: alias,
		Status: machine.Status{
			State: state,
		},
	}
}

func TestShortDuration(t *testing.T) {
	now := time.Now()
	tests := map[string]struct {
		Time     time.Time
		Expected string
	}{
		"zero value": {
			Time:     time.Time{},
			Expected: "-",
		},
		"seconds only": {
			Time:     now.Add(-40 * time.Second),
			Expected: "40s",
		},
		"one minute": {
			Time:     now.Add(-time.Minute),
			Expected: "1m",
		},
		"one minute fifteen sec": {
			Time:     now.Add(-75 * time.Second),
			Expected: "1m15s",
		},
		"one hour": {
			Time:     now.Add(-time.Hour),
			Expected: "1h",
		},
		"one hour five minutes": {
			Time:     now.Add(-65 * time.Minute),
			Expected: "1h5m",
		},
		"one day": {
			Time:     now.Add(-24 * time.Hour),
			Expected: "1d",
		},
		"one day two hours": {
			Time:     now.Add(-26 * time.Hour),
			Expected: "1d2h",
		},
	}

	for name, test := range tests {
		// capture range variable here
		test := test
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			got := ShortDuration(test.Time, now)
			if got != test.Expected {
				t.Fatalf("want formatted time = %v; got %v", test.Expected, got)
			}
		})
	}
}
