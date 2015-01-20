package slices

import "testing"

func TestU16SliceString(t *testing.T) {
	ConfirmString := func(s U16Slice, r string) {
		if x := s.String(); x != r {
			t.Fatalf("%v erroneously serialised as '%v'", r, x)
		}
	}

	ConfirmString(U16Slice{}, "()")
	ConfirmString(U16Slice{0}, "(0)")
	ConfirmString(U16Slice{0, 1}, "(0 1)")
}

func TestU16SliceLen(t *testing.T) {
	ConfirmLength := func(s U16Slice, i int) {
		if x := s.Len(); x != i {
			t.Fatalf("%v.Len() should be %v but is %v", s, i, x)
		}
	}
	
	ConfirmLength(U16Slice{0}, 1)
	ConfirmLength(U16Slice{0, 1}, 2)
}

func TestU16SliceSwap(t *testing.T) {
	ConfirmSwap := func(s U16Slice, i, j int, r U16Slice) {
		if s.Swap(i, j); !r.Equal(s) {
			t.Fatalf("Swap(%v, %v) should be %v but is %v", i, j, r, s)
		}
	}
	ConfirmSwap(U16Slice{0, 1, 2}, 0, 1, U16Slice{1, 0, 2})
	ConfirmSwap(U16Slice{0, 1, 2}, 0, 2, U16Slice{2, 1, 0})
}

func TestU16SliceCompare(t *testing.T) {
	ConfirmCompare := func(s U16Slice, i, j, r int) {
		if x := s.Compare(i, j); x != r {
			t.Fatalf("Compare(%v, %v) should be %v but is %v", i, j, r, x)
		}
	}

	ConfirmCompare(U16Slice{0, 1}, 0, 0, IS_SAME_AS)
	ConfirmCompare(U16Slice{0, 1}, 0, 1, IS_LESS_THAN)
	ConfirmCompare(U16Slice{0, 1}, 1, 0, IS_GREATER_THAN)
}

func TestU16SliceZeroCompare(t *testing.T) {
	ConfirmCompare := func(s U16Slice, i, r int) {
		if x := s.ZeroCompare(i); x != r {
			t.Fatalf("ZeroCompare(%v) should be %v but is %v", i, r, x)
		}
	}

	ConfirmCompare(U16Slice{0, 1, 2}, 0, IS_SAME_AS)
	ConfirmCompare(U16Slice{0, 1, 2}, 1, IS_LESS_THAN)
	ConfirmCompare(U16Slice{0, 1, 2}, 2, IS_LESS_THAN)
}

func TestU16SliceCut(t *testing.T) {
	ConfirmCut := func(s U16Slice, start, end int, r U16Slice) {
		if s.Cut(start, end); !r.Equal(s) {
			t.Fatalf("Cut(%v, %v) should be %v but is %v", start, end, r, s)
		}
	}

	ConfirmCut(U16Slice{0, 1, 2, 3, 4, 5}, 0, 1, U16Slice{1, 2, 3, 4, 5})
	ConfirmCut(U16Slice{0, 1, 2, 3, 4, 5}, 1, 2, U16Slice{0, 2, 3, 4, 5})
	ConfirmCut(U16Slice{0, 1, 2, 3, 4, 5}, 2, 3, U16Slice{0, 1, 3, 4, 5})
	ConfirmCut(U16Slice{0, 1, 2, 3, 4, 5}, 3, 4, U16Slice{0, 1, 2, 4, 5})
	ConfirmCut(U16Slice{0, 1, 2, 3, 4, 5}, 4, 5, U16Slice{0, 1, 2, 3, 5})
	ConfirmCut(U16Slice{0, 1, 2, 3, 4, 5}, 5, 6, U16Slice{0, 1, 2, 3, 4})

	ConfirmCut(U16Slice{0, 1, 2, 3, 4, 5}, -1, 1, U16Slice{1, 2, 3, 4, 5})
	ConfirmCut(U16Slice{0, 1, 2, 3, 4, 5}, 0, 2, U16Slice{2, 3, 4, 5})
	ConfirmCut(U16Slice{0, 1, 2, 3, 4, 5}, 1, 3, U16Slice{0, 3, 4, 5})
	ConfirmCut(U16Slice{0, 1, 2, 3, 4, 5}, 2, 4, U16Slice{0, 1, 4, 5})
	ConfirmCut(U16Slice{0, 1, 2, 3, 4, 5}, 3, 5, U16Slice{0, 1, 2, 5})
	ConfirmCut(U16Slice{0, 1, 2, 3, 4, 5}, 4, 6, U16Slice{0, 1, 2, 3})
	ConfirmCut(U16Slice{0, 1, 2, 3, 4, 5}, 5, 7, U16Slice{0, 1, 2, 3, 4})
}

