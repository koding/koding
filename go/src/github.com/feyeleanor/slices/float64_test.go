package slices

import "testing"

func TestF64SliceString(t *testing.T) {
	ConfirmString := func(s F64Slice, r string) {
		if x := s.String(); x != r {
			t.Fatalf("%v erroneously serialised as '%v'", r, x)
		}
	}

	ConfirmString(F64Slice{}, "()")
	ConfirmString(F64Slice{0}, "(0)")
	ConfirmString(F64Slice{0, 1}, "(0 1)")
}

func TestF64SliceLen(t *testing.T) {
	ConfirmLength := func(s F64Slice, i int) {
		if x := s.Len(); x != i {
			t.Fatalf("%v.Len() should be %v but is %v", s, i, x)
		}
	}
	
	ConfirmLength(F64Slice{0}, 1)
	ConfirmLength(F64Slice{0, 1}, 2)
}

func TestF64SliceSwap(t *testing.T) {
	ConfirmSwap := func(s F64Slice, i, j int, r F64Slice) {
		if s.Swap(i, j); !r.Equal(s) {
			t.Fatalf("Swap(%v, %v) should be %v but is %v", i, j, r, s)
		}
	}
	ConfirmSwap(F64Slice{0, 1, 2}, 0, 1, F64Slice{1, 0, 2})
	ConfirmSwap(F64Slice{0, 1, 2}, 0, 2, F64Slice{2, 1, 0})
}

func TestF64SliceCompare(t *testing.T) {
	ConfirmCompare := func(s F64Slice, i, j, r int) {
		if x := s.Compare(i, j); x != r {
			t.Fatalf("Compare(%v, %v) should be %v but is %v", i, j, r, x)
		}
	}

	ConfirmCompare(F64Slice{0, 1}, 0, 0, IS_SAME_AS)
	ConfirmCompare(F64Slice{0, 1}, 0, 1, IS_LESS_THAN)
	ConfirmCompare(F64Slice{0, 1}, 1, 0, IS_GREATER_THAN)
}

func TestF64SliceZeroCompare(t *testing.T) {
	ConfirmCompare := func(s F64Slice, i, r int) {
		if x := s.ZeroCompare(i); x != r {
			t.Fatalf("ZeroCompare(%v) should be %v but is %v", i, r, x)
		}
	}

	ConfirmCompare(F64Slice{0, -1, 1}, 0, IS_SAME_AS)
	ConfirmCompare(F64Slice{0, -1, 1}, 1, IS_GREATER_THAN)
	ConfirmCompare(F64Slice{0, -1, 1}, 2, IS_LESS_THAN)
}

func TestF64SliceCut(t *testing.T) {
	ConfirmCut := func(s F64Slice, start, end int, r F64Slice) {
		if s.Cut(start, end); !r.Equal(s) {
			t.Fatalf("Cut(%v, %v) should be %v but is %v", start, end, r, s)
		}
	}

	ConfirmCut(F64Slice{0, 1, 2, 3, 4, 5}, 0, 1, F64Slice{1, 2, 3, 4, 5})
	ConfirmCut(F64Slice{0, 1, 2, 3, 4, 5}, 1, 2, F64Slice{0, 2, 3, 4, 5})
	ConfirmCut(F64Slice{0, 1, 2, 3, 4, 5}, 2, 3, F64Slice{0, 1, 3, 4, 5})
	ConfirmCut(F64Slice{0, 1, 2, 3, 4, 5}, 3, 4, F64Slice{0, 1, 2, 4, 5})
	ConfirmCut(F64Slice{0, 1, 2, 3, 4, 5}, 4, 5, F64Slice{0, 1, 2, 3, 5})
	ConfirmCut(F64Slice{0, 1, 2, 3, 4, 5}, 5, 6, F64Slice{0, 1, 2, 3, 4})

	ConfirmCut(F64Slice{0, 1, 2, 3, 4, 5}, -1, 1, F64Slice{1, 2, 3, 4, 5})
	ConfirmCut(F64Slice{0, 1, 2, 3, 4, 5}, 0, 2, F64Slice{2, 3, 4, 5})
	ConfirmCut(F64Slice{0, 1, 2, 3, 4, 5}, 1, 3, F64Slice{0, 3, 4, 5})
	ConfirmCut(F64Slice{0, 1, 2, 3, 4, 5}, 2, 4, F64Slice{0, 1, 4, 5})
	ConfirmCut(F64Slice{0, 1, 2, 3, 4, 5}, 3, 5, F64Slice{0, 1, 2, 5})
	ConfirmCut(F64Slice{0, 1, 2, 3, 4, 5}, 4, 6, F64Slice{0, 1, 2, 3})
	ConfirmCut(F64Slice{0, 1, 2, 3, 4, 5}, 5, 7, F64Slice{0, 1, 2, 3, 4})
}

