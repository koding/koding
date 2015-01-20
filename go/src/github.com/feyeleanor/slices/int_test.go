package slices

import "testing"

func TestISliceString(t *testing.T) {
	ConfirmString := func(s ISlice, r string) {
		if x := s.String(); x != r {
			t.Fatalf("%v erroneously serialised as '%v'", r, x)
		}
	}

	ConfirmString(ISlice{}, "()")
	ConfirmString(ISlice{0}, "(0)")
	ConfirmString(ISlice{0, 1}, "(0 1)")
}

func TestISliceLen(t *testing.T) {
	ConfirmLength := func(s ISlice, i int) {
		if x := s.Len(); x != i {
			t.Fatalf("%v.Len() should be %v but is %v", s, i, x)
		}
	}
	
	ConfirmLength(ISlice{0}, 1)
	ConfirmLength(ISlice{0, 1}, 2)
}

func TestISliceSwap(t *testing.T) {
	ConfirmSwap := func(s ISlice, i, j int, r ISlice) {
		if s.Swap(i, j); !r.Equal(s) {
			t.Fatalf("Swap(%v, %v) should be %v but is %v", i, j, r, s)
		}
	}
	ConfirmSwap(ISlice{0, 1, 2}, 0, 1, ISlice{1, 0, 2})
	ConfirmSwap(ISlice{0, 1, 2}, 0, 2, ISlice{2, 1, 0})
}

func TestISliceCompare(t *testing.T) {
	ConfirmCompare := func(s ISlice, i, j, r int) {
		if x := s.Compare(i, j); x != r {
			t.Fatalf("Compare(%v, %v) should be %v but is %v", i, j, r, x)
		}
	}

	ConfirmCompare(ISlice{0, 1}, 0, 0, IS_SAME_AS)
	ConfirmCompare(ISlice{0, 1}, 0, 1, IS_LESS_THAN)
	ConfirmCompare(ISlice{0, 1}, 1, 0, IS_GREATER_THAN)
}

func TestISliceZeroCompare(t *testing.T) {
	ConfirmCompare := func(s ISlice, i, r int) {
		if x := s.ZeroCompare(i); x != r {
			t.Fatalf("ZeroCompare(%v) should be %v but is %v", i, r, x)
		}
	}

	ConfirmCompare(ISlice{0, -1, 1}, 0, IS_SAME_AS)
	ConfirmCompare(ISlice{0, -1, 1}, 1, IS_GREATER_THAN)
	ConfirmCompare(ISlice{0, -1, 1}, 2, IS_LESS_THAN)
}

func TestISliceCut(t *testing.T) {
	ConfirmCut := func(s ISlice, start, end int, r ISlice) {
		if s.Cut(start, end); !r.Equal(s) {
			t.Fatalf("Cut(%v, %v) should be %v but is %v", start, end, r, s)
		}
	}

	ConfirmCut(ISlice{0, 1, 2, 3, 4, 5}, 0, 1, ISlice{1, 2, 3, 4, 5})
	ConfirmCut(ISlice{0, 1, 2, 3, 4, 5}, 1, 2, ISlice{0, 2, 3, 4, 5})
	ConfirmCut(ISlice{0, 1, 2, 3, 4, 5}, 2, 3, ISlice{0, 1, 3, 4, 5})
	ConfirmCut(ISlice{0, 1, 2, 3, 4, 5}, 3, 4, ISlice{0, 1, 2, 4, 5})
	ConfirmCut(ISlice{0, 1, 2, 3, 4, 5}, 4, 5, ISlice{0, 1, 2, 3, 5})
	ConfirmCut(ISlice{0, 1, 2, 3, 4, 5}, 5, 6, ISlice{0, 1, 2, 3, 4})

	ConfirmCut(ISlice{0, 1, 2, 3, 4, 5}, -1, 1, ISlice{1, 2, 3, 4, 5})
	ConfirmCut(ISlice{0, 1, 2, 3, 4, 5}, 0, 2, ISlice{2, 3, 4, 5})
	ConfirmCut(ISlice{0, 1, 2, 3, 4, 5}, 1, 3, ISlice{0, 3, 4, 5})
	ConfirmCut(ISlice{0, 1, 2, 3, 4, 5}, 2, 4, ISlice{0, 1, 4, 5})
	ConfirmCut(ISlice{0, 1, 2, 3, 4, 5}, 3, 5, ISlice{0, 1, 2, 5})
	ConfirmCut(ISlice{0, 1, 2, 3, 4, 5}, 4, 6, ISlice{0, 1, 2, 3})
	ConfirmCut(ISlice{0, 1, 2, 3, 4, 5}, 5, 7, ISlice{0, 1, 2, 3, 4})
}