func TestU16SliceTrim(t *testing.T) {
	ConfirmTrim := func(s U16Slice, start, end int, r U16Slice) {
		if s.Trim(start, end); !r.Equal(s) {
			t.Fatalf("Trim(%v, %v) should be %v but is %v", start, end, r, s)
		}
	}

	ConfirmTrim(U16Slice{0, 1, 2, 3, 4, 5}, 0, 1, U16Slice{0})
	ConfirmTrim(U16Slice{0, 1, 2, 3, 4, 5}, 1, 2, U16Slice{1})
	ConfirmTrim(U16Slice{0, 1, 2, 3, 4, 5}, 2, 3, U16Slice{2})
	ConfirmTrim(U16Slice{0, 1, 2, 3, 4, 5}, 3, 4, U16Slice{3})
	ConfirmTrim(U16Slice{0, 1, 2, 3, 4, 5}, 4, 5, U16Slice{4})
	ConfirmTrim(U16Slice{0, 1, 2, 3, 4, 5}, 5, 6, U16Slice{5})

	ConfirmTrim(U16Slice{0, 1, 2, 3, 4, 5}, -1, 1, U16Slice{0})
	ConfirmTrim(U16Slice{0, 1, 2, 3, 4, 5}, 0, 2, U16Slice{0, 1})
	ConfirmTrim(U16Slice{0, 1, 2, 3, 4, 5}, 1, 3, U16Slice{1, 2})
	ConfirmTrim(U16Slice{0, 1, 2, 3, 4, 5}, 2, 4, U16Slice{2, 3})
	ConfirmTrim(U16Slice{0, 1, 2, 3, 4, 5}, 3, 5, U16Slice{3, 4})
	ConfirmTrim(U16Slice{0, 1, 2, 3, 4, 5}, 4, 6, U16Slice{4, 5})
	ConfirmTrim(U16Slice{0, 1, 2, 3, 4, 5}, 5, 7, U16Slice{5})
}

func TestU16SliceDelete(t *testing.T) {
	ConfirmDelete := func(s U16Slice, index int, r U16Slice) {
		if s.Delete(index); !r.Equal(s) {
			t.Fatalf("Delete(%v) should be %v but is %v", index, r, s)
		}
	}

	ConfirmDelete(U16Slice{0, 1, 2, 3, 4, 5}, -1, U16Slice{0, 1, 2, 3, 4, 5})
	ConfirmDelete(U16Slice{0, 1, 2, 3, 4, 5}, 0, U16Slice{1, 2, 3, 4, 5})
	ConfirmDelete(U16Slice{0, 1, 2, 3, 4, 5}, 1, U16Slice{0, 2, 3, 4, 5})
	ConfirmDelete(U16Slice{0, 1, 2, 3, 4, 5}, 2, U16Slice{0, 1, 3, 4, 5})
	ConfirmDelete(U16Slice{0, 1, 2, 3, 4, 5}, 3, U16Slice{0, 1, 2, 4, 5})
	ConfirmDelete(U16Slice{0, 1, 2, 3, 4, 5}, 4, U16Slice{0, 1, 2, 3, 5})
	ConfirmDelete(U16Slice{0, 1, 2, 3, 4, 5}, 5, U16Slice{0, 1, 2, 3, 4})
	ConfirmDelete(U16Slice{0, 1, 2, 3, 4, 5}, 6, U16Slice{0, 1, 2, 3, 4, 5})
}

