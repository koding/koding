package slices

import "github.com/feyeleanor/lists"
import "reflect"
import "testing"

func TestVSliceMakeSlice(t *testing.T) {}

func TestVSliceVSlice(t *testing.T) {
	g := VList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9)
	if g == nil {
		t.Fatal("Make slice returned a nil value")
	}

	if g.Len() != 10 {
		t.Fatalf("Slice length should be %v not %v", 10, g.Len())
	}

	for i := 0; i < g.Len(); i++ {
		if g.At(i) != i {
			t.Fatalf("g[%v] should contain %v but contains %v", i, g.At(i))
		}
	}
}

func TestVSliceString(t *testing.T) {
	ConfirmString := func(s VSlice, r string) {
		if x := s.String(); x != r {
			t.Fatalf("%v erroneously serialised as '%v'", r, x)
		}
	}

	ConfirmString(VList(), "()")
	ConfirmString(VList(0), "(0)")
	ConfirmString(VList(0, 1), "(0 1)")
}

func TestVSliceLen(t *testing.T) {
	ConfirmLength := func(s VSlice, i int) {
		if x := s.Len(); x != i {
			t.Fatalf("%v.Len() should be %v but is %v", s, i, x)
		}
	}
	
	ConfirmLength(VList(0), 1)
	ConfirmLength(VList(0, 1), 2)
}

func TestVSliceClear(t *testing.T) {
	ConfirmClear := func(s VSlice, i int, r VSlice) {
		if s.Clear(i); !r.Equal(s) {
			t.Fatalf("Clear(%v) should be %v but is %v", i, r, s)
		}
	}

	ConfirmClear(VList(0, 1, 2, 3, 4), 0, VList(nil, 1, 2, 3, 4))
	ConfirmClear(VList(0, 1, 2, 3, 4), 1, VList(0, nil, 2, 3, 4))
	ConfirmClear(VList(0, 1, 2, 3, 4), 2, VList(0, 1, nil, 3, 4))
	ConfirmClear(VList(0, 1, 2, 3, 4), 3, VList(0, 1, 2, nil, 4))
	ConfirmClear(VList(0, 1, 2, 3, 4), 4, VList(0, 1, 2, 3, nil))
}

func TestVSliceSwap(t *testing.T) {
	ConfirmSwap := func(s VSlice, i, j int, r VSlice) {
		if s.Swap(i, j); !r.Equal(s) {
			t.Fatalf("Swap(%v, %v) should be %v but is %v", i, j, r, s)
		}
	}
	ConfirmSwap(VList(0, 1, 2), 0, 1, VList(1, 0, 2))
	ConfirmSwap(VList(0, 1, 2), 0, 2, VList(2, 1, 0))
}

func TestVSliceCut(t *testing.T) {
	ConfirmCut := func(s VSlice, start, end int, r VSlice) {
		if s.Cut(start, end); !r.Equal(s) {
			t.Fatalf("Cut(%v, %v) should be %v but is %v", start, end, r, s)
		}
	}

	ConfirmCut(VList(0, 1, 2, 3, 4, 5), 0, 1, VList(1, 2, 3, 4, 5))
	ConfirmCut(VList(0, 1, 2, 3, 4, 5), 1, 2, VList(0, 2, 3, 4, 5))
	ConfirmCut(VList(0, 1, 2, 3, 4, 5), 2, 3, VList(0, 1, 3, 4, 5))
	ConfirmCut(VList(0, 1, 2, 3, 4, 5), 3, 4, VList(0, 1, 2, 4, 5))
	ConfirmCut(VList(0, 1, 2, 3, 4, 5), 4, 5, VList(0, 1, 2, 3, 5))
	ConfirmCut(VList(0, 1, 2, 3, 4, 5), 5, 6, VList(0, 1, 2, 3, 4))

	ConfirmCut(VList(0, 1, 2, 3, 4, 5), -1, 1, VList(1, 2, 3, 4, 5))
	ConfirmCut(VList(0, 1, 2, 3, 4, 5), 0, 2, VList(2, 3, 4, 5))
	ConfirmCut(VList(0, 1, 2, 3, 4, 5), 1, 3, VList(0, 3, 4, 5))
	ConfirmCut(VList(0, 1, 2, 3, 4, 5), 2, 4, VList(0, 1, 4, 5))
	ConfirmCut(VList(0, 1, 2, 3, 4, 5), 3, 5, VList(0, 1, 2, 5))
	ConfirmCut(VList(0, 1, 2, 3, 4, 5), 4, 6, VList(0, 1, 2, 3))
	ConfirmCut(VList(0, 1, 2, 3, 4, 5), 5, 7, VList(0, 1, 2, 3, 4))
}

