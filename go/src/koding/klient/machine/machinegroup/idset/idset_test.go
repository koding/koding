package idset

import (
	"reflect"
	"testing"

	"koding/klient/machine"
)

func TestUnion(t *testing.T) {
	tests := map[string]struct {
		A, B, Expected machine.IDSlice
	}{
		"simple union": {
			A:        machine.IDSlice{"x1", "x2", "x3", "x4"},
			B:        machine.IDSlice{"x3", "x4", "x5"},
			Expected: machine.IDSlice{"x1", "x2", "x3", "x4", "x5"},
		},
		"empty A": {
			A:        machine.IDSlice{},
			B:        machine.IDSlice{"x1", "x2", "x3"},
			Expected: machine.IDSlice{"x1", "x2", "x3"},
		},
		"empty B": {
			A:        machine.IDSlice{"x1", "x2", "x3"},
			B:        machine.IDSlice{},
			Expected: machine.IDSlice{"x1", "x2", "x3"},
		},
		"union of zero slices": {
			A:        machine.IDSlice{},
			B:        machine.IDSlice{},
			Expected: machine.IDSlice{},
		},
		"unordered elements": {
			A:        machine.IDSlice{"x5", "x4", "x3", "x2", "x1"},
			B:        machine.IDSlice{"x3", "x4", "x6", "x5"},
			Expected: machine.IDSlice{"x5", "x4", "x3", "x2", "x1", "x6"},
		},
		"duplicated elements": {
			A:        machine.IDSlice{"x5", "x3", "x3", "x3", "x1"},
			B:        machine.IDSlice{"x3", "x4"},
			Expected: machine.IDSlice{"x5", "x3", "x3", "x3", "x1", "x4"},
		},
	}

	for name, test := range tests {
		// capture range variable here
		test := test
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			res := Union(test.A, test.B)
			if !reflect.DeepEqual(res, test.Expected) {
				t.Errorf("want result set = %v; got %v", test.Expected, res)
			}
		})
	}
}

func TestIntersection(t *testing.T) {
	tests := map[string]struct {
		A, B, Expected machine.IDSlice
	}{
		"simple intersection": {
			A:        machine.IDSlice{"x1", "x2", "x3", "x4"},
			B:        machine.IDSlice{"x3", "x4", "x5"},
			Expected: machine.IDSlice{"x3", "x4"},
		},
		"empty A": {
			A:        machine.IDSlice{},
			B:        machine.IDSlice{"x1", "x2", "x3"},
			Expected: machine.IDSlice{},
		},
		"empty B": {
			A:        machine.IDSlice{"x1", "x2", "x3"},
			B:        machine.IDSlice{},
			Expected: machine.IDSlice{},
		},
		"intersection to zero slice": {
			A:        machine.IDSlice{"x1", "x2", "x3"},
			B:        machine.IDSlice{"x4", "x5", "x6"},
			Expected: machine.IDSlice{},
		},
		"unordered elements": {
			A:        machine.IDSlice{"x5", "x4", "x3", "x2", "x1"},
			B:        machine.IDSlice{"x3", "x4", "x6", "x5"},
			Expected: machine.IDSlice{"x3", "x4", "x5"},
		},
		"duplicated elements": {
			A:        machine.IDSlice{"x5", "x3", "x3", "x3", "x1"},
			B:        machine.IDSlice{"x3", "x4"},
			Expected: machine.IDSlice{"x3"},
		},
	}

	for name, test := range tests {
		// capture range variable here
		test := test
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			res := Intersection(test.A, test.B)
			if !reflect.DeepEqual(res, test.Expected) {
				t.Errorf("want result set = %v; got %v", test.Expected, res)
			}
		})
	}
}

func TestDiff(t *testing.T) {
	tests := map[string]struct {
		A, B, Expected machine.IDSlice
	}{
		"simple diff": {
			A:        machine.IDSlice{"x1", "x2", "x3", "x4"},
			B:        machine.IDSlice{"x3", "x4", "x5"},
			Expected: machine.IDSlice{"x1", "x2"},
		},
		"empty A": {
			A:        machine.IDSlice{},
			B:        machine.IDSlice{"x1", "x2", "x3"},
			Expected: machine.IDSlice{},
		},
		"empty B": {
			A:        machine.IDSlice{"x1", "x2", "x3"},
			B:        machine.IDSlice{},
			Expected: machine.IDSlice{"x1", "x2", "x3"},
		},
		"diff to zero slice": {
			A:        machine.IDSlice{"x1", "x2", "x3"},
			B:        machine.IDSlice{"x1", "x2", "x3", "x4"},
			Expected: machine.IDSlice{},
		},
		"unordered elements": {
			A:        machine.IDSlice{"x5", "x4", "x3", "x2", "x1"},
			B:        machine.IDSlice{"x3", "x4", "x5"},
			Expected: machine.IDSlice{"x2", "x1"},
		},
		"duplicated elements": {
			A:        machine.IDSlice{"x5", "x3", "x3", "x3", "x1"},
			B:        machine.IDSlice{"x3", "x4"},
			Expected: machine.IDSlice{"x5", "x1"},
		},
	}

	for name, test := range tests {
		// capture range variable here
		test := test
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			res := Diff(test.A, test.B)
			if !reflect.DeepEqual(res, test.Expected) {
				t.Errorf("want result set = %v; got %v", test.Expected, res)
			}
		})
	}
}