func TestU16SliceDeleteIf(t *testing.T) {
	ConfirmDeleteIf := func(s U16Slice, f interface{}, r U16Slice) {
		if s.DeleteIf(f); !r.Equal(s) {
			t.Fatalf("DeleteIf(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmDeleteIf(U16Slice{0, 1, 0, 3, 0, 5}, uint16(0), U16Slice{1, 3, 5})
	ConfirmDeleteIf(U16Slice{0, 1, 0, 3, 0, 5}, uint16(1), U16Slice{0, 0, 3, 0, 5})
	ConfirmDeleteIf(U16Slice{0, 1, 0, 3, 0, 5}, uint16(6), U16Slice{0, 1, 0, 3, 0, 5})

	ConfirmDeleteIf(U16Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uint16(0) }, U16Slice{1, 3, 5})
	ConfirmDeleteIf(U16Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uint16(1) }, U16Slice{0, 0, 3, 0, 5})
	ConfirmDeleteIf(U16Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uint16(6) }, U16Slice{0, 1, 0, 3, 0, 5})

	ConfirmDeleteIf(U16Slice{0, 1, 0, 3, 0, 5}, func(x uint16) bool { return x == uint16(0) }, U16Slice{1, 3, 5})
	ConfirmDeleteIf(U16Slice{0, 1, 0, 3, 0, 5}, func(x uint16) bool { return x == uint16(1) }, U16Slice{0, 0, 3, 0, 5})
	ConfirmDeleteIf(U16Slice{0, 1, 0, 3, 0, 5}, func(x uint16) bool { return x == uint16(6) }, U16Slice{0, 1, 0, 3, 0, 5})
}

func TestU16SliceEach(t *testing.T) {
	var count	uint16
	U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(i interface{}) {
		if i != count {
			t.Fatalf("element %v erroneously reported as %v", count, i)
		}
		count++
	})

	U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(index int, i interface{}) {
		if i != uint16(index) {
			t.Fatalf("element %v erroneously reported as %v", index, i)
		}
	})

	U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(key, i interface{}) {
		if i != uint16(key.(int)) {
			t.Fatalf("element %v erroneously reported as %v", key, i)
		}
	})

	count = 0
	U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(i uint16) {
		if i != count {
			t.Fatalf("element %v erroneously reported as %v", count, i)
		}
		count++
	})

	U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(index int, i uint16) {
		if i != uint16(index) {
			t.Fatalf("element %v erroneously reported as %v", index, i)
		}
	})

	U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(key interface{}, i uint16) {
		if i != uint16(key.(int)) {
			t.Fatalf("element %v erroneously reported as %v", key, i)
		}
	})
}

func TestU16SliceWhile(t *testing.T) {
	ConfirmLimit := func(s U16Slice, l int, f interface{}) {
		if count := s.While(f); count != l {
			t.Fatalf("%v.While() should have iterated %v times not %v times", s, l, count)
		}
	}

	s := U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}
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
	ConfirmLimit(s, limit, func(i uint16) bool {
		if count == limit {
			return false
		}
		count++
		return true
	})

	ConfirmLimit(s, limit, func(index int, i uint16) bool {
		return index != limit
	})

	ConfirmLimit(s, limit, func(key interface{}, i uint16) bool {
		return key.(int) != limit
	})
}

func TestU16SliceUntil(t *testing.T) {
	ConfirmLimit := func(s U16Slice, l int, f interface{}) {
		if count := s.Until(f); count != l {
			t.Fatalf("%v.Until() should have iterated %v times not %v times", s, l, count)
		}
	}

	s := U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}
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
	ConfirmLimit(s, limit, func(i uint16) bool {
		if count == limit {
			return true
		}
		count++
		return false
	})

	ConfirmLimit(s, limit, func(index int, i uint16) bool {
		return index == limit
	})

	ConfirmLimit(s, limit, func(key interface{}, i uint16) bool {
		return key.(int) == limit
	})
}

func TestU16SliceBlockCopy(t *testing.T) {
	ConfirmBlockCopy := func(s U16Slice, destination, source, count int, r U16Slice) {
		s.BlockCopy(destination, source, count)
		if !r.Equal(s) {
			t.Fatalf("BlockCopy(%v, %v, %v) should be %v but is %v", destination, source, count, r, s)
		}
	}

	ConfirmBlockCopy(U16Slice{}, 0, 0, 1, U16Slice{})
	ConfirmBlockCopy(U16Slice{}, 1, 0, 1, U16Slice{})
	ConfirmBlockCopy(U16Slice{}, 0, 1, 1, U16Slice{})

	ConfirmBlockCopy(U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 0, 0, 4, U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 9, 9, 4, U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 9, 0, 4, U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 0})
	ConfirmBlockCopy(U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 0, 4, U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 10, 4, U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, 2, 4, U16Slice{0, 1, 2, 3, 4, 2, 3, 4, 5, 9})
	ConfirmBlockCopy(U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 2, 5, 4, U16Slice{0, 1, 5, 6, 7, 8, 6, 7, 8, 9})
}

