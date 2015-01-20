package slices

import "testing"

func TestI32SliceString(t *testing.T) {
	ConfirmString := func(s I32Slice, r string) {
		if x := s.String(); x != r {
			t.Fatalf("%v erroneously serialised as '%v'", r, x)
		}
	}

	ConfirmString(I32Slice{}, "()")
	ConfirmString(I32Slice{0}, "(0)")
	ConfirmString(I32Slice{0, 1}, "(0 1)")
}

func TestI32SliceLen(t *testing.T) {
	ConfirmLength := func(s I32Slice, i int) {
		if x := s.Len(); x != i {
			t.Fatalf("%v.Len() should be %v but is %v", s, i, x)
		}
	}
	
	ConfirmLength(I32Slice{0}, 1)
	ConfirmLength(I32Slice{0, 1}, 2)
}

func TestI32SliceSwap(t *testing.T) {
	ConfirmSwap := func(s I32Slice, i, j int, r I32Slice) {
		if s.Swap(i, j); !r.Equal(s) {
			t.Fatalf("Swap(%v, %v) should be %v but is %v", i, j, r, s)
		}
	}
	ConfirmSwap(I32Slice{0, 1, 2}, 0, 1, I32Slice{1, 0, 2})
	ConfirmSwap(I32Slice{0, 1, 2}, 0, 2, I32Slice{2, 1, 0})
}

func TestI32SliceCompare(t *testing.T) {
	ConfirmCompare := func(s I32Slice, i, j, r int) {
		if x := s.Compare(i, j); x != r {
			t.Fatalf("Compare(%v, %v) should be %v but is %v", i, j, r, x)
		}
	}

	ConfirmCompare(I32Slice{0, 1}, 0, 0, IS_SAME_AS)
	ConfirmCompare(I32Slice{0, 1}, 0, 1, IS_LESS_THAN)
	ConfirmCompare(I32Slice{0, 1}, 1, 0, IS_GREATER_THAN)
}

func TestI32SliceZeroCompare(t *testing.T) {
	ConfirmCompare := func(s I32Slice, i, r int) {
		if x := s.ZeroCompare(i); x != r {
			t.Fatalf("ZeroCompare(%v) should be %v but is %v", i, r, x)
		}
	}

	ConfirmCompare(I32Slice{0, -1, 1}, 0, IS_SAME_AS)
	ConfirmCompare(I32Slice{0, -1, 1}, 1, IS_GREATER_THAN)
	ConfirmCompare(I32Slice{0, -1, 1}, 2, IS_LESS_THAN)
}

func TestI32SliceCut(t *testing.T) {
	ConfirmCut := func(s I32Slice, start, end int, r I32Slice) {
		if s.Cut(start, end); !r.Equal(s) {
			t.Fatalf("Cut(%v, %v) should be %v but is %v", start, end, r, s)
		}
	}

	ConfirmCut(I32Slice{0, 1, 2, 3, 4, 5}, 0, 1, I32Slice{1, 2, 3, 4, 5})
	ConfirmCut(I32Slice{0, 1, 2, 3, 4, 5}, 1, 2, I32Slice{0, 2, 3, 4, 5})
	ConfirmCut(I32Slice{0, 1, 2, 3, 4, 5}, 2, 3, I32Slice{0, 1, 3, 4, 5})
	ConfirmCut(I32Slice{0, 1, 2, 3, 4, 5}, 3, 4, I32Slice{0, 1, 2, 4, 5})
	ConfirmCut(I32Slice{0, 1, 2, 3, 4, 5}, 4, 5, I32Slice{0, 1, 2, 3, 5})
	ConfirmCut(I32Slice{0, 1, 2, 3, 4, 5}, 5, 6, I32Slice{0, 1, 2, 3, 4})

	ConfirmCut(I32Slice{0, 1, 2, 3, 4, 5}, -1, 1, I32Slice{1, 2, 3, 4, 5})
	ConfirmCut(I32Slice{0, 1, 2, 3, 4, 5}, 0, 2, I32Slice{2, 3, 4, 5})
	ConfirmCut(I32Slice{0, 1, 2, 3, 4, 5}, 1, 3, I32Slice{0, 3, 4, 5})
	ConfirmCut(I32Slice{0, 1, 2, 3, 4, 5}, 2, 4, I32Slice{0, 1, 4, 5})
	ConfirmCut(I32Slice{0, 1, 2, 3, 4, 5}, 3, 5, I32Slice{0, 1, 2, 5})
	ConfirmCut(I32Slice{0, 1, 2, 3, 4, 5}, 4, 6, I32Slice{0, 1, 2, 3})
	ConfirmCut(I32Slice{0, 1, 2, 3, 4, 5}, 5, 7, I32Slice{0, 1, 2, 3, 4})
}

