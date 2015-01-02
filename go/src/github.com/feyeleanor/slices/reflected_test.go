package slices

import "github.com/feyeleanor/lists"
import "reflect"
import "testing"

func TestRSliceMakeSlice(t *testing.T) {}

func TestRSliceRSlice(t *testing.T) {
	g := RWrap([]int{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 })
	if g.Len() != 10 {
		t.Fatalf("Slice length should be %v not %v", 10, g.Len())
	}
	for i := 0; i < g.Len(); i++ {
		if g.At(i) != i {
			t.Fatalf("g[%v] should contain %v but contains %v", 0, g.At(0))
		}
	}
}

func TestRSliceString(t *testing.T) {
	ConfirmString := func(s RSlice, r string) {
		if x := s.String(); x != r {
			t.Fatalf("%v erroneously serialised as '%v'", r, x)
		}
	}

	ConfirmString(RList(), "()")
	ConfirmString(RList(0), "(0)")
	ConfirmString(RList(0, 1), "(0 1)")
}

func TestRSliceLen(t *testing.T) {
	ConfirmLength := func(s RSlice, i int) {
		if x := s.Len(); x != i {
			t.Fatalf("%v.Len() should be %v but is %v", s, i, x)
		}
	}
	
	ConfirmLength(RList(0), 1)
	ConfirmLength(RList(0, 1), 2)
}

func TestRSliceClear(t *testing.T) {
	ConfirmClear := func(s RSlice, i int, r RSlice) {
		if s.Clear(i); !r.Equal(s) {
			t.Fatalf("Clear(%v) should be %v but is %v", i, r, s)
		}
	}

	ConfirmClear(RList(0, 1, 2, 3, 4), 0, RList(nil, 1, 2, 3, 4))
	ConfirmClear(RList(0, 1, 2, 3, 4), 1, RList(0, nil, 2, 3, 4))
	ConfirmClear(RList(0, 1, 2, 3, 4), 2, RList(0, 1, nil, 3, 4))
	ConfirmClear(RList(0, 1, 2, 3, 4), 3, RList(0, 1, 2, nil, 4))
	ConfirmClear(RList(0, 1, 2, 3, 4), 4, RList(0, 1, 2, 3, nil))

	ConfirmClear(RWrap([]int{0, 1, 2, 3, 4}), 0, RList(0, 1, 2, 3, 4))
	ConfirmClear(RWrap([]int{0, 1, 2, 3, 4}), 1, RList(0, 0, 2, 3, 4))
	ConfirmClear(RWrap([]int{0, 1, 2, 3, 4}), 2, RList(0, 1, 0, 3, 4))
	ConfirmClear(RWrap([]int{0, 1, 2, 3, 4}), 3, RList(0, 1, 2, 0, 4))
	ConfirmClear(RWrap([]int{0, 1, 2, 3, 4}), 4, RList(0, 1, 2, 3, 0))
}

func TestRSliceSwap(t *testing.T) {
	ConfirmSwap := func(s RSlice, i, j int, r RSlice) {
		if s.Swap(i, j); !r.Equal(s) {
			t.Fatalf("Swap(%v, %v) should be %v but is %v", i, j, r, s)
		}
	}
	ConfirmSwap(RList(0, 1, 2), 0, 1, RList(1, 0, 2))
	ConfirmSwap(RList(0, 1, 2), 0, 2, RList(2, 1, 0))
}

func TestRSliceCut(t *testing.T) {
	ConfirmCut := func(s RSlice, start, end int, r RSlice) {
		if s.Cut(start, end); !r.Equal(s) {
			t.Fatalf("Cut(%v, %v) should be %v but is %v", start, end, r, s)
		}
	}

	ConfirmCut(RList(0, 1, 2, 3, 4, 5), 0, 1, RList(1, 2, 3, 4, 5))
	ConfirmCut(RList(0, 1, 2, 3, 4, 5), 1, 2, RList(0, 2, 3, 4, 5))
	ConfirmCut(RList(0, 1, 2, 3, 4, 5), 2, 3, RList(0, 1, 3, 4, 5))
	ConfirmCut(RList(0, 1, 2, 3, 4, 5), 3, 4, RList(0, 1, 2, 4, 5))
	ConfirmCut(RList(0, 1, 2, 3, 4, 5), 4, 5, RList(0, 1, 2, 3, 5))
	ConfirmCut(RList(0, 1, 2, 3, 4, 5), 5, 6, RList(0, 1, 2, 3, 4))

	ConfirmCut(RList(0, 1, 2, 3, 4, 5), -1, 1, RList(1, 2, 3, 4, 5))
	ConfirmCut(RList(0, 1, 2, 3, 4, 5), 0, 2, RList(2, 3, 4, 5))
	ConfirmCut(RList(0, 1, 2, 3, 4, 5), 1, 3, RList(0, 3, 4, 5))
	ConfirmCut(RList(0, 1, 2, 3, 4, 5), 2, 4, RList(0, 1, 4, 5))
	ConfirmCut(RList(0, 1, 2, 3, 4, 5), 3, 5, RList(0, 1, 2, 5))
	ConfirmCut(RList(0, 1, 2, 3, 4, 5), 4, 6, RList(0, 1, 2, 3))
	ConfirmCut(RList(0, 1, 2, 3, 4, 5), 5, 7, RList(0, 1, 2, 3, 4))
}

