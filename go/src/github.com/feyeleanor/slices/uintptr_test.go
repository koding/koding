package slices

import "testing"

func TestASliceString(t *testing.T) {
	ConfirmString := func(s ASlice, r string) {
		if x := s.String(); x != r {
			t.Fatalf("%v erroneously serialised as '%v'", r, x)
		}
	}

	ConfirmString(ASlice{}, "()")
	ConfirmString(ASlice{0}, "(0)")
	ConfirmString(ASlice{0, 1}, "(0 1)")
}

func TestASliceLen(t *testing.T) {
	ConfirmLength := func(s ASlice, i int) {
		if x := s.Len(); x != i {
			t.Fatalf("%v.Len() should be %v but is %v", s, i, x)
		}
	}
	
	ConfirmLength(ASlice{0}, 1)
	ConfirmLength(ASlice{0, 1}, 2)
}

func TestASliceSwap(t *testing.T) {
	ConfirmSwap := func(s ASlice, i, j int, r ASlice) {
		if s.Swap(i, j); !r.Equal(s) {
			t.Fatalf("Swap(%v, %v) should be %v but is %v", i, j, r, s)
		}
	}
	ConfirmSwap(ASlice{0, 1, 2}, 0, 1, ASlice{1, 0, 2})
	ConfirmSwap(ASlice{0, 1, 2}, 0, 2, ASlice{2, 1, 0})
}

func TestASliceCompare(t *testing.T) {
	ConfirmCompare := func(s ASlice, i, j, r int) {
		if x := s.Compare(i, j); x != r {
			t.Fatalf("Compare(%v, %v) should be %v but is %v", i, j, r, x)
		}
	}

	ConfirmCompare(ASlice{0, 1}, 0, 0, IS_SAME_AS)
	ConfirmCompare(ASlice{0, 1}, 0, 1, IS_LESS_THAN)
	ConfirmCompare(ASlice{0, 1}, 1, 0, IS_GREATER_THAN)
}

func TestASliceZeroCompare(t *testing.T) {
	ConfirmCompare := func(s ASlice, i, r int) {
		if x := s.ZeroCompare(i); x != r {
			t.Fatalf("ZeroCompare(%v) should be %v but is %v", i, r, x)
		}
	}

	ConfirmCompare(ASlice{1, 0, 2}, 0, IS_LESS_THAN)
	ConfirmCompare(ASlice{1, 0, 2}, 1, IS_SAME_AS)
	ConfirmCompare(ASlice{1, 0, 3}, 2, IS_LESS_THAN)
}

func TestASliceCut(t *testing.T) {
	ConfirmCut := func(s ASlice, start, end int, r ASlice) {
		if s.Cut(start, end); !r.Equal(s) {
			t.Fatalf("Cut(%v, %v) should be %v but is %v", start, end, r, s)
		}
	}

	ConfirmCut(ASlice{0, 1, 2, 3, 4, 5}, 0, 1, ASlice{1, 2, 3, 4, 5})
	ConfirmCut(ASlice{0, 1, 2, 3, 4, 5}, 1, 2, ASlice{0, 2, 3, 4, 5})
	ConfirmCut(ASlice{0, 1, 2, 3, 4, 5}, 2, 3, ASlice{0, 1, 3, 4, 5})
	ConfirmCut(ASlice{0, 1, 2, 3, 4, 5}, 3, 4, ASlice{0, 1, 2, 4, 5})
	ConfirmCut(ASlice{0, 1, 2, 3, 4, 5}, 4, 5, ASlice{0, 1, 2, 3, 5})
	ConfirmCut(ASlice{0, 1, 2, 3, 4, 5}, 5, 6, ASlice{0, 1, 2, 3, 4})

	ConfirmCut(ASlice{0, 1, 2, 3, 4, 5}, -1, 1, ASlice{1, 2, 3, 4, 5})
	ConfirmCut(ASlice{0, 1, 2, 3, 4, 5}, 0, 2, ASlice{2, 3, 4, 5})
	ConfirmCut(ASlice{0, 1, 2, 3, 4, 5}, 1, 3, ASlice{0, 3, 4, 5})
	ConfirmCut(ASlice{0, 1, 2, 3, 4, 5}, 2, 4, ASlice{0, 1, 4, 5})
	ConfirmCut(ASlice{0, 1, 2, 3, 4, 5}, 3, 5, ASlice{0, 1, 2, 5})
	ConfirmCut(ASlice{0, 1, 2, 3, 4, 5}, 4, 6, ASlice{0, 1, 2, 3})
	ConfirmCut(ASlice{0, 1, 2, 3, 4, 5}, 5, 7, ASlice{0, 1, 2, 3, 4})
}