func TestU16SliceBlockClear(t *testing.T) {
	ConfirmBlockClear := func(s U16Slice, start, count int, r U16Slice) {
		s.BlockClear(start, count)
		if !r.Equal(s) {
			t.Fatalf("BlockClear(%v, %v) should be %v but is %v", start, count, r, s)
		}
	}

	ConfirmBlockClear(U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 0, 4, U16Slice{0, 0, 0, 0, 4, 5, 6, 7, 8, 9})
	ConfirmBlockClear(U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 4, U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockClear(U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, 4, U16Slice{0, 1, 2, 3, 4, 0, 0, 0, 0, 9})
}

func TestU16SliceOverwrite(t *testing.T) {
	ConfirmOverwrite := func(s U16Slice, offset int, v, r U16Slice) {
		s.Overwrite(offset, v)
		if !r.Equal(s) {
			t.Fatalf("Overwrite(%v, %v) should be %v but is %v", offset, v, r, s)
		}
	}

	ConfirmOverwrite(U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 0, U16Slice{10, 9, 8, 7}, U16Slice{10, 9, 8, 7, 4, 5, 6, 7, 8, 9})
	ConfirmOverwrite(U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, U16Slice{10, 9, 8, 7}, U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmOverwrite(U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, U16Slice{11, 12, 13, 14}, U16Slice{0, 1, 2, 3, 4, 11, 12, 13, 14, 9})
}

func TestU16SliceReallocate(t *testing.T) {
	ConfirmReallocate := func(s U16Slice, l, c int, r U16Slice) {
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

	ConfirmReallocate(U16Slice{}, 0, 10, make(U16Slice, 0, 10))
	ConfirmReallocate(U16Slice{0, 1, 2, 3, 4}, 3, 10, U16Slice{0, 1, 2})
	ConfirmReallocate(U16Slice{0, 1, 2, 3, 4}, 5, 10, U16Slice{0, 1, 2, 3, 4})
	ConfirmReallocate(U16Slice{0, 1, 2, 3, 4}, 10, 10, U16Slice{0, 1, 2, 3, 4, 0, 0, 0, 0, 0})
	ConfirmReallocate(U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 1, 5, U16Slice{0})
	ConfirmReallocate(U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, 5, U16Slice{0, 1, 2, 3, 4})
	ConfirmReallocate(U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 5, U16Slice{0, 1, 2, 3, 4})
}

func TestU16SliceExtend(t *testing.T) {
	ConfirmExtend := func(s U16Slice, n int, r U16Slice) {
		c := s.Cap()
		s.Extend(n)
		switch {
		case s.Len() != r.Len():	t.Fatalf("Extend(%v) len should be %v but is %v", n, r.Len(), s.Len())
		case s.Cap() != c + n:		t.Fatalf("Extend(%v) cap should be %v but is %v", n, c + n, s.Cap())
		case !r.Equal(s):			t.Fatalf("Extend(%v) should be %v but is %v", n, r, s)
		}
	}

	ConfirmExtend(U16Slice{}, 1, U16Slice{0})
	ConfirmExtend(U16Slice{}, 2, U16Slice{0, 0})
}

func TestU16SliceExpand(t *testing.T) {
	ConfirmExpand := func(s U16Slice, i, n int, r U16Slice) {
		c := s.Cap()
		s.Expand(i, n)
		switch {
		case s.Len() != r.Len():	t.Fatalf("Expand(%v, %v) len should be %v but is %v", i, n, r.Len(), s.Len())
		case s.Cap() != c + n:		t.Fatalf("Expand(%v, %v) cap should be %v but is %v", i, n, c + n, s.Cap())
		case !r.Equal(s):			t.Fatalf("Expand(%v, %v) should be %v but is %v", i, n, r, s)
		}
	}

	ConfirmExpand(U16Slice{}, -1, 1, U16Slice{0})
	ConfirmExpand(U16Slice{}, 0, 1, U16Slice{0})
	ConfirmExpand(U16Slice{}, 1, 1, U16Slice{0})
	ConfirmExpand(U16Slice{}, 0, 2, U16Slice{0, 0})

	ConfirmExpand(U16Slice{0, 1, 2}, -1, 2, U16Slice{0, 0, 0, 1, 2})
	ConfirmExpand(U16Slice{0, 1, 2}, 0, 2, U16Slice{0, 0, 0, 1, 2})
	ConfirmExpand(U16Slice{0, 1, 2}, 1, 2, U16Slice{0, 0, 0, 1, 2})
	ConfirmExpand(U16Slice{0, 1, 2}, 2, 2, U16Slice{0, 1, 0, 0, 2})
	ConfirmExpand(U16Slice{0, 1, 2}, 3, 2, U16Slice{0, 1, 2, 0, 0})
	ConfirmExpand(U16Slice{0, 1, 2}, 4, 2, U16Slice{0, 1, 2, 0, 0})
}

func TestU16SliceDepth(t *testing.T) {
	ConfirmDepth := func(s U16Slice, i int) {
		if x := s.Depth(); x != i {
			t.Fatalf("%v.Depth() should be %v but is %v", s, i, x)
		}
	}
	ConfirmDepth(U16Slice{0, 1}, 0)
}

func TestU16SliceReverse(t *testing.T) {
	ConfirmReverse := func(s, r U16Slice) {
		if s.Reverse(); !Equal(s, r) {
			t.Fatalf("Reverse() should be %v but is %v", r, s)
		}
	}
	ConfirmReverse(U16Slice{}, U16Slice{})
	ConfirmReverse(U16Slice{1}, U16Slice{1})
	ConfirmReverse(U16Slice{1, 2}, U16Slice{2, 1})
	ConfirmReverse(U16Slice{1, 2, 3}, U16Slice{3, 2, 1})
	ConfirmReverse(U16Slice{1, 2, 3, 4}, U16Slice{4, 3, 2, 1})
}

func TestU16SliceAppend(t *testing.T) {
	ConfirmAppend := func(s U16Slice, v interface{}, r U16Slice) {
		s.Append(v)
		if !r.Equal(s) {
			t.Fatalf("Append(%v) should be %v but is %v", v, r, s)
		}
	}

	ConfirmAppend(U16Slice{}, uint16(0), U16Slice{0})

	ConfirmAppend(U16Slice{}, U16Slice{0}, U16Slice{0})
	ConfirmAppend(U16Slice{}, U16Slice{0, 1}, U16Slice{0, 1})
	ConfirmAppend(U16Slice{0, 1, 2}, U16Slice{3, 4}, U16Slice{0, 1, 2, 3, 4})
}

func TestU16SlicePrepend(t *testing.T) {
	ConfirmPrepend := func(s U16Slice, v interface{}, r U16Slice) {
		if s.Prepend(v); !r.Equal(s) {
			t.Fatalf("Prepend(%v) should be %v but is %v", v, r, s)
		}
	}

	ConfirmPrepend(U16Slice{}, uint16(0), U16Slice{0})
	ConfirmPrepend(U16Slice{0}, uint16(1), U16Slice{1, 0})

	ConfirmPrepend(U16Slice{}, U16Slice{0}, U16Slice{0})
	ConfirmPrepend(U16Slice{}, U16Slice{0, 1}, U16Slice{0, 1})
	ConfirmPrepend(U16Slice{0, 1, 2}, U16Slice{3, 4}, U16Slice{3, 4, 0, 1, 2})
}

func TestU16SliceRepeat(t *testing.T) {
	ConfirmRepeat := func(s U16Slice, count int, r U16Slice) {
		if x := s.Repeat(count); !x.Equal(r) {
			t.Fatalf("%v.Repeat(%v) should be %v but is %v", s, count, r, x)
		}
	}

	ConfirmRepeat(U16Slice{}, 5, U16Slice{})
	ConfirmRepeat(U16Slice{0}, 1, U16Slice{0})
	ConfirmRepeat(U16Slice{0}, 2, U16Slice{0, 0})
	ConfirmRepeat(U16Slice{0}, 3, U16Slice{0, 0, 0})
	ConfirmRepeat(U16Slice{0}, 4, U16Slice{0, 0, 0, 0})
	ConfirmRepeat(U16Slice{0}, 5, U16Slice{0, 0, 0, 0, 0})
}

func TestU16SliceCar(t *testing.T) {
	ConfirmCar := func(s U16Slice, r uint16) {
		n := s.Car().(uint16)
		if ok := n == r; !ok {
			t.Fatalf("head should be '%v' but is '%v'", r, n)
		}
	}
	ConfirmCar(U16Slice{1, 2, 3}, 1)
}

func TestU16SliceCdr(t *testing.T) {
	ConfirmCdr := func(s, r U16Slice) {
		if n := s.Cdr(); !n.Equal(r) {
			t.Fatalf("tail should be '%v' but is '%v'", r, n)
		}
	}
	ConfirmCdr(U16Slice{1, 2, 3}, U16Slice{2, 3})
}

func TestU16SliceRplaca(t *testing.T) {
	ConfirmRplaca := func(s U16Slice, v interface{}, r U16Slice) {
		if s.Rplaca(v); !s.Equal(r) {
			t.Fatalf("slice should be '%v' but is '%v'", r, s)
		}
	}
	ConfirmRplaca(U16Slice{1, 2, 3, 4, 5}, uint16(0), U16Slice{0, 2, 3, 4, 5})
}

func TestU16SliceRplacd(t *testing.T) {
	ConfirmRplacd := func(s U16Slice, v interface{}, r U16Slice) {
		if s.Rplacd(v); !s.Equal(r) {
			t.Fatalf("slice should be '%v' but is '%v'", r, s)
		}
	}
	ConfirmRplacd(U16Slice{1, 2, 3, 4, 5}, nil, U16Slice{1})
	ConfirmRplacd(U16Slice{1, 2, 3, 4, 5}, uint16(10), U16Slice{1, 10})
	ConfirmRplacd(U16Slice{1, 2, 3, 4, 5}, U16Slice{5, 4, 3, 2}, U16Slice{1, 5, 4, 3, 2})
	ConfirmRplacd(U16Slice{1, 2, 3, 4, 5, 6}, U16Slice{2, 4, 8, 16}, U16Slice{1, 2, 4, 8, 16})
}

func TestU16SliceFind(t *testing.T) {
	ConfirmFind := func(s U16Slice, v uint16, i int) {
		if x, ok := s.Find(v); !ok || x != i {
			t.Fatalf("%v.Find(%v) should be %v but is %v", s, v, i, x)
		}
	}

	ConfirmFind(U16Slice{0, 1, 2, 3, 4}, 0, 0)
	ConfirmFind(U16Slice{0, 1, 2, 3, 4}, 1, 1)
	ConfirmFind(U16Slice{0, 1, 2, 4, 3}, 2, 2)
	ConfirmFind(U16Slice{0, 1, 2, 4, 3}, 3, 4)
	ConfirmFind(U16Slice{0, 1, 2, 4, 3}, 4, 3)
}

func TestU16SliceFindN(t *testing.T) {
	ConfirmFindN := func(s U16Slice, v uint16, n int, i ISlice) {
		if x := s.FindN(v, n); !x.Equal(i) {
			t.Fatalf("%v.Find(%v, %v) should be %v but is %v", s, v, n, i, x)
		}
	}

	ConfirmFindN(U16Slice{1, 0, 1, 0, 1}, 2, 3, ISlice{})
	ConfirmFindN(U16Slice{1, 0, 1, 0, 1}, 1, 0, ISlice{0, 2, 4})
	ConfirmFindN(U16Slice{1, 0, 1, 0, 1}, 1, 1, ISlice{0})
	ConfirmFindN(U16Slice{1, 0, 1, 0, 1}, 1, 2, ISlice{0, 2})
	ConfirmFindN(U16Slice{1, 0, 1, 0, 1}, 1, 3, ISlice{0, 2, 4})
	ConfirmFindN(U16Slice{1, 0, 1, 0, 1}, 1, 4, ISlice{0, 2, 4})
}

func TestU16SliceKeepIf(t *testing.T) {
	ConfirmKeepIf := func(s U16Slice, f interface{}, r U16Slice) {
		if s.KeepIf(f); !r.Equal(s) {
			t.Fatalf("KeepIf(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmKeepIf(U16Slice{0, 1, 0, 3, 0, 5}, uint16(0), U16Slice{0, 0, 0})
	ConfirmKeepIf(U16Slice{0, 1, 0, 3, 0, 5}, uint16(1), U16Slice{1})
	ConfirmKeepIf(U16Slice{0, 1, 0, 3, 0, 5}, uint16(6), U16Slice{})

	ConfirmKeepIf(U16Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uint16(0) }, U16Slice{0, 0, 0})
	ConfirmKeepIf(U16Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uint16(1) }, U16Slice{1})
	ConfirmKeepIf(U16Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uint16(6) }, U16Slice{})

	ConfirmKeepIf(U16Slice{0, 1, 0, 3, 0, 5}, func(x uint16) bool { return x == uint16(0) }, U16Slice{0, 0, 0})
	ConfirmKeepIf(U16Slice{0, 1, 0, 3, 0, 5}, func(x uint16) bool { return x == uint16(1) }, U16Slice{1})
	ConfirmKeepIf(U16Slice{0, 1, 0, 3, 0, 5}, func(x uint16) bool { return x == uint16(6) }, U16Slice{})
}

func TestU16SliceReverseEach(t *testing.T) {
	var count	uint16
	count = 9
	U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(i interface{}) {
		if i != count {
			t.Fatalf("0: element %v erroneously reported as %v", count, i)
		}
		count--
	})

	U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(index int, i interface{}) {
		if index != int(i.(uint16)) {
			t.Fatalf("1: element %v erroneously reported as %v", index, i)
		}
	})

	U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(key, i interface{}) {
		if uint16(key.(int)) != i {
			t.Fatalf("2: element %v erroneously reported as %v", key, i)
		}
	})

	count = 9
	U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(i uint16) {
		if i != count {
			t.Fatalf("3: element %v erroneously reported as %v", count, i)
		}
		count--
	})

	U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(index int, i uint16) {
		if int(i) != index {
			t.Fatalf("4: element %v erroneously reported as %v", index, i)
		}
	})

	U16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(key interface{}, i uint16) {
		if key.(int) != int(i) {
			t.Fatalf("5: element %v erroneously reported as %v", key, i)
		}
	})
}