func TestVSliceTrim(t *testing.T) {
	ConfirmTrim := func(s VSlice, start, end int, r VSlice) {
		if s.Trim(start, end); !r.Equal(s) {
			t.Fatalf("Trim(%v, %v) should be %v but is %v", start, end, r, s)
		}
	}

	ConfirmTrim(VList(0, 1, 2, 3, 4, 5), 0, 1, VList(0))
	ConfirmTrim(VList(0, 1, 2, 3, 4, 5), 1, 2, VList(1))
	ConfirmTrim(VList(0, 1, 2, 3, 4, 5), 2, 3, VList(2))
	ConfirmTrim(VList(0, 1, 2, 3, 4, 5), 3, 4, VList(3))
	ConfirmTrim(VList(0, 1, 2, 3, 4, 5), 4, 5, VList(4))
	ConfirmTrim(VList(0, 1, 2, 3, 4, 5), 5, 6, VList(5))

	ConfirmTrim(VList(0, 1, 2, 3, 4, 5), -1, 1, VList(0))
	ConfirmTrim(VList(0, 1, 2, 3, 4, 5), 0, 2, VList(0, 1))
	ConfirmTrim(VList(0, 1, 2, 3, 4, 5), 1, 3, VList(1, 2))
	ConfirmTrim(VList(0, 1, 2, 3, 4, 5), 2, 4, VList(2, 3))
	ConfirmTrim(VList(0, 1, 2, 3, 4, 5), 3, 5, VList(3, 4))
	ConfirmTrim(VList(0, 1, 2, 3, 4, 5), 4, 6, VList(4, 5))
	ConfirmTrim(VList(0, 1, 2, 3, 4, 5), 5, 7, VList(5))
}

func TestVSliceDelete(t *testing.T) {
	ConfirmDelete := func(s VSlice, index int, r VSlice) {
		if s.Delete(index); !r.Equal(s) {
			t.Fatalf("Delete(%v) should be %v but is %v", index, r, s)
		}
	}

	ConfirmDelete(VList(0, 1, 2, 3, 4, 5), -1, VList(0, 1, 2, 3, 4, 5))
	ConfirmDelete(VList(0, 1, 2, 3, 4, 5), 0, VList(1, 2, 3, 4, 5))
	ConfirmDelete(VList(0, 1, 2, 3, 4, 5), 1, VList(0, 2, 3, 4, 5))
	ConfirmDelete(VList(0, 1, 2, 3, 4, 5), 2, VList(0, 1, 3, 4, 5))
	ConfirmDelete(VList(0, 1, 2, 3, 4, 5), 3, VList(0, 1, 2, 4, 5))
	ConfirmDelete(VList(0, 1, 2, 3, 4, 5), 4, VList(0, 1, 2, 3, 5))
	ConfirmDelete(VList(0, 1, 2, 3, 4, 5), 5, VList(0, 1, 2, 3, 4))
	ConfirmDelete(VList(0, 1, 2, 3, 4, 5), 6, VList(0, 1, 2, 3, 4, 5))
}

func TestVSliceDeleteIf(t *testing.T) {
	ConfirmDeleteIf := func(s VSlice, f interface{}, r VSlice) {
		if s.DeleteIf(f); !r.Equal(s) {
			t.Fatalf("DeleteIf(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmDeleteIf(VList(0, 1, 0, 3, 0, 5), 0, VList(1, 3, 5))
	ConfirmDeleteIf(VList(0, 1, 0, 3, 0, 5), 1, VList(0, 0, 3, 0, 5))
	ConfirmDeleteIf(VList(0, 1, 0, 3, 0, 5), 6, VList(0, 1, 0, 3, 0, 5))

	ConfirmDeleteIf(VList(0, 1, 0, 3, 0, 5), reflect.ValueOf(0), VList(1, 3, 5))
	ConfirmDeleteIf(VList(0, 1, 0, 3, 0, 5), reflect.ValueOf(1), VList(0, 0, 3, 0, 5))
	ConfirmDeleteIf(VList(0, 1, 0, 3, 0, 5), reflect.ValueOf(6), VList(0, 1, 0, 3, 0, 5))

	ConfirmDeleteIf(VList(0, 1, 0, 3, 0, 5), func(x interface{}) bool { return x == 0 }, VList(1, 3, 5))
	ConfirmDeleteIf(VList(0, 1, 0, 3, 0, 5), func(x interface{}) bool { return x == 1 }, VList(0, 0, 3, 0, 5))
	ConfirmDeleteIf(VList(0, 1, 0, 3, 0, 5), func(x interface{}) bool { return x == 6 }, VList(0, 1, 0, 3, 0, 5))

	ConfirmDeleteIf(VList(0, 1, 0, 3, 0, 5), func(x reflect.Value) bool { return x.Interface() == 0 }, VList(1, 3, 5))
	ConfirmDeleteIf(VList(0, 1, 0, 3, 0, 5), func(x reflect.Value) bool { return x.Interface() == 1 }, VList(0, 0, 3, 0, 5))
	ConfirmDeleteIf(VList(0, 1, 0, 3, 0, 5), func(x reflect.Value) bool { return x.Interface() == 6 }, VList(0, 1, 0, 3, 0, 5))
}

func TestVSliceEach(t *testing.T) {
	count := 0
	VList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9).Each(func(i interface{}) {
		if i != count {
			t.Fatalf("element %v erroneously reported as %v", count, i)
		}
		count++
	})

	VList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9).Each(func(index int, i interface{}) {
		if i != index {
			t.Fatalf("element %v erroneously reported as %v", index, i)
		}
	})

	VList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9).Each(func(key, i interface{}) {
		if i != key {
			t.Fatalf("element %v erroneously reported as %v", key, i)
		}
	})

	count = 0
	VList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9).Each(func(i reflect.Value) {
		if i.Interface() != count {
			t.Fatalf("element %v erroneously reported as %v", count, i)
		}
		count++
	})

	VList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9).Each(func(index int, i reflect.Value) {
		if i.Interface() != index {
			t.Fatalf("element %v erroneously reported as %v", index, i)
		}
	})

	VList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9).Each(func(key interface{}, i reflect.Value) {
		if i.Interface() != key {
			t.Fatalf("element %v erroneously reported as %v", key, i)
		}
	})
}