func TestI32SliceTrim(t *testing.T) {
	ConfirmTrim := func(s I32Slice, start, end int, r I32Slice) {
		if s.Trim(start, end); !r.Equal(s) {
			t.Fatalf("Trim(%v, %v) should be %v but is %v", start, end, r, s)
		}
	}

	ConfirmTrim(I32Slice{0, 1, 2, 3, 4, 5}, 0, 1, I32Slice{0})
	ConfirmTrim(I32Slice{0, 1, 2, 3, 4, 5}, 1, 2, I32Slice{1})
	ConfirmTrim(I32Slice{0, 1, 2, 3, 4, 5}, 2, 3, I32Slice{2})
	ConfirmTrim(I32Slice{0, 1, 2, 3, 4, 5}, 3, 4, I32Slice{3})
	ConfirmTrim(I32Slice{0, 1, 2, 3, 4, 5}, 4, 5, I32Slice{4})
	ConfirmTrim(I32Slice{0, 1, 2, 3, 4, 5}, 5, 6, I32Slice{5})

	ConfirmTrim(I32Slice{0, 1, 2, 3, 4, 5}, -1, 1, I32Slice{0})
	ConfirmTrim(I32Slice{0, 1, 2, 3, 4, 5}, 0, 2, I32Slice{0, 1})
	ConfirmTrim(I32Slice{0, 1, 2, 3, 4, 5}, 1, 3, I32Slice{1, 2})
	ConfirmTrim(I32Slice{0, 1, 2, 3, 4, 5}, 2, 4, I32Slice{2, 3})
	ConfirmTrim(I32Slice{0, 1, 2, 3, 4, 5}, 3, 5, I32Slice{3, 4})
	ConfirmTrim(I32Slice{0, 1, 2, 3, 4, 5}, 4, 6, I32Slice{4, 5})
	ConfirmTrim(I32Slice{0, 1, 2, 3, 4, 5}, 5, 7, I32Slice{5})
}

func TestI32SliceDelete(t *testing.T) {
	ConfirmDelete := func(s I32Slice, index int, r I32Slice) {
		if s.Delete(index); !r.Equal(s) {
			t.Fatalf("Delete(%v) should be %v but is %v", index, r, s)
		}
	}

	ConfirmDelete(I32Slice{0, 1, 2, 3, 4, 5}, -1, I32Slice{0, 1, 2, 3, 4, 5})
	ConfirmDelete(I32Slice{0, 1, 2, 3, 4, 5}, 0, I32Slice{1, 2, 3, 4, 5})
	ConfirmDelete(I32Slice{0, 1, 2, 3, 4, 5}, 1, I32Slice{0, 2, 3, 4, 5})
	ConfirmDelete(I32Slice{0, 1, 2, 3, 4, 5}, 2, I32Slice{0, 1, 3, 4, 5})
	ConfirmDelete(I32Slice{0, 1, 2, 3, 4, 5}, 3, I32Slice{0, 1, 2, 4, 5})
	ConfirmDelete(I32Slice{0, 1, 2, 3, 4, 5}, 4, I32Slice{0, 1, 2, 3, 5})
	ConfirmDelete(I32Slice{0, 1, 2, 3, 4, 5}, 5, I32Slice{0, 1, 2, 3, 4})
	ConfirmDelete(I32Slice{0, 1, 2, 3, 4, 5}, 6, I32Slice{0, 1, 2, 3, 4, 5})
}

