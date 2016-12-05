package machine

import (
	"reflect"
	"sort"
	"testing"

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
		t.Run(name, func(t *testing.T) {
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