func TestRSliceTrim(t *testing.T) {
	ConfirmTrim := func(s RSlice, start, end int, r RSlice) {
		if s.Trim(start, end); !r.Equal(s) {
			t.Fatalf("Trim(%v, %v) should be %v but is %v", start, end, r, s)
		}
	}

	ConfirmTrim(RList(0, 1, 2, 3, 4, 5), 0, 1, RList(0))
	ConfirmTrim(RList(0, 1, 2, 3, 4, 5), 1, 2, RList(1))
	ConfirmTrim(RList(0, 1, 2, 3, 4, 5), 2, 3, RList(2))
	ConfirmTrim(RList(0, 1, 2, 3, 4, 5), 3, 4, RList(3))
	ConfirmTrim(RList(0, 1, 2, 3, 4, 5), 4, 5, RList(4))
	ConfirmTrim(RList(0, 1, 2, 3, 4, 5), 5, 6, RList(5))

	ConfirmTrim(RList(0, 1, 2, 3, 4, 5), -1, 1, RList(0))
	ConfirmTrim(RList(0, 1, 2, 3, 4, 5), 0, 2, RList(0, 1))
	ConfirmTrim(RList(0, 1, 2, 3, 4, 5), 1, 3, RList(1, 2))
	ConfirmTrim(RList(0, 1, 2, 3, 4, 5), 2, 4, RList(2, 3))
	ConfirmTrim(RList(0, 1, 2, 3, 4, 5), 3, 5, RList(3, 4))
	ConfirmTrim(RList(0, 1, 2, 3, 4, 5), 4, 6, RList(4, 5))
	ConfirmTrim(RList(0, 1, 2, 3, 4, 5), 5, 7, RList(5))
}

func TestRSliceDelete(t *testing.T) {
	ConfirmDelete := func(s RSlice, index int, r RSlice) {
		if s.Delete(index); !r.Equal(s) {
			t.Fatalf("Delete(%v) should be %v but is %v", index, r, s)
		}
	}

	ConfirmDelete(RList(0, 1, 2, 3, 4, 5), -1, RList(0, 1, 2, 3, 4, 5))
	ConfirmDelete(RList(0, 1, 2, 3, 4, 5), 0, RList(1, 2, 3, 4, 5))
	ConfirmDelete(RList(0, 1, 2, 3, 4, 5), 1, RList(0, 2, 3, 4, 5))
	ConfirmDelete(RList(0, 1, 2, 3, 4, 5), 2, RList(0, 1, 3, 4, 5))
	ConfirmDelete(RList(0, 1, 2, 3, 4, 5), 3, RList(0, 1, 2, 4, 5))
	ConfirmDelete(RList(0, 1, 2, 3, 4, 5), 4, RList(0, 1, 2, 3, 5))
	ConfirmDelete(RList(0, 1, 2, 3, 4, 5), 5, RList(0, 1, 2, 3, 4))
	ConfirmDelete(RList(0, 1, 2, 3, 4, 5), 6, RList(0, 1, 2, 3, 4, 5))
}