func TestISliceTrim(t *testing.T) {
	ConfirmTrim := func(s ISlice, start, end int, r ISlice) {
		if s.Trim(start, end); !r.Equal(s) {
			t.Fatalf("Trim(%v, %v) should be %v but is %v", start, end, r, s)
		}
	}

	ConfirmTrim(ISlice{0, 1, 2, 3, 4, 5}, 0, 1, ISlice{0})
	ConfirmTrim(ISlice{0, 1, 2, 3, 4, 5}, 1, 2, ISlice{1})
	ConfirmTrim(ISlice{0, 1, 2, 3, 4, 5}, 2, 3, ISlice{2})
	ConfirmTrim(ISlice{0, 1, 2, 3, 4, 5}, 3, 4, ISlice{3})
	ConfirmTrim(ISlice{0, 1, 2, 3, 4, 5}, 4, 5, ISlice{4})
	ConfirmTrim(ISlice{0, 1, 2, 3, 4, 5}, 5, 6, ISlice{5})

	ConfirmTrim(ISlice{0, 1, 2, 3, 4, 5}, -1, 1, ISlice{0})
	ConfirmTrim(ISlice{0, 1, 2, 3, 4, 5}, 0, 2, ISlice{0, 1})
	ConfirmTrim(ISlice{0, 1, 2, 3, 4, 5}, 1, 3, ISlice{1, 2})
	ConfirmTrim(ISlice{0, 1, 2, 3, 4, 5}, 2, 4, ISlice{2, 3})
	ConfirmTrim(ISlice{0, 1, 2, 3, 4, 5}, 3, 5, ISlice{3, 4})
	ConfirmTrim(ISlice{0, 1, 2, 3, 4, 5}, 4, 6, ISlice{4, 5})
	ConfirmTrim(ISlice{0, 1, 2, 3, 4, 5}, 5, 7, ISlice{5})
}

func TestISliceDelete(t *testing.T) {
	ConfirmDelete := func(s ISlice, index int, r ISlice) {
		if s.Delete(index); !r.Equal(s) {
			t.Fatalf("Delete(%v) should be %v but is %v", index, r, s)
		}
	}

	ConfirmDelete(ISlice{0, 1, 2, 3, 4, 5}, -1, ISlice{0, 1, 2, 3, 4, 5})
	ConfirmDelete(ISlice{0, 1, 2, 3, 4, 5}, 0, ISlice{1, 2, 3, 4, 5})
	ConfirmDelete(ISlice{0, 1, 2, 3, 4, 5}, 1, ISlice{0, 2, 3, 4, 5})
	ConfirmDelete(ISlice{0, 1, 2, 3, 4, 5}, 2, ISlice{0, 1, 3, 4, 5})
	ConfirmDelete(ISlice{0, 1, 2, 3, 4, 5}, 3, ISlice{0, 1, 2, 4, 5})
	ConfirmDelete(ISlice{0, 1, 2, 3, 4, 5}, 4, ISlice{0, 1, 2, 3, 5})
	ConfirmDelete(ISlice{0, 1, 2, 3, 4, 5}, 5, ISlice{0, 1, 2, 3, 4})
	ConfirmDelete(ISlice{0, 1, 2, 3, 4, 5}, 6, ISlice{0, 1, 2, 3, 4, 5})
}

