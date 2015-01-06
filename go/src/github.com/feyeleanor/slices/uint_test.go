package slices

import "testing"

func TestUSliceString(t *testing.T) {
	ConfirmString := func(s USlice, r string) {
		if x := s.String(); x != r {
			t.Fatalf("%v erroneously serialised as '%v'", r, x)
		}
	}

	ConfirmString(USlice{}, "()")
	ConfirmString(USlice{0}, "(0)")
	ConfirmString(USlice{0, 1}, "(0 1)")
}

func TestUSliceLen(t *testing.T) {
	ConfirmLength := func(s USlice, i int) {
		if x := s.Len(); x != i {
			t.Fatalf("%v.Len() should be %v but is %v", s, i, x)
		}
	}
	
	ConfirmLength(USlice{0}, 1)
	ConfirmLength(USlice{0, 1}, 2)
}

func TestUSliceSwap(t *testing.T) {
	ConfirmSwap := func(s USlice, i, j int, r USlice) {
		if s.Swap(i, j); !r.Equal(s) {
			t.Fatalf("Swap(%v, %v) should be %v but is %v", i, j, r, s)
		}
	}
	ConfirmSwap(USlice{0, 1, 2}, 0, 1, USlice{1, 0, 2})
	ConfirmSwap(USlice{0, 1, 2}, 0, 2, USlice{2, 1, 0})
}

func TestUSliceCompare(t *testing.T) {
	ConfirmCompare := func(s USlice, i, j, r int) {
		if x := s.Compare(i, j); x != r {
			t.Fatalf("Compare(%v, %v) should be %v but is %v", i, j, r, x)
		}
	}

	ConfirmCompare(USlice{0, 1}, 0, 0, IS_SAME_AS)
	ConfirmCompare(USlice{0, 1}, 0, 1, IS_LESS_THAN)
	ConfirmCompare(USlice{0, 1}, 1, 0, IS_GREATER_THAN)
}

func TestUSliceZeroCompare(t *testing.T) {
	ConfirmCompare := func(s USlice, i, r int) {
		if x := s.ZeroCompare(i); x != r {
			t.Fatalf("ZeroCompare(%v) should be %v but is %v", i, r, x)
		}
	}

	ConfirmCompare(USlice{1, 0, 2}, 0, IS_LESS_THAN)
	ConfirmCompare(USlice{1, 0, 2}, 1, IS_SAME_AS)
	ConfirmCompare(USlice{1, 0, 3}, 2, IS_LESS_THAN)
}

func TestUSliceCut(t *testing.T) {
	ConfirmCut := func(s USlice, start, end int, r USlice) {
		if s.Cut(start, end); !r.Equal(s) {
			t.Fatalf("Cut(%v, %v) should be %v but is %v", start, end, r, s)
		}
	}

	ConfirmCut(USlice{0, 1, 2, 3, 4, 5}, 0, 1, USlice{1, 2, 3, 4, 5})
	ConfirmCut(USlice{0, 1, 2, 3, 4, 5}, 1, 2, USlice{0, 2, 3, 4, 5})
	ConfirmCut(USlice{0, 1, 2, 3, 4, 5}, 2, 3, USlice{0, 1, 3, 4, 5})
	ConfirmCut(USlice{0, 1, 2, 3, 4, 5}, 3, 4, USlice{0, 1, 2, 4, 5})
	ConfirmCut(USlice{0, 1, 2, 3, 4, 5}, 4, 5, USlice{0, 1, 2, 3, 5})
	ConfirmCut(USlice{0, 1, 2, 3, 4, 5}, 5, 6, USlice{0, 1, 2, 3, 4})

	ConfirmCut(USlice{0, 1, 2, 3, 4, 5}, -1, 1, USlice{1, 2, 3, 4, 5})
	ConfirmCut(USlice{0, 1, 2, 3, 4, 5}, 0, 2, USlice{2, 3, 4, 5})
	ConfirmCut(USlice{0, 1, 2, 3, 4, 5}, 1, 3, USlice{0, 3, 4, 5})
	ConfirmCut(USlice{0, 1, 2, 3, 4, 5}, 2, 4, USlice{0, 1, 4, 5})
	ConfirmCut(USlice{0, 1, 2, 3, 4, 5}, 3, 5, USlice{0, 1, 2, 5})
	ConfirmCut(USlice{0, 1, 2, 3, 4, 5}, 4, 6, USlice{0, 1, 2, 3})
	ConfirmCut(USlice{0, 1, 2, 3, 4, 5}, 5, 7, USlice{0, 1, 2, 3, 4})
}