func TestASliceTrim(t *testing.T) {
	ConfirmTrim := func(s ASlice, start, end int, r ASlice) {
		if s.Trim(start, end); !r.Equal(s) {
			t.Fatalf("Trim(%v, %v) should be %v but is %v", start, end, r, s)
		}
	}

	ConfirmTrim(ASlice{0, 1, 2, 3, 4, 5}, 0, 1, ASlice{0})
	ConfirmTrim(ASlice{0, 1, 2, 3, 4, 5}, 1, 2, ASlice{1})
	ConfirmTrim(ASlice{0, 1, 2, 3, 4, 5}, 2, 3, ASlice{2})
	ConfirmTrim(ASlice{0, 1, 2, 3, 4, 5}, 3, 4, ASlice{3})
	ConfirmTrim(ASlice{0, 1, 2, 3, 4, 5}, 4, 5, ASlice{4})
	ConfirmTrim(ASlice{0, 1, 2, 3, 4, 5}, 5, 6, ASlice{5})

	ConfirmTrim(ASlice{0, 1, 2, 3, 4, 5}, -1, 1, ASlice{0})
	ConfirmTrim(ASlice{0, 1, 2, 3, 4, 5}, 0, 2, ASlice{0, 1})
	ConfirmTrim(ASlice{0, 1, 2, 3, 4, 5}, 1, 3, ASlice{1, 2})
	ConfirmTrim(ASlice{0, 1, 2, 3, 4, 5}, 2, 4, ASlice{2, 3})
	ConfirmTrim(ASlice{0, 1, 2, 3, 4, 5}, 3, 5, ASlice{3, 4})
	ConfirmTrim(ASlice{0, 1, 2, 3, 4, 5}, 4, 6, ASlice{4, 5})
	ConfirmTrim(ASlice{0, 1, 2, 3, 4, 5}, 5, 7, ASlice{5})
}

func TestASliceDelete(t *testing.T) {
	ConfirmDelete := func(s ASlice, index int, r ASlice) {
		if s.Delete(index); !r.Equal(s) {
			t.Fatalf("Delete(%v) should be %v but is %v", index, r, s)
		}
	}

	ConfirmDelete(ASlice{0, 1, 2, 3, 4, 5}, -1, ASlice{0, 1, 2, 3, 4, 5})
	ConfirmDelete(ASlice{0, 1, 2, 3, 4, 5}, 0, ASlice{1, 2, 3, 4, 5})
	ConfirmDelete(ASlice{0, 1, 2, 3, 4, 5}, 1, ASlice{0, 2, 3, 4, 5})
	ConfirmDelete(ASlice{0, 1, 2, 3, 4, 5}, 2, ASlice{0, 1, 3, 4, 5})
	ConfirmDelete(ASlice{0, 1, 2, 3, 4, 5}, 3, ASlice{0, 1, 2, 4, 5})
	ConfirmDelete(ASlice{0, 1, 2, 3, 4, 5}, 4, ASlice{0, 1, 2, 3, 5})
	ConfirmDelete(ASlice{0, 1, 2, 3, 4, 5}, 5, ASlice{0, 1, 2, 3, 4})
	ConfirmDelete(ASlice{0, 1, 2, 3, 4, 5}, 6, ASlice{0, 1, 2, 3, 4, 5})
}