func TestVSliceWhile(t *testing.T) {
	ConfirmLimit := func(s VSlice, l int, f interface{}) {
		if count := s.While(f); count != l {
			t.Fatalf("%v.While() should have iterated %v times not %v times", s, l, count)
		}
	}

	s := VList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9)
	count := 0
	limit := 5
	ConfirmLimit(s, limit, func(i interface{}) bool {
		if count == limit {
			return false
		}
		count++
		return true
	})

	ConfirmLimit(s, limit, func(index int, i interface{}) bool {
		return index != limit
	})

	ConfirmLimit(s, limit, func(key, i interface{}) bool {
		return key.(int) != limit
	})

	count = 0
	ConfirmLimit(s, limit, func(i reflect.Value) bool {
		if count == limit {
			return false
		}
		count++
		return true
	})

	ConfirmLimit(s, limit, func(index int, i reflect.Value) bool {
		return index != limit
	})

	ConfirmLimit(s, limit, func(key interface{}, i reflect.Value) bool {
		return key.(int) != limit
	})
}

func TestVSliceUntil(t *testing.T) {
	ConfirmLimit := func(s VSlice, l int, f interface{}) {
		if count := s.Until(f); count != l {
			t.Fatalf("%v.Until() should have iterated %v times not %v times", s, l, count)
		}
	}

	s := VList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9)
	count := 0
	limit := 5
	ConfirmLimit(s, limit, func(i interface{}) bool {
		if count == limit {
			return true
		}
		count++
		return false
	})

	ConfirmLimit(s, limit, func(index int, i interface{}) bool {
		return index == limit
	})

	ConfirmLimit(s, limit, func(key, i interface{}) bool {
		return key.(int) == limit
	})

	count = 0
	ConfirmLimit(s, limit, func(i reflect.Value) bool {
		if count == limit {
			return true
		}
		count++
		return false
	})

	ConfirmLimit(s, limit, func(index int, i reflect.Value) bool {
		return index == limit
	})

	ConfirmLimit(s, limit, func(key interface{}, i reflect.Value) bool {
		return key.(int) == limit
	})
}

func TestVSliceBlockCopy(t *testing.T) {
	ConfirmBlockCopy := func(s VSlice, destination, source, count int, r VSlice) {
		s.BlockCopy(destination, source, count)
		if !r.Equal(s) {
			t.Fatalf("BlockCopy(%v, %v, %v) should be %v but is %v", destination, source, count, r, s)
		}
	}

	ConfirmBlockCopy(VList(), 0, 0, 1, VList())
	ConfirmBlockCopy(VList(), 1, 0, 1, VList())
	ConfirmBlockCopy(VList(), 0, 1, 1, VList())

	ConfirmBlockCopy(VList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9), 0, 0, 4, VList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9))
	ConfirmBlockCopy(VList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9), 9, 9, 4, VList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9))
	ConfirmBlockCopy(VList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9), 9, 0, 4, VList(0, 1, 2, 3, 4, 5, 6, 7, 8, 0))
	ConfirmBlockCopy(VList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9), 10, 0, 4, VList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9))
	ConfirmBlockCopy(VList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9), 10, 10, 4, VList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9))
	ConfirmBlockCopy(VList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9), 5, 2, 4, VList(0, 1, 2, 3, 4, 2, 3, 4, 5, 9))
	ConfirmBlockCopy(VList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9), 2, 5, 4, VList(0, 1, 5, 6, 7, 8, 6, 7, 8, 9))
}

func TestVSliceBlockClear(t *testing.T) {
	ConfirmBlockClear := func(s VSlice, start, count int, r VSlice) {
		s.BlockClear(start, count)
		if !r.Equal(s) {
			t.Fatalf("BlockClear(%v, %v) should be %v but is %v", start, count, r, s)
		}
	}

	ConfirmBlockClear(VList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9), 0, 4, VList(nil, nil, nil, nil, 4, 5, 6, 7, 8, 9))
	ConfirmBlockClear(VList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9), 10, 4, VList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9))
	ConfirmBlockClear(VList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9), 5, 4, VList(0, 1, 2, 3, 4, nil, nil, nil, nil, 9))
}