func TestUSliceTrim(t *testing.T) {
	ConfirmTrim := func(s USlice, start, end int, r USlice) {
		if s.Trim(start, end); !r.Equal(s) {
			t.Fatalf("Trim(%v, %v) should be %v but is %v", start, end, r, s)
		}
	}

	ConfirmTrim(USlice{0, 1, 2, 3, 4, 5}, 0, 1, USlice{0})
	ConfirmTrim(USlice{0, 1, 2, 3, 4, 5}, 1, 2, USlice{1})
	ConfirmTrim(USlice{0, 1, 2, 3, 4, 5}, 2, 3, USlice{2})
	ConfirmTrim(USlice{0, 1, 2, 3, 4, 5}, 3, 4, USlice{3})
	ConfirmTrim(USlice{0, 1, 2, 3, 4, 5}, 4, 5, USlice{4})
	ConfirmTrim(USlice{0, 1, 2, 3, 4, 5}, 5, 6, USlice{5})

	ConfirmTrim(USlice{0, 1, 2, 3, 4, 5}, -1, 1, USlice{0})
	ConfirmTrim(USlice{0, 1, 2, 3, 4, 5}, 0, 2, USlice{0, 1})
	ConfirmTrim(USlice{0, 1, 2, 3, 4, 5}, 1, 3, USlice{1, 2})
	ConfirmTrim(USlice{0, 1, 2, 3, 4, 5}, 2, 4, USlice{2, 3})
	ConfirmTrim(USlice{0, 1, 2, 3, 4, 5}, 3, 5, USlice{3, 4})
	ConfirmTrim(USlice{0, 1, 2, 3, 4, 5}, 4, 6, USlice{4, 5})
	ConfirmTrim(USlice{0, 1, 2, 3, 4, 5}, 5, 7, USlice{5})
}

func TestUSliceDelete(t *testing.T) {
	ConfirmDelete := func(s USlice, index int, r USlice) {
		if s.Delete(index); !r.Equal(s) {
			t.Fatalf("Delete(%v) should be %v but is %v", index, r, s)
		}
	}

	ConfirmDelete(USlice{0, 1, 2, 3, 4, 5}, -1, USlice{0, 1, 2, 3, 4, 5})
	ConfirmDelete(USlice{0, 1, 2, 3, 4, 5}, 0, USlice{1, 2, 3, 4, 5})
	ConfirmDelete(USlice{0, 1, 2, 3, 4, 5}, 1, USlice{0, 2, 3, 4, 5})
	ConfirmDelete(USlice{0, 1, 2, 3, 4, 5}, 2, USlice{0, 1, 3, 4, 5})
	ConfirmDelete(USlice{0, 1, 2, 3, 4, 5}, 3, USlice{0, 1, 2, 4, 5})
	ConfirmDelete(USlice{0, 1, 2, 3, 4, 5}, 4, USlice{0, 1, 2, 3, 5})
	ConfirmDelete(USlice{0, 1, 2, 3, 4, 5}, 5, USlice{0, 1, 2, 3, 4})
	ConfirmDelete(USlice{0, 1, 2, 3, 4, 5}, 6, USlice{0, 1, 2, 3, 4, 5})
}