func TestF64SliceTrim(t *testing.T) {
	ConfirmTrim := func(s F64Slice, start, end int, r F64Slice) {
		if s.Trim(start, end); !r.Equal(s) {
			t.Fatalf("Trim(%v, %v) should be %v but is %v", start, end, r, s)
		}
	}

	ConfirmTrim(F64Slice{0, 1, 2, 3, 4, 5}, 0, 1, F64Slice{0})
	ConfirmTrim(F64Slice{0, 1, 2, 3, 4, 5}, 1, 2, F64Slice{1})
	ConfirmTrim(F64Slice{0, 1, 2, 3, 4, 5}, 2, 3, F64Slice{2})
	ConfirmTrim(F64Slice{0, 1, 2, 3, 4, 5}, 3, 4, F64Slice{3})
	ConfirmTrim(F64Slice{0, 1, 2, 3, 4, 5}, 4, 5, F64Slice{4})
	ConfirmTrim(F64Slice{0, 1, 2, 3, 4, 5}, 5, 6, F64Slice{5})

	ConfirmTrim(F64Slice{0, 1, 2, 3, 4, 5}, -1, 1, F64Slice{0})
	ConfirmTrim(F64Slice{0, 1, 2, 3, 4, 5}, 0, 2, F64Slice{0, 1})
	ConfirmTrim(F64Slice{0, 1, 2, 3, 4, 5}, 1, 3, F64Slice{1, 2})
	ConfirmTrim(F64Slice{0, 1, 2, 3, 4, 5}, 2, 4, F64Slice{2, 3})
	ConfirmTrim(F64Slice{0, 1, 2, 3, 4, 5}, 3, 5, F64Slice{3, 4})
	ConfirmTrim(F64Slice{0, 1, 2, 3, 4, 5}, 4, 6, F64Slice{4, 5})
	ConfirmTrim(F64Slice{0, 1, 2, 3, 4, 5}, 5, 7, F64Slice{5})
}

func TestF64SliceDelete(t *testing.T) {
	ConfirmDelete := func(s F64Slice, index int, r F64Slice) {
		if s.Delete(index); !r.Equal(s) {
			t.Fatalf("Delete(%v) should be %v but is %v", index, r, s)
		}
	}

	ConfirmDelete(F64Slice{0, 1, 2, 3, 4, 5}, -1, F64Slice{0, 1, 2, 3, 4, 5})
	ConfirmDelete(F64Slice{0, 1, 2, 3, 4, 5}, 0, F64Slice{1, 2, 3, 4, 5})
	ConfirmDelete(F64Slice{0, 1, 2, 3, 4, 5}, 1, F64Slice{0, 2, 3, 4, 5})
	ConfirmDelete(F64Slice{0, 1, 2, 3, 4, 5}, 2, F64Slice{0, 1, 3, 4, 5})
	ConfirmDelete(F64Slice{0, 1, 2, 3, 4, 5}, 3, F64Slice{0, 1, 2, 4, 5})
	ConfirmDelete(F64Slice{0, 1, 2, 3, 4, 5}, 4, F64Slice{0, 1, 2, 3, 5})
	ConfirmDelete(F64Slice{0, 1, 2, 3, 4, 5}, 5, F64Slice{0, 1, 2, 3, 4})
	ConfirmDelete(F64Slice{0, 1, 2, 3, 4, 5}, 6, F64Slice{0, 1, 2, 3, 4, 5})
}