func TestRSliceDeleteIf(t *testing.T) {
	ConfirmDeleteIf := func(s RSlice, f interface{}, r RSlice) {
		if s.DeleteIf(f); !r.Equal(s) {
			t.Fatalf("DeleteIf(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmDeleteIf(RList(0, 1, 0, 3, 0, 5), 0, RList(1, 3, 5))
	ConfirmDeleteIf(RList(0, 1, 0, 3, 0, 5), 1, RList(0, 0, 3, 0, 5))
	ConfirmDeleteIf(RList(0, 1, 0, 3, 0, 5), 6, RList(0, 1, 0, 3, 0, 5))

	ConfirmDeleteIf(RList(0, 1, 0, 3, 0, 5), reflect.ValueOf(0), RList(1, 3, 5))
	ConfirmDeleteIf(RList(0, 1, 0, 3, 0, 5), reflect.ValueOf(1), RList(0, 0, 3, 0, 5))
	ConfirmDeleteIf(RList(0, 1, 0, 3, 0, 5), reflect.ValueOf(6), RList(0, 1, 0, 3, 0, 5))

	ConfirmDeleteIf(RList(0, 1, 0, 3, 0, 5), func(x interface{}) bool { return x == 0 }, RList(1, 3, 5))
	ConfirmDeleteIf(RList(0, 1, 0, 3, 0, 5), func(x interface{}) bool { return x == 1 }, RList(0, 0, 3, 0, 5))
	ConfirmDeleteIf(RList(0, 1, 0, 3, 0, 5), func(x interface{}) bool { return x == 6 }, RList(0, 1, 0, 3, 0, 5))

	ConfirmDeleteIf(RList(0, 1, 0, 3, 0, 5), func(x reflect.Value) bool { return x.Interface() == 0 }, RList(1, 3, 5))
	ConfirmDeleteIf(RList(0, 1, 0, 3, 0, 5), func(x reflect.Value) bool { return x.Interface() == 1 }, RList(0, 0, 3, 0, 5))
	ConfirmDeleteIf(RList(0, 1, 0, 3, 0, 5), func(x reflect.Value) bool { return x.Interface() == 6 }, RList(0, 1, 0, 3, 0, 5))

	ConfirmDeleteIf(RList(0, 1, 0, 3, 0, 5), func(x int) bool { return x == 0 }, RList(1, 3, 5))
	ConfirmDeleteIf(RList(0, 1, 0, 3, 0, 5), func(x int) bool { return x == 1 }, RList(0, 0, 3, 0, 5))
	ConfirmDeleteIf(RList(0, 1, 0, 3, 0, 5), func(x int) bool { return x == 6 }, RList(0, 1, 0, 3, 0, 5))
}

func TestRSliceEach(t *testing.T) {
	count := 0
	RList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9).Each(func(i interface{}) {
		if i != count {
			t.Fatalf("element %v erroneously reported as %v", count, i)
		}
		count++
	})

	RList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9).Each(func(index int, i interface{}) {
		if i != index {
			t.Fatalf("element %v erroneously reported as %v", index, i)
		}
	})

	RList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9).Each(func(key, i interface{}) {
		if i != key {
			t.Fatalf("element %v erroneously reported as %v", key, i)
		}
	})

	count = 0
	RList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9).Each(func(i reflect.Value) {
		if i.Interface() != count {
			t.Fatalf("element %v erroneously reported as %v", count, i)
		}
		count++
	})

	RList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9).Each(func(index int, i reflect.Value) {
		if i.Interface() != index {
			t.Fatalf("element %v erroneously reported as %v", index, i)
		}
	})

	RList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9).Each(func(key interface{}, i reflect.Value) {
		if i.Interface() != key {
			t.Fatalf("element %v erroneously reported as %v", key, i)
		}
	})
}

func TestRSliceWhile(t *testing.T) {
	ConfirmLimit := func(s RSlice, l int, f interface{}) {
		if count := s.While(f); count != l {
			t.Fatalf("%v.While() should have iterated %v times not %v times", s, l, count)
		}
	}

	s := RList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9)
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

func TestRSliceUntil(t *testing.T) {
	ConfirmLimit := func(s RSlice, l int, f interface{}) {
		if count := s.Until(f); count != l {
			t.Fatalf("%v.Until() should have iterated %v times not %v times", s, l, count)
		}
	}

	s := RList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9)
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

func TestRSliceBlockCopy(t *testing.T) {
	ConfirmBlockCopy := func(s RSlice, destination, source, count int, r RSlice) {
		s.BlockCopy(destination, source, count)
		if !r.Equal(s) {
			t.Fatalf("BlockCopy(%v, %v, %v) should be %v but is %v", destination, source, count, r, s)
		}
	}

	ConfirmBlockCopy(RList(), 0, 0, 1, RList())
	ConfirmBlockCopy(RList(), 1, 0, 1, RList())
	ConfirmBlockCopy(RList(), 0, 1, 1, RList())

	ConfirmBlockCopy(RList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9), 0, 0, 4, RList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9))
	ConfirmBlockCopy(RList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9), 9, 9, 4, RList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9))
	ConfirmBlockCopy(RList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9), 9, 0, 4, RList(0, 1, 2, 3, 4, 5, 6, 7, 8, 0))
	ConfirmBlockCopy(RList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9), 10, 0, 4, RList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9))
	ConfirmBlockCopy(RList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9), 10, 10, 4, RList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9))
	ConfirmBlockCopy(RList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9), 5, 2, 4, RList(0, 1, 2, 3, 4, 2, 3, 4, 5, 9))
	ConfirmBlockCopy(RList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9), 2, 5, 4, RList(0, 1, 5, 6, 7, 8, 6, 7, 8, 9))
}

func TestRSliceBlockClear(t *testing.T) {
	ConfirmBlockClear := func(s RSlice, start, count int, r RSlice) {
		s.BlockClear(start, count)
		if !r.Equal(s) {
			t.Fatalf("BlockClear(%v, %v) should be %v but is %v", start, count, r, s)
		}
	}

	ConfirmBlockClear(RList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9), 0, 4, RList(nil, nil, nil, nil, 4, 5, 6, 7, 8, 9))
	ConfirmBlockClear(RList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9), 10, 4, RList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9))
	ConfirmBlockClear(RList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9), 5, 4, RList(0, 1, 2, 3, 4, nil, nil, nil, nil, 9))

	ConfirmBlockClear(RWrap([]int{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}), 0, 4, RList(0, 0, 0, 0, 4, 5, 6, 7, 8, 9))
	ConfirmBlockClear(RWrap([]int{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}), 10, 4, RList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9))
	ConfirmBlockClear(RWrap([]int{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}), 5, 4, RList(0, 1, 2, 3, 4, 0, 0, 0, 0, 9))
}

