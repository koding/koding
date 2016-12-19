package idset

import (
	"reflect"
	"testing"

	"koding/klient/machine"
)

func TestUnion(t *testing.T) {
	tests := map[string]struct {
		A, B, Expected []machine.ID
	}{
		"simple union": {
			A:        []machine.ID{"x1", "x2", "x3", "x4"},
			B:        []machine.ID{"x3", "x4", "x5"},
			Expected: []machine.ID{"x1", "x2", "x3", "x4", "x5"},
		},
		"empty A": {
			A:        []machine.ID{},
			B:        []machine.ID{"x1", "x2", "x3"},
			Expected: []machine.ID{"x1", "x2", "x3"},
		},
		"empty B": {
			A:        []machine.ID{"x1", "x2", "x3"},
			B:        []machine.ID{},
			Expected: []machine.ID{"x1", "x2", "x3"},
		},
		"union of zero slices": {
			A:        []machine.ID{},
			B:        []machine.ID{},
			Expected: []machine.ID{},
		},
		"unordered elements": {
			A:        []machine.ID{"x5", "x4", "x3", "x2", "x1"},
			B:        []machine.ID{"x3", "x4", "x6", "x5"},
			Expected: []machine.ID{"x5", "x4", "x3", "x2", "x1", "x6"},
		},
		"duplicated elements": {
			A:        []machine.ID{"x5", "x3", "x3", "x3", "x1"},
			B:        []machine.ID{"x3", "x4"},
			Expected: []machine.ID{"x5", "x3", "x3", "x3", "x1", "x4"},
		},
	}

	for name, test := range tests {
		t.Run(name, func(t *testing.T) {
			res := Union(test.A, test.B)
			if !reflect.DeepEqual(res, test.Expected) {
				t.Errorf("want result set = %v; got %v", test.Expected, res)
			}
		})
	}
}

func TestIntersection(t *testing.T) {
	tests := map[string]struct {
		A, B, Expected []machine.ID
	}{
		"simple intersection": {
			A:        []machine.ID{"x1", "x2", "x3", "x4"},
			B:        []machine.ID{"x3", "x4", "x5"},
			Expected: []machine.ID{"x3", "x4"},
		},
		"empty A": {
			A:        []machine.ID{},
			B:        []machine.ID{"x1", "x2", "x3"},
			Expected: []machine.ID{},
		},
		"empty B": {
			A:        []machine.ID{"x1", "x2", "x3"},
			B:        []machine.ID{},
			Expected: []machine.ID{},
		},
		"intersection to zero slice": {
			A:        []machine.ID{"x1", "x2", "x3"},
			B:        []machine.ID{"x4", "x5", "x6"},
			Expected: []machine.ID{},
		},
		"unordered elements": {
			A:        []machine.ID{"x5", "x4", "x3", "x2", "x1"},
			B:        []machine.ID{"x3", "x4", "x6", "x5"},
			Expected: []machine.ID{"x3", "x4", "x5"},
		},
		"duplicated elements": {
			A:        []machine.ID{"x5", "x3", "x3", "x3", "x1"},
			B:        []machine.ID{"x3", "x4"},
			Expected: []machine.ID{"x3"},
		},
	}

	for name, test := range tests {
		t.Run(name, func(t *testing.T) {
			res := Intersection(test.A, test.B)
			if !reflect.DeepEqual(res, test.Expected) {
				t.Errorf("want result set = %v; got %v", test.Expected, res)
			}
		})
	}
}

func TestDiff(t *testing.T) {
	tests := map[string]struct {
		A, B, Expected []machine.ID
	}{
		"simple diff": {
			A:        []machine.ID{"x1", "x2", "x3", "x4"},
			B:        []machine.ID{"x3", "x4", "x5"},
			Expected: []machine.ID{"x1", "x2"},
		},
		"empty A": {
			A:        []machine.ID{},
			B:        []machine.ID{"x1", "x2", "x3"},
			Expected: []machine.ID{},
		},
		"empty B": {
			A:        []machine.ID{"x1", "x2", "x3"},
			B:        []machine.ID{},
			Expected: []machine.ID{"x1", "x2", "x3"},
		},
		"diff to zero slice": {
			A:        []machine.ID{"x1", "x2", "x3"},
			B:        []machine.ID{"x1", "x2", "x3", "x4"},
			Expected: []machine.ID{},
		},
		"unordered elements": {
			A:        []machine.ID{"x5", "x4", "x3", "x2", "x1"},
			B:        []machine.ID{"x3", "x4", "x5"},
			Expected: []machine.ID{"x2", "x1"},
		},
		"duplicated elements": {
			A:        []machine.ID{"x5", "x3", "x3", "x3", "x1"},
			B:        []machine.ID{"x3", "x4"},
			Expected: []machine.ID{"x5", "x1"},
		},
	}

	for name, test := range tests {
		t.Run(name, func(t *testing.T) {
			res := Diff(test.A, test.B)
			if !reflect.DeepEqual(res, test.Expected) {
				t.Errorf("want result set = %v; got %v", test.Expected, res)
			}
		})
	}
}