func TestF64SliceDeleteIf(t *testing.T) {
	ConfirmDeleteIf := func(s F64Slice, f interface{}, r F64Slice) {
		if s.DeleteIf(f); !r.Equal(s) {
			t.Fatalf("DeleteIf(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmDeleteIf(F64Slice{0, 1, 0, 3, 0, 5}, float64(0), F64Slice{1, 3, 5})
	ConfirmDeleteIf(F64Slice{0, 1, 0, 3, 0, 5}, float64(1), F64Slice{0, 0, 3, 0, 5})
	ConfirmDeleteIf(F64Slice{0, 1, 0, 3, 0, 5}, float64(6), F64Slice{0, 1, 0, 3, 0, 5})

	ConfirmDeleteIf(F64Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == float64(0) }, F64Slice{1, 3, 5})
	ConfirmDeleteIf(F64Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == float64(1) }, F64Slice{0, 0, 3, 0, 5})
	ConfirmDeleteIf(F64Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == float64(6) }, F64Slice{0, 1, 0, 3, 0, 5})

	ConfirmDeleteIf(F64Slice{0, 1, 0, 3, 0, 5}, func(x float64) bool { return x == float64(0) }, F64Slice{1, 3, 5})
	ConfirmDeleteIf(F64Slice{0, 1, 0, 3, 0, 5}, func(x float64) bool { return x == float64(1) }, F64Slice{0, 0, 3, 0, 5})
	ConfirmDeleteIf(F64Slice{0, 1, 0, 3, 0, 5}, func(x float64) bool { return x == float64(6) }, F64Slice{0, 1, 0, 3, 0, 5})
}

func TestF64SliceEach(t *testing.T) {
	count := 0
	F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(i interface{}) {
		if i != float64(count) {
			t.Fatalf("element %v erroneously reported as %v", count, i)
		}
		count++
	})

	F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(index int, i interface{}) {
		if i != float64(index) {
			t.Fatalf("element %v erroneously reported as %v", index, i)
		}
	})

	F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(key, i interface{}) {
		if i != float64(key.(int)) {
			t.Fatalf("element %v erroneously reported as %v", key, i)
		}
	})

	count = 0
	F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(f float64) {
		if f != float64(count) {
			t.Fatalf("element %v erroneously reported as %v", count, f)
		}
		count++
	})

	F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(index int, f float64) {
		if f != float64(index) {
			t.Fatalf("element %v erroneously reported as %v", index, f)
		}
	})

	F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(key interface{}, f float64) {
		if f != float64(key.(int)) {
			t.Fatalf("element %v erroneously reported as %v", key, f)
		}
	})
}

func TestF64SliceWhile(t *testing.T) {
	ConfirmLimit := func(s F64Slice, l int, f interface{}) {
		if count := s.While(f); count != l {
			t.Fatalf("%v.While() should have iterated %v times not %v times", s, l, count)
		}
	}

	s := F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}
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
	ConfirmLimit(s, limit, func(i float64) bool {
		if count == limit {
			return false
		}
		count++
		return true
	})

	ConfirmLimit(s, limit, func(index int, i float64) bool {
		return index != limit
	})

	ConfirmLimit(s, limit, func(key interface{}, i float64) bool {
		return key.(int) != limit
	})
}

func TestF64SliceUntil(t *testing.T) {
	ConfirmLimit := func(s F64Slice, l int, f interface{}) {
		if count := s.Until(f); count != l {
			t.Fatalf("%v.Until() should have iterated %v times not %v times", s, l, count)
		}
	}

	s := F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}
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
	ConfirmLimit(s, limit, func(i float64) bool {
		if count == limit {
			return true
		}
		count++
		return false
	})

	ConfirmLimit(s, limit, func(index int, i float64) bool {
		return index == limit
	})

	ConfirmLimit(s, limit, func(key interface{}, i float64) bool {
		return key.(int) == limit
	})
}

func TestF64SliceBlockCopy(t *testing.T) {
	ConfirmBlockCopy := func(s F64Slice, destination, source, count int, r F64Slice) {
		s.BlockCopy(destination, source, count)
		if !r.Equal(s) {
			t.Fatalf("BlockCopy(%v, %v, %v) should be %v but is %v", destination, source, count, r, s)
		}
	}

	ConfirmBlockCopy(F64Slice{}, 0, 0, 1, F64Slice{})
	ConfirmBlockCopy(F64Slice{}, 1, 0, 1, F64Slice{})
	ConfirmBlockCopy(F64Slice{}, 0, 1, 1, F64Slice{})

	ConfirmBlockCopy(F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 0, 0, 4, F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 9, 9, 4, F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 9, 0, 4, F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 0})
	ConfirmBlockCopy(F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 0, 4, F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 10, 4, F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, 2, 4, F64Slice{0, 1, 2, 3, 4, 2, 3, 4, 5, 9})
	ConfirmBlockCopy(F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 2, 5, 4, F64Slice{0, 1, 5, 6, 7, 8, 6, 7, 8, 9})
}