func TestRSliceOverwrite(t *testing.T) {
	g := RWrap([]int{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 })
	c := RWrap(make([]int, g.Len(), g.Cap()))
	c.Overwrite(0, g)
	for i := 0; i < g.Len(); i++ {
		if c.At(i) != g.At(i) {
			t.Fatalf("Slice elements g[%v] and c[%v] should match but are %v and %v", i, i, g.At(0), c.At(0))
		}
	}
}

func TestRSliceReallocate(t *testing.T) {
	ConfirmReallocate := func(s RSlice, l, c int, r RSlice) {
		o := s.String()
		el := l
		if el > c {
			el = c
		}
		switch s.Reallocate(l, c); {
		case s.Cap() != c:			t.Fatalf("%v.Reallocate(%v, %v) capacity should be %v but is %v", o, l, c, c, s.Cap())
		case s.Len() != el:			t.Fatalf("%v.Reallocate(%v, %v) length should be %v but is %v", o, l, c, el, s.Len())
		case !r.Equal(s):			t.Fatalf("%v.Reallocate(%v, %v) should be %v but is %v", o, l, c, r, s)
		}
	}

	ConfirmReallocate(RList(), 0, 10, RWrap(make([]interface{}, 0, 10)))
	ConfirmReallocate(RList(0, 1, 2, 3, 4), 3, 10, RList(0, 1, 2))
	ConfirmReallocate(RList(0, 1, 2, 3, 4), 5, 10, RList(0, 1, 2, 3, 4))
	ConfirmReallocate(RList(0, 1, 2, 3, 4), 10, 10, RList(0, 1, 2, 3, 4, nil, nil, nil, nil, nil))
	ConfirmReallocate(RList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9), 1, 5, RList(0))
	ConfirmReallocate(RList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9), 5, 5, RList(0, 1, 2, 3, 4))
	ConfirmReallocate(RList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9), 10, 5, RList(0, 1, 2, 3, 4))
}

func TestRSliceExtend(t *testing.T) {
	ConfirmExtend := func(s RSlice, n int, r RSlice) {
		c := s.Cap()
		s.Extend(n)
		switch {
		case s.Len() != r.Len():	t.Fatalf("Extend(%v) len should be %v but is %v", n, r.Len(), s.Len())
		case s.Cap() != c + n:		t.Fatalf("Extend(%v) cap should be %v but is %v", n, c + n, s.Cap())
		case !r.Equal(s):			t.Fatalf("Extend(%v) should be %v but is %v", n, r, s)
		}
	}

	ConfirmExtend(RList(), 1, RList(nil))
	ConfirmExtend(RList(), 2, RList(nil, nil))
}

func TestRSliceExpand(t *testing.T) {
	ConfirmExpand := func(s RSlice, i, n int, r RSlice) {
		if s.Expand(i, n); !r.Equal(s) {
			t.Fatalf("Expand(%v, %v) should be %v but is %v", i, n, r, s)
		}
	}

	ConfirmExpand(RList(), -1, 1, RList(nil))
	ConfirmExpand(RList(), 0, 1, RList(nil))
	ConfirmExpand(RList(), 1, 1, RList(nil))
	ConfirmExpand(RList(), 0, 2, RList(nil, nil))

	ConfirmExpand(RList(0, 1, 2), -1, 2, RList(nil, nil, 0, 1, 2))
	ConfirmExpand(RList(0, 1, 2), 0, 2, RList(nil, nil, 0, 1, 2))
	ConfirmExpand(RList(0, 1, 2), 1, 2, RList(0, nil, nil, 1, 2))
	ConfirmExpand(RList(0, 1, 2), 2, 2, RList(0, 1, nil, nil, 2))
	ConfirmExpand(RList(0, 1, 2), 3, 2, RList(0, 1, 2, nil, nil))
	ConfirmExpand(RList(0, 1, 2), 4, 2, RList(0, 1, 2, nil, nil))

	ConfirmExpand(RWrap([]int{0, 1, 2}), -1, 2, RList(0, 0, 0, 1, 2))
	ConfirmExpand(RWrap([]int{0, 1, 2}), 0, 2, RList(0, 0, 0, 1, 2))
	ConfirmExpand(RWrap([]int{0, 1, 2}), 1, 2, RList(0, 0, 0, 1, 2))
	ConfirmExpand(RWrap([]int{0, 1, 2}), 2, 2, RList(0, 1, 0, 0, 2))
	ConfirmExpand(RWrap([]int{0, 1, 2}), 3, 2, RList(0, 1, 2, 0, 0))
	ConfirmExpand(RWrap([]int{0, 1, 2}), 4, 2, RList(0, 1, 2, 0, 0))
}