func TestUSliceDeleteIf(t *testing.T) {
	ConfirmDeleteIf := func(s USlice, f interface{}, r USlice) {
		if s.DeleteIf(f); !r.Equal(s) {
			t.Fatalf("DeleteIf(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmDeleteIf(USlice{0, 1, 0, 3, 0, 5}, uint(0), USlice{1, 3, 5})
	ConfirmDeleteIf(USlice{0, 1, 0, 3, 0, 5}, uint(1), USlice{0, 0, 3, 0, 5})
	ConfirmDeleteIf(USlice{0, 1, 0, 3, 0, 5}, uint(6), USlice{0, 1, 0, 3, 0, 5})

	ConfirmDeleteIf(USlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uint(0) }, USlice{1, 3, 5})
	ConfirmDeleteIf(USlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uint(1) }, USlice{0, 0, 3, 0, 5})
	ConfirmDeleteIf(USlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uint(6) }, USlice{0, 1, 0, 3, 0, 5})

	ConfirmDeleteIf(USlice{0, 1, 0, 3, 0, 5}, func(x uint) bool { return x == uint(0) }, USlice{1, 3, 5})
	ConfirmDeleteIf(USlice{0, 1, 0, 3, 0, 5}, func(x uint) bool { return x == uint(1) }, USlice{0, 0, 3, 0, 5})
	ConfirmDeleteIf(USlice{0, 1, 0, 3, 0, 5}, func(x uint) bool { return x == uint(6) }, USlice{0, 1, 0, 3, 0, 5})
}

func TestUSliceEach(t *testing.T) {
	var	count	uint
	USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(i interface{}) {
		if i != uint(count) {
			t.Fatalf("element %v erroneously reported as %v", count, i)
		}
		count++
	})

	USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(index int, i interface{}) {
		if i != uint(index) {
			t.Fatalf("element %v erroneously reported as %v", index, i)
		}
	})

	USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(key, i interface{}) {
		if i != uint(key.(int)) {
			t.Fatalf("element %v erroneously reported as %v", key, i)
		}
	})

	count = 0
	USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(i uint) {
		if i != count {
			t.Fatalf("element %v erroneously reported as %v", count, i)
		}
		count++
	})

	USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(index int, i uint) {
		if i != uint(index) {
			t.Fatalf("element %v erroneously reported as %v", index, i)
		}
	})

	USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(key interface{}, i uint) {
		if i != uint(key.(int)) {
			t.Fatalf("element %v erroneously reported as %v", key, i)
		}
	})
}

func TestUSliceWhile(t *testing.T) {
	ConfirmLimit := func(s USlice, l int, f interface{}) {
		if count := s.While(f); count != l {
			t.Fatalf("%v.While() should have iterated %v times not %v times", s, l, count)
		}
	}

	s := USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}
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
	ConfirmLimit(s, limit, func(i uint) bool {
		if count == limit {
			return false
		}
		count++
		return true
	})

	ConfirmLimit(s, limit, func(index int, i uint) bool {
		return index != limit
	})

	ConfirmLimit(s, limit, func(key interface{}, i uint) bool {
		return key.(int) != limit
	})
}

func TestUSliceUntil(t *testing.T) {
	ConfirmLimit := func(s USlice, l int, f interface{}) {
		if count := s.Until(f); count != l {
			t.Fatalf("%v.Until() should have iterated %v times not %v times", s, l, count)
		}
	}

	s := USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}
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
	ConfirmLimit(s, limit, func(i uint) bool {
		if count == limit {
			return true
		}
		count++
		return false
	})

	ConfirmLimit(s, limit, func(index int, i uint) bool {
		return index == limit
	})

	ConfirmLimit(s, limit, func(key interface{}, i uint) bool {
		return key.(int) == limit
	})
}

func TestUSliceBlockCopy(t *testing.T) {
	ConfirmBlockCopy := func(s USlice, destination, source, count int, r USlice) {
		s.BlockCopy(destination, source, count)
		if !r.Equal(s) {
			t.Fatalf("BlockCopy(%v, %v, %v) should be %v but is %v", destination, source, count, r, s)
		}
	}

	ConfirmBlockCopy(USlice{}, 0, 0, 1, USlice{})
	ConfirmBlockCopy(USlice{}, 1, 0, 1, USlice{})
	ConfirmBlockCopy(USlice{}, 0, 1, 1, USlice{})

	ConfirmBlockCopy(USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 0, 0, 4, USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 9, 9, 4, USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 9, 0, 4, USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 0})
	ConfirmBlockCopy(USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 0, 4, USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 10, 4, USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, 2, 4, USlice{0, 1, 2, 3, 4, 2, 3, 4, 5, 9})
	ConfirmBlockCopy(USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 2, 5, 4, USlice{0, 1, 5, 6, 7, 8, 6, 7, 8, 9})
}