func TestI32SliceDeleteIf(t *testing.T) {
	ConfirmDeleteIf := func(s I32Slice, f interface{}, r I32Slice) {
		if s.DeleteIf(f); !r.Equal(s) {
			t.Fatalf("DeleteIf(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmDeleteIf(I32Slice{0, 1, 0, 3, 0, 5}, int32(0), I32Slice{1, 3, 5})
	ConfirmDeleteIf(I32Slice{0, 1, 0, 3, 0, 5}, int32(1), I32Slice{0, 0, 3, 0, 5})
	ConfirmDeleteIf(I32Slice{0, 1, 0, 3, 0, 5}, int32(6), I32Slice{0, 1, 0, 3, 0, 5})

	ConfirmDeleteIf(I32Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int32(0) }, I32Slice{1, 3, 5})
	ConfirmDeleteIf(I32Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int32(1) }, I32Slice{0, 0, 3, 0, 5})
	ConfirmDeleteIf(I32Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int32(6) }, I32Slice{0, 1, 0, 3, 0, 5})

	ConfirmDeleteIf(I32Slice{0, 1, 0, 3, 0, 5}, func(x int32) bool { return x == int32(0) }, I32Slice{1, 3, 5})
	ConfirmDeleteIf(I32Slice{0, 1, 0, 3, 0, 5}, func(x int32) bool { return x == int32(1) }, I32Slice{0, 0, 3, 0, 5})
	ConfirmDeleteIf(I32Slice{0, 1, 0, 3, 0, 5}, func(x int32) bool { return x == int32(6) }, I32Slice{0, 1, 0, 3, 0, 5})
}

func TestI32SliceEach(t *testing.T) {
	var count	int32
	I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(i interface{}) {
		if i != count {
			t.Fatalf("element %v erroneously reported as %v", count, i)
		}
		count++
	})

	I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(index int, i interface{}) {
		if i != int32(index) {
			t.Fatalf("element %v erroneously reported as %v", index, i)
		}
	})

	I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(key, i interface{}) {
		if i != int32(key.(int)) {
			t.Fatalf("element %v erroneously reported as %v", key, i)
		}
	})

	count = 0
	I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(i int32) {
		if i != count {
			t.Fatalf("element %v erroneously reported as %v", count, i)
		}
		count++
	})

	I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(index int, i int32) {
		if i != int32(index) {
			t.Fatalf("element %v erroneously reported as %v", index, i)
		}
	})

	I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(key interface{}, i int32) {
		if i != int32(key.(int)) {
			t.Fatalf("element %v erroneously reported as %v", key, i)
		}
	})
}

func TestI32SliceWhile(t *testing.T) {
	ConfirmLimit := func(s I32Slice, l int, f interface{}) {
		if count := s.While(f); count != l {
			t.Fatalf("%v.While() should have iterated %v times not %v times", s, l, count)
		}
	}

	s := I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}
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
	ConfirmLimit(s, limit, func(i int32) bool {
		if count == limit {
			return false
		}
		count++
		return true
	})

	ConfirmLimit(s, limit, func(index int, i int32) bool {
		return index != limit
	})

	ConfirmLimit(s, limit, func(key interface{}, i int32) bool {
		return key.(int) != limit
	})
}

func TestI32SliceUntil(t *testing.T) {
	ConfirmLimit := func(s I32Slice, l int, f interface{}) {
		if count := s.Until(f); count != l {
			t.Fatalf("%v.Until() should have iterated %v times not %v times", s, l, count)
		}
	}

	s := I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}
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
	ConfirmLimit(s, limit, func(i int32) bool {
		if count == limit {
			return true
		}
		count++
		return false
	})

	ConfirmLimit(s, limit, func(index int, i int32) bool {
		return index == limit
	})

	ConfirmLimit(s, limit, func(key interface{}, i int32) bool {
		return key.(int) == limit
	})
}

func TestI32SliceBlockCopy(t *testing.T) {
	ConfirmBlockCopy := func(s I32Slice, destination, source, count int, r I32Slice) {
		s.BlockCopy(destination, source, count)
		if !r.Equal(s) {
			t.Fatalf("BlockCopy(%v, %v, %v) should be %v but is %v", destination, source, count, r, s)
		}
	}

	ConfirmBlockCopy(I32Slice{}, 0, 0, 1, I32Slice{})
	ConfirmBlockCopy(I32Slice{}, 1, 0, 1, I32Slice{})
	ConfirmBlockCopy(I32Slice{}, 0, 1, 1, I32Slice{})

	ConfirmBlockCopy(I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 0, 0, 4, I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 9, 9, 4, I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 9, 0, 4, I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 0})
	ConfirmBlockCopy(I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 0, 4, I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 10, 4, I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, 2, 4, I32Slice{0, 1, 2, 3, 4, 2, 3, 4, 5, 9})
	ConfirmBlockCopy(I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 2, 5, 4, I32Slice{0, 1, 5, 6, 7, 8, 6, 7, 8, 9})
}