func TestRSliceDepth(t *testing.T) {
	ConfirmDepth := func(s RSlice, i int) {
		if x := s.Depth(); x != i {
			t.Fatalf("%v.Depth() should be %v but is %v", s, i, x)
		}
	}
	ConfirmDepth(RList(0, 1), 0)
	ConfirmDepth(RList(0, 1), 0)
	ConfirmDepth(RList(RList(0, 1), 2), 1)
	ConfirmDepth(RList(0, RList(1, 2)), 1)
	ConfirmDepth(RList(0, 1, RList(2, RList(3, 4, 5))), 2)

	sxp := RList(0, 1,
				RList(2, RList(3, 4, 5)),
				RList(6, RList(7, RList(8, RList(9, 0)))),
				RList(2, RList(3, 4, 5)))
	ConfirmDepth(sxp, 4)

	rxp := RList(0, sxp, sxp)
	ConfirmDepth(rxp, 5)
	ConfirmDepth(RList(rxp, sxp), 6)

	ConfirmDepth(RList(0, 1), 0)
	ConfirmDepth(RList(Slice{0, 1}, 2), 1)
	ConfirmDepth(RList(0, Slice{1, 2}), 1)
	ConfirmDepth(RList(0, 1, Slice{2, Slice{3, 4, 5}}), 2)

	sxp = RList(0, 1,
				Slice{2, Slice{3, 4, 5}},
				Slice{6, Slice{7, Slice{8, Slice{9, 0}}}},
				Slice{2, Slice{3, 4, 5}})
	ConfirmDepth(sxp, 4)

	rxp = RList(0, sxp, sxp)
	ConfirmDepth(rxp, 5)
	ConfirmDepth(RList(rxp, sxp), 6)
}

func TestRSliceReverse(t *testing.T) {
	ConfirmReverse := func(s, r RSlice) {
		if s.Reverse(); !Equal(s, r) {
			t.Fatalf("Reverse() should be %v but is %v", r, s)
		}
	}

	ConfirmReverse(RList(1), RList(1))
	ConfirmReverse(RList(1, 2), RList(2, 1))
	ConfirmReverse(RList(1, 2, 3), RList(3, 2, 1))
	ConfirmReverse(RList(1, 2, 3, 4), RList(4, 3, 2, 1))
}

func TestRSliceAppend(t *testing.T) {
	ConfirmAppend := func(s RSlice, v interface{}, r RSlice) {
		if s.Append(v); !r.Equal(s) {
			t.Fatalf("Append(%v) should be %v but is %v", v, r, s)
		}
	}

	ConfirmAppend(RList(0, 1, 2), 3, RList(0, 1, 2, 3))
	ConfirmAppend(RWrap([]int{0, 1, 2}), 3, RList(0, 1, 2, 3))
	ConfirmAppend(RList(0, 1, 2), 3, RWrap([]int{0, 1, 2, 3}))

	ConfirmAppend(RList(0, 1, 2), RList(3, 4, 5), RList(0, 1, 2, 3, 4, 5))
	ConfirmAppend(RWrap([]int{0, 1, 2}), []int{3, 4, 5}, RList(0, 1, 2, 3, 4, 5))
	ConfirmAppend(RWrap([]int{0, 1, 2}), RWrap([]int{3, 4, 5}), RList(0, 1, 2, 3, 4, 5))
}

func TestRSlicePrepend(t *testing.T) {
	ConfirmPrepend := func(s RSlice, v interface{}, r RSlice) {
		if s.Prepend(v); !r.Equal(s) {
			t.Fatalf("Prepend(%v) should be %v but is %v", v, r, s)
		}
	}

	ConfirmPrepend(RList(0, 1, 2), 3, RList(3, 0, 1, 2))
	ConfirmPrepend(RWrap([]int{0, 1, 2}), 3, RList(3, 0, 1, 2))
	ConfirmPrepend(RList(0, 1, 2), 3, RWrap([]int{3, 0, 1, 2}))

	ConfirmPrepend(RList(0, 1, 2), RList(3, 4, 5), RList(3, 4, 5, 0, 1, 2))
	ConfirmPrepend(RWrap([]int{0, 1, 2}), []int{3, 4, 5}, RList(3, 4, 5, 0, 1, 2))
	ConfirmPrepend(RWrap([]int{0, 1, 2}), RWrap([]int{3, 4, 5}), RList(3, 4, 5, 0, 1, 2))
}