func TestASliceDeleteIf(t *testing.T) {
	ConfirmDeleteIf := func(s ASlice, f interface{}, r ASlice) {
		if s.DeleteIf(f); !r.Equal(s) {
			t.Fatalf("DeleteIf(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmDeleteIf(ASlice{0, 1, 0, 3, 0, 5}, uintptr(0), ASlice{1, 3, 5})
	ConfirmDeleteIf(ASlice{0, 1, 0, 3, 0, 5}, uintptr(1), ASlice{0, 0, 3, 0, 5})
	ConfirmDeleteIf(ASlice{0, 1, 0, 3, 0, 5}, uintptr(6), ASlice{0, 1, 0, 3, 0, 5})

	ConfirmDeleteIf(ASlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uintptr(0) }, ASlice{1, 3, 5})
	ConfirmDeleteIf(ASlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uintptr(1) }, ASlice{0, 0, 3, 0, 5})
	ConfirmDeleteIf(ASlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uintptr(6) }, ASlice{0, 1, 0, 3, 0, 5})

	ConfirmDeleteIf(ASlice{0, 1, 0, 3, 0, 5}, func(x uintptr) bool { return x == uintptr(0) }, ASlice{1, 3, 5})
	ConfirmDeleteIf(ASlice{0, 1, 0, 3, 0, 5}, func(x uintptr) bool { return x == uintptr(1) }, ASlice{0, 0, 3, 0, 5})
	ConfirmDeleteIf(ASlice{0, 1, 0, 3, 0, 5}, func(x uintptr) bool { return x == uintptr(6) }, ASlice{0, 1, 0, 3, 0, 5})
}

func TestASliceEach(t *testing.T) {
	var	count	uintptr
	ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(i interface{}) {
		if i != uintptr(count) {
			t.Fatalf("element %v erroneously reported as %v", count, i)
		}
		count++
	})

	ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(index int, i interface{}) {
		if i != uintptr(index) {
			t.Fatalf("element %v erroneously reported as %v", index, i)
		}
	})

	ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(key, i interface{}) {
		if i != uintptr(key.(int)) {
			t.Fatalf("element %v erroneously reported as %v", key, i)
		}
	})

	count = 0
	ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(i uintptr) {
		if i != count {
			t.Fatalf("element %v erroneously reported as %v", count, i)
		}
		count++
	})

	ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(index int, i uintptr) {
		if i != uintptr(index) {
			t.Fatalf("element %v erroneously reported as %v", index, i)
		}
	})

	ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(key interface{}, i uintptr) {
		if i != uintptr(key.(int)) {
			t.Fatalf("element %v erroneously reported as %v", key, i)
		}
	})
}

func TestUASliceWhile(t *testing.T) {
	ConfirmLimit := func(s ASlice, l int, f interface{}) {
		if count := s.While(f); count != l {
			t.Fatalf("%v.While() should have iterated %v times not %v times", s, l, count)
		}
	}

	s := ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}
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
	ConfirmLimit(s, limit, func(i uintptr) bool {
		if count == limit {
			return false
		}
		count++
		return true
	})

	ConfirmLimit(s, limit, func(index int, i uintptr) bool {
		return index != limit
	})

	ConfirmLimit(s, limit, func(key interface{}, i uintptr) bool {
		return key.(int) != limit
	})
}

func TestUASliceUntil(t *testing.T) {
	ConfirmLimit := func(s ASlice, l int, f interface{}) {
		if count := s.Until(f); count != l {
			t.Fatalf("%v.Until() should have iterated %v times not %v times", s, l, count)
		}
	}

	s := ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}
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
	ConfirmLimit(s, limit, func(i uintptr) bool {
		if count == limit {
			return true
		}
		count++
		return false
	})

	ConfirmLimit(s, limit, func(index int, i uintptr) bool {
		return index == limit
	})

	ConfirmLimit(s, limit, func(key interface{}, i uintptr) bool {
		return key.(int) == limit
	})
}

func TestASliceBlockCopy(t *testing.T) {
	ConfirmBlockCopy := func(s ASlice, destination, source, count int, r ASlice) {
		s.BlockCopy(destination, source, count)
		if !r.Equal(s) {
			t.Fatalf("BlockCopy(%v, %v, %v) should be %v but is %v", destination, source, count, r, s)
		}
	}

	ConfirmBlockCopy(ASlice{}, 0, 0, 1, ASlice{})
	ConfirmBlockCopy(ASlice{}, 1, 0, 1, ASlice{})
	ConfirmBlockCopy(ASlice{}, 0, 1, 1, ASlice{})

	ConfirmBlockCopy(ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 0, 0, 4, ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 9, 9, 4, ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 9, 0, 4, ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 0})
	ConfirmBlockCopy(ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 0, 4, ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 10, 4, ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, 2, 4, ASlice{0, 1, 2, 3, 4, 2, 3, 4, 5, 9})
	ConfirmBlockCopy(ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 2, 5, 4, ASlice{0, 1, 5, 6, 7, 8, 6, 7, 8, 9})
}