func TestI32SliceBlockClear(t *testing.T) {
	ConfirmBlockClear := func(s I32Slice, start, count int, r I32Slice) {
		s.BlockClear(start, count)
		if !r.Equal(s) {
			t.Fatalf("BlockClear(%v, %v) should be %v but is %v", start, count, r, s)
		}
	}

	ConfirmBlockClear(I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 0, 4, I32Slice{0, 0, 0, 0, 4, 5, 6, 7, 8, 9})
	ConfirmBlockClear(I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 4, I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockClear(I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, 4, I32Slice{0, 1, 2, 3, 4, 0, 0, 0, 0, 9})
}

func TestI32SliceOverwrite(t *testing.T) {
	ConfirmOverwrite := func(s I32Slice, offset int, v, r I32Slice) {
		s.Overwrite(offset, v)
		if !r.Equal(s) {
			t.Fatalf("Overwrite(%v, %v) should be %v but is %v", offset, v, r, s)
		}
	}

	ConfirmOverwrite(I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 0, I32Slice{10, 9, 8, 7}, I32Slice{10, 9, 8, 7, 4, 5, 6, 7, 8, 9})
	ConfirmOverwrite(I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, I32Slice{10, 9, 8, 7}, I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmOverwrite(I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, I32Slice{11, 12, 13, 14}, I32Slice{0, 1, 2, 3, 4, 11, 12, 13, 14, 9})
}

func TestI32SliceReallocate(t *testing.T) {
	ConfirmReallocate := func(s I32Slice, l, c int, r I32Slice) {
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

	ConfirmReallocate(I32Slice{}, 0, 10, make(I32Slice, 0, 10))
	ConfirmReallocate(I32Slice{0, 1, 2, 3, 4}, 3, 10, I32Slice{0, 1, 2})
	ConfirmReallocate(I32Slice{0, 1, 2, 3, 4}, 5, 10, I32Slice{0, 1, 2, 3, 4})
	ConfirmReallocate(I32Slice{0, 1, 2, 3, 4}, 10, 10, I32Slice{0, 1, 2, 3, 4, 0, 0, 0, 0, 0})
	ConfirmReallocate(I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 1, 5, I32Slice{0})
	ConfirmReallocate(I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, 5, I32Slice{0, 1, 2, 3, 4})
	ConfirmReallocate(I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 5, I32Slice{0, 1, 2, 3, 4})
}

func TestI32SliceExtend(t *testing.T) {
	ConfirmExtend := func(s I32Slice, n int, r I32Slice) {
		c := s.Cap()
		s.Extend(n)
		switch {
		case s.Len() != r.Len():	t.Fatalf("Extend(%v) len should be %v but is %v", n, r.Len(), s.Len())
		case s.Cap() != c + n:		t.Fatalf("Extend(%v) cap should be %v but is %v", n, c + n, s.Cap())
		case !r.Equal(s):			t.Fatalf("Extend(%v) should be %v but is %v", n, r, s)
		}
	}

	ConfirmExtend(I32Slice{}, 1, I32Slice{0})
	ConfirmExtend(I32Slice{}, 2, I32Slice{0, 0})
}

func TestI32SliceExpand(t *testing.T) {
	ConfirmExpand := func(s I32Slice, i, n int, r I32Slice) {
		c := s.Cap()
		s.Expand(i, n)
		switch {
		case s.Len() != r.Len():	t.Fatalf("Expand(%v, %v) len should be %v but is %v", i, n, r.Len(), s.Len())
		case s.Cap() != c + n:		t.Fatalf("Expand(%v, %v) cap should be %v but is %v", i, n, c + n, s.Cap())
		case !r.Equal(s):			t.Fatalf("Expand(%v, %v) should be %v but is %v", i, n, r, s)
		}
	}

	ConfirmExpand(I32Slice{}, -1, 1, I32Slice{0})
	ConfirmExpand(I32Slice{}, 0, 1, I32Slice{0})
	ConfirmExpand(I32Slice{}, 1, 1, I32Slice{0})
	ConfirmExpand(I32Slice{}, 0, 2, I32Slice{0, 0})

	ConfirmExpand(I32Slice{0, 1, 2}, -1, 2, I32Slice{0, 0, 0, 1, 2})
	ConfirmExpand(I32Slice{0, 1, 2}, 0, 2, I32Slice{0, 0, 0, 1, 2})
	ConfirmExpand(I32Slice{0, 1, 2}, 1, 2, I32Slice{0, 0, 0, 1, 2})
	ConfirmExpand(I32Slice{0, 1, 2}, 2, 2, I32Slice{0, 1, 0, 0, 2})
	ConfirmExpand(I32Slice{0, 1, 2}, 3, 2, I32Slice{0, 1, 2, 0, 0})
	ConfirmExpand(I32Slice{0, 1, 2}, 4, 2, I32Slice{0, 1, 2, 0, 0})
}

func TestI32SliceDepth(t *testing.T) {
	ConfirmDepth := func(s I32Slice, i int) {
		if x := s.Depth(); x != i {
			t.Fatalf("%v.Depth() should be %v but is %v", s, i, x)
		}
	}
	ConfirmDepth(I32Slice{0, 1}, 0)
}

func TestI32SliceReverse(t *testing.T) {
	ConfirmReverse := func(s, r I32Slice) {
		if s.Reverse(); !Equal(s, r) {
			t.Fatalf("Reverse() should be %v but is %v", r, s)
		}
	}
	ConfirmReverse(I32Slice{}, I32Slice{})
	ConfirmReverse(I32Slice{1}, I32Slice{1})
	ConfirmReverse(I32Slice{1, 2}, I32Slice{2, 1})
	ConfirmReverse(I32Slice{1, 2, 3}, I32Slice{3, 2, 1})
	ConfirmReverse(I32Slice{1, 2, 3, 4}, I32Slice{4, 3, 2, 1})
}

func TestI32SliceAppend(t *testing.T) {
	ConfirmAppend := func(s I32Slice, v interface{}, r I32Slice) {
		s.Append(v)
		if !r.Equal(s) {
			t.Fatalf("Append(%v) should be %v but is %v", v, r, s)
		}
	}

	ConfirmAppend(I32Slice{}, int32(0), I32Slice{0})

	ConfirmAppend(I32Slice{}, I32Slice{0}, I32Slice{0})
	ConfirmAppend(I32Slice{}, I32Slice{0, 1}, I32Slice{0, 1})
	ConfirmAppend(I32Slice{0, 1, 2}, I32Slice{3, 4}, I32Slice{0, 1, 2, 3, 4})
}

func TestI32SlicePrepend(t *testing.T) {
	ConfirmPrepend := func(s I32Slice, v interface{}, r I32Slice) {
		if s.Prepend(v); !r.Equal(s) {
			t.Fatalf("Prepend(%v) should be %v but is %v", v, r, s)
		}
	}

	ConfirmPrepend(I32Slice{}, int32(0), I32Slice{0})
	ConfirmPrepend(I32Slice{0}, int32(1), I32Slice{1, 0})

	ConfirmPrepend(I32Slice{}, I32Slice{0}, I32Slice{0})
	ConfirmPrepend(I32Slice{}, I32Slice{0, 1}, I32Slice{0, 1})
	ConfirmPrepend(I32Slice{0, 1, 2}, I32Slice{3, 4}, I32Slice{3, 4, 0, 1, 2})
}

func TestI32SliceRepeat(t *testing.T) {
	ConfirmRepeat := func(s I32Slice, count int, r I32Slice) {
		if x := s.Repeat(count); !x.Equal(r) {
			t.Fatalf("%v.Repeat(%v) should be %v but is %v", s, count, r, x)
		}
	}

	ConfirmRepeat(I32Slice{}, 5, I32Slice{})
	ConfirmRepeat(I32Slice{0}, 1, I32Slice{0})
	ConfirmRepeat(I32Slice{0}, 2, I32Slice{0, 0})
	ConfirmRepeat(I32Slice{0}, 3, I32Slice{0, 0, 0})
	ConfirmRepeat(I32Slice{0}, 4, I32Slice{0, 0, 0, 0})
	ConfirmRepeat(I32Slice{0}, 5, I32Slice{0, 0, 0, 0, 0})
}

func TestI32SliceCar(t *testing.T) {
	ConfirmCar := func(s I32Slice, r int32) {
		n := s.Car().(int32)
		if ok := n == r; !ok {
			t.Fatalf("head should be '%v' but is '%v'", r, n)
		}
	}
	ConfirmCar(I32Slice{1, 2, 3}, 1)
}

func TestI32SliceCdr(t *testing.T) {
	ConfirmCdr := func(s, r I32Slice) {
		if n := s.Cdr(); !n.Equal(r) {
			t.Fatalf("tail should be '%v' but is '%v'", r, n)
		}
	}
	ConfirmCdr(I32Slice{1, 2, 3}, I32Slice{2, 3})
}

func TestI32SliceRplaca(t *testing.T) {
	ConfirmRplaca := func(s I32Slice, v interface{}, r I32Slice) {
		if s.Rplaca(v); !s.Equal(r) {
			t.Fatalf("slice should be '%v' but is '%v'", r, s)
		}
	}
	ConfirmRplaca(I32Slice{1, 2, 3, 4, 5}, int32(0), I32Slice{0, 2, 3, 4, 5})
}

func TestI32SliceRplacd(t *testing.T) {
	ConfirmRplacd := func(s I32Slice, v interface{}, r I32Slice) {
		if s.Rplacd(v); !s.Equal(r) {
			t.Fatalf("slice should be '%v' but is '%v'", r, s)
		}
	}
	ConfirmRplacd(I32Slice{1, 2, 3, 4, 5}, nil, I32Slice{1})
	ConfirmRplacd(I32Slice{1, 2, 3, 4, 5}, int32(10), I32Slice{1, 10})
	ConfirmRplacd(I32Slice{1, 2, 3, 4, 5}, I32Slice{5, 4, 3, 2}, I32Slice{1, 5, 4, 3, 2})
	ConfirmRplacd(I32Slice{1, 2, 3, 4, 5, 6}, I32Slice{2, 4, 8, 32}, I32Slice{1, 2, 4, 8, 32})
}

func TestI32SliceFind(t *testing.T) {
	ConfirmFind := func(s I32Slice, v int32, i int) {
		if x, ok := s.Find(v); !ok || x != i {
			t.Fatalf("%v.Find(%v) should be %v but is %v", s, v, i, x)
		}
	}

	ConfirmFind(I32Slice{0, 1, 2, 3, 4}, 0, 0)
	ConfirmFind(I32Slice{0, 1, 2, 3, 4}, 1, 1)
	ConfirmFind(I32Slice{0, 1, 2, 4, 3}, 2, 2)
	ConfirmFind(I32Slice{0, 1, 2, 4, 3}, 3, 4)
	ConfirmFind(I32Slice{0, 1, 2, 4, 3}, 4, 3)
}

func TestI32SliceFindN(t *testing.T) {
	ConfirmFindN := func(s I32Slice, v int32, n int, i ISlice) {
		if x := s.FindN(v, n); !ISlice(x).Equal(i) {
			t.Fatalf("%v.Find(%v, %v) should be %v but is %v", s, v, n, i, x)
		}
	}

	ConfirmFindN(I32Slice{1, 0, 1, 0, 1}, 2, 3, ISlice{})
	ConfirmFindN(I32Slice{1, 0, 1, 0, 1}, 1, 0, ISlice{0, 2, 4})
	ConfirmFindN(I32Slice{1, 0, 1, 0, 1}, 1, 1, ISlice{0})
	ConfirmFindN(I32Slice{1, 0, 1, 0, 1}, 1, 2, ISlice{0, 2})
	ConfirmFindN(I32Slice{1, 0, 1, 0, 1}, 1, 3, ISlice{0, 2, 4})
	ConfirmFindN(I32Slice{1, 0, 1, 0, 1}, 1, 4, ISlice{0, 2, 4})
}

func TestI32SliceKeepIf(t *testing.T) {
	ConfirmKeepIf := func(s I32Slice, f interface{}, r I32Slice) {
		if s.KeepIf(f); !r.Equal(s) {
			t.Fatalf("KeepIf(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmKeepIf(I32Slice{0, 1, 0, 3, 0, 5}, int32(0), I32Slice{0, 0, 0})
	ConfirmKeepIf(I32Slice{0, 1, 0, 3, 0, 5}, int32(1), I32Slice{1})
	ConfirmKeepIf(I32Slice{0, 1, 0, 3, 0, 5}, int32(6), I32Slice{})

	ConfirmKeepIf(I32Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int32(0) }, I32Slice{0, 0, 0})
	ConfirmKeepIf(I32Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int32(1) }, I32Slice{1})
	ConfirmKeepIf(I32Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int32(6) }, I32Slice{})

	ConfirmKeepIf(I32Slice{0, 1, 0, 3, 0, 5}, func(x int32) bool { return x == int32(0) }, I32Slice{0, 0, 0})
	ConfirmKeepIf(I32Slice{0, 1, 0, 3, 0, 5}, func(x int32) bool { return x == int32(1) }, I32Slice{1})
	ConfirmKeepIf(I32Slice{0, 1, 0, 3, 0, 5}, func(x int32) bool { return x == int32(6) }, I32Slice{})
}

func TestI32SliceReverseEach(t *testing.T) {
	var count	int32
	count = 9
	I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(i interface{}) {
		if i != count {
			t.Fatalf("0: element %v erroneously reported as %v", count, i)
		}
		count--
	})

	I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(index int, i interface{}) {
		if index != int(i.(int32)) {
			t.Fatalf("1: element %v erroneously reported as %v", index, i)
		}
	})

	I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(key, i interface{}) {
		if key.(int) != int(i.(int32)) {
			t.Fatalf("2: element %v erroneously reported as %v", key, i)
		}
	})

	count = 9
	I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(i int32) {
		if i != count {
			t.Fatalf("3: element %v erroneously reported as %v", count, i)
		}
		count--
	})

	I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(index int, i int32) {
		if int(i) != index {
			t.Fatalf("4: element %v erroneously reported as %v", index, i)
		}
	})

	I32Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(key interface{}, i int32) {
		if key.(int) != int(i) {
			t.Fatalf("5: element %v erroneously reported as %v", key, i)
		}
	})
}