func TestU16SliceReplaceIf(t *testing.T) {
	ConfirmReplaceIf := func(s U16Slice, f, v interface{}, r U16Slice) {
		if s.ReplaceIf(f, v); !r.Equal(s) {
			t.Fatalf("ReplaceIf(%v, %v) should be %v but is %v", f, v, r, s)
		}
	}

	ConfirmReplaceIf(U16Slice{0, 1, 0, 3, 0, 5}, uint16(0), uint16(1), U16Slice{1, 1, 1, 3, 1, 5})
	ConfirmReplaceIf(U16Slice{0, 1, 0, 3, 0, 5}, uint16(1), uint16(0), U16Slice{0, 0, 0, 3, 0, 5})
	ConfirmReplaceIf(U16Slice{0, 1, 0, 3, 0, 5}, uint16(6), uint16(0), U16Slice{0, 1, 0, 3, 0, 5})

	ConfirmReplaceIf(U16Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uint16(0) }, uint16(1), U16Slice{1, 1, 1, 3, 1, 5})
	ConfirmReplaceIf(U16Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uint16(1) }, uint16(0), U16Slice{0, 0, 0, 3, 0, 5})
	ConfirmReplaceIf(U16Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uint16(6) }, uint16(0), U16Slice{0, 1, 0, 3, 0, 5})

	ConfirmReplaceIf(U16Slice{0, 1, 0, 3, 0, 5}, func(x uint16) bool { return x == uint16(0) }, uint16(1), U16Slice{1, 1, 1, 3, 1, 5})
	ConfirmReplaceIf(U16Slice{0, 1, 0, 3, 0, 5}, func(x uint16) bool { return x == uint16(1) }, uint16(0), U16Slice{0, 0, 0, 3, 0, 5})
	ConfirmReplaceIf(U16Slice{0, 1, 0, 3, 0, 5}, func(x uint16) bool { return x == uint16(6) }, uint16(0), U16Slice{0, 1, 0, 3, 0, 5})
}