func TestUSliceBlockClear(t *testing.T) {
	ConfirmBlockClear := func(s USlice, start, count int, r USlice) {
		s.BlockClear(start, count)
		if !r.Equal(s) {
			t.Fatalf("BlockClear(%v, %v) should be %v but is %v", start, count, r, s)
		}
	}

	ConfirmBlockClear(USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 0, 4, USlice{0, 0, 0, 0, 4, 5, 6, 7, 8, 9})
	ConfirmBlockClear(USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 4, USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockClear(USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, 4, USlice{0, 1, 2, 3, 4, 0, 0, 0, 0, 9})
}

func TestUSliceOverwrite(t *testing.T) {
	ConfirmOverwrite := func(s USlice, offset int, v, r USlice) {
		s.Overwrite(offset, v)
		if !r.Equal(s) {
			t.Fatalf("Overwrite(%v, %v) should be %v but is %v", offset, v, r, s)
		}
	}

	ConfirmOverwrite(USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 0, USlice{10, 9, 8, 7}, USlice{10, 9, 8, 7, 4, 5, 6, 7, 8, 9})
	ConfirmOverwrite(USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, USlice{10, 9, 8, 7}, USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmOverwrite(USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, USlice{11, 12, 13, 14}, USlice{0, 1, 2, 3, 4, 11, 12, 13, 14, 9})
}

func TestUSliceReallocate(t *testing.T) {
	ConfirmReallocate := func(s USlice, l, c int, r USlice) {
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

	ConfirmReallocate(USlice{}, 0, 10, make(USlice, 0, 10))
	ConfirmReallocate(USlice{0, 1, 2, 3, 4}, 3, 10, USlice{0, 1, 2})
	ConfirmReallocate(USlice{0, 1, 2, 3, 4}, 5, 10, USlice{0, 1, 2, 3, 4})
	ConfirmReallocate(USlice{0, 1, 2, 3, 4}, 10, 10, USlice{0, 1, 2, 3, 4, 0, 0, 0, 0, 0})
	ConfirmReallocate(USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 1, 5, USlice{0})
	ConfirmReallocate(USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, 5, USlice{0, 1, 2, 3, 4})
	ConfirmReallocate(USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 5, USlice{0, 1, 2, 3, 4})
}

func TestUSliceExtend(t *testing.T) {
	ConfirmExtend := func(s USlice, n int, r USlice) {
		c := s.Cap()
		s.Extend(n)
		switch {
		case s.Len() != r.Len():	t.Fatalf("Extend(%v) len should be %v but is %v", n, r.Len(), s.Len())
		case s.Cap() != c + n:		t.Fatalf("Extend(%v) cap should be %v but is %v", n, c + n, s.Cap())
		case !r.Equal(s):			t.Fatalf("Extend(%v) should be %v but is %v", n, r, s)
		}
	}

	ConfirmExtend(USlice{}, 1, USlice{0})
	ConfirmExtend(USlice{}, 2, USlice{0, 0})
}

func TestUSliceExpand(t *testing.T) {
	ConfirmExpand := func(s USlice, i, n int, r USlice) {
		c := s.Cap()
		s.Expand(i, n)
		switch {
		case s.Len() != r.Len():	t.Fatalf("Expand(%v, %v) len should be %v but is %v", i, n, r.Len(), s.Len())
		case s.Cap() != c + n:		t.Fatalf("Expand(%v, %v) cap should be %v but is %v", i, n, c + n, s.Cap())
		case !r.Equal(s):			t.Fatalf("Expand(%v, %v) should be %v but is %v", i, n, r, s)
		}
	}

	ConfirmExpand(USlice{}, -1, 1, USlice{0})
	ConfirmExpand(USlice{}, 0, 1, USlice{0})
	ConfirmExpand(USlice{}, 1, 1, USlice{0})
	ConfirmExpand(USlice{}, 0, 2, USlice{0, 0})

	ConfirmExpand(USlice{0, 1, 2}, -1, 2, USlice{0, 0, 0, 1, 2})
	ConfirmExpand(USlice{0, 1, 2}, 0, 2, USlice{0, 0, 0, 1, 2})
	ConfirmExpand(USlice{0, 1, 2}, 1, 2, USlice{0, 0, 0, 1, 2})
	ConfirmExpand(USlice{0, 1, 2}, 2, 2, USlice{0, 1, 0, 0, 2})
	ConfirmExpand(USlice{0, 1, 2}, 3, 2, USlice{0, 1, 2, 0, 0})
	ConfirmExpand(USlice{0, 1, 2}, 4, 2, USlice{0, 1, 2, 0, 0})
}

func TestUSliceDepth(t *testing.T) {
	ConfirmDepth := func(s USlice, i int) {
		if x := s.Depth(); x != i {
			t.Fatalf("%v.Depth() should be %v but is %v", s, i, x)
		}
	}
	ConfirmDepth(USlice{0, 1}, 0)
}

func TestUSliceReverse(t *testing.T) {
	ConfirmReverse := func(s, r USlice) {
		if s.Reverse(); !Equal(s, r) {
			t.Fatalf("Reverse() should be %v but is %v", r, s)
		}
	}
	ConfirmReverse(USlice{}, USlice{})
	ConfirmReverse(USlice{1}, USlice{1})
	ConfirmReverse(USlice{1, 2}, USlice{2, 1})
	ConfirmReverse(USlice{1, 2, 3}, USlice{3, 2, 1})
	ConfirmReverse(USlice{1, 2, 3, 4}, USlice{4, 3, 2, 1})
}

func TestUSliceAppend(t *testing.T) {
	ConfirmAppend := func(s USlice, v interface{}, r USlice) {
		s.Append(v)
		if !r.Equal(s) {
			t.Fatalf("Append(%v) should be %v but is %v", v, r, s)
		}
	}

	ConfirmAppend(USlice{}, uint(0), USlice{0})

	ConfirmAppend(USlice{}, USlice{0}, USlice{0})
	ConfirmAppend(USlice{}, USlice{0, 1}, USlice{0, 1})
	ConfirmAppend(USlice{0, 1, 2}, USlice{3, 4}, USlice{0, 1, 2, 3, 4})
}

func TestUSlicePrepend(t *testing.T) {
	ConfirmPrepend := func(s USlice, v interface{}, r USlice) {
		if s.Prepend(v); !r.Equal(s) {
			t.Fatalf("Prepend(%v) should be %v but is %v", v, r, s)
		}
	}

	ConfirmPrepend(USlice{}, uint(0), USlice{0})
	ConfirmPrepend(USlice{0}, uint(1), USlice{1, 0})

	ConfirmPrepend(USlice{}, USlice{0}, USlice{0})
	ConfirmPrepend(USlice{}, USlice{0, 1}, USlice{0, 1})
	ConfirmPrepend(USlice{0, 1, 2}, USlice{3, 4}, USlice{3, 4, 0, 1, 2})
}

func TestUSliceRepeat(t *testing.T) {
	ConfirmRepeat := func(s USlice, count int, r USlice) {
		if x := s.Repeat(count); !x.Equal(r) {
			t.Fatalf("%v.Repeat(%v) should be %v but is %v", s, count, r, x)
		}
	}

	ConfirmRepeat(USlice{}, 5, USlice{})
	ConfirmRepeat(USlice{0}, 1, USlice{0})
	ConfirmRepeat(USlice{0}, 2, USlice{0, 0})
	ConfirmRepeat(USlice{0}, 3, USlice{0, 0, 0})
	ConfirmRepeat(USlice{0}, 4, USlice{0, 0, 0, 0})
	ConfirmRepeat(USlice{0}, 5, USlice{0, 0, 0, 0, 0})
}

func TestUSliceCar(t *testing.T) {
	ConfirmCar := func(s USlice, r uint) {
		n := s.Car()
		if ok := n == r; !ok {
			t.Fatalf("head should be '%v' but is '%v'", r, n)
		}
	}
	ConfirmCar(USlice{1, 2, 3}, 1)
}

func TestUSliceCdr(t *testing.T) {
	ConfirmCdr := func(s, r USlice) {
		if n := s.Cdr(); !n.Equal(r) {
			t.Fatalf("tail should be '%v' but is '%v'", r, n)
		}
	}
	ConfirmCdr(USlice{1, 2, 3}, USlice{2, 3})
}

func TestUSliceRplaca(t *testing.T) {
	ConfirmRplaca := func(s USlice, v interface{}, r USlice) {
		if s.Rplaca(v); !s.Equal(r) {
			t.Fatalf("slice should be '%v' but is '%v'", r, s)
		}
	}
	ConfirmRplaca(USlice{1, 2, 3, 4, 5}, uint(0), USlice{0, 2, 3, 4, 5})
}

func TestUSliceRplacd(t *testing.T) {
	ConfirmRplacd := func(s USlice, v interface{}, r USlice) {
		if s.Rplacd(v); !s.Equal(r) {
			t.Fatalf("slice should be '%v' but is '%v'", r, s)
		}
	}
	ConfirmRplacd(USlice{1, 2, 3, 4, 5}, nil, USlice{1})
	ConfirmRplacd(USlice{1, 2, 3, 4, 5}, uint(10), USlice{1, 10})
	ConfirmRplacd(USlice{1, 2, 3, 4, 5}, USlice{5, 4, 3, 2}, USlice{1, 5, 4, 3, 2})
	ConfirmRplacd(USlice{1, 2, 3, 4, 5, 6}, USlice{2, 4, 8, 16}, USlice{1, 2, 4, 8, 16})
}

func TestUSliceFind(t *testing.T) {
	ConfirmFind := func(s USlice, v uint, i int) {
		if x, ok := s.Find(v); !ok || x != i {
			t.Fatalf("%v.Find(%v) should be %v but is %v", s, v, i, x)
		}
	}

	ConfirmFind(USlice{0, 1, 2, 3, 4}, 0, 0)
	ConfirmFind(USlice{0, 1, 2, 3, 4}, 1, 1)
	ConfirmFind(USlice{0, 1, 2, 4, 3}, 2, 2)
	ConfirmFind(USlice{0, 1, 2, 4, 3}, 3, 4)
	ConfirmFind(USlice{0, 1, 2, 4, 3}, 4, 3)
}

func TestUSliceFindN(t *testing.T) {
	ConfirmFindN := func(s USlice, v uint, n int, i ISlice) {
		if x := s.FindN(v, n); !x.Equal(i) {
			t.Fatalf("%v.Find(%v, %v) should be %v but is %v", s, v, n, i, x)
		}
	}

	ConfirmFindN(USlice{1, 0, 1, 0, 1}, 2, 3, ISlice{})
	ConfirmFindN(USlice{1, 0, 1, 0, 1}, 1, 0, ISlice{0, 2, 4})
	ConfirmFindN(USlice{1, 0, 1, 0, 1}, 1, 1, ISlice{0})
	ConfirmFindN(USlice{1, 0, 1, 0, 1}, 1, 2, ISlice{0, 2})
	ConfirmFindN(USlice{1, 0, 1, 0, 1}, 1, 3, ISlice{0, 2, 4})
	ConfirmFindN(USlice{1, 0, 1, 0, 1}, 1, 4, ISlice{0, 2, 4})
}

func TestUSliceKeepIf(t *testing.T) {
	ConfirmKeepIf := func(s USlice, f interface{}, r USlice) {
		if s.KeepIf(f); !r.Equal(s) {
			t.Fatalf("KeepIf(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmKeepIf(USlice{0, 1, 0, 3, 0, 5}, uint(0), USlice{0, 0, 0})
	ConfirmKeepIf(USlice{0, 1, 0, 3, 0, 5}, uint(1), USlice{1})
	ConfirmKeepIf(USlice{0, 1, 0, 3, 0, 5}, uint(6), USlice{})

	ConfirmKeepIf(USlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uint(0) }, USlice{0, 0, 0})
	ConfirmKeepIf(USlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uint(1) }, USlice{1})
	ConfirmKeepIf(USlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uint(6) }, USlice{})

	ConfirmKeepIf(USlice{0, 1, 0, 3, 0, 5}, func(x uint) bool { return x == uint(0) }, USlice{0, 0, 0})
	ConfirmKeepIf(USlice{0, 1, 0, 3, 0, 5}, func(x uint) bool { return x == uint(1) }, USlice{1})
	ConfirmKeepIf(USlice{0, 1, 0, 3, 0, 5}, func(x uint) bool { return x == uint(6) }, USlice{})
}

func TestUSliceReverseEach(t *testing.T) {
	var count	uint
	count = 9
	USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(i interface{}) {
		if i != count {
			t.Fatalf("0: element %v erroneously reported as %v", count, i)
		}
		count--
	})

	USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(index int, i interface{}) {
		if index != int(i.(uint)) {
			t.Fatalf("1: element %v erroneously reported as %v", index, i)
		}
	})

	USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(key, i interface{}) {
		if uint(key.(int)) != i {
			t.Fatalf("2: element %v erroneously reported as %v", key, i)
		}
	})

	count = 9
	USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(i uint) {
		if i != count {
			t.Fatalf("3: element %v erroneously reported as %v", count, i)
		}
		count--
	})

	USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(index int, i uint) {
		if int(i) != index {
			t.Fatalf("4: element %v erroneously reported as %v", index, i)
		}
	})

	USlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(key interface{}, i uint) {
		if key.(int) != int(i) {
			t.Fatalf("5: element %v erroneously reported as %v", key, i)
		}
	})
}