func TestI32SliceReplaceIf(t *testing.T) {
	ConfirmReplaceIf := func(s I32Slice, f, v interface{}, r I32Slice) {
		if s.ReplaceIf(f, v); !r.Equal(s) {
			t.Fatalf("ReplaceIf(%v, %v) should be %v but is %v", f, v, r, s)
		}
	}

	ConfirmReplaceIf(I32Slice{0, 1, 0, 3, 0, 5}, int32(0), int32(1), I32Slice{1, 1, 1, 3, 1, 5})
	ConfirmReplaceIf(I32Slice{0, 1, 0, 3, 0, 5}, int32(1), int32(0), I32Slice{0, 0, 0, 3, 0, 5})
	ConfirmReplaceIf(I32Slice{0, 1, 0, 3, 0, 5}, int32(6), int32(0), I32Slice{0, 1, 0, 3, 0, 5})

	ConfirmReplaceIf(I32Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int32(0) }, int32(1), I32Slice{1, 1, 1, 3, 1, 5})
	ConfirmReplaceIf(I32Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int32(1) }, int32(0), I32Slice{0, 0, 0, 3, 0, 5})
	ConfirmReplaceIf(I32Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int32(6) }, int32(0), I32Slice{0, 1, 0, 3, 0, 5})

	ConfirmReplaceIf(I32Slice{0, 1, 0, 3, 0, 5}, func(x int32) bool { return x == int32(0) }, int32(1), I32Slice{1, 1, 1, 3, 1, 5})
	ConfirmReplaceIf(I32Slice{0, 1, 0, 3, 0, 5}, func(x int32) bool { return x == int32(1) }, int32(0), I32Slice{0, 0, 0, 3, 0, 5})
	ConfirmReplaceIf(I32Slice{0, 1, 0, 3, 0, 5}, func(x int32) bool { return x == int32(6) }, int32(0), I32Slice{0, 1, 0, 3, 0, 5})
}