func TestASliceBlockClear(t *testing.T) {
	ConfirmBlockClear := func(s ASlice, start, count int, r ASlice) {
		s.BlockClear(start, count)
		if !r.Equal(s) {
			t.Fatalf("BlockClear(%v, %v) should be %v but is %v", start, count, r, s)
		}
	}

	ConfirmBlockClear(ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 0, 4, ASlice{0, 0, 0, 0, 4, 5, 6, 7, 8, 9})
	ConfirmBlockClear(ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 4, ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockClear(ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, 4, ASlice{0, 1, 2, 3, 4, 0, 0, 0, 0, 9})
}

func TestASliceOverwrite(t *testing.T) {
	ConfirmOverwrite := func(s ASlice, offset int, v, r ASlice) {
		s.Overwrite(offset, v)
		if !r.Equal(s) {
			t.Fatalf("Overwrite(%v, %v) should be %v but is %v", offset, v, r, s)
		}
	}

	ConfirmOverwrite(ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 0, ASlice{10, 9, 8, 7}, ASlice{10, 9, 8, 7, 4, 5, 6, 7, 8, 9})
	ConfirmOverwrite(ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, ASlice{10, 9, 8, 7}, ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmOverwrite(ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, ASlice{11, 12, 13, 14}, ASlice{0, 1, 2, 3, 4, 11, 12, 13, 14, 9})
}

func TestASliceReallocate(t *testing.T) {
	ConfirmReallocate := func(s ASlice, l, c int, r ASlice) {
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

	ConfirmReallocate(ASlice{}, 0, 10, make(ASlice, 0, 10))
	ConfirmReallocate(ASlice{0, 1, 2, 3, 4}, 3, 10, ASlice{0, 1, 2})
	ConfirmReallocate(ASlice{0, 1, 2, 3, 4}, 5, 10, ASlice{0, 1, 2, 3, 4})
	ConfirmReallocate(ASlice{0, 1, 2, 3, 4}, 10, 10, ASlice{0, 1, 2, 3, 4, 0, 0, 0, 0, 0})
	ConfirmReallocate(ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 1, 5, ASlice{0})
	ConfirmReallocate(ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, 5, ASlice{0, 1, 2, 3, 4})
	ConfirmReallocate(ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 5, ASlice{0, 1, 2, 3, 4})
}

func TestASliceExtend(t *testing.T) {
	ConfirmExtend := func(s ASlice, n int, r ASlice) {
		c := s.Cap()
		s.Extend(n)
		switch {
		case s.Len() != r.Len():	t.Fatalf("Extend(%v) len should be %v but is %v", n, r.Len(), s.Len())
		case s.Cap() != c + n:		t.Fatalf("Extend(%v) cap should be %v but is %v", n, c + n, s.Cap())
		case !r.Equal(s):			t.Fatalf("Extend(%v) should be %v but is %v", n, r, s)
		}
	}

	ConfirmExtend(ASlice{}, 1, ASlice{0})
	ConfirmExtend(ASlice{}, 2, ASlice{0, 0})
}

func TestASliceExpand(t *testing.T) {
	ConfirmExpand := func(s ASlice, i, n int, r ASlice) {
		c := s.Cap()
		s.Expand(i, n)
		switch {
		case s.Len() != r.Len():	t.Fatalf("Expand(%v, %v) len should be %v but is %v", i, n, r.Len(), s.Len())
		case s.Cap() != c + n:		t.Fatalf("Expand(%v, %v) cap should be %v but is %v", i, n, c + n, s.Cap())
		case !r.Equal(s):			t.Fatalf("Expand(%v, %v) should be %v but is %v", i, n, r, s)
		}
	}

	ConfirmExpand(ASlice{}, -1, 1, ASlice{0})
	ConfirmExpand(ASlice{}, 0, 1, ASlice{0})
	ConfirmExpand(ASlice{}, 1, 1, ASlice{0})
	ConfirmExpand(ASlice{}, 0, 2, ASlice{0, 0})

	ConfirmExpand(ASlice{0, 1, 2}, -1, 2, ASlice{0, 0, 0, 1, 2})
	ConfirmExpand(ASlice{0, 1, 2}, 0, 2, ASlice{0, 0, 0, 1, 2})
	ConfirmExpand(ASlice{0, 1, 2}, 1, 2, ASlice{0, 0, 0, 1, 2})
	ConfirmExpand(ASlice{0, 1, 2}, 2, 2, ASlice{0, 1, 0, 0, 2})
	ConfirmExpand(ASlice{0, 1, 2}, 3, 2, ASlice{0, 1, 2, 0, 0})
	ConfirmExpand(ASlice{0, 1, 2}, 4, 2, ASlice{0, 1, 2, 0, 0})
}

func TestASliceDepth(t *testing.T) {
	ConfirmDepth := func(s ASlice, i int) {
		if x := s.Depth(); x != i {
			t.Fatalf("%v.Depth() should be %v but is %v", s, i, x)
		}
	}
	ConfirmDepth(ASlice{0, 1}, 0)
}

func TestASliceReverse(t *testing.T) {
	ConfirmReverse := func(s, r ASlice) {
		if s.Reverse(); !Equal(s, r) {
			t.Fatalf("Reverse() should be %v but is %v", r, s)
		}
	}
	ConfirmReverse(ASlice{}, ASlice{})
	ConfirmReverse(ASlice{1}, ASlice{1})
	ConfirmReverse(ASlice{1, 2}, ASlice{2, 1})
	ConfirmReverse(ASlice{1, 2, 3}, ASlice{3, 2, 1})
	ConfirmReverse(ASlice{1, 2, 3, 4}, ASlice{4, 3, 2, 1})
}

func TestASliceAppend(t *testing.T) {
	ConfirmAppend := func(s ASlice, v interface{}, r ASlice) {
		s.Append(v)
		if !r.Equal(s) {
			t.Fatalf("Append(%v) should be %v but is %v", v, r, s)
		}
	}

	ConfirmAppend(ASlice{}, uintptr(0), ASlice{0})

	ConfirmAppend(ASlice{}, ASlice{0}, ASlice{0})
	ConfirmAppend(ASlice{}, ASlice{0, 1}, ASlice{0, 1})
	ConfirmAppend(ASlice{0, 1, 2}, ASlice{3, 4}, ASlice{0, 1, 2, 3, 4})
}

func TestASlicePrepend(t *testing.T) {
	ConfirmPrepend := func(s ASlice, v interface{}, r ASlice) {
		if s.Prepend(v); !r.Equal(s) {
			t.Fatalf("Prepend(%v) should be %v but is %v", v, r, s)
		}
	}

	ConfirmPrepend(ASlice{}, uintptr(0), ASlice{0})
	ConfirmPrepend(ASlice{0}, uintptr(1), ASlice{1, 0})

	ConfirmPrepend(ASlice{}, ASlice{0}, ASlice{0})
	ConfirmPrepend(ASlice{}, ASlice{0, 1}, ASlice{0, 1})
	ConfirmPrepend(ASlice{0, 1, 2}, ASlice{3, 4}, ASlice{3, 4, 0, 1, 2})
}

func TestASliceRepeat(t *testing.T) {
	ConfirmRepeat := func(s ASlice, count int, r ASlice) {
		if x := s.Repeat(count); !x.Equal(r) {
			t.Fatalf("%v.Repeat(%v) should be %v but is %v", s, count, r, x)
		}
	}

	ConfirmRepeat(ASlice{}, 5, ASlice{})
	ConfirmRepeat(ASlice{0}, 1, ASlice{0})
	ConfirmRepeat(ASlice{0}, 2, ASlice{0, 0})
	ConfirmRepeat(ASlice{0}, 3, ASlice{0, 0, 0})
	ConfirmRepeat(ASlice{0}, 4, ASlice{0, 0, 0, 0})
	ConfirmRepeat(ASlice{0}, 5, ASlice{0, 0, 0, 0, 0})
}

func TestASliceCar(t *testing.T) {
	ConfirmCar := func(s ASlice, r uintptr) {
		n := s.Car()
		if ok := n == r; !ok {
			t.Fatalf("head should be '%v' but is '%v'", r, n)
		}
	}
	ConfirmCar(ASlice{1, 2, 3}, 1)
}

func TestASliceCdr(t *testing.T) {
	ConfirmCdr := func(s, r ASlice) {
		if n := s.Cdr(); !n.Equal(r) {
			t.Fatalf("tail should be '%v' but is '%v'", r, n)
		}
	}
	ConfirmCdr(ASlice{1, 2, 3}, ASlice{2, 3})
}

func TestASliceRplaca(t *testing.T) {
	ConfirmRplaca := func(s ASlice, v interface{}, r ASlice) {
		if s.Rplaca(v); !s.Equal(r) {
			t.Fatalf("slice should be '%v' but is '%v'", r, s)
		}
	}
	ConfirmRplaca(ASlice{1, 2, 3, 4, 5}, uintptr(0), ASlice{0, 2, 3, 4, 5})
}

func TestASliceRplacd(t *testing.T) {
	ConfirmRplacd := func(s ASlice, v interface{}, r ASlice) {
		if s.Rplacd(v); !s.Equal(r) {
			t.Fatalf("slice should be '%v' but is '%v'", r, s)
		}
	}
	ConfirmRplacd(ASlice{1, 2, 3, 4, 5}, nil, ASlice{1})
	ConfirmRplacd(ASlice{1, 2, 3, 4, 5}, uintptr(10), ASlice{1, 10})
	ConfirmRplacd(ASlice{1, 2, 3, 4, 5}, ASlice{5, 4, 3, 2}, ASlice{1, 5, 4, 3, 2})
	ConfirmRplacd(ASlice{1, 2, 3, 4, 5, 6}, ASlice{2, 4, 8, 16}, ASlice{1, 2, 4, 8, 16})
}

func TestASliceFind(t *testing.T) {
	ConfirmFind := func(s ASlice, v uintptr, i int) {
		if x, ok := s.Find(v); !ok || x != i {
			t.Fatalf("%v.Find(%v) should be %v but is %v", s, v, i, x)
		}
	}

	ConfirmFind(ASlice{0, 1, 2, 3, 4}, 0, 0)
	ConfirmFind(ASlice{0, 1, 2, 3, 4}, 1, 1)
	ConfirmFind(ASlice{0, 1, 2, 4, 3}, 2, 2)
	ConfirmFind(ASlice{0, 1, 2, 4, 3}, 3, 4)
	ConfirmFind(ASlice{0, 1, 2, 4, 3}, 4, 3)
}

func TestASliceFindN(t *testing.T) {
	ConfirmFindN := func(s ASlice, v uintptr, n int, i ISlice) {
		if x := s.FindN(v, n); !x.Equal(i) {
			t.Fatalf("%v.Find(%v, %v) should be %v but is %v", s, v, n, i, x)
		}
	}

	ConfirmFindN(ASlice{1, 0, 1, 0, 1}, 2, 3, ISlice{})
	ConfirmFindN(ASlice{1, 0, 1, 0, 1}, 1, 0, ISlice{0, 2, 4})
	ConfirmFindN(ASlice{1, 0, 1, 0, 1}, 1, 1, ISlice{0})
	ConfirmFindN(ASlice{1, 0, 1, 0, 1}, 1, 2, ISlice{0, 2})
	ConfirmFindN(ASlice{1, 0, 1, 0, 1}, 1, 3, ISlice{0, 2, 4})
	ConfirmFindN(ASlice{1, 0, 1, 0, 1}, 1, 4, ISlice{0, 2, 4})
}

func TestASliceKeepIf(t *testing.T) {
	ConfirmKeepIf := func(s ASlice, f interface{}, r ASlice) {
		if s.KeepIf(f); !r.Equal(s) {
			t.Fatalf("KeepIf(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmKeepIf(ASlice{0, 1, 0, 3, 0, 5}, uintptr(0), ASlice{0, 0, 0})
	ConfirmKeepIf(ASlice{0, 1, 0, 3, 0, 5}, uintptr(1), ASlice{1})
	ConfirmKeepIf(ASlice{0, 1, 0, 3, 0, 5}, uintptr(6), ASlice{})

	ConfirmKeepIf(ASlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uintptr(0) }, ASlice{0, 0, 0})
	ConfirmKeepIf(ASlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uintptr(1) }, ASlice{1})
	ConfirmKeepIf(ASlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uintptr(6) }, ASlice{})

	ConfirmKeepIf(ASlice{0, 1, 0, 3, 0, 5}, func(x uintptr) bool { return x == uintptr(0) }, ASlice{0, 0, 0})
	ConfirmKeepIf(ASlice{0, 1, 0, 3, 0, 5}, func(x uintptr) bool { return x == uintptr(1) }, ASlice{1})
	ConfirmKeepIf(ASlice{0, 1, 0, 3, 0, 5}, func(x uintptr) bool { return x == uintptr(6) }, ASlice{})
}

func TestASliceReverseEach(t *testing.T) {
	var count	uintptr
	count = 9
	ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(i interface{}) {
		if i != count {
			t.Fatalf("0: element %v erroneously reported as %v", count, i)
		}
		count--
	})

	ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(index int, i interface{}) {
		if index != int(i.(uintptr)) {
			t.Fatalf("1: element %v erroneously reported as %v", index, i)
		}
	})

	ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(key, i interface{}) {
		if uintptr(key.(int)) != i {
			t.Fatalf("2: element %v erroneously reported as %v", key, i)
		}
	})

	count = 9
	ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(i uintptr) {
		if i != count {
			t.Fatalf("3: element %v erroneously reported as %v", count, i)
		}
		count--
	})

	ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(index int, i uintptr) {
		if int(i) != index {
			t.Fatalf("4: element %v erroneously reported as %v", index, i)
		}
	})

	ASlice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(key interface{}, i uintptr) {
		if key.(int) != int(i) {
			t.Fatalf("5: element %v erroneously reported as %v", key, i)
		}
	})
}