func TestF64SliceBlockClear(t *testing.T) {
	ConfirmBlockClear := func(s F64Slice, start, count int, r F64Slice) {
		s.BlockClear(start, count)
		if !r.Equal(s) {
			t.Fatalf("BlockClear(%v, %v) should be %v but is %v", start, count, r, s)
		}
	}

	ConfirmBlockClear(F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 0, 4, F64Slice{0, 0, 0, 0, 4, 5, 6, 7, 8, 9})
	ConfirmBlockClear(F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 4, F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockClear(F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, 4, F64Slice{0, 1, 2, 3, 4, 0, 0, 0, 0, 9})
}

func TestF64SliceOverwrite(t *testing.T) {
	ConfirmOverwrite := func(s F64Slice, offset int, v, r F64Slice) {
		s.Overwrite(offset, v)
		if !r.Equal(s) {
			t.Fatalf("Overwrite(%v, %v) should be %v but is %v", offset, v, r, s)
		}
	}

	ConfirmOverwrite(F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 0, F64Slice{10, 9, 8, 7}, F64Slice{10, 9, 8, 7, 4, 5, 6, 7, 8, 9})
	ConfirmOverwrite(F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, F64Slice{10, 9, 8, 7}, F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmOverwrite(F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, F64Slice{11, 12, 13, 14}, F64Slice{0, 1, 2, 3, 4, 11, 12, 13, 14, 9})
}

func TestF64SliceReallocate(t *testing.T) {
	ConfirmReallocate := func(s F64Slice, l, c int, r F64Slice) {
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

	ConfirmReallocate(F64Slice{}, 0, 10, make(F64Slice, 0, 10))
	ConfirmReallocate(F64Slice{0, 1, 2, 3, 4}, 3, 10, F64Slice{0, 1, 2})
	ConfirmReallocate(F64Slice{0, 1, 2, 3, 4}, 5, 10, F64Slice{0, 1, 2, 3, 4})
	ConfirmReallocate(F64Slice{0, 1, 2, 3, 4}, 10, 10, F64Slice{0, 1, 2, 3, 4, 0, 0, 0, 0, 0})
	ConfirmReallocate(F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 1, 5, F64Slice{0})
	ConfirmReallocate(F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, 5, F64Slice{0, 1, 2, 3, 4})
	ConfirmReallocate(F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 5, F64Slice{0, 1, 2, 3, 4})
}

func TestF64SliceExtend(t *testing.T) {
	ConfirmExtend := func(s F64Slice, n int, r F64Slice) {
		c := s.Cap()
		s.Extend(n)
		switch {
		case s.Len() != r.Len():	t.Fatalf("Extend(%v) len should be %v but is %v", n, r.Len(), s.Len())
		case s.Cap() != c + n:		t.Fatalf("Extend(%v) cap should be %v but is %v", n, c + n, s.Cap())
		case !r.Equal(s):			t.Fatalf("Extend(%v) should be %v but is %v", n, r, s)
		}
	}

	ConfirmExtend(F64Slice{}, 1, F64Slice{0})
	ConfirmExtend(F64Slice{}, 2, F64Slice{0, 0})
}

func TestF64SliceExpand(t *testing.T) {
	ConfirmExpand := func(s F64Slice, i, n int, r F64Slice) {
		c := s.Cap()
		s.Expand(i, n)
		switch {
		case s.Len() != r.Len():	t.Fatalf("Expand(%v, %v) len should be %v but is %v", i, n, r.Len(), s.Len())
		case s.Cap() != c + n:		t.Fatalf("Expand(%v, %v) cap should be %v but is %v", i, n, c + n, s.Cap())
		case !r.Equal(s):			t.Fatalf("Expand(%v, %v) should be %v but is %v", i, n, r, s)
		}
	}

	ConfirmExpand(F64Slice{}, -1, 1, F64Slice{0})
	ConfirmExpand(F64Slice{}, 0, 1, F64Slice{0})
	ConfirmExpand(F64Slice{}, 1, 1, F64Slice{0})
	ConfirmExpand(F64Slice{}, 0, 2, F64Slice{0, 0})

	ConfirmExpand(F64Slice{0, 1, 2}, -1, 2, F64Slice{0, 0, 0, 1, 2})
	ConfirmExpand(F64Slice{0, 1, 2}, 0, 2, F64Slice{0, 0, 0, 1, 2})
	ConfirmExpand(F64Slice{0, 1, 2}, 1, 2, F64Slice{0, 0, 0, 1, 2})
	ConfirmExpand(F64Slice{0, 1, 2}, 2, 2, F64Slice{0, 1, 0, 0, 2})
	ConfirmExpand(F64Slice{0, 1, 2}, 3, 2, F64Slice{0, 1, 2, 0, 0})
	ConfirmExpand(F64Slice{0, 1, 2}, 4, 2, F64Slice{0, 1, 2, 0, 0})
}

func TestF64SliceDepth(t *testing.T) {
	ConfirmDepth := func(s F64Slice, i int) {
		if x := s.Depth(); x != i {
			t.Fatalf("%v.Depth() should be %v but is %v", s, i, x)
		}
	}
	ConfirmDepth(F64Slice{0, 1}, 0)
}

func TestF64SliceReverse(t *testing.T) {
	ConfirmReverse := func(s, r F64Slice) {
		if s.Reverse(); !Equal(s, r) {
			t.Fatalf("Reverse() should be %v but is %v", r, s)
		}
	}
	ConfirmReverse(F64Slice{}, F64Slice{})
	ConfirmReverse(F64Slice{1}, F64Slice{1})
	ConfirmReverse(F64Slice{1, 2}, F64Slice{2, 1})
	ConfirmReverse(F64Slice{1, 2, 3}, F64Slice{3, 2, 1})
	ConfirmReverse(F64Slice{1, 2, 3, 4}, F64Slice{4, 3, 2, 1})
}

func TestF64SliceAppend(t *testing.T) {
	ConfirmAppend := func(s F64Slice, v interface{}, r F64Slice) {
		s.Append(v)
		if !r.Equal(s) {
			t.Fatalf("Append(%v) should be %v but is %v", v, r, s)
		}
	}

	ConfirmAppend(F64Slice{}, float64(0), F64Slice{0})

	ConfirmAppend(F64Slice{}, F64Slice{0}, F64Slice{0})
	ConfirmAppend(F64Slice{}, F64Slice{0, 1}, F64Slice{0, 1})
	ConfirmAppend(F64Slice{0, 1, 2}, F64Slice{3, 4}, F64Slice{0, 1, 2, 3, 4})
}

func TestF64SlicePrepend(t *testing.T) {
	ConfirmPrepend := func(s F64Slice, v interface{}, r F64Slice) {
		if s.Prepend(v); !r.Equal(s) {
			t.Fatalf("Prepend(%v) should be %v but is %v", v, r, s)
		}
	}

	ConfirmPrepend(F64Slice{}, float64(0), F64Slice{0})
	ConfirmPrepend(F64Slice{0}, float64(1), F64Slice{1, 0})

	ConfirmPrepend(F64Slice{}, F64Slice{0}, F64Slice{0})
	ConfirmPrepend(F64Slice{}, F64Slice{0, 1}, F64Slice{0, 1})
	ConfirmPrepend(F64Slice{0, 1, 2}, F64Slice{3, 4}, F64Slice{3, 4, 0, 1, 2})
}

func TestF64SliceRepeat(t *testing.T) {
	ConfirmRepeat := func(s F64Slice, count int, r F64Slice) {
		if x := s.Repeat(count); !x.Equal(r) {
			t.Fatalf("%v.Repeat(%v) should be %v but is %v", s, count, r, x)
		}
	}

	ConfirmRepeat(F64Slice{}, 5, F64Slice{})
	ConfirmRepeat(F64Slice{0}, 1, F64Slice{0})
	ConfirmRepeat(F64Slice{0}, 2, F64Slice{0, 0})
	ConfirmRepeat(F64Slice{0}, 3, F64Slice{0, 0, 0})
	ConfirmRepeat(F64Slice{0}, 4, F64Slice{0, 0, 0, 0})
	ConfirmRepeat(F64Slice{0}, 5, F64Slice{0, 0, 0, 0, 0})
}

func TestF64SliceCar(t *testing.T) {
	ConfirmCar := func(s F64Slice, r float64) {
		n := s.Car()
		if ok := n == r; !ok {
			t.Fatalf("head should be '%v' but is '%v'", r, n)
		}
	}
	ConfirmCar(F64Slice{1, 2, 3}, 1)
}

func TestF64SliceCdr(t *testing.T) {
	ConfirmCdr := func(s, r F64Slice) {
		if n := s.Cdr(); !n.Equal(r) {
			t.Fatalf("tail should be '%v' but is '%v'", r, n)
		}
	}
	ConfirmCdr(F64Slice{1, 2, 3}, F64Slice{2, 3})
}

func TestF64SliceRplaca(t *testing.T) {
	ConfirmRplaca := func(s F64Slice, v interface{}, r F64Slice) {
		if s.Rplaca(v); !s.Equal(r) {
			t.Fatalf("slice should be '%v' but is '%v'", r, s)
		}
	}
	ConfirmRplaca(F64Slice{1, 2, 3, 4, 5}, float64(0), F64Slice{0, 2, 3, 4, 5})
}

func TestF64SliceRplacd(t *testing.T) {
	ConfirmRplacd := func(s F64Slice, v interface{}, r F64Slice) {
		if s.Rplacd(v); !s.Equal(r) {
			t.Fatalf("slice should be '%v' but is '%v'", r, s)
		}
	}
	ConfirmRplacd(F64Slice{1, 2, 3, 4, 5}, nil, F64Slice{1})
	ConfirmRplacd(F64Slice{1, 2, 3, 4, 5}, float64(10), F64Slice{1, 10})
	ConfirmRplacd(F64Slice{1, 2, 3, 4, 5}, F64Slice{5, 4, 3, 2}, F64Slice{1, 5, 4, 3, 2})
	ConfirmRplacd(F64Slice{1, 2, 3, 4, 5, 6}, F64Slice{2, 4, 8, 16}, F64Slice{1, 2, 4, 8, 16})
}

func TestF64SliceFind(t *testing.T) {
	ConfirmFind := func(s F64Slice, v float64, i int) {
		if x, ok := s.Find(v); !ok && x != i {
			t.Fatalf("%v.Find(%v) should be %v but is %v", s, v, i, x)
		}
	}

	ConfirmFind(F64Slice{0, 1, 2, 3, 4}, 0, 0)
	ConfirmFind(F64Slice{0, 1, 2, 3, 4}, 1, 1)
	ConfirmFind(F64Slice{0, 1, 2, 4, 3}, 2, 2)
	ConfirmFind(F64Slice{0, 1, 2, 4, 3}, 3, 4)
	ConfirmFind(F64Slice{0, 1, 2, 4, 3}, 4, 3)
}

func TestF64SliceFindN(t *testing.T) {
	ConfirmFindN := func(s F64Slice, v float64, n int, i ISlice) {
		if x := s.FindN(v, n); !x.Equal(i) {
			t.Fatalf("%v.Find(%v, %v) should be %v but is %v", s, v, n, i, x)
		}
	}

	ConfirmFindN(F64Slice{1, 0, 1, 0, 1}, 2, 3, ISlice{})
	ConfirmFindN(F64Slice{1, 0, 1, 0, 1}, 1, 0, ISlice{0, 2, 4})
	ConfirmFindN(F64Slice{1, 0, 1, 0, 1}, 1, 1, ISlice{0})
	ConfirmFindN(F64Slice{1, 0, 1, 0, 1}, 1, 2, ISlice{0, 2})
	ConfirmFindN(F64Slice{1, 0, 1, 0, 1}, 1, 3, ISlice{0, 2, 4})
	ConfirmFindN(F64Slice{1, 0, 1, 0, 1}, 1, 4, ISlice{0, 2, 4})
}

func TestF64SliceKeepIf(t *testing.T) {
	ConfirmKeepIf := func(s F64Slice, f interface{}, r F64Slice) {
		if s.KeepIf(f); !r.Equal(s) {
			t.Fatalf("KeepIf(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmKeepIf(F64Slice{0, 1, 0, 3, 0, 5}, float64(0), F64Slice{0, 0, 0})
	ConfirmKeepIf(F64Slice{0, 1, 0, 3, 0, 5}, float64(1), F64Slice{1})
	ConfirmKeepIf(F64Slice{0, 1, 0, 3, 0, 5}, float64(6), F64Slice{})

	ConfirmKeepIf(F64Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == float64(0) }, F64Slice{0, 0, 0})
	ConfirmKeepIf(F64Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == float64(1) }, F64Slice{1})
	ConfirmKeepIf(F64Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == float64(6) }, F64Slice{})

	ConfirmKeepIf(F64Slice{0, 1, 0, 3, 0, 5}, func(x float64) bool { return x == float64(0) }, F64Slice{0, 0, 0})
	ConfirmKeepIf(F64Slice{0, 1, 0, 3, 0, 5}, func(x float64) bool { return x == float64(1) }, F64Slice{1})
	ConfirmKeepIf(F64Slice{0, 1, 0, 3, 0, 5}, func(x float64) bool { return x == float64(6) }, F64Slice{})
}

func TestF64SliceReverseEach(t *testing.T) {
	var count	float64
	count = 9
	F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(i interface{}) {
		if i != count {
			t.Fatalf("0: element %v erroneously reported as %v", count, i)
		}
		count--
	})

	F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(index int, i interface{}) {
		if index != int(i.(float64)) {
			t.Fatalf("1: element %v erroneously reported as %v", index, i)
		}
	})

	F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(key, i interface{}) {
		if float64(key.(int)) != i {
			t.Fatalf("2: element %v erroneously reported as %v", key, i)
		}
	})

	count = 9
	F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(i float64) {
		if i != count {
			t.Fatalf("3: element %v erroneously reported as %v", count, i)
		}
		count--
	})

	F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(index int, i float64) {
		if int(i) != index {
			t.Fatalf("4: element %v erroneously reported as %v", index, i)
		}
	})

	F64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(key interface{}, i float64) {
		if key.(int) != int(i) {
			t.Fatalf("5: element %v erroneously reported as %v", key, i)
		}
	})
}