func TestUSliceReplaceIf(t *testing.T) {
	ConfirmReplaceIf := func(s USlice, f, v interface{}, r USlice) {
		if s.ReplaceIf(f, v); !r.Equal(s) {
			t.Fatalf("ReplaceIf(%v, %v) should be %v but is %v", f, v, r, s)
		}
	}

	ConfirmReplaceIf(USlice{0, 1, 0, 3, 0, 5}, uint(0), uint(1), USlice{1, 1, 1, 3, 1, 5})
	ConfirmReplaceIf(USlice{0, 1, 0, 3, 0, 5}, uint(1), uint(0), USlice{0, 0, 0, 3, 0, 5})
	ConfirmReplaceIf(USlice{0, 1, 0, 3, 0, 5}, uint(6), uint(0), USlice{0, 1, 0, 3, 0, 5})

	ConfirmReplaceIf(USlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uint(0) }, uint(1), USlice{1, 1, 1, 3, 1, 5})
	ConfirmReplaceIf(USlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uint(1) }, uint(0), USlice{0, 0, 0, 3, 0, 5})
	ConfirmReplaceIf(USlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uint(6) }, uint(0), USlice{0, 1, 0, 3, 0, 5})

	ConfirmReplaceIf(USlice{0, 1, 0, 3, 0, 5}, func(x uint) bool { return x == uint(0) }, uint(1), USlice{1, 1, 1, 3, 1, 5})
	ConfirmReplaceIf(USlice{0, 1, 0, 3, 0, 5}, func(x uint) bool { return x == uint(1) }, uint(0), USlice{0, 0, 0, 3, 0, 5})
	ConfirmReplaceIf(USlice{0, 1, 0, 3, 0, 5}, func(x uint) bool { return x == uint(6) }, uint(0), USlice{0, 1, 0, 3, 0, 5})
}