func TestASliceReplaceIf(t *testing.T) {
	ConfirmReplaceIf := func(s ASlice, f, v interface{}, r ASlice) {
		if s.ReplaceIf(f, v); !r.Equal(s) {
			t.Fatalf("ReplaceIf(%v, %v) should be %v but is %v", f, v, r, s)
		}
	}

	ConfirmReplaceIf(ASlice{0, 1, 0, 3, 0, 5}, uintptr(0), uintptr(1), ASlice{1, 1, 1, 3, 1, 5})
	ConfirmReplaceIf(ASlice{0, 1, 0, 3, 0, 5}, uintptr(1), uintptr(0), ASlice{0, 0, 0, 3, 0, 5})
	ConfirmReplaceIf(ASlice{0, 1, 0, 3, 0, 5}, uintptr(6), uintptr(0), ASlice{0, 1, 0, 3, 0, 5})

	ConfirmReplaceIf(ASlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uintptr(0) }, uintptr(1), ASlice{1, 1, 1, 3, 1, 5})
	ConfirmReplaceIf(ASlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uintptr(1) }, uintptr(0), ASlice{0, 0, 0, 3, 0, 5})
	ConfirmReplaceIf(ASlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uintptr(6) }, uintptr(0), ASlice{0, 1, 0, 3, 0, 5})

	ConfirmReplaceIf(ASlice{0, 1, 0, 3, 0, 5}, func(x uintptr) bool { return x == uintptr(0) }, uintptr(1), ASlice{1, 1, 1, 3, 1, 5})
	ConfirmReplaceIf(ASlice{0, 1, 0, 3, 0, 5}, func(x uintptr) bool { return x == uintptr(1) }, uintptr(0), ASlice{0, 0, 0, 3, 0, 5})
	ConfirmReplaceIf(ASlice{0, 1, 0, 3, 0, 5}, func(x uintptr) bool { return x == uintptr(6) }, uintptr(0), ASlice{0, 1, 0, 3, 0, 5})
}