func TestI32SliceReplace(t *testing.T) {
	ConfirmReplace := func(s I32Slice, v interface{}) {
		if s.Replace(v); !s.Equal(v) {
			t.Fatalf("Replace() should be %v but is %v", s, v)
		}
	}

	ConfirmReplace(I32Slice{0, 1, 2, 3, 4, 5}, I32Slice{9, 8, 7, 6, 5})
	ConfirmReplace(I32Slice{0, 1, 2, 3, 4, 5}, I32Slice{ 9, 8, 7, 6, 5 })
	ConfirmReplace(I32Slice{0, 1, 2, 3, 4, 5}, []int32{ 9, 8, 7, 6, 5 })
}

func TestI32SliceSelect(t *testing.T) {
	ConfirmSelect := func(s I32Slice, f interface{}, r I32Slice) {
		if x := s.Select(f); !r.Equal(x) {
			t.Fatalf("Select(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmSelect(I32Slice{0, 1, 0, 3, 0, 5}, int32(0), I32Slice{0, 0, 0})
	ConfirmSelect(I32Slice{0, 1, 0, 3, 0, 5}, int32(1), I32Slice{1})
	ConfirmSelect(I32Slice{0, 1, 0, 3, 0, 5}, int32(6), I32Slice{})

	ConfirmSelect(I32Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int32(0) }, I32Slice{0, 0, 0})
	ConfirmSelect(I32Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int32(1) }, I32Slice{1})
	ConfirmSelect(I32Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int32(6) }, I32Slice{})

	ConfirmSelect(I32Slice{0, 1, 0, 3, 0, 5}, func(x int32) bool { return x == int32(0) }, I32Slice{0, 0, 0})
	ConfirmSelect(I32Slice{0, 1, 0, 3, 0, 5}, func(x int32) bool { return x == int32(1) }, I32Slice{1})
	ConfirmSelect(I32Slice{0, 1, 0, 3, 0, 5}, func(x int32) bool { return x == int32(6) }, I32Slice{})
}