func TestRSliceRepeat(t *testing.T) {
	ConfirmRepeat := func(s RSlice, count int, r RSlice) {
		if x := s.Repeat(count); !x.Equal(r) {
			t.Fatalf("%v.Repeat(%v) should be %v but is %v", s, count, r, x)
		}
	}

	ConfirmRepeat(RList(), 5, RList())
	ConfirmRepeat(RList(0), 1,RList(0))
	ConfirmRepeat(RList(0), 2, RList(0, 0))
	ConfirmRepeat(RList(0), 3, RList(0, 0, 0))
	ConfirmRepeat(RList(0), 4, RList(0, 0, 0, 0))
	ConfirmRepeat(RList(0), 5, RList(0, 0, 0, 0, 0))
}

func TestRSliceFlatten(t *testing.T) {
	ConfirmFlatten := func(s, r RSlice) {
		o := s.String()
		if s.Flatten(); !r.Equal(s) {
			t.Fatalf("%v.Flatten() should be %v but is %v", o, r, s)
		}
	}
	ConfirmFlatten(RList(), RList())
	ConfirmFlatten(RList(1), RList(1))
	ConfirmFlatten(RList(1, RList(2)), RList(1, 2))
	ConfirmFlatten(RList(1, RList(2, RList(3))), RList(1, 2, 3))
	ConfirmFlatten(RList(1, 2, RList(3, RList(4, 5), RList(6, RList(7, 8, 9), RList(10, 11)))), RList(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11))

	ConfirmFlatten(RList(0, lists.List(1, 2, RList(3, 4))), RList(0, lists.List(1, 2, RList(3, 4))))
	ConfirmFlatten(RList(0, lists.List(1, 2, lists.List(3, 4))), RList(0, lists.List(1, 2, 3, 4)))

	ConfirmFlatten(RList(0, lists.Loop(1, 2)), RList(0, lists.Loop(1, 2)))
	ConfirmFlatten(RList(0, lists.List(1, lists.Loop(2, 3))), RList(0, lists.List(1, 2, 3)))

	ConfirmFlatten(RList(0, lists.List(1, 2, lists.Loop(3, 4))), RList(0, lists.List(1, 2, 3, 4)))
	ConfirmFlatten(RList(3, 4, RList(5, 6, 7)), RList(3, 4, 5, 6, 7))
	ConfirmFlatten(RList(0, lists.Loop(1, 2, RList(3, 4, RList(5, 6, 7)))), RList(0, lists.Loop(1, 2, RList(3, 4, 5, 6, 7))))

	sxp := RList(1, 2, RList(3, RList(4, 5), RList(6, RList(7, 8, 9), RList(10, 11))))
	rxp := RList(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11)
	ConfirmFlatten(sxp, rxp)

	rxp = RList(1, 2, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 3, 4, 5, 6, 7, 8, 9, 10, 11, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11)
	sxp = RList(1, 2, sxp, RList(3, RList(4, 5), RList(6, RList(7, 8, 9), RList(10, 11), sxp)))
	ConfirmFlatten(sxp, rxp)
}

func TestRSliceEqual(t *testing.T) {
	ConfirmEqual := func(s RSlice, o interface{}) {
		if !s.Equal(o) {
			t.Fatalf("%v.Equal(%v) should be equal", s, o)
		}
	}
	RefuteEqual := func(s RSlice, o interface{}) {
		if s.Equal(o) {
			t.Fatalf("%v.Equal(%v) should not be equal", s, o)
		}
	}

	ConfirmEqual(RList(0), RWrap([]int{ 0 }))
	RefuteEqual(RList(0), RWrap([]uint{ 0 }))
	RefuteEqual(RList(0), RWrap([]int{ 1 }))
}