func TestASliceReplace(t *testing.T) {
	ConfirmReplace := func(s ASlice, v interface{}) {
		if s.Replace(v); !s.Equal(v) {
			t.Fatalf("Replace() should be %v but is %v", s, v)
		}
	}

	ConfirmReplace(ASlice{0, 1, 2, 3, 4, 5}, ASlice{ 9, 8, 7, 6, 5 })
	ConfirmReplace(ASlice{0, 1, 2, 3, 4, 5}, []uintptr{ 9, 8, 7, 6, 5 })
}

func TestASliceSelect(t *testing.T) {
	ConfirmSelect := func(s ASlice, f interface{}, r ASlice) {
		if x := s.Select(f); !r.Equal(x) {
			t.Fatalf("Select(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmSelect(ASlice{0, 1, 0, 3, 0, 5}, uintptr(0), ASlice{0, 0, 0})
	ConfirmSelect(ASlice{0, 1, 0, 3, 0, 5}, uintptr(1), ASlice{1})
	ConfirmSelect(ASlice{0, 1, 0, 3, 0, 5}, uintptr(6), ASlice{})

	ConfirmSelect(ASlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uintptr(0) }, ASlice{0, 0, 0})
	ConfirmSelect(ASlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uintptr(1) }, ASlice{1})
	ConfirmSelect(ASlice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == uintptr(6) }, ASlice{})

	ConfirmSelect(ASlice{0, 1, 0, 3, 0, 5}, func(x uintptr) bool { return x == uintptr(0) }, ASlice{0, 0, 0})
	ConfirmSelect(ASlice{0, 1, 0, 3, 0, 5}, func(x uintptr) bool { return x == uintptr(1) }, ASlice{1})
	ConfirmSelect(ASlice{0, 1, 0, 3, 0, 5}, func(x uintptr) bool { return x == uintptr(6) }, ASlice{})
}

