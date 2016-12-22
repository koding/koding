package idset

import (
	"koding/klient/machine"
)

// Union returns a set of all elements in A and B sets.
func Union(a, b machine.IDSlice) machine.IDSlice {
	aset := make(map[machine.ID]struct{})
	for i := range a {
		aset[a[i]] = struct{}{}
	}

	res := make(machine.IDSlice, len(a))
	copy(res, a)

	for i := range b {
		if _, ok := aset[b[i]]; !ok {
			res = append(res, b[i])
		}
	}

	return res
}

// Intersection returns a set that contains all elements of A that also belong
// to B, but no other elements.
func Intersection(a, b machine.IDSlice) machine.IDSlice {
	aset := make(map[machine.ID]struct{})
	for i := range a {
		aset[a[i]] = struct{}{}
	}

	res := make(machine.IDSlice, 0, len(a))
	for i := range b {
		if _, ok := aset[b[i]]; ok {
			res = append(res, b[i])
		}
	}

	return res
}

// Diff returns a relative complement of B in A. This means that the result
// contains elements present in A but not in B.
func Diff(a, b machine.IDSlice) machine.IDSlice {
	aset := make(map[machine.ID]struct{})
	for i := range a {
		aset[a[i]] = struct{}{}
	}

	for i := range b {
		if _, ok := aset[b[i]]; ok {
			delete(aset, b[i])
		}
	}

	res := make(machine.IDSlice, 0, len(a))
	for i := range a {
		if _, ok := aset[a[i]]; ok {
			res = append(res, a[i])
		}
	}

	return res
}