func TestU16SliceReplace(t *testing.T) {
	ConfirmReplace := func(s U16Slice, v interface{}) {
		if s.Replace(v); !s.Equal(v) {
			t.Fatalf("Replace() should be %v but is %v", s, v)
		}
	}

	ConfirmReplace(U16Slice{0, 1, 2, 3, 4, 5}, U16Slice{9, 8, 7, 6, 5})
	ConfirmReplace(U16Slice{0, 1, 2, 3, 4, 5}, U16Slice{ 9, 8, 7, 6, 5 })
	ConfirmReplace(U16Slice{0, 1, 2, 3, 4, 5}, []uint16{ 9, 8, 7, 6, 5 })
}

func TestU16SliceSelect(t *testing.T) {
	ConfirmSelect := func(s U16Slice, f interface{}, r U16Slice) {
		if x := s.Select(f); !r.Equal(x) {
			t.Fatalf("Select(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmSelect(U16Slice{0, 1, 0, 3, 0, 5}, uint16(0), U16Slice{0, 0, 0})
	ConfirmSelect(U16Slice{0, 1, 0, 3, 0, 5}, uint16(1), U16Slice{1})
	ConfirmSelect(U16Slice{0, 1, 0, 3, 0, 5}, uint16(6), U16Slice{})

	ConfirmSelect(U16Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uint16(0) }, U16Slice{0, 0, 0})
	ConfirmSelect(U16Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uint16(1) }, U16Slice{1})
	ConfirmSelect(U16Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uint16(6) }, U16Slice{})

	ConfirmSelect(U16Slice{0, 1, 0, 3, 0, 5}, func(x uint16) bool { return x == uint16(0) }, U16Slice{0, 0, 0})
	ConfirmSelect(U16Slice{0, 1, 0, 3, 0, 5}, func(x uint16) bool { return x == uint16(1) }, U16Slice{1})
	ConfirmSelect(U16Slice{0, 1, 0, 3, 0, 5}, func(x uint16) bool { return x == uint16(6) }, U16Slice{})
}