func TestI32SliceUniq(t *testing.T) {
	ConfirmUniq := func(s, r I32Slice) {
		if s.Uniq(); !r.Equal(s) {
			t.Fatalf("Uniq() should be %v but is %v", r, s)
		}
	}

	ConfirmUniq(I32Slice{0, 0, 0, 0, 0, 0}, I32Slice{0})
	ConfirmUniq(I32Slice{0, 1, 0, 3, 0, 5}, I32Slice{0, 1, 3, 5})
}

func TestI32SlicePick(t *testing.T) {
	ConfirmPick := func(s I32Slice, i []int, r I32Slice) {
		if x := s.Pick(i...); !r.Equal(x) {
			t.Fatalf("%v.Pick(%v) should be %v but is %v", s, i, r, x)
		}
	}

	ConfirmPick(I32Slice{0, 1, 2, 3, 4, 5}, []int{}, I32Slice{})
	ConfirmPick(I32Slice{0, 1, 2, 3, 4, 5}, []int{ 0, 1 }, I32Slice{0, 1})
	ConfirmPick(I32Slice{0, 1, 2, 3, 4, 5}, []int{ 0, 3 }, I32Slice{0, 3})
	ConfirmPick(I32Slice{0, 1, 2, 3, 4, 5}, []int{ 0, 3, 4, 3 }, I32Slice{0, 3, 4, 3})
}