func TestVSliceOverwrite(t *testing.T) {
	g := VList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9)
	c := make(VSlice, g.Len(), g.Cap())
	c.Overwrite(0, g)
	for i := 0; i < g.Len(); i++ {
		if c.At(i) != g.At(i) {
			t.Fatalf("Slice elements g[%v] and c[%v] should match but are %v and %v", i, i, g.At(0), c.At(0))
		}
	}
}

func TestVSliceReallocate(t *testing.T) {
	ConfirmReallocate := func(s VSlice, l, c int, r VSlice) {
		o := s.String()
		el := l
		if el > c {
			el = c
		}
		switch s.Reallocate(l, c); {
		case s == nil:				t.Fatalf("%v.Reallocate(%v, %v) created a nil value for Slice", o, l, c)
		case s.Cap() != c:			t.Fatalf("%v.Reallocate(%v, %v) capacity should be %v but is %v", o, l, c, c, s.Cap())
		case s.Len() != el:			t.Fatalf("%v.Reallocate(%v, %v) length should be %v but is %v", o, l, c, el, s.Len())
		case !r.Equal(s):			t.Fatalf("%v.Reallocate(%v, %v) should be %v but is %v", o, l, c, r, s)
		}
	}

	ConfirmReallocate(VList(), 0, 10, make(VSlice, 0, 10))
	ConfirmReallocate(VList(0, 1, 2, 3, 4), 3, 10, VList(0, 1, 2))
	ConfirmReallocate(VList(0, 1, 2, 3, 4), 5, 10, VList(0, 1, 2, 3, 4))
	ConfirmReallocate(VList(0, 1, 2, 3, 4), 10, 10, VList(0, 1, 2, 3, 4, nil, nil, nil, nil, nil))
	ConfirmReallocate(VList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9), 1, 5, VList(0))
	ConfirmReallocate(VList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9), 5, 5, VList(0, 1, 2, 3, 4))
	ConfirmReallocate(VList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9), 10, 5, VList(0, 1, 2, 3, 4))
}

func TestVSliceExtend(t *testing.T) {
	ConfirmExtend := func(s VSlice, n int, r VSlice) {
		c := s.Cap()
		s.Extend(n)
		switch {
		case s.Len() != r.Len():	t.Fatalf("Extend(%v) len should be %v but is %v", n, r.Len(), s.Len())
		case s.Cap() != c + n:		t.Fatalf("Extend(%v) cap should be %v but is %v", n, c + n, s.Cap())
		case !r.Equal(s):			t.Fatalf("Extend(%v) should be %v but is %v", n, r, s)
		}
	}

	ConfirmExtend(VList(), 1, VList(nil))
	ConfirmExtend(VList(), 2, VList(nil, nil))
}

func TestVSliceExpand(t *testing.T) {
	ConfirmExpand := func(s VSlice, i, n int, r VSlice) {
		c := s.Cap()
		s.Expand(i, n)
		switch {
		case s.Len() != r.Len():	t.Fatalf("Expand(%v, %v) len should be %v but is %v", i, n, r.Len(), s.Len())
		case s.Cap() != c + n:		t.Fatalf("Expand(%v, %v) cap should be %v but is %v", i, n, c + n, s.Cap())
		case !r.Equal(s):			t.Fatalf("Expand(%v, %v) should be %v but is %v", i, n, r, s)
		}
	}

	ConfirmExpand(VList(), -1, 1, VList(nil))
	ConfirmExpand(VList(), 0, 1, VList(nil))
	ConfirmExpand(VList(), 1, 1, VList(nil))
	ConfirmExpand(VList(), 0, 2, VList(nil, nil))

	ConfirmExpand(VList(0, 1, 2), -1, 2, VList(nil, nil, 0, 1, 2))
	ConfirmExpand(VList(0, 1, 2), 0, 2, VList(nil, nil, 0, 1, 2))
	ConfirmExpand(VList(0, 1, 2), 1, 2, VList(0, nil, nil, 1, 2))
	ConfirmExpand(VList(0, 1, 2), 2, 2, VList(0, 1, nil, nil, 2))
	ConfirmExpand(VList(0, 1, 2), 3, 2, VList(0, 1, 2, nil, nil))
	ConfirmExpand(VList(0, 1, 2), 4, 2, VList(0, 1, 2, nil, nil))
}