func TestRSliceCar(t *testing.T) {
	ConfirmCar := func(s RSlice, r interface{}) {
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
	ConfirmCar(RList(1, 2, 3), 1)
	ConfirmCar(RList(RList(10, 20), 2, 3), RList(10, 20))
}

func TestRSliceCdr(t *testing.T) {
	ConfirmCdr := func(s, r RSlice) {
		if n := s.Cdr(); !r.Equal(n) {
			t.Fatalf("%v.Cdr() should be %v but is %v", s, r, n)
		}
	}
//	ConfirmCdr(RList(), RList())
	ConfirmCdr(RList(1), RList())
	ConfirmCdr(RList(1, 2, 3), RList(2, 3))
}

func TestRSliceRplaca(t *testing.T) {
	ConfirmRplaca := func(s RSlice, v interface{}, r RSlice) {
		if s.Rplaca(v); !s.Equal(r) {
			t.Fatalf("Rplaca() should be %v but is %v", r, s)
		}
	}
	ConfirmRplaca(RList(1, 2, 3, 4, 5), 0, RList(0, 2, 3, 4, 5))
	ConfirmRplaca(RList(1, 2, 3, 4, 5), RList(1, 2, 3), RList(RList(1, 2, 3), 2, 3, 4, 5))
}

func TestRSliceRplacd(t *testing.T) {
	ConfirmRplacd := func(s RSlice, v interface{}, r RSlice) {
		if s.Rplacd(v); !s.Equal(r) {
			t.Fatalf("Rplacd() should be %v but is %v", r, s)
		}
	}
	ConfirmRplacd(RList(1, 2, 3, 4, 5), nil, RList(1))
	ConfirmRplacd(RList(1, 2, 3, 4, 5), 10, RList(1, 10))
	ConfirmRplacd(RList(1, 2, 3, 4, 5), RList(5, 4, 3, 2), RList(1, 5, 4, 3, 2))
	ConfirmRplacd(RList(1, 2, 3, 4, 5, 6), RList(2, 4, 8, 16), RList(1, 2, 4, 8, 16))
}

func TestRSliceFind(t *testing.T) {
	ConfirmFind := func(s RSlice, v interface{}, i int) {
		if x, ok := s.Find(v); !ok || x != i {
			t.Fatalf("%v.Find(%v) should be %v but is %v", s, v, i, x)
		}
	}

	ConfirmFind(RList(0, 1, 2, 3, 4), 0, 0)
	ConfirmFind(RList(0, 1, 2, 3, 4), 1, 1)
	ConfirmFind(RList(0, 1, 2, 4, 3), 2, 2)
	ConfirmFind(RList(0, 1, 2, 4, 3), 3, 4)
	ConfirmFind(RList(0, 1, 2, 4, 3), 4, 3)
}

func TestRSliceFindN(t *testing.T) {
	ConfirmFindN := func(s RSlice, v interface{}, n int, i ISlice) {
		if x := s.FindN(v, n); !x.Equal(i) {
			t.Fatalf("%v.Find(%v, %v) should be %v but is %v", s, n, v, i, x)
		}
	}

	ConfirmFindN(RList(1, 0, 1, 0, 1), 2, 3, ISlice{})
	ConfirmFindN(RList(1, 0, 1, 0, 1), 1, 0, ISlice{0, 2, 4})
	ConfirmFindN(RList(1, 0, 1, 0, 1), 1, 1, ISlice{0})
	ConfirmFindN(RList(1, 0, 1, 0, 1), 1, 2, ISlice{0, 2})
	ConfirmFindN(RList(1, 0, 1, 0, 1), 1, 3, ISlice{0, 2, 4})
	ConfirmFindN(RList(1, 0, 1, 0, 1), 1, 4, ISlice{0, 2, 4})
}

func TestRSliceKeepIf(t *testing.T) {
	ConfirmKeepIf := func(s RSlice, f interface{}, r RSlice) {
		if s.KeepIf(f); !r.Equal(s) {
			t.Fatalf("KeepIf(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmKeepIf(RList(0, 1, 0, 3, 0, 5), 0, RList(0, 0, 0))
	ConfirmKeepIf(RList(0, 1, 0, 3, 0, 5), 1, RList(1))
	ConfirmKeepIf(RList(0, 1, 0, 3, 0, 5), 6, RList())

	ConfirmKeepIf(RList(0, 1, 0, 3, 0, 5), func(x interface{}) bool { return x == 0 }, RList(0, 0, 0))
	ConfirmKeepIf(RList(0, 1, 0, 3, 0, 5), func(x interface{}) bool { return x == 1 }, RList(1))
	ConfirmKeepIf(RList(0, 1, 0, 3, 0, 5), func(x interface{}) bool { return x == 6 }, RList())
}

func TestRSliceReverseEach(t *testing.T) {
	var count	int
	count = 9
	RList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9).ReverseEach(func(i interface{}) {
		if i != count {
			t.Fatalf("0: element %v erroneously reported as %v", count, i)
		}
		count--
	})

	RList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9).ReverseEach(func(index int, i interface{}) {
		if index != i.(int) {
			t.Fatalf("1: element %v erroneously reported as %v", index, i)
		}
	})

	RList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9).ReverseEach(func(key, i interface{}) {
		if key.(int) != i.(int) {
			t.Fatalf("2: element %v erroneously reported as %v", key, i)
		}
	})
}

func TestRSliceReplaceIf(t *testing.T) {
	ConfirmReplaceIf := func(s RSlice, f, v interface{}, r RSlice) {
		if s.ReplaceIf(f, v); !r.Equal(s) {
			t.Fatalf("ReplaceIf(%v, %v) should be %v but is %v", f, v, r, s)
		}
	}

	ConfirmReplaceIf(RList(0, 1, 0, 3, 0, 5), 0, 1, RList(1, 1, 1, 3, 1, 5))
	ConfirmReplaceIf(RList(0, 1, 0, 3, 0, 5), 1, 0, RList(0, 0, 0, 3, 0, 5))
	ConfirmReplaceIf(RList(0, 1, 0, 3, 0, 5), 6, 0, RList(0, 1, 0, 3, 0, 5))

	ConfirmReplaceIf(RList(0, 1, 0, 3, 0, 5), func(x interface{}) bool { return x == 0 }, 1, RList(1, 1, 1, 3, 1, 5))
	ConfirmReplaceIf(RList(0, 1, 0, 3, 0, 5), func(x interface{}) bool { return x == 1 }, 0, RList(0, 0, 0, 3, 0, 5))
	ConfirmReplaceIf(RList(0, 1, 0, 3, 0, 5), func(x interface{}) bool { return x == 6 }, 0, RList(0, 1, 0, 3, 0, 5))
}

func TestRSliceReplace(t *testing.T) {
	ConfirmReplace := func(s RSlice, v interface{}) {
		if s.Replace(v); !s.Equal(v) {
			t.Fatalf("Replace() should be %v but is %v", s, v)
		}
	}

	ConfirmReplace(RList(0, 1, 2, 3, 4, 5), RList(9, 8, 7, 6, 5))
	ConfirmReplace(RList(0, 1, 2, 3, 4, 5), RWrap([]int{ 9, 8, 7, 6, 5 }))
	ConfirmReplace(RList(0, 1, 2, 3, 4, 5), []float64{ 9, 8, 7, 6, 5 })
}

func TestRSliceSelect(t *testing.T) {
	ConfirmSelect := func(s RSlice, f interface{}, r RSlice) {
		if x := s.Select(f); !r.Equal(x) {
			t.Fatalf("Select(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmSelect(RList(0, 1, 0, 3, 0, 5), 0, RList(0, 0, 0))
	ConfirmSelect(RList(0, 1, 0, 3, 0, 5), 1, RList(1))
	ConfirmSelect(RList(0, 1, 0, 3, 0, 5), 6, RList())

	ConfirmSelect(RList(0, 1, 0, 3, 0, 5), func(x interface{}) bool { return x == 0 }, RList(0, 0, 0))
	ConfirmSelect(RList(0, 1, 0, 3, 0, 5), func(x interface{}) bool { return x == 1 }, RList(1))
	ConfirmSelect(RList(0, 1, 0, 3, 0, 5), func(x interface{}) bool { return x == 6 }, RList())
}

func TestRSliceUniq(t *testing.T) {
	ConfirmUniq := func(s, r RSlice) {
		if s.Uniq(); !r.Equal(s) {
			t.Fatalf("Uniq() should be %v but is %v", r, s)
		}
	}

	ConfirmUniq(RList(0, 0, 0, 0, 0, 0), RList(0))
	ConfirmUniq(RList(0, 1, 0, 3, 0, 5), RList(0, 1, 3, 5))
}

func TestRSlicePick(t *testing.T) {
	ConfirmPick := func(s RSlice, i []int, r RSlice) {
		if x := s.Pick(i...); !r.Equal(x) {
			t.Fatalf("%v.Pick(%v) should be %v but is %v", s, i, r, x)
		}
	}

	ConfirmPick(RList(0, 1, 2, 3, 4, 5), []int{}, RList())
	ConfirmPick(RList(0, 1, 2, 3, 4, 5), []int{ 0, 1 }, RList(0, 1))
	ConfirmPick(RList(0, 1, 2, 3, 4, 5), []int{ 0, 3 }, RList(0, 3))
	ConfirmPick(RList(0, 1, 2, 3, 4, 5), []int{ 0, 3, 4, 3 }, RList(0, 3, 4, 3))
}

func TestRSliceInsert(t *testing.T) {
	ConfirmInsert := func(s RSlice, n int, v interface{}, r RSlice) {
		if s.Insert(n, v); !r.Equal(s) {
			t.Fatalf("Insert(%v, %v) should be %v but is %v", n, v, r, s)
		}
	}

	ConfirmInsert(RList(), 0, 0, RList(0))
	ConfirmInsert(RList(), 0, RList(0), RList(0))
	ConfirmInsert(RList(), 0, RList(0, 1), RList(0, 1))

	ConfirmInsert(RList(0), 0, 1, RList(1, 0))
	ConfirmInsert(RList(0), 0, RList(1), RList(1, 0))
	ConfirmInsert(RList(0), 1, 1, RList(0, 1))
	ConfirmInsert(RList(0), 1, RList(1), RList(0, 1))

	ConfirmInsert(RList(0, 1, 2), 0, 3, RList(3, 0, 1, 2))
	ConfirmInsert(RList(0, 1, 2), 1, 3, RList(0, 3, 1, 2))
	ConfirmInsert(RList(0, 1, 2), 2, 3, RList(0, 1, 3, 2))
	ConfirmInsert(RList(0, 1, 2), 3, 3, RList(0, 1, 2, 3))

	ConfirmInsert(RList(0, 1, 2), 0, RList(3, 4), RList(3, 4, 0, 1, 2))
	ConfirmInsert(RList(0, 1, 2), 1, RList(3, 4), RList(0, 3, 4, 1, 2))
	ConfirmInsert(RList(0, 1, 2), 2, RList(3, 4), RList(0, 1, 3, 4, 2))
	ConfirmInsert(RList(0, 1, 2), 3, RList(3, 4), RList(0, 1, 2, 3, 4))
}