func TestISliceDeleteIf(t *testing.T) {
	ConfirmDeleteIf := func(s ISlice, f interface{}, r ISlice) {
		if s.DeleteIf(f); !r.Equal(s) {
			t.Fatalf("DeleteIf(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmDeleteIf(ISlice{0, 1, 0, 3, 0, 5}, int(0), ISlice{1, 3, 5})
	ConfirmDeleteIf(ISlice{0, 1, 0, 3, 0, 5}, int(1), ISlice{0, 0, 3, 0, 5})
	ConfirmDeleteIf(ISlice{0, 1, 0, 3, 0, 5}, int(6), ISlice{0, 1, 0, 3, 0, 5})

	ConfirmDeleteIf(ISlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int(0) }, ISlice{1, 3, 5})
	ConfirmDeleteIf(ISlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int(1) }, ISlice{0, 0, 3, 0, 5})
	ConfirmDeleteIf(ISlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int(6) }, ISlice{0, 1, 0, 3, 0, 5})

	ConfirmDeleteIf(ISlice{0, 1, 0, 3, 0, 5}, func(x int) bool { return x == int(0) }, ISlice{1, 3, 5})
	ConfirmDeleteIf(ISlice{0, 1, 0, 3, 0, 5}, func(x int) bool { return x == int(1) }, ISlice{0, 0, 3, 0, 5})
	ConfirmDeleteIf(ISlice{0, 1, 0, 3, 0, 5}, func(x int) bool { return x == int(6) }, ISlice{0, 1, 0, 3, 0, 5})
}

func TestISliceEach(t *testing.T) {
	count := 0
	ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(i interface{}) {
		if i != count {
			t.Fatalf("element %v erroneously reported as %v", count, i)
		}
		count++
	})

	ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(index int, i interface{}) {
		if i != index {
			t.Fatalf("element %v erroneously reported as %v", index, i)
		}
	})

	ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(key, i interface{}) {
		if i != key {
			t.Fatalf("element %v erroneously reported as %v", key, i)
		}
	})

	count = 0
	ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(i int) {
		if i != count {
			t.Fatalf("element %v erroneously reported as %v", count, i)
		}
		count++
	})

	ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(index int, i int) {
		if i != index {
			t.Fatalf("element %v erroneously reported as %v", index, i)
		}
	})

	ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(key interface{}, i int) {
		if i != key {
			t.Fatalf("element %v erroneously reported as %v", key, i)
		}
	})
}

func TestISliceWhile(t *testing.T) {
	ConfirmLimit := func(s ISlice, l int, f interface{}) {
		if count := s.While(f); count != l {
			t.Fatalf("%v.While() should have iterated %v times not %v times", s, l, count)
		}
	}

	s := ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}
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
	ConfirmLimit(s, limit, func(i int) bool {
		if count == limit {
			return false
		}
		count++
		return true
	})

	ConfirmLimit(s, limit, func(index int, i int) bool {
		return index != limit
	})

	ConfirmLimit(s, limit, func(key interface{}, i int) bool {
		return key.(int) != limit
	})
}

func TestISliceUntil(t *testing.T) {
	ConfirmLimit := func(s ISlice, l int, f interface{}) {
		if count := s.Until(f); count != l {
			t.Fatalf("%v.Until() should have iterated %v times not %v times", s, l, count)
		}
	}

	s := ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}
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
	ConfirmLimit(s, limit, func(i int) bool {
		if count == limit {
			return true
		}
		count++
		return false
	})

	ConfirmLimit(s, limit, func(index int, i int) bool {
		return index == limit
	})

	ConfirmLimit(s, limit, func(key interface{}, i int) bool {
		return key.(int) == limit
	})
}

func TestISliceBlockCopy(t *testing.T) {
	ConfirmBlockCopy := func(s ISlice, destination, source, count int, r ISlice) {
		s.BlockCopy(destination, source, count)
		if !r.Equal(s) {
			t.Fatalf("BlockCopy(%v, %v, %v) should be %v but is %v", destination, source, count, r, s)
		}
	}

	ConfirmBlockCopy(ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 0, 0, 4, ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 9, 9, 4, ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 9, 0, 4, ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 0})
	ConfirmBlockCopy(ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 0, 4, ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 10, 4, ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, 2, 4, ISlice{0, 1, 2, 3, 4, 2, 3, 4, 5, 9})
	ConfirmBlockCopy(ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 2, 5, 4, ISlice{0, 1, 5, 6, 7, 8, 6, 7, 8, 9})
}