func TestUSliceReplace(t *testing.T) {
	ConfirmReplace := func(s USlice, v interface{}) {
		if s.Replace(v); !s.Equal(v) {
			t.Fatalf("Replace() should be %v but is %v", s, v)
		}
	}

	ConfirmReplace(USlice{0, 1, 2, 3, 4, 5}, USlice{9, 8, 7, 6, 5})
	ConfirmReplace(USlice{0, 1, 2, 3, 4, 5}, []uint{9, 8, 7, 6, 5})
}

func TestUSliceSelect(t *testing.T) {
	ConfirmSelect := func(s USlice, f interface{}, r USlice) {
		if x := s.Select(f); !r.Equal(x) {
			t.Fatalf("Select(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmSelect(USlice{0, 1, 0, 3, 0, 5}, uint(0), USlice{0, 0, 0})
	ConfirmSelect(USlice{0, 1, 0, 3, 0, 5}, uint(1), USlice{1})
	ConfirmSelect(USlice{0, 1, 0, 3, 0, 5}, uint(6), USlice{})

	ConfirmSelect(USlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uint(0) }, USlice{0, 0, 0})
	ConfirmSelect(USlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uint(1) }, USlice{1})
	ConfirmSelect(USlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uint(6) }, USlice{})

	ConfirmSelect(USlice{0, 1, 0, 3, 0, 5}, func(x uint) bool { return x == uint(0) }, USlice{0, 0, 0})
	ConfirmSelect(USlice{0, 1, 0, 3, 0, 5}, func(x uint) bool { return x == uint(1) }, USlice{1})
	ConfirmSelect(USlice{0, 1, 0, 3, 0, 5}, func(x uint) bool { return x == uint(6) }, USlice{})
}

