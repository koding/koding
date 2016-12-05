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

func TestInfoSliceFindByName(t *testing.T) {
	tests := map[string]struct {
		Provided []*Info
		Name     string
		Expected *Info
	}{
		"simple find": {
			Provided: []*Info{
				testInfo("a", machine.StateOnline),
				testInfo("b", machine.StateOnline),
				testInfo("c", machine.StateOnline),
				testInfo("d", machine.StateOnline),
				testInfo("e", machine.StateOnline),
				testInfo("f", machine.StateOnline),
			},
			Name:     "d",
			Expected: testInfo("d", machine.StateOnline),
		},
		"by prefix": {
			Provided: []*Info{
				testInfo("aa", machine.StateOnline),
				testInfo("bb", machine.StateOnline),
				testInfo("cc", machine.StateOnline),
			},
			Name:     "b",
			Expected: testInfo("bb", machine.StateOnline),
		},
		"exact match": {
			Provided: []*Info{
				testInfo("aa", machine.StateOnline),
				testInfo("a", machine.StateOnline),
				testInfo("aaa", machine.StateOnline),
			},
			Name:     "a",
			Expected: testInfo("a", machine.StateOnline),
		},
		"not found": {
			Provided: []*Info{
				testInfo("g", machine.StateOnline),
			},
			Name:     "a",
			Expected: nil,
		},
	}

	for name, test := range tests {
		t.Run(name, func(t *testing.T) {
			found := InfoSlice(test.Provided).FindByName(test.Name)

			if !reflect.DeepEqual(found, test.Expected) {
				t.Errorf("want %v; got %v", test.Expected, found)
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