func TestISliceBlockClear(t *testing.T) {
	ConfirmBlockClear := func(s ISlice, start, count int, r ISlice) {
		s.BlockClear(start, count)
		if !r.Equal(s) {
			t.Fatalf("BlockClear(%v, %v) should be %v but is %v", start, count, r, s)
		}
	}

	ConfirmBlockClear(ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 0, 4, ISlice{0, 0, 0, 0, 4, 5, 6, 7, 8, 9})
	ConfirmBlockClear(ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 4, ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockClear(ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, 4, ISlice{0, 1, 2, 3, 4, 0, 0, 0, 0, 9})
}

func TestISliceOverwrite(t *testing.T) {
	ConfirmOverwrite := func(s ISlice, offset int, v, r ISlice) {
		s.Overwrite(offset, v)
		if !r.Equal(s) {
			t.Fatalf("Overwrite(%v, %v) should be %v but is %v", offset, v, r, s)
		}
	}

	ConfirmOverwrite(ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 0, ISlice{10, 9, 8, 7}, ISlice{10, 9, 8, 7, 4, 5, 6, 7, 8, 9})
	ConfirmOverwrite(ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, ISlice{10, 9, 8, 7}, ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmOverwrite(ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, ISlice{11, 12, 13, 14}, ISlice{0, 1, 2, 3, 4, 11, 12, 13, 14, 9})
}

func TestISliceReallocate(t *testing.T) {
	ConfirmReallocate := func(s ISlice, l, c int, r ISlice) {
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

	ConfirmReallocate(ISlice{}, 0, 10, make(ISlice, 0, 10))
	ConfirmReallocate(ISlice{0, 1, 2, 3, 4}, 3, 10, ISlice{0, 1, 2})
	ConfirmReallocate(ISlice{0, 1, 2, 3, 4}, 5, 10, ISlice{0, 1, 2, 3, 4})
	ConfirmReallocate(ISlice{0, 1, 2, 3, 4}, 10, 10, ISlice{0, 1, 2, 3, 4, 0, 0, 0, 0, 0})
	ConfirmReallocate(ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 1, 5, ISlice{0})
	ConfirmReallocate(ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, 5, ISlice{0, 1, 2, 3, 4})
	ConfirmReallocate(ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 5, ISlice{0, 1, 2, 3, 4})
}

func TestISliceExtend(t *testing.T) {
	ConfirmExtend := func(s ISlice, n int, r ISlice) {
		c := s.Cap()
		s.Extend(n)
		switch {
		case s.Len() != r.Len():	t.Fatalf("Extend(%v) len should be %v but is %v", n, r.Len(), s.Len())
		case s.Cap() != c + n:		t.Fatalf("Extend(%v) cap should be %v but is %v", n, c + n, s.Cap())
		case !r.Equal(s):			t.Fatalf("Extend(%v) should be %v but is %v", n, r, s)
		}
	}

	ConfirmExtend(ISlice{}, 1, ISlice{0})
	ConfirmExtend(ISlice{}, 2, ISlice{0, 0})
}

func TestISliceExpand(t *testing.T) {
	ConfirmExpand := func(s ISlice, i, n int, r ISlice) {
		c := s.Cap()
		s.Expand(i, n)
		switch {
		case s.Len() != r.Len():	t.Fatalf("Expand(%v, %v) len should be %v but is %v", i, n, r.Len(), s.Len())
		case s.Cap() != c + n:		t.Fatalf("Expand(%v, %v) cap should be %v but is %v", i, n, c + n, s.Cap())
		case !r.Equal(s):			t.Fatalf("Expand(%v, %v) should be %v but is %v", i, n, r, s)
		}
	}

	ConfirmExpand(ISlice{}, -1, 1, ISlice{0})
	ConfirmExpand(ISlice{}, 0, 1, ISlice{0})
	ConfirmExpand(ISlice{}, 1, 1, ISlice{0})
	ConfirmExpand(ISlice{}, 0, 2, ISlice{0, 0})

	ConfirmExpand(ISlice{0, 1, 2}, -1, 2, ISlice{0, 0, 0, 1, 2})
	ConfirmExpand(ISlice{0, 1, 2}, 0, 2, ISlice{0, 0, 0, 1, 2})
	ConfirmExpand(ISlice{0, 1, 2}, 1, 2, ISlice{0, 0, 0, 1, 2})
	ConfirmExpand(ISlice{0, 1, 2}, 2, 2, ISlice{0, 1, 0, 0, 2})
	ConfirmExpand(ISlice{0, 1, 2}, 3, 2, ISlice{0, 1, 2, 0, 0})
	ConfirmExpand(ISlice{0, 1, 2}, 4, 2, ISlice{0, 1, 2, 0, 0})
}

func TestISliceDepth(t *testing.T) {
	ConfirmDepth := func(s ISlice, i int) {
		if x := s.Depth(); x != i {
			t.Fatalf("%v.Depth() should be %v but is %v", s, i, x)
		}
	}
	ConfirmDepth(ISlice{0, 1}, 0)
}

func TestISliceReverse(t *testing.T) {
	ConfirmReverse := func(s, r ISlice) {
		if s.Reverse(); !Equal(s, r) {
			t.Fatalf("Reverse() should be %v but is %v", r, s)
		}
	}
	ConfirmReverse(ISlice{}, ISlice{})
	ConfirmReverse(ISlice{1}, ISlice{1})
	ConfirmReverse(ISlice{1, 2}, ISlice{2, 1})
	ConfirmReverse(ISlice{1, 2, 3}, ISlice{3, 2, 1})
	ConfirmReverse(ISlice{1, 2, 3, 4}, ISlice{4, 3, 2, 1})
}

func TestISliceAppend(t *testing.T) {
	ConfirmAppend := func(s ISlice, v interface{}, r ISlice) {
		s.Append(v)
		if !r.Equal(s) {
			t.Fatalf("Append(%v) should be %v but is %v", v, r, s)
		}
	}

	ConfirmAppend(ISlice{}, 0, ISlice{0})

	ConfirmAppend(ISlice{}, ISlice{0}, ISlice{0})
	ConfirmAppend(ISlice{}, ISlice{0, 1}, ISlice{0, 1})
	ConfirmAppend(ISlice{0, 1, 2}, ISlice{3, 4}, ISlice{0, 1, 2, 3, 4})
}

func TestISlicePrepend(t *testing.T) {
	ConfirmPrepend := func(s ISlice, v interface{}, r ISlice) {
		if s.Prepend(v); !r.Equal(s) {
			t.Fatalf("Prepend(%v) should be %v but is %v", v, r, s)
		}
	}

	ConfirmPrepend(ISlice{}, 0, ISlice{0})
	ConfirmPrepend(ISlice{0}, 1, ISlice{1, 0})

	ConfirmPrepend(ISlice{}, ISlice{0}, ISlice{0})
	ConfirmPrepend(ISlice{}, ISlice{0, 1}, ISlice{0, 1})
	ConfirmPrepend(ISlice{0, 1, 2}, ISlice{3, 4}, ISlice{3, 4, 0, 1, 2})
}

func TestISliceRepeat(t *testing.T) {
	ConfirmRepeat := func(s ISlice, count int, r ISlice) {
		if x := s.Repeat(count); !x.Equal(r) {
			t.Fatalf("%v.Repeat(%v) should be %v but is %v", s, count, r, x)
		}
	}

	ConfirmRepeat(ISlice{}, 5, ISlice{})
	ConfirmRepeat(ISlice{0}, 1, ISlice{0})
	ConfirmRepeat(ISlice{0}, 2, ISlice{0, 0})
	ConfirmRepeat(ISlice{0}, 3, ISlice{0, 0, 0})
	ConfirmRepeat(ISlice{0}, 4, ISlice{0, 0, 0, 0})
	ConfirmRepeat(ISlice{0}, 5, ISlice{0, 0, 0, 0, 0})
}

func TestISliceCar(t *testing.T) {
	ConfirmCar := func(s ISlice, r int) {
		n := s.Car()
		if ok := n == r; !ok {
			t.Fatalf("head should be '%v' but is '%v'", r, n)
		}
	}
	ConfirmCar(ISlice{1, 2, 3}, 1)
}

func TestISliceCdr(t *testing.T) {
	ConfirmCdr := func(s, r ISlice) {
		if n := s.Cdr(); !n.Equal(r) {
			t.Fatalf("tail should be '%v' but is '%v'", r, n)
		}
	}
	ConfirmCdr(ISlice{1, 2, 3}, ISlice{2, 3})
}

func TestISliceRplaca(t *testing.T) {
	ConfirmRplaca := func(s ISlice, v interface{}, r ISlice) {
		if s.Rplaca(v); !s.Equal(r) {
			t.Fatalf("slice should be '%v' but is '%v'", r, s)
		}
	}
	ConfirmRplaca(ISlice{1, 2, 3, 4, 5}, 0, ISlice{0, 2, 3, 4, 5})
}

func TestISliceRplacd(t *testing.T) {
	ConfirmRplacd := func(s ISlice, v interface{}, r ISlice) {
		if s.Rplacd(v); !s.Equal(r) {
			t.Fatalf("slice should be '%v' but is '%v'", r, s)
		}
	}
	ConfirmRplacd(ISlice{1, 2, 3, 4, 5}, nil, ISlice{1})
	ConfirmRplacd(ISlice{1, 2, 3, 4, 5}, 10, ISlice{1, 10})
	ConfirmRplacd(ISlice{1, 2, 3, 4, 5}, ISlice{5, 4, 3, 2}, ISlice{1, 5, 4, 3, 2})
	ConfirmRplacd(ISlice{1, 2, 3, 4, 5, 6}, ISlice{2, 4, 8, 16}, ISlice{1, 2, 4, 8, 16})
}

func TestISliceFind(t *testing.T) {
	ConfirmFind := func(s ISlice, v, i int) {
		if x, ok := s.Find(v); !ok || x != i {
			t.Fatalf("%v.Find(%v) should be %v but is %v, %v", s, v, i, x, ok)
		}
	}

	ConfirmFind(ISlice{0, 1, 2, 3, 4}, 0, 0)
	ConfirmFind(ISlice{0, 1, 2, 3, 4}, 1, 1)
	ConfirmFind(ISlice{0, 1, 2, 4, 3}, 2, 2)
	ConfirmFind(ISlice{0, 1, 2, 4, 3}, 3, 4)
	ConfirmFind(ISlice{0, 1, 2, 4, 3}, 4, 3)
}

func TestISliceFindN(t *testing.T) {
	ConfirmFindN := func(s ISlice, v, n int, i ISlice) {
		if x := s.FindN(v, n); !ISlice(x).Equal(i) {
			t.Fatalf("%v.Find(%v, %v) should be %v but is %v", s, v, n, i, x)
		}
	}

	ConfirmFindN(ISlice{1, 0, 1, 0, 1}, 2, 3, ISlice{})
	ConfirmFindN(ISlice{1, 0, 1, 0, 1}, 1, 0, ISlice{0, 2, 4})
	ConfirmFindN(ISlice{1, 0, 1, 0, 1}, 1, 1, ISlice{0})
	ConfirmFindN(ISlice{1, 0, 1, 0, 1}, 1, 2, ISlice{0, 2})
	ConfirmFindN(ISlice{1, 0, 1, 0, 1}, 1, 3, ISlice{0, 2, 4})
	ConfirmFindN(ISlice{1, 0, 1, 0, 1}, 1, 4, ISlice{0, 2, 4})
}

func TestISliceKeepIf(t *testing.T) {
	ConfirmKeepIf := func(s ISlice, f interface{}, r ISlice) {
		if s.KeepIf(f); !r.Equal(s) {
			t.Fatalf("KeepIf(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmKeepIf(ISlice{0, 1, 0, 3, 0, 5}, int(0), ISlice{0, 0, 0})
	ConfirmKeepIf(ISlice{0, 1, 0, 3, 0, 5}, int(1), ISlice{1})
	ConfirmKeepIf(ISlice{0, 1, 0, 3, 0, 5}, int(6), ISlice{})

	ConfirmKeepIf(ISlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int(0) }, ISlice{0, 0, 0})
	ConfirmKeepIf(ISlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int(1) }, ISlice{1})
	ConfirmKeepIf(ISlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int(6) }, ISlice{})

	ConfirmKeepIf(ISlice{0, 1, 0, 3, 0, 5}, func(x int) bool { return x == int(0) }, ISlice{0, 0, 0})
	ConfirmKeepIf(ISlice{0, 1, 0, 3, 0, 5}, func(x int) bool { return x == int(1) }, ISlice{1})
	ConfirmKeepIf(ISlice{0, 1, 0, 3, 0, 5}, func(x int) bool { return x == int(6) }, ISlice{})
}

func TestISliceReverseEach(t *testing.T) {
	var count	int
	count = 9
	ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(i interface{}) {
		if i != count {
			t.Fatalf("0: element %v erroneously reported as %v", count, i)
		}
		count--
	})

	ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(index int, i interface{}) {
		if index != int(i.(int)) {
			t.Fatalf("1: element %v erroneously reported as %v", index, i)
		}
	})

	ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(key, i interface{}) {
		if int(key.(int)) != i {
			t.Fatalf("2: element %v erroneously reported as %v", key, i)
		}
	})

	count = 9
	ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(i int) {
		if i != count {
			t.Fatalf("3: element %v erroneously reported as %v", count, i)
		}
		count--
	})

	ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(index int, i int) {
		if int(i) != index {
			t.Fatalf("4: element %v erroneously reported as %v", index, i)
		}
	})

	ISlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(key interface{}, i int) {
		if key.(int) != int(i) {
			t.Fatalf("5: element %v erroneously reported as %v", key, i)
		}
	})
}