func TestVSliceDepth(t *testing.T) {
	ConfirmDepth := func(s VSlice, i int) {
		if x := s.Depth(); x != i {
			t.Fatalf("%v.Depth() should be %v but is %v", s, i, x)
		}
	}
	ConfirmDepth(VList(0, 1), 0)
	ConfirmDepth(VList(0, 1), 0)
	ConfirmDepth(VList(VList(0, 1), 2), 1)
	ConfirmDepth(VList(0, VList(1, 2)), 1)
	ConfirmDepth(VList(0, 1, VList(2, VList(3, 4, 5))), 2)

	sxp := VList(0, 1,
				VList(2, VList(3, 4, 5)),
				VList(6, VList(7, VList(8, VList(9, 0)))),
				VList(2, VList(3, 4, 5)))
	ConfirmDepth(sxp, 4)

	rxp := VList(0, sxp, sxp)
	ConfirmDepth(rxp, 5)
	ConfirmDepth(VList(rxp, sxp), 6)

	ConfirmDepth(VList(0, 1), 0)
	ConfirmDepth(VList(Slice{0, 1}, 2), 1)
	ConfirmDepth(VList(0, Slice{1, 2}), 1)
	ConfirmDepth(VList(0, 1, Slice{2, Slice{3, 4, 5}}), 2)

	sxp = VList(0, 1,
				Slice{2, Slice{3, 4, 5}},
				Slice{6, Slice{7, Slice{8, Slice{9, 0}}}},
				Slice{2, Slice{3, 4, 5}})
	ConfirmDepth(sxp, 4)

	rxp = VList(0, sxp, sxp)
	ConfirmDepth(rxp, 5)
	ConfirmDepth(VList(rxp, sxp), 6)
}

func TestVSliceReverse(t *testing.T) {
	ConfirmReverse := func(s, r VSlice) {
		if s.Reverse(); !Equal(s, r) {
			t.Fatalf("Reverse() should be %v but is %v", r, s)
		}
	}
	ConfirmReverse(VList(), VList())
	ConfirmReverse(VList(1), VList(1))
	ConfirmReverse(VList(1, 2), VList(2, 1))
	ConfirmReverse(VList(1, 2, 3), VList(3, 2, 1))
	ConfirmReverse(VList(1, 2, 3, 4), VList(4, 3, 2, 1))
}

func TestVSliceAppend(t *testing.T) {
	ConfirmAppend := func(s VSlice, v interface{}, r VSlice) {
		if s.Append(v); !r.Equal(s) {
			t.Fatalf("Append(%v) should be %v but is %v", v, r, s)
		}
	}

	ConfirmAppend(VList(0, 1, 2), 3, VList(0, 1, 2, 3))
	ConfirmAppend(VList(0, 1, 2), VList(3, 4, 5), VList(0, 1, 2, 3, 4, 5))
}

func TestVSlicePrepend(t *testing.T) {
	ConfirmPrepend := func(s VSlice, v interface{}, r VSlice) {
		if s.Prepend(v); !r.Equal(s) {
			t.Fatalf("Prepend(%v) should be %v but is %v", v, r, s)
		}
	}

	ConfirmPrepend(VList(0, 1, 2), 3, VList(3, 0, 1, 2))
	ConfirmPrepend(VList(0, 1, 2), VList(3, 4, 5), VList(3, 4, 5, 0, 1, 2))
}

func TestVSliceAppendSlice(t *testing.T) {
	ConfirmAppendSlice := func(s VSlice, v interface{}, r VSlice) {
		if s.AppendSlice(v); !r.Equal(s) {
			t.Fatalf("AppendSlice(%v) should be %v but is %v", v, r, s)
		}
	}

	ConfirmAppendSlice(VList(), VList(0, 1), VList(VList(0, 1)))
	ConfirmAppendSlice(VList(0, 1, 2), VList(3, 4), VList(0, 1, 2, VList(3, 4)))
}

func TestVSlicePrependSlice(t *testing.T) {
	ConfirmPrependSlice := func(s VSlice, v interface{}, r VSlice) {
		if s.PrependSlice(v); !r.Equal(s) {
			t.Fatalf("PrependSlice(%v) should be %v but is %v", v, r, s)
		}
	}

	ConfirmPrependSlice(VList(), VList(0, 1), VList(VList(0, 1)))
	ConfirmPrependSlice(VList(0, 1, 2), VList(3, 4), VList(VList(3, 4), 0, 1, 2))
}

func TestVSliceRepeat(t *testing.T) {
	ConfirmRepeat := func(s VSlice, count int, r VSlice) {
		if x := s.Repeat(count); !x.Equal(r) {
			t.Fatalf("%v.Repeat(%v) should be %v but is %v", s, count, r, x)
		}
	}

	ConfirmRepeat(VList(), 5, VList())
	ConfirmRepeat(VList(0), 1,VList(0))
	ConfirmRepeat(VList(0), 2, VList(0, 0))
	ConfirmRepeat(VList(0), 3, VList(0, 0, 0))
	ConfirmRepeat(VList(0), 4, VList(0, 0, 0, 0))
	ConfirmRepeat(VList(0), 5, VList(0, 0, 0, 0, 0))
}