func TestI32SliceInsert(t *testing.T) {
	ConfirmInsert := func(s I32Slice, n int, v interface{}, r I32Slice) {
		if s.Insert(n, v); !r.Equal(s) {
			t.Fatalf("Insert(%v, %v) should be %v but is %v", n, v, r, s)
		}
	}

	ConfirmInsert(I32Slice{}, 0, int32(0), I32Slice{0})
	ConfirmInsert(I32Slice{}, 0, I32Slice{0}, I32Slice{0})
	ConfirmInsert(I32Slice{}, 0, I32Slice{0, 1}, I32Slice{0, 1})

	ConfirmInsert(I32Slice{0}, 0, int32(1), I32Slice{1, 0})
	ConfirmInsert(I32Slice{0}, 0, I32Slice{1}, I32Slice{1, 0})
	ConfirmInsert(I32Slice{0}, 1, int32(1), I32Slice{0, 1})
	ConfirmInsert(I32Slice{0}, 1, I32Slice{1}, I32Slice{0, 1})

	ConfirmInsert(I32Slice{0, 1, 2}, 0, int32(3), I32Slice{3, 0, 1, 2})
	ConfirmInsert(I32Slice{0, 1, 2}, 1, int32(3), I32Slice{0, 3, 1, 2})
	ConfirmInsert(I32Slice{0, 1, 2}, 2, int32(3), I32Slice{0, 1, 3, 2})
	ConfirmInsert(I32Slice{0, 1, 2}, 3, int32(3), I32Slice{0, 1, 2, 3})

	ConfirmInsert(I32Slice{0, 1, 2}, 0, I32Slice{3, 4}, I32Slice{3, 4, 0, 1, 2})
	ConfirmInsert(I32Slice{0, 1, 2}, 1, I32Slice{3, 4}, I32Slice{0, 3, 4, 1, 2})
	ConfirmInsert(I32Slice{0, 1, 2}, 2, I32Slice{3, 4}, I32Slice{0, 1, 3, 4, 2})
	ConfirmInsert(I32Slice{0, 1, 2}, 3, I32Slice{3, 4}, I32Slice{0, 1, 2, 3, 4})
}