func TestISliceReplaceIf(t *testing.T) {
	ConfirmReplaceIf := func(s ISlice, f, v interface{}, r ISlice) {
		if s.ReplaceIf(f, v); !r.Equal(s) {
			t.Fatalf("ReplaceIf(%v, %v) should be %v but is %v", f, v, r, s)
		}
	}

	ConfirmReplaceIf(ISlice{0, 1, 0, 3, 0, 5}, int(0), int(1), ISlice{1, 1, 1, 3, 1, 5})
	ConfirmReplaceIf(ISlice{0, 1, 0, 3, 0, 5}, int(1), int(0), ISlice{0, 0, 0, 3, 0, 5})
	ConfirmReplaceIf(ISlice{0, 1, 0, 3, 0, 5}, int(6), int(0), ISlice{0, 1, 0, 3, 0, 5})

	ConfirmReplaceIf(ISlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int(0) }, int(1), ISlice{1, 1, 1, 3, 1, 5})
	ConfirmReplaceIf(ISlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int(1) }, int(0), ISlice{0, 0, 0, 3, 0, 5})
	ConfirmReplaceIf(ISlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int(6) }, int(0), ISlice{0, 1, 0, 3, 0, 5})

	ConfirmReplaceIf(ISlice{0, 1, 0, 3, 0, 5}, func(x int) bool { return x == int(0) }, int(1), ISlice{1, 1, 1, 3, 1, 5})
	ConfirmReplaceIf(ISlice{0, 1, 0, 3, 0, 5}, func(x int) bool { return x == int(1) }, int(0), ISlice{0, 0, 0, 3, 0, 5})
	ConfirmReplaceIf(ISlice{0, 1, 0, 3, 0, 5}, func(x int) bool { return x == int(6) }, int(0), ISlice{0, 1, 0, 3, 0, 5})
}