func TestVSliceFlatten(t *testing.T) {
	ConfirmFlatten := func(s, r VSlice) {
		o := s.String()
		if s.Flatten(); !r.Equal(s) {
			t.Fatalf("Flatten(%v) should be %v but is %v", o, r, s)
		}
	}
	ConfirmFlatten(VList(), VList())
	ConfirmFlatten(VList(1), VList(1))
	ConfirmFlatten(VList(1, VList(2)), VList(1, 2))
	ConfirmFlatten(VList(1, VList(2, VList(3))), VList(1, 2, 3))
	ConfirmFlatten(VList(1, 2, VList(3, VList(4, 5), VList(6, VList(7, 8, 9), VList(10, 11)))), VList(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11))

	ConfirmFlatten(VList(0, lists.List(1, 2, VList(3, 4))), VList(0, lists.List(1, 2, VList(3, 4))))
	ConfirmFlatten(VList(0, lists.List(1, 2, lists.List(3, 4))), VList(0, lists.List(1, 2, 3, 4)))

	ConfirmFlatten(VList(0, lists.Loop(1, 2)), VList(0, lists.Loop(1, 2)))
	ConfirmFlatten(VList(0, lists.List(1, lists.Loop(2, 3))), VList(0, lists.List(1, 2, 3)))

	ConfirmFlatten(VList(0, lists.List(1, 2, lists.Loop(3, 4))), VList(0, lists.List(1, 2, 3, 4)))
	ConfirmFlatten(VList(3, 4, VList(5, 6, 7)), VList(3, 4, 5, 6, 7))
	ConfirmFlatten(VList(0, lists.Loop(1, 2, VList(3, 4, VList(5, 6, 7)))), VList(0, lists.Loop(1, 2, VList(3, 4, 5, 6, 7))))

	sxp := VList(1, 2, VList(3, VList(4, 5), VList(6, VList(7, 8, 9), VList(10, 11))))
	rxp := VList(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11)
	ConfirmFlatten(sxp, rxp)

	rxp = VList(1, 2, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 3, 4, 5, 6, 7, 8, 9, 10, 11, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11)
	sxp = VList(1, 2, sxp, VList(3, VList(4, 5), VList(6, VList(7, 8, 9), VList(10, 11), sxp)))
	ConfirmFlatten(sxp, rxp)
}

func TestVSliceEqual(t *testing.T) {
	ConfirmEqual := func(s VSlice, o interface{}) {
		if !s.Equal(o) {
			t.Fatalf("%v.Equal(%v) should be equal", s, o)
		}
	}
	RefuteEqual := func(s VSlice, o interface{}) {
		if s.Equal(o) {
			t.Fatalf("%v.Equal(%v) should not be equal", s, o)
		}
	}

	ConfirmEqual(VList(0), []reflect.Value{ reflect.ValueOf(0) })
	RefuteEqual(VList(0), VList(uint(0)))
	RefuteEqual(VList(0), []reflect.Value{ reflect.ValueOf(uint(0)) })
	RefuteEqual(VList(0), VList(1))
}


func TestVSliceCar(t *testing.T) {
	ConfirmCar := func(s VSlice, r interface{}) {
		var ok bool
		n := s.Car()
		switch n := n.(type) {
		case Equatable:		ok = n.Equal(r)
		default:			ok = n == r
		}
		if !ok {
			t.Fatalf("%s.Car() should be %v but is %v", s, r, n)
		}
	}
	ConfirmCar(VList(1, 2, 3), 1)
	ConfirmCar(VList(VList(10, 20), 2, 3), VList(10, 20))
}

func TestVSliceCdr(t *testing.T) {
	ConfirmCdr := func(s, r VSlice) {
		if n := s.Cdr(); !r.Equal(n) {
			t.Fatalf("%v.Cdr() should be %v but is %v", s, r, n)
		}
	}
//	ConfirmCdr(VList(), VList())
	ConfirmCdr(VList(1), VList())
	ConfirmCdr(VList(1, 2, 3), VList(2, 3))
}

func TestVSliceRplaca(t *testing.T) {
	ConfirmRplaca := func(s VSlice, v interface{}, r VSlice) {
		if s.Rplaca(v); !s.Equal(r) {
			t.Fatalf("Rplaca() should be %v but is %v", r, s)
		}
	}
	ConfirmRplaca(VList(1, 2, 3, 4, 5), 0, VList(0, 2, 3, 4, 5))
	ConfirmRplaca(VList(1, 2, 3, 4, 5), VList(1, 2, 3), VList(VList(1, 2, 3), 2, 3, 4, 5))
}

func TestVSliceRplacd(t *testing.T) {
	ConfirmRplacd := func(s VSlice, v interface{}, r VSlice) {
		if s.Rplacd(v); !s.Equal(r) {
			t.Fatalf("Rplacd() should be %v but is %v", r, s)
		}
	}
	ConfirmRplacd(VList(1, 2, 3, 4, 5), nil, VList(1))
	ConfirmRplacd(VList(1, 2, 3, 4, 5), 10, VList(1, 10))
	ConfirmRplacd(VList(1, 2, 3, 4, 5), VList(5, 4, 3, 2), VList(1, 5, 4, 3, 2))
	ConfirmRplacd(VList(1, 2, 3, 4, 5, 6), VList(2, 4, 8, 16), VList(1, 2, 4, 8, 16))
}