func TestF64SliceReplaceIf(t *testing.T) {
	ConfirmReplaceIf := func(s F64Slice, f, v interface{}, r F64Slice) {
		if s.ReplaceIf(f, v); !r.Equal(s) {
			t.Fatalf("ReplaceIf(%v, %v) should be %v but is %v", f, v, r, s)
		}
	}

	ConfirmReplaceIf(F64Slice{0, 1, 0, 3, 0, 5}, float64(0), float64(1), F64Slice{1, 1, 1, 3, 1, 5})
	ConfirmReplaceIf(F64Slice{0, 1, 0, 3, 0, 5}, float64(1), float64(0), F64Slice{0, 0, 0, 3, 0, 5})
	ConfirmReplaceIf(F64Slice{0, 1, 0, 3, 0, 5}, float64(6), float64(0), F64Slice{0, 1, 0, 3, 0, 5})

	ConfirmReplaceIf(F64Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == float64(0) }, float64(1), F64Slice{1, 1, 1, 3, 1, 5})
	ConfirmReplaceIf(F64Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == float64(1) }, float64(0), F64Slice{0, 0, 0, 3, 0, 5})
	ConfirmReplaceIf(F64Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == float64(6) }, float64(0), F64Slice{0, 1, 0, 3, 0, 5})

	ConfirmReplaceIf(F64Slice{0, 1, 0, 3, 0, 5}, func(x float64) bool { return x == float64(0) }, float64(1), F64Slice{1, 1, 1, 3, 1, 5})
	ConfirmReplaceIf(F64Slice{0, 1, 0, 3, 0, 5}, func(x float64) bool { return x == float64(1) }, float64(0), F64Slice{0, 0, 0, 3, 0, 5})
	ConfirmReplaceIf(F64Slice{0, 1, 0, 3, 0, 5}, func(x float64) bool { return x == float64(6) }, float64(0), F64Slice{0, 1, 0, 3, 0, 5})
}