func TestISliceReplace(t *testing.T) {
	ConfirmReplace := func(s ISlice, v interface{}) {
		if s.Replace(v); !s.Equal(v) {
			t.Fatalf("Replace() should be %v but is %v", s, v)
		}
	}

	ConfirmReplace(ISlice{0, 1, 2, 3, 4, 5}, ISlice{9, 8, 7, 6, 5})
	ConfirmReplace(ISlice{0, 1, 2, 3, 4, 5}, ISlice{9, 8, 7, 6, 5})
	ConfirmReplace(ISlice{0, 1, 2, 3, 4, 5}, []int{9, 8, 7, 6, 5})
}

func TestISliceSelect(t *testing.T) {
	ConfirmSelect := func(s ISlice, f interface{}, r ISlice) {
		if x := s.Select(f); !r.Equal(x) {
			t.Fatalf("Select(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmSelect(ISlice{0, 1, 0, 3, 0, 5}, int(0), ISlice{0, 0, 0})
	ConfirmSelect(ISlice{0, 1, 0, 3, 0, 5}, int(1), ISlice{1})
	ConfirmSelect(ISlice{0, 1, 0, 3, 0, 5}, int(6), ISlice{})

	ConfirmSelect(ISlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int(0) }, ISlice{0, 0, 0})
	ConfirmSelect(ISlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int(1) }, ISlice{1})
	ConfirmSelect(ISlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int(6) }, ISlice{})

	ConfirmSelect(ISlice{0, 1, 0, 3, 0, 5}, func(x int) bool { return x == int(0) }, ISlice{0, 0, 0})
	ConfirmSelect(ISlice{0, 1, 0, 3, 0, 5}, func(x int) bool { return x == int(1) }, ISlice{1})
	ConfirmSelect(ISlice{0, 1, 0, 3, 0, 5}, func(x int) bool { return x == int(6) }, ISlice{})
}