func TestUSliceUniq(t *testing.T) {
	ConfirmUniq := func(s, r USlice) {
		if s.Uniq(); !r.Equal(s) {
			t.Fatalf("Uniq() should be %v but is %v", r, s)
		}
	}

	ConfirmUniq(USlice{0, 0, 0, 0, 0, 0}, USlice{0})
	ConfirmUniq(USlice{0, 1, 0, 3, 0, 5}, USlice{0, 1, 3, 5})
}

func TestUSlicePick(t *testing.T) {
	ConfirmPick := func(s USlice, i []int, r USlice) {
		if x := s.Pick(i...); !r.Equal(x) {
			t.Fatalf("%v.Pick(%v) should be %v but is %v", s, i, r, x)
		}
	}

	ConfirmPick(USlice{0, 1, 2, 3, 4, 5}, []int{}, USlice{})
	ConfirmPick(USlice{0, 1, 2, 3, 4, 5}, []int{ 0, 1 }, USlice{0, 1})
	ConfirmPick(USlice{0, 1, 2, 3, 4, 5}, []int{ 0, 3 }, USlice{0, 3})
	ConfirmPick(USlice{0, 1, 2, 3, 4, 5}, []int{ 0, 3, 4, 3 }, USlice{0, 3, 4, 3})
}