func TestF64SliceReplace(t *testing.T) {
	ConfirmReplace := func(s F64Slice, v interface{}) {
		if s.Replace(v); !s.Equal(v) {
			t.Fatalf("Replace() should be %v but is %v", s, v)
		}
	}

	ConfirmReplace(F64Slice{0, 1, 2, 3, 4, 5}, F64Slice{9, 8, 7, 6, 5})
	ConfirmReplace(F64Slice{0, 1, 2, 3, 4, 5}, F64Slice{ 9, 8, 7, 6, 5 })
	ConfirmReplace(F64Slice{0, 1, 2, 3, 4, 5}, []float64{ 9, 8, 7, 6, 5 })
}

func TestF64SliceSelect(t *testing.T) {
	ConfirmSelect := func(s F64Slice, f interface{}, r F64Slice) {
		if x := s.Select(f); !r.Equal(x) {
			t.Fatalf("Select(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmSelect(F64Slice{0, 1, 0, 3, 0, 5}, float64(0), F64Slice{0, 0, 0})
	ConfirmSelect(F64Slice{0, 1, 0, 3, 0, 5}, float64(1), F64Slice{1})
	ConfirmSelect(F64Slice{0, 1, 0, 3, 0, 5}, float64(6), F64Slice{})

	ConfirmSelect(F64Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == float64(0) }, F64Slice{0, 0, 0})
	ConfirmSelect(F64Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == float64(1) }, F64Slice{1})
	ConfirmSelect(F64Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == float64(6) }, F64Slice{})

	ConfirmSelect(F64Slice{0, 1, 0, 3, 0, 5}, func(x float64) bool { return x == float64(0) }, F64Slice{0, 0, 0})
	ConfirmSelect(F64Slice{0, 1, 0, 3, 0, 5}, func(x float64) bool { return x == float64(1) }, F64Slice{1})
	ConfirmSelect(F64Slice{0, 1, 0, 3, 0, 5}, func(x float64) bool { return x == float64(6) }, F64Slice{})
}

