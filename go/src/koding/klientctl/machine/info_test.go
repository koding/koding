package machine

import (
	"reflect"
	"sort"
	"testing"
)

func TestInfoSliceSort(t *testing.T) {
	tests := map[string]struct {
		Provided []*Info
		Expected []*Info
	}{
		"sort by state": {
			Provided: []*Info{
				testInfo("coconut", StateDisconnected, ListMountInfo{}),
				testInfo("apple", StateOffline),
				testInfo("pear", StateOnline),
				testInfo("date", StateOnline),
				testInfo("grapefruit", StateOffline),
				testInfo("orange", StateOffline),
				testInfo("banana", StateOffline),
				testInfo("squash", StateConnected, ListMountInfo{}),
				testInfo("kiwi", StateOnline),
				testInfo("jackfruit", StateConnected, ListMountInfo{}),
			},
			Expected: []*Info{
				testInfo("coconut", StateDisconnected, ListMountInfo{}),
				testInfo("jackfruit", StateConnected, ListMountInfo{}),
				testInfo("squash", StateConnected, ListMountInfo{}),
				testInfo("date", StateOnline),
				testInfo("kiwi", StateOnline),
				testInfo("pear", StateOnline),
				testInfo("apple", StateOffline),
				testInfo("banana", StateOffline),
				testInfo("grapefruit", StateOffline),
				testInfo("orange", StateOffline),
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
				testInfo("a", StateOnline),
				testInfo("b", StateOnline),
				testInfo("c", StateOnline),
				testInfo("d", StateOnline),
				testInfo("e", StateOnline),
				testInfo("f", StateOnline),
			},
			Name:     "d",
			Expected: testInfo("d", StateOnline),
		},
		"by prefix": {
			Provided: []*Info{
				testInfo("aa", StateOnline),
				testInfo("bb", StateOnline),
				testInfo("cc", StateOnline),
			},
			Name:     "b",
			Expected: testInfo("bb", StateOnline),
		},
		"exact match": {
			Provided: []*Info{
				testInfo("aa", StateOnline),
				testInfo("a", StateOnline),
				testInfo("aaa", StateOnline),
			},
			Name:     "a",
			Expected: testInfo("a", StateOnline),
		},
		"not found": {
			Provided: []*Info{
				testInfo("g", StateOnline),
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

func testInfo(alias string, state State, mounts ...ListMountInfo) *Info {
	return &Info{
		Alias: alias,
		Status: Status{
			State: state,
		},
		Mounts: mounts,
	}
}