func TestUSliceInsert(t *testing.T) {
	ConfirmInsert := func(s USlice, n int, v interface{}, r USlice) {
		if s.Insert(n, v); !r.Equal(s) {
			t.Fatalf("Insert(%v, %v) should be %v but is %v", n, v, r, s)
		}
	}

	ConfirmInsert(USlice{}, 0, uint(0), USlice{0})
	ConfirmInsert(USlice{}, 0, USlice{0}, USlice{0})
	ConfirmInsert(USlice{}, 0, USlice{0, 1}, USlice{0, 1})

	ConfirmInsert(USlice{0}, 0, uint(1), USlice{1, 0})
	ConfirmInsert(USlice{0}, 0, USlice{1}, USlice{1, 0})
	ConfirmInsert(USlice{0}, 1, uint(1), USlice{0, 1})
	ConfirmInsert(USlice{0}, 1, USlice{1}, USlice{0, 1})

	ConfirmInsert(USlice{0, 1, 2}, 0, uint(3), USlice{3, 0, 1, 2})
	ConfirmInsert(USlice{0, 1, 2}, 1, uint(3), USlice{0, 3, 1, 2})
	ConfirmInsert(USlice{0, 1, 2}, 2, uint(3), USlice{0, 1, 3, 2})
	ConfirmInsert(USlice{0, 1, 2}, 3, uint(3), USlice{0, 1, 2, 3})

	ConfirmInsert(USlice{0, 1, 2}, 0, USlice{3, 4}, USlice{3, 4, 0, 1, 2})
	ConfirmInsert(USlice{0, 1, 2}, 1, USlice{3, 4}, USlice{0, 3, 4, 1, 2})
	ConfirmInsert(USlice{0, 1, 2}, 2, USlice{3, 4}, USlice{0, 1, 3, 4, 2})
	ConfirmInsert(USlice{0, 1, 2}, 3, USlice{3, 4}, USlice{0, 1, 2, 3, 4})
}