func TestISliceUniq(t *testing.T) {
	ConfirmUniq := func(s, r ISlice) {
		if s.Uniq(); !r.Equal(s) {
			t.Fatalf("Uniq() should be %v but is %v", r, s)
		}
	}

	ConfirmUniq(ISlice{0, 0, 0, 0, 0, 0}, ISlice{0})
	ConfirmUniq(ISlice{0, 1, 0, 3, 0, 5}, ISlice{0, 1, 3, 5})
}

func TestISlicePick(t *testing.T) {
	ConfirmPick := func(s ISlice, i []int, r ISlice) {
		if x := s.Pick(i...); !r.Equal(x) {
			t.Fatalf("%v.Pick(%v) should be %v but is %v", s, i, r, x)
		}
	}

	ConfirmPick(ISlice{0, 1, 2, 3, 4, 5}, []int{}, ISlice{})
	ConfirmPick(ISlice{0, 1, 2, 3, 4, 5}, []int{ 0, 1 }, ISlice{0, 1})
	ConfirmPick(ISlice{0, 1, 2, 3, 4, 5}, []int{ 0, 3 }, ISlice{0, 3})
	ConfirmPick(ISlice{0, 1, 2, 3, 4, 5}, []int{ 0, 3, 4, 3 }, ISlice{0, 3, 4, 3})
}