func TestU16SliceUniq(t *testing.T) {
	ConfirmUniq := func(s, r U16Slice) {
		if s.Uniq(); !r.Equal(s) {
			t.Fatalf("Uniq() should be %v but is %v", r, s)
		}
	}

	ConfirmUniq(U16Slice{0, 0, 0, 0, 0, 0}, U16Slice{0})
	ConfirmUniq(U16Slice{0, 1, 0, 3, 0, 5}, U16Slice{0, 1, 3, 5})
}

func TestU16SlicePick(t *testing.T) {
	ConfirmPick := func(s U16Slice, i []int, r U16Slice) {
		if x := s.Pick(i...); !r.Equal(x) {
			t.Fatalf("%v.Pick(%v) should be %v but is %v", s, i, r, x)
		}
	}

	ConfirmPick(U16Slice{0, 1, 2, 3, 4, 5}, []int{}, U16Slice{})
	ConfirmPick(U16Slice{0, 1, 2, 3, 4, 5}, []int{ 0, 1 }, U16Slice{0, 1})
	ConfirmPick(U16Slice{0, 1, 2, 3, 4, 5}, []int{ 0, 3 }, U16Slice{0, 3})
	ConfirmPick(U16Slice{0, 1, 2, 3, 4, 5}, []int{ 0, 3, 4, 3 }, U16Slice{0, 3, 4, 3})
}