func TestVSliceFind(t *testing.T) {
	ConfirmFind := func(s VSlice, v interface{}, i int) {
		if x, ok := s.Find(v); !ok || x != i {
			t.Fatalf("%v.Find(%v) should be %v but is %v", s, v, i, x)
		}
	}

	ConfirmFind(VList(0, 1, 2, 3, 4), 0, 0)
	ConfirmFind(VList(0, 1, 2, 3, 4), 1, 1)
	ConfirmFind(VList(0, 1, 2, 4, 3), 2, 2)
	ConfirmFind(VList(0, 1, 2, 4, 3), 3, 4)
	ConfirmFind(VList(0, 1, 2, 4, 3), 4, 3)
}

func TestVSliceFindN(t *testing.T) {
	ConfirmFindN := func(s VSlice, v interface{}, n int, i ISlice) {
		if x := s.FindN(v, n); !x.Equal(i) {
			t.Fatalf("%v.Find(%v, %v) should be %v but is %v", s, v, n, i, x)
		}
	}

	ConfirmFindN(VList(1, 0, 1, 0, 1), 2, 3, ISlice{})
	ConfirmFindN(VList(1, 0, 1, 0, 1), 1, 0, ISlice{0, 2, 4})
	ConfirmFindN(VList(1, 0, 1, 0, 1), 1, 1, ISlice{0})
	ConfirmFindN(VList(1, 0, 1, 0, 1), 1, 2, ISlice{0, 2})
	ConfirmFindN(VList(1, 0, 1, 0, 1), 1, 3, ISlice{0, 2, 4})
	ConfirmFindN(VList(1, 0, 1, 0, 1), 1, 4, ISlice{0, 2, 4})
}

func TestVSliceKeepIf(t *testing.T) {
	ConfirmKeepIf := func(s VSlice, f interface{}, r VSlice) {
		if s.KeepIf(f); !r.Equal(s) {
			t.Fatalf("KeepIf(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmKeepIf(VList(0, 1, 0, 3, 0, 5), 0, VList(0, 0, 0))
	ConfirmKeepIf(VList(0, 1, 0, 3, 0, 5), 1, VList(1))
	ConfirmKeepIf(VList(0, 1, 0, 3, 0, 5), 6, VList())

	ConfirmKeepIf(VList(0, 1, 0, 3, 0, 5), func(x interface{}) bool { return x == 0 }, VList(0, 0, 0))
	ConfirmKeepIf(VList(0, 1, 0, 3, 0, 5), func(x interface{}) bool { return x == 1 }, VList(1))
	ConfirmKeepIf(VList(0, 1, 0, 3, 0, 5), func(x interface{}) bool { return x == 6 }, VList())
}

func TestVSliceReverseEach(t *testing.T) {
	var count	int
	count = 9
	VList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9).ReverseEach(func(i interface{}) {
		if i != count {
			t.Fatalf("0: element %v erroneously reported as %v", count, i)
		}
		count--
	})

	VList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9).ReverseEach(func(index int, i interface{}) {
		if index != i.(int) {
			t.Fatalf("1: element %v erroneously reported as %v", index, i)
		}
	})

	VList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9).ReverseEach(func(key, i interface{}) {
		if key.(int) != i.(int) {
			t.Fatalf("2: element %v erroneously reported as %v", key, i)
		}
	})
}

func TestVSliceReplaceIf(t *testing.T) {
	ConfirmReplaceIf := func(s VSlice, f, v interface{}, r VSlice) {
		if s.ReplaceIf(f, v); !r.Equal(s) {
			t.Fatalf("ReplaceIf(%v, %v) should be %v but is %v", f, v, r, s)
		}
	}

	ConfirmReplaceIf(VList(0, 1, 0, 3, 0, 5), 0, 1, VList(1, 1, 1, 3, 1, 5))
	ConfirmReplaceIf(VList(0, 1, 0, 3, 0, 5), 1, 0, VList(0, 0, 0, 3, 0, 5))
	ConfirmReplaceIf(VList(0, 1, 0, 3, 0, 5), 6, 0, VList(0, 1, 0, 3, 0, 5))

	ConfirmReplaceIf(VList(0, 1, 0, 3, 0, 5), func(x interface{}) bool { return x == 0 }, 1, VList(1, 1, 1, 3, 1, 5))
	ConfirmReplaceIf(VList(0, 1, 0, 3, 0, 5), func(x interface{}) bool { return x == 1 }, 0, VList(0, 0, 0, 3, 0, 5))
	ConfirmReplaceIf(VList(0, 1, 0, 3, 0, 5), func(x interface{}) bool { return x == 6 }, 0, VList(0, 1, 0, 3, 0, 5))
}