func TestISliceInsert(t *testing.T) {
	ConfirmInsert := func(s ISlice, n int, v interface{}, r ISlice) {
		if s.Insert(n, v); !r.Equal(s) {
			t.Fatalf("Insert(%v, %v) should be %v but is %v", n, v, r, s)
		}
	}

	ConfirmInsert(ISlice{}, 0, int(0), ISlice{0})
	ConfirmInsert(ISlice{}, 0, ISlice{0}, ISlice{0})
	ConfirmInsert(ISlice{}, 0, ISlice{0, 1}, ISlice{0, 1})

	ConfirmInsert(ISlice{0}, 0, int(1), ISlice{1, 0})
	ConfirmInsert(ISlice{0}, 0, ISlice{1}, ISlice{1, 0})
	ConfirmInsert(ISlice{0}, 1, int(1), ISlice{0, 1})
	ConfirmInsert(ISlice{0}, 1, ISlice{1}, ISlice{0, 1})

	ConfirmInsert(ISlice{0, 1, 2}, 0, int(3), ISlice{3, 0, 1, 2})
	ConfirmInsert(ISlice{0, 1, 2}, 1, int(3), ISlice{0, 3, 1, 2})
	ConfirmInsert(ISlice{0, 1, 2}, 2, int(3), ISlice{0, 1, 3, 2})
	ConfirmInsert(ISlice{0, 1, 2}, 3, int(3), ISlice{0, 1, 2, 3})

	ConfirmInsert(ISlice{0, 1, 2}, 0, ISlice{3, 4}, ISlice{3, 4, 0, 1, 2})
	ConfirmInsert(ISlice{0, 1, 2}, 1, ISlice{3, 4}, ISlice{0, 3, 4, 1, 2})
	ConfirmInsert(ISlice{0, 1, 2}, 2, ISlice{3, 4}, ISlice{0, 1, 3, 4, 2})
	ConfirmInsert(ISlice{0, 1, 2}, 3, ISlice{3, 4}, ISlice{0, 1, 2, 3, 4})
}