func TestASliceUniq(t *testing.T) {
	ConfirmUniq := func(s, r ASlice) {
		if s.Uniq(); !r.Equal(s) {
			t.Fatalf("Uniq() should be %v but is %v", r, s)
		}
	}

	ConfirmUniq(ASlice{0, 0, 0, 0, 0, 0}, ASlice{0})
	ConfirmUniq(ASlice{0, 1, 0, 3, 0, 5}, ASlice{0, 1, 3, 5})
}

func TestASlicePick(t *testing.T) {
	ConfirmPick := func(s ASlice, i []int, r ASlice) {
		if x := s.Pick(i...); !r.Equal(x) {
			t.Fatalf("%v.Pick(%v) should be %v but is %v", s, i, r, x)
		}
	}

	ConfirmPick(ASlice{0, 1, 2, 3, 4, 5}, []int{}, ASlice{})
	ConfirmPick(ASlice{0, 1, 2, 3, 4, 5}, []int{ 0, 1 }, ASlice{0, 1})
	ConfirmPick(ASlice{0, 1, 2, 3, 4, 5}, []int{ 0, 3 }, ASlice{0, 3})
	ConfirmPick(ASlice{0, 1, 2, 3, 4, 5}, []int{ 0, 3, 4, 3 }, ASlice{0, 3, 4, 3})
}