func TestF64SliceUniq(t *testing.T) {
	ConfirmUniq := func(s, r F64Slice) {
		if s.Uniq(); !r.Equal(s) {
			t.Fatalf("Uniq() should be %v but is %v", r, s)
		}
	}

	ConfirmUniq(F64Slice{0, 0, 0, 0, 0, 0}, F64Slice{0})
	ConfirmUniq(F64Slice{0, 1, 0, 3, 0, 5}, F64Slice{0, 1, 3, 5})
}

func TestF64SlicePick(t *testing.T) {
	ConfirmPick := func(s F64Slice, i []int, r F64Slice) {
		if x := s.Pick(i...); !r.Equal(x) {
			t.Fatalf("%v.Pick(%v) should be %v but is %v", s, i, r, x)
		}
	}

	ConfirmPick(F64Slice{0, 1, 2, 3, 4, 5}, []int{}, F64Slice{})
	ConfirmPick(F64Slice{0, 1, 2, 3, 4, 5}, []int{ 0, 1 }, F64Slice{0, 1})
	ConfirmPick(F64Slice{0, 1, 2, 3, 4, 5}, []int{ 0, 3 }, F64Slice{0, 3})
	ConfirmPick(F64Slice{0, 1, 2, 3, 4, 5}, []int{ 0, 3, 4, 3 }, F64Slice{0, 3, 4, 3})
}

