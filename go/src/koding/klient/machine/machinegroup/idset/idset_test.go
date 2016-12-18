package idset

import (
	"reflect"
	"strings"
	"testing"

	"koding/klient/machine"
)

func TestUnion(t *testing.T) {
	tests := map[string]struct {
		A, B, Expected []machine.ID
	}{
		"simple union": {
			A:        genIDs("x1, x2, x3, x4"),
			B:        genIDs("x3, x4, x5"),
			Expected: genIDs("x1, x2, x3, x4, x5"),
		},
		"empty A": {
			A:        genIDs(""),
			B:        genIDs("x1, x2, x3"),
			Expected: genIDs("x1, x2, x3"),
		},
		"empty B": {
			A:        genIDs("x1, x2, x3"),
			B:        genIDs(""),
			Expected: genIDs("x1, x2, x3"),
		},
		"union of zero slices": {
			A:        genIDs(""),
			B:        genIDs(""),
			Expected: genIDs(""),
		},
		"unordered elements": {
			A:        genIDs("x5, x4, x3, x2, x1"),
			B:        genIDs("x3, x4, x6, x5"),
			Expected: genIDs("x5, x4, x3, x2, x1, x6"),
		},
		"duplicated elements": {
			A:        genIDs("x5, x3, x3, x3, x1"),
			B:        genIDs("x3, x4"),
			Expected: genIDs("x5, x3, x3, x3, x1, x4"),
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
			A:        genIDs("x1, x2, x3, x4"),
			B:        genIDs("x3, x4, x5"),
			Expected: genIDs("x3, x4"),
		},
		"empty A": {
			A:        genIDs(""),
			B:        genIDs("x1, x2, x3"),
			Expected: genIDs(""),
		},
		"empty B": {
			A:        genIDs("x1, x2, x3"),
			B:        genIDs(""),
			Expected: genIDs(""),
		},
		"intersection to zero slice": {
			A:        genIDs("x1, x2, x3"),
			B:        genIDs("x4, x5, x6"),
			Expected: genIDs(""),
		},
		"unordered elements": {
			A:        genIDs("x5, x4, x3, x2, x1"),
			B:        genIDs("x3, x4, x6, x5"),
			Expected: genIDs("x3, x4, x5"),
		},
		"duplicated elements": {
			A:        genIDs("x5, x3, x3, x3, x1"),
			B:        genIDs("x3, x4"),
			Expected: genIDs("x3"),
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
			A:        genIDs("x1, x2, x3, x4"),
			B:        genIDs("x3, x4, x5"),
			Expected: genIDs("x1, x2"),
		},
		"empty A": {
			A:        genIDs(""),
			B:        genIDs("x1, x2, x3"),
			Expected: genIDs(""),
		},
		"empty B": {
			A:        genIDs("x1, x2, x3"),
			B:        genIDs(""),
			Expected: genIDs("x1, x2, x3"),
		},
		"diff to zero slice": {
			A:        genIDs("x1, x2, x3"),
			B:        genIDs("x1, x2, x3, x4"),
			Expected: genIDs(""),
		},
		"unordered elements": {
			A:        genIDs("x5, x4, x3, x2, x1"),
			B:        genIDs("x3, x4, x5"),
			Expected: genIDs("x2, x1"),
		},
		"duplicated elements": {
			A:        genIDs("x5, x3, x3, x3, x1"),
			B:        genIDs("x3, x4"),
			Expected: genIDs("x5, x1"),
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

func genIDs(ids string) (res []machine.ID) {
	if ids == "" {
		return []machine.ID{}
	}

	for _, id := range strings.Split(ids, ",") {
		res = append(res, machine.ID(strings.TrimSpace(id)))
	}

	return res
}