func TestU16SliceInsert(t *testing.T) {
	ConfirmInsert := func(s U16Slice, n int, v interface{}, r U16Slice) {
		if s.Insert(n, v); !r.Equal(s) {
			t.Fatalf("Insert(%v, %v) should be %v but is %v", n, v, r, s)
		}
	}

	ConfirmInsert(U16Slice{}, 0, uint16(0), U16Slice{0})
	ConfirmInsert(U16Slice{}, 0, U16Slice{0}, U16Slice{0})
	ConfirmInsert(U16Slice{}, 0, U16Slice{0, 1}, U16Slice{0, 1})

	ConfirmInsert(U16Slice{0}, 0, uint16(1), U16Slice{1, 0})
	ConfirmInsert(U16Slice{0}, 0, U16Slice{1}, U16Slice{1, 0})
	ConfirmInsert(U16Slice{0}, 1, uint16(1), U16Slice{0, 1})
	ConfirmInsert(U16Slice{0}, 1, U16Slice{1}, U16Slice{0, 1})

	ConfirmInsert(U16Slice{0, 1, 2}, 0, uint16(3), U16Slice{3, 0, 1, 2})
	ConfirmInsert(U16Slice{0, 1, 2}, 1, uint16(3), U16Slice{0, 3, 1, 2})
	ConfirmInsert(U16Slice{0, 1, 2}, 2, uint16(3), U16Slice{0, 1, 3, 2})
	ConfirmInsert(U16Slice{0, 1, 2}, 3, uint16(3), U16Slice{0, 1, 2, 3})

	ConfirmInsert(U16Slice{0, 1, 2}, 0, U16Slice{3, 4}, U16Slice{3, 4, 0, 1, 2})
	ConfirmInsert(U16Slice{0, 1, 2}, 1, U16Slice{3, 4}, U16Slice{0, 3, 4, 1, 2})
	ConfirmInsert(U16Slice{0, 1, 2}, 2, U16Slice{3, 4}, U16Slice{0, 1, 3, 4, 2})
	ConfirmInsert(U16Slice{0, 1, 2}, 3, U16Slice{3, 4}, U16Slice{0, 1, 2, 3, 4})
}