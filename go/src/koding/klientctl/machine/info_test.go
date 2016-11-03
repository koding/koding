package machine

import (
	"fmt"
	"reflect"
	"sort"
	"testing"
)

func TestInfoSliceSort(t *testing.T) {
	tests := []struct {
		Provided []*Info
		Expected []*Info
	}{
		{
			// 0 //
			Provided: []*Info{
				testInfo("coconut", StatusDisconnected, ListMountInfo{}),
				testInfo("apple", StatusOffline),
				testInfo("pear", StatusOnline),
				testInfo("date", StatusOnline),
				testInfo("grapefruit", StatusOffline),
				testInfo("orange", StatusOffline),
				testInfo("banana", StatusOffline),
				testInfo("squash", StatusConnected, ListMountInfo{}),
				testInfo("kiwi", StatusOnline),
				testInfo("jackfruit", StatusConnected, ListMountInfo{}),
			},
			Expected: []*Info{
				testInfo("coconut", StatusDisconnected, ListMountInfo{}),
				testInfo("jackfruit", StatusConnected, ListMountInfo{}),
				testInfo("squash", StatusConnected, ListMountInfo{}),
				testInfo("date", StatusOnline),
				testInfo("kiwi", StatusOnline),
				testInfo("pear", StatusOnline),
				testInfo("apple", StatusOffline),
				testInfo("banana", StatusOffline),
				testInfo("grapefruit", StatusOffline),
				testInfo("orange", StatusOffline),
			},
		},
	}

	getNames := func(is []*Info) (names []string) {
		for _, info := range is {
			names = append(names, info.VMName)
		}
		return
	}

	for i, test := range tests {
		t.Run(fmt.Sprintf("test_no_%d", i), func(t *testing.T) {
			sort.Sort(InfoSlice(test.Provided))

			provided, expected := getNames(test.Provided), getNames(test.Expected)
			if !reflect.DeepEqual(provided, expected) {
				t.Errorf("want %v; got %v", expected, provided)
			}
		})
	}
}

func TestInfoSliceFindByName(t *testing.T) {
	tests := []struct {
		Provided []*Info
		Name     string
		Expected *Info
	}{
		{
			// 0 //
			Provided: []*Info{
				testInfo("a", StatusOnline),
				testInfo("b", StatusOnline),
				testInfo("c", StatusOnline),
				testInfo("d", StatusOnline),
				testInfo("e", StatusOnline),
				testInfo("f", StatusOnline),
			},
			Name:     "d",
			Expected: testInfo("d", StatusOnline),
		},
		{
			// 1 //
			Provided: []*Info{
				testInfo("aa", StatusOnline),
				testInfo("bb", StatusOnline),
				testInfo("cc", StatusOnline),
			},
			Name:     "b",
			Expected: testInfo("bb", StatusOnline),
		},
		{
			// 2 //
			Provided: []*Info{
				testInfo("aa", StatusOnline),
				testInfo("a", StatusOnline),
				testInfo("aaa", StatusOnline),
			},
			Name:     "a",
			Expected: testInfo("a", StatusOnline),
		},
		{
			// 3 //
			Provided: []*Info{
				testInfo("g", StatusOnline),
			},
			Name:     "a",
			Expected: nil,
		},
	}

	for i, test := range tests {
		t.Run(fmt.Sprintf("test_no_%d", i), func(t *testing.T) {
			found := InfoSlice(test.Provided).FindByName(test.Name)

			if !reflect.DeepEqual(found, test.Expected) {
				t.Errorf("want %v; got %v", test.Expected, found)
			}
		})
	}
}

func testInfo(vmname string, status Status, mounts ...ListMountInfo) *Info {
	return &Info{
		VMName: vmname,
		Status: status,
		Mounts: mounts,
	}
}