func TestF64SliceInsert(t *testing.T) {
	ConfirmInsert := func(s F64Slice, n int, v interface{}, r F64Slice) {
		if s.Insert(n, v); !r.Equal(s) {
			t.Fatalf("Insert(%v, %v) should be %v but is %v", n, v, r, s)
		}
	}

	ConfirmInsert(F64Slice{}, 0, float64(0), F64Slice{0})
	ConfirmInsert(F64Slice{}, 0, F64Slice{0}, F64Slice{0})
	ConfirmInsert(F64Slice{}, 0, F64Slice{0, 1}, F64Slice{0, 1})

	ConfirmInsert(F64Slice{0}, 0, float64(1), F64Slice{1, 0})
	ConfirmInsert(F64Slice{0}, 0, F64Slice{1}, F64Slice{1, 0})
	ConfirmInsert(F64Slice{0}, 1, float64(1), F64Slice{0, 1})
	ConfirmInsert(F64Slice{0}, 1, F64Slice{1}, F64Slice{0, 1})

	ConfirmInsert(F64Slice{0, 1, 2}, 0, float64(3), F64Slice{3, 0, 1, 2})
	ConfirmInsert(F64Slice{0, 1, 2}, 1, float64(3), F64Slice{0, 3, 1, 2})
	ConfirmInsert(F64Slice{0, 1, 2}, 2, float64(3), F64Slice{0, 1, 3, 2})
	ConfirmInsert(F64Slice{0, 1, 2}, 3, float64(3), F64Slice{0, 1, 2, 3})

	ConfirmInsert(F64Slice{0, 1, 2}, 0, F64Slice{3, 4}, F64Slice{3, 4, 0, 1, 2})
	ConfirmInsert(F64Slice{0, 1, 2}, 1, F64Slice{3, 4}, F64Slice{0, 3, 4, 1, 2})
	ConfirmInsert(F64Slice{0, 1, 2}, 2, F64Slice{3, 4}, F64Slice{0, 1, 3, 4, 2})
	ConfirmInsert(F64Slice{0, 1, 2}, 3, F64Slice{3, 4}, F64Slice{0, 1, 2, 3, 4})
}