func TestASliceInsert(t *testing.T) {
	ConfirmInsert := func(s ASlice, n int, v interface{}, r ASlice) {
		if s.Insert(n, v); !r.Equal(s) {
			t.Fatalf("Insert(%v, %v) should be %v but is %v", n, v, r, s)
		}
	}

	ConfirmInsert(ASlice{}, 0, uintptr(0), ASlice{0})
	ConfirmInsert(ASlice{}, 0, ASlice{0}, ASlice{0})
	ConfirmInsert(ASlice{}, 0, ASlice{0, 1}, ASlice{0, 1})

	ConfirmInsert(ASlice{0}, 0, uintptr(1), ASlice{1, 0})
	ConfirmInsert(ASlice{0}, 0, ASlice{1}, ASlice{1, 0})
	ConfirmInsert(ASlice{0}, 1, uintptr(1), ASlice{0, 1})
	ConfirmInsert(ASlice{0}, 1, ASlice{1}, ASlice{0, 1})

	ConfirmInsert(ASlice{0, 1, 2}, 0, uintptr(3), ASlice{3, 0, 1, 2})
	ConfirmInsert(ASlice{0, 1, 2}, 1, uintptr(3), ASlice{0, 3, 1, 2})
	ConfirmInsert(ASlice{0, 1, 2}, 2, uintptr(3), ASlice{0, 1, 3, 2})
	ConfirmInsert(ASlice{0, 1, 2}, 3, uintptr(3), ASlice{0, 1, 2, 3})

	ConfirmInsert(ASlice{0, 1, 2}, 0, ASlice{3, 4}, ASlice{3, 4, 0, 1, 2})
	ConfirmInsert(ASlice{0, 1, 2}, 1, ASlice{3, 4}, ASlice{0, 3, 4, 1, 2})
	ConfirmInsert(ASlice{0, 1, 2}, 2, ASlice{3, 4}, ASlice{0, 1, 3, 4, 2})
	ConfirmInsert(ASlice{0, 1, 2}, 3, ASlice{3, 4}, ASlice{0, 1, 2, 3, 4})
}