func TestVSliceReplace(t *testing.T) {
	ConfirmReplace := func(s VSlice, v interface{}, r VSlice) {
		if s.Replace(v); !s.Equal(r) {
			t.Fatalf("Replace() should be %v but is %v", r, v)
		}
	}

	ConfirmReplace(VList(0, 1, 2, 3, 4, 5), 9, VList(9))
	ConfirmReplace(VList(0, 1, 2, 3, 4, 5), reflect.ValueOf(9), VList(9))
	ConfirmReplace(VList(0, 1, 2, 3, 4, 5), VList(9, 8, 7, 6, 5), VList(9, 8, 7, 6, 5))
	ConfirmReplace(VList(0, 1, 2, 3, 4, 5), []int{ 9, 8, 7, 6, 5 }, VList(9, 8, 7, 6, 5))
	ConfirmReplace(VList(0, 1, 2, 3, 4, 5), []float64{ 9, 8, 7, 6, 5 }, VList(9.0, 8.0, 7.0, 6.0, 5.0))
}

func TestVSliceSelect(t *testing.T) {
	ConfirmSelect := func(s VSlice, f interface{}, r VSlice) {
		if x := s.Select(f); !r.Equal(x) {
			t.Fatalf("Select(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmSelect(VList(0, 1, 0, 3, 0, 5), 0, VList(0, 0, 0))
	ConfirmSelect(VList(0, 1, 0, 3, 0, 5), 1, VList(1))
	ConfirmSelect(VList(0, 1, 0, 3, 0, 5), 6, VList())

	ConfirmSelect(VList(0, 1, 0, 3, 0, 5), func(x interface{}) bool { return x == 0 }, VList(0, 0, 0))
	ConfirmSelect(VList(0, 1, 0, 3, 0, 5), func(x interface{}) bool { return x == 1 }, VList(1))
	ConfirmSelect(VList(0, 1, 0, 3, 0, 5), func(x interface{}) bool { return x == 6 }, VList())
}

func TestVSliceUniq(t *testing.T) {
	ConfirmUniq := func(s, r VSlice) {
		if s.Uniq(); !r.Equal(s) {
			t.Fatalf("Uniq() should be %v but is %v", r, s)
		}
	}

	ConfirmUniq(VList(0, 0, 0, 0, 0, 0), VList(0))
	ConfirmUniq(VList(0, 1, 0, 3, 0, 5), VList(0, 1, 3, 5))
}

func TestVSlicePick(t *testing.T) {
	ConfirmPick := func(s VSlice, i []int, r VSlice) {
		if x := s.Pick(i...); !r.Equal(x) {
			t.Fatalf("%v.Pick(%v) should be %v but is %v", s, i, r, x)
		}
	}

	ConfirmPick(VList(0, 1, 2, 3, 4, 5), []int{}, VList())
	ConfirmPick(VList(0, 1, 2, 3, 4, 5), []int{ 0, 1 }, VList(0, 1))
	ConfirmPick(VList(0, 1, 2, 3, 4, 5), []int{ 0, 3 }, VList(0, 3))
	ConfirmPick(VList(0, 1, 2, 3, 4, 5), []int{ 0, 3, 4, 3 }, VList(0, 3, 4, 3))
}

func TestVSliceInsert(t *testing.T) {
	ConfirmInsert := func(s VSlice, n int, v interface{}, r VSlice) {
		if s.Insert(n, v); !r.Equal(s) {
			t.Fatalf("Insert(%v, %v) should be %v but is %v", n, v, r, s)
		}
	}

	ConfirmInsert(VList(), 0, 0, VList(0))
	ConfirmInsert(VList(), 0, VList(0), VList(0))
	ConfirmInsert(VList(), 0, VList(0, 1), VList(0, 1))

	ConfirmInsert(VList(0), 0, 1, VList(1, 0))
	ConfirmInsert(VList(0), 0, VList(1), VList(1, 0))
	ConfirmInsert(VList(0), 1, 1, VList(0, 1))
	ConfirmInsert(VList(0), 1, VList(1), VList(0, 1))

	ConfirmInsert(VList(0, 1, 2), 0, 3, VList(3, 0, 1, 2))
	ConfirmInsert(VList(0, 1, 2), 1, 3, VList(0, 3, 1, 2))
	ConfirmInsert(VList(0, 1, 2), 2, 3, VList(0, 1, 3, 2))
	ConfirmInsert(VList(0, 1, 2), 3, 3, VList(0, 1, 2, 3))

	ConfirmInsert(VList(0, 1, 2), 0, VList(3, 4), VList(3, 4, 0, 1, 2))
	ConfirmInsert(VList(0, 1, 2), 1, VList(3, 4), VList(0, 3, 4, 1, 2))
	ConfirmInsert(VList(0, 1, 2), 2, VList(3, 4), VList(0, 1, 3, 4, 2))
	ConfirmInsert(VList(0, 1, 2), 3, VList(3, 4), VList(0, 1, 2, 3, 4))
}