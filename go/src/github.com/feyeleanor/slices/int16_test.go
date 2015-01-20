package slices

import "testing"

func TestI16SliceString(t *testing.T) {
	ConfirmString := func(s I16Slice, r string) {
		if x := s.String(); x != r {
			t.Fatalf("%v erroneously serialised as '%v'", r, x)
		}
	}

	ConfirmString(I16Slice{}, "()")
	ConfirmString(I16Slice{0}, "(0)")
	ConfirmString(I16Slice{0, 1}, "(0 1)")
}

func TestI16SliceLen(t *testing.T) {
	ConfirmLength := func(s I16Slice, i int) {
		if x := s.Len(); x != i {
			t.Fatalf("%v.Len() should be %v but is %v", s, i, x)
		}
	}
	
	ConfirmLength(I16Slice{0}, 1)
	ConfirmLength(I16Slice{0, 1}, 2)
}

func TestI16SliceSwap(t *testing.T) {
	ConfirmSwap := func(s I16Slice, i, j int, r I16Slice) {
		if s.Swap(i, j); !r.Equal(s) {
			t.Fatalf("Swap(%v, %v) should be %v but is %v", i, j, r, s)
		}
	}
	ConfirmSwap(I16Slice{0, 1, 2}, 0, 1, I16Slice{1, 0, 2})
	ConfirmSwap(I16Slice{0, 1, 2}, 0, 2, I16Slice{2, 1, 0})
}

func TestI16SliceCompare(t *testing.T) {
	ConfirmCompare := func(s I16Slice, i, j, r int) {
		if x := s.Compare(i, j); x != r {
			t.Fatalf("Compare(%v, %v) should be %v but is %v", i, j, r, x)
		}
	}

	ConfirmCompare(I16Slice{0, 1}, 0, 0, IS_SAME_AS)
	ConfirmCompare(I16Slice{0, 1}, 0, 1, IS_LESS_THAN)
	ConfirmCompare(I16Slice{0, 1}, 1, 0, IS_GREATER_THAN)
}

func TestI16SliceZeroCompare(t *testing.T) {
	ConfirmCompare := func(s I16Slice, i, r int) {
		if x := s.ZeroCompare(i); x != r {
			t.Fatalf("ZeroCompare(%v) should be %v but is %v", i, r, x)
		}
	}

	ConfirmCompare(I16Slice{0, -1, 1}, 0, IS_SAME_AS)
	ConfirmCompare(I16Slice{0, -1, 1}, 1, IS_GREATER_THAN)
	ConfirmCompare(I16Slice{0, -1, 1}, 2, IS_LESS_THAN)
}

func TestI16SliceCut(t *testing.T) {
	ConfirmCut := func(s I16Slice, start, end int, r I16Slice) {
		if s.Cut(start, end); !r.Equal(s) {
			t.Fatalf("Cut(%v, %v) should be %v but is %v", start, end, r, s)
		}
	}

	ConfirmCut(I16Slice{0, 1, 2, 3, 4, 5}, 0, 1, I16Slice{1, 2, 3, 4, 5})
	ConfirmCut(I16Slice{0, 1, 2, 3, 4, 5}, 1, 2, I16Slice{0, 2, 3, 4, 5})
	ConfirmCut(I16Slice{0, 1, 2, 3, 4, 5}, 2, 3, I16Slice{0, 1, 3, 4, 5})
	ConfirmCut(I16Slice{0, 1, 2, 3, 4, 5}, 3, 4, I16Slice{0, 1, 2, 4, 5})
	ConfirmCut(I16Slice{0, 1, 2, 3, 4, 5}, 4, 5, I16Slice{0, 1, 2, 3, 5})
	ConfirmCut(I16Slice{0, 1, 2, 3, 4, 5}, 5, 6, I16Slice{0, 1, 2, 3, 4})

	ConfirmCut(I16Slice{0, 1, 2, 3, 4, 5}, -1, 1, I16Slice{1, 2, 3, 4, 5})
	ConfirmCut(I16Slice{0, 1, 2, 3, 4, 5}, 0, 2, I16Slice{2, 3, 4, 5})
	ConfirmCut(I16Slice{0, 1, 2, 3, 4, 5}, 1, 3, I16Slice{0, 3, 4, 5})
	ConfirmCut(I16Slice{0, 1, 2, 3, 4, 5}, 2, 4, I16Slice{0, 1, 4, 5})
	ConfirmCut(I16Slice{0, 1, 2, 3, 4, 5}, 3, 5, I16Slice{0, 1, 2, 5})
	ConfirmCut(I16Slice{0, 1, 2, 3, 4, 5}, 4, 6, I16Slice{0, 1, 2, 3})
	ConfirmCut(I16Slice{0, 1, 2, 3, 4, 5}, 5, 7, I16Slice{0, 1, 2, 3, 4})
}

func TestI16SliceTrim(t *testing.T) {
	ConfirmTrim := func(s I16Slice, start, end int, r I16Slice) {
		if s.Trim(start, end); !r.Equal(s) {
			t.Fatalf("Trim(%v, %v) should be %v but is %v", start, end, r, s)
		}
	}

	ConfirmTrim(I16Slice{0, 1, 2, 3, 4, 5}, 0, 1, I16Slice{0})
	ConfirmTrim(I16Slice{0, 1, 2, 3, 4, 5}, 1, 2, I16Slice{1})
	ConfirmTrim(I16Slice{0, 1, 2, 3, 4, 5}, 2, 3, I16Slice{2})
	ConfirmTrim(I16Slice{0, 1, 2, 3, 4, 5}, 3, 4, I16Slice{3})
	ConfirmTrim(I16Slice{0, 1, 2, 3, 4, 5}, 4, 5, I16Slice{4})
	ConfirmTrim(I16Slice{0, 1, 2, 3, 4, 5}, 5, 6, I16Slice{5})

	ConfirmTrim(I16Slice{0, 1, 2, 3, 4, 5}, -1, 1, I16Slice{0})
	ConfirmTrim(I16Slice{0, 1, 2, 3, 4, 5}, 0, 2, I16Slice{0, 1})
	ConfirmTrim(I16Slice{0, 1, 2, 3, 4, 5}, 1, 3, I16Slice{1, 2})
	ConfirmTrim(I16Slice{0, 1, 2, 3, 4, 5}, 2, 4, I16Slice{2, 3})
	ConfirmTrim(I16Slice{0, 1, 2, 3, 4, 5}, 3, 5, I16Slice{3, 4})
	ConfirmTrim(I16Slice{0, 1, 2, 3, 4, 5}, 4, 6, I16Slice{4, 5})
	ConfirmTrim(I16Slice{0, 1, 2, 3, 4, 5}, 5, 7, I16Slice{5})
}

func TestI16SliceDelete(t *testing.T) {
	ConfirmDelete := func(s I16Slice, index int, r I16Slice) {
		if s.Delete(index); !r.Equal(s) {
			t.Fatalf("Delete(%v) should be %v but is %v", index, r, s)
		}
	}

	ConfirmDelete(I16Slice{0, 1, 2, 3, 4, 5}, -1, I16Slice{0, 1, 2, 3, 4, 5})
	ConfirmDelete(I16Slice{0, 1, 2, 3, 4, 5}, 0, I16Slice{1, 2, 3, 4, 5})
	ConfirmDelete(I16Slice{0, 1, 2, 3, 4, 5}, 1, I16Slice{0, 2, 3, 4, 5})
	ConfirmDelete(I16Slice{0, 1, 2, 3, 4, 5}, 2, I16Slice{0, 1, 3, 4, 5})
	ConfirmDelete(I16Slice{0, 1, 2, 3, 4, 5}, 3, I16Slice{0, 1, 2, 4, 5})
	ConfirmDelete(I16Slice{0, 1, 2, 3, 4, 5}, 4, I16Slice{0, 1, 2, 3, 5})
	ConfirmDelete(I16Slice{0, 1, 2, 3, 4, 5}, 5, I16Slice{0, 1, 2, 3, 4})
	ConfirmDelete(I16Slice{0, 1, 2, 3, 4, 5}, 6, I16Slice{0, 1, 2, 3, 4, 5})
}

func TestI16SliceDeleteIf(t *testing.T) {
	ConfirmDeleteIf := func(s I16Slice, f interface{}, r I16Slice) {
		if s.DeleteIf(f); !r.Equal(s) {
			t.Fatalf("DeleteIf(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmDeleteIf(I16Slice{0, 1, 0, 3, 0, 5}, int16(0), I16Slice{1, 3, 5})
	ConfirmDeleteIf(I16Slice{0, 1, 0, 3, 0, 5}, int16(1), I16Slice{0, 0, 3, 0, 5})
	ConfirmDeleteIf(I16Slice{0, 1, 0, 3, 0, 5}, int16(6), I16Slice{0, 1, 0, 3, 0, 5})

	ConfirmDeleteIf(I16Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int16(0) }, I16Slice{1, 3, 5})
	ConfirmDeleteIf(I16Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int16(1) }, I16Slice{0, 0, 3, 0, 5})
	ConfirmDeleteIf(I16Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int16(6) }, I16Slice{0, 1, 0, 3, 0, 5})

	ConfirmDeleteIf(I16Slice{0, 1, 0, 3, 0, 5}, func(x int16) bool { return x == int16(0) }, I16Slice{1, 3, 5})
	ConfirmDeleteIf(I16Slice{0, 1, 0, 3, 0, 5}, func(x int16) bool { return x == int16(1) }, I16Slice{0, 0, 3, 0, 5})
	ConfirmDeleteIf(I16Slice{0, 1, 0, 3, 0, 5}, func(x int16) bool { return x == int16(6) }, I16Slice{0, 1, 0, 3, 0, 5})
}

func TestI16SliceEach(t *testing.T) {
	var count	int16
	I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(i interface{}) {
		if i != count {
			t.Fatalf("element %v erroneously reported as %v", count, i)
		}
		count++
	})

	I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(index int, i interface{}) {
		if i != int16(index) {
			t.Fatalf("element %v erroneously reported as %v", index, i)
		}
	})

	I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(key, i interface{}) {
		if i != int16(key.(int)) {
			t.Fatalf("element %v erroneously reported as %v", key, i)
		}
	})

	count = 0
	I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(i int16) {
		if i != count {
			t.Fatalf("element %v erroneously reported as %v", count, i)
		}
		count++
	})

	I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(index int, i int16) {
		if i != int16(index) {
			t.Fatalf("element %v erroneously reported as %v", index, i)
		}
	})

	I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(key interface{}, i int16) {
		if i != int16(key.(int)) {
			t.Fatalf("element %v erroneously reported as %v", key, i)
		}
	})
}

func TestI16SliceWhile(t *testing.T) {
	ConfirmLimit := func(s I16Slice, l int, f interface{}) {
		if count := s.While(f); count != l {
			t.Fatalf("%v.While() should have iterated %v times not %v times", s, l, count)
		}
	}

	s := I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}
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
	ConfirmLimit(s, limit, func(i int16) bool {
		if count == limit {
			return false
		}
		count++
		return true
	})

	ConfirmLimit(s, limit, func(index int, i int16) bool {
		return index != limit
	})

	ConfirmLimit(s, limit, func(key interface{}, i int16) bool {
		return key.(int) != limit
	})
}

func TestI16SliceUntil(t *testing.T) {
	ConfirmLimit := func(s I16Slice, l int, f interface{}) {
		if count := s.Until(f); count != l {
			t.Fatalf("%v.Until() should have iterated %v times not %v times", s, l, count)
		}
	}

	s := I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}
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
	ConfirmLimit(s, limit, func(i int16) bool {
		if count == limit {
			return true
		}
		count++
		return false
	})

	ConfirmLimit(s, limit, func(index int, i int16) bool {
		return index == limit
	})

	ConfirmLimit(s, limit, func(key interface{}, i int16) bool {
		return key.(int) == limit
	})
}

func TestI16SliceBlockCopy(t *testing.T) {
	ConfirmBlockCopy := func(s I16Slice, destination, source, count int, r I16Slice) {
		s.BlockCopy(destination, source, count)
		if !r.Equal(s) {
			t.Fatalf("BlockCopy(%v, %v, %v) should be %v but is %v", destination, source, count, r, s)
		}
	}

	ConfirmBlockCopy(I16Slice{}, 0, 0, 1, I16Slice{})
	ConfirmBlockCopy(I16Slice{}, 1, 0, 1, I16Slice{})
	ConfirmBlockCopy(I16Slice{}, 0, 1, 1, I16Slice{})

	ConfirmBlockCopy(I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 0, 0, 4, I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 9, 9, 4, I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 9, 0, 4, I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 0})
	ConfirmBlockCopy(I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 0, 4, I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 10, 4, I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, 2, 4, I16Slice{0, 1, 2, 3, 4, 2, 3, 4, 5, 9})
	ConfirmBlockCopy(I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 2, 5, 4, I16Slice{0, 1, 5, 6, 7, 8, 6, 7, 8, 9})
}

func TestI16SliceBlockClear(t *testing.T) {
	ConfirmBlockClear := func(s I16Slice, start, count int, r I16Slice) {
		s.BlockClear(start, count)
		if !r.Equal(s) {
			t.Fatalf("BlockClear(%v, %v) should be %v but is %v", start, count, r, s)
		}
	}

	ConfirmBlockClear(I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 0, 4, I16Slice{0, 0, 0, 0, 4, 5, 6, 7, 8, 9})
	ConfirmBlockClear(I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 4, I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockClear(I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, 4, I16Slice{0, 1, 2, 3, 4, 0, 0, 0, 0, 9})
}

func TestI16SliceOverwrite(t *testing.T) {
	ConfirmOverwrite := func(s I16Slice, offset int, v, r I16Slice) {
		s.Overwrite(offset, v)
		if !r.Equal(s) {
			t.Fatalf("Overwrite(%v, %v) should be %v but is %v", offset, v, r, s)
		}
	}

	ConfirmOverwrite(I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 0, I16Slice{10, 9, 8, 7}, I16Slice{10, 9, 8, 7, 4, 5, 6, 7, 8, 9})
	ConfirmOverwrite(I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, I16Slice{10, 9, 8, 7}, I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmOverwrite(I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, I16Slice{11, 12, 13, 14}, I16Slice{0, 1, 2, 3, 4, 11, 12, 13, 14, 9})
}

func TestI16SliceReallocate(t *testing.T) {
	ConfirmReallocate := func(s I16Slice, l, c int, r I16Slice) {
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

	ConfirmReallocate(I16Slice{}, 0, 10, make(I16Slice, 0, 10))
	ConfirmReallocate(I16Slice{0, 1, 2, 3, 4}, 3, 10, I16Slice{0, 1, 2})
	ConfirmReallocate(I16Slice{0, 1, 2, 3, 4}, 5, 10, I16Slice{0, 1, 2, 3, 4})
	ConfirmReallocate(I16Slice{0, 1, 2, 3, 4}, 10, 10, I16Slice{0, 1, 2, 3, 4, 0, 0, 0, 0, 0})
	ConfirmReallocate(I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 1, 5, I16Slice{0})
	ConfirmReallocate(I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, 5, I16Slice{0, 1, 2, 3, 4})
	ConfirmReallocate(I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 5, I16Slice{0, 1, 2, 3, 4})
}

func TestI16SliceExtend(t *testing.T) {
	ConfirmExtend := func(s I16Slice, n int, r I16Slice) {
		c := s.Cap()
		s.Extend(n)
		switch {
		case s.Len() != r.Len():	t.Fatalf("Extend(%v) len should be %v but is %v", n, r.Len(), s.Len())
		case s.Cap() != c + n:		t.Fatalf("Extend(%v) cap should be %v but is %v", n, c + n, s.Cap())
		case !r.Equal(s):			t.Fatalf("Extend(%v) should be %v but is %v", n, r, s)
		}
	}

	ConfirmExtend(I16Slice{}, 1, I16Slice{0})
	ConfirmExtend(I16Slice{}, 2, I16Slice{0, 0})
}

func TestI16SliceExpand(t *testing.T) {
	ConfirmExpand := func(s I16Slice, i, n int, r I16Slice) {
		c := s.Cap()
		s.Expand(i, n)
		switch {
		case s.Len() != r.Len():	t.Fatalf("Expand(%v, %v) len should be %v but is %v", i, n, r.Len(), s.Len())
		case s.Cap() != c + n:		t.Fatalf("Expand(%v, %v) cap should be %v but is %v", i, n, c + n, s.Cap())
		case !r.Equal(s):			t.Fatalf("Expand(%v, %v) should be %v but is %v", i, n, r, s)
		}
	}

	ConfirmExpand(I16Slice{}, -1, 1, I16Slice{0})
	ConfirmExpand(I16Slice{}, 0, 1, I16Slice{0})
	ConfirmExpand(I16Slice{}, 1, 1, I16Slice{0})
	ConfirmExpand(I16Slice{}, 0, 2, I16Slice{0, 0})

	ConfirmExpand(I16Slice{0, 1, 2}, -1, 2, I16Slice{0, 0, 0, 1, 2})
	ConfirmExpand(I16Slice{0, 1, 2}, 0, 2, I16Slice{0, 0, 0, 1, 2})
	ConfirmExpand(I16Slice{0, 1, 2}, 1, 2, I16Slice{0, 0, 0, 1, 2})
	ConfirmExpand(I16Slice{0, 1, 2}, 2, 2, I16Slice{0, 1, 0, 0, 2})
	ConfirmExpand(I16Slice{0, 1, 2}, 3, 2, I16Slice{0, 1, 2, 0, 0})
	ConfirmExpand(I16Slice{0, 1, 2}, 4, 2, I16Slice{0, 1, 2, 0, 0})
}

func TestI16SliceDepth(t *testing.T) {
	ConfirmDepth := func(s I16Slice, i int) {
		if x := s.Depth(); x != i {
			t.Fatalf("%v.Depth() should be %v but is %v", s, i, x)
		}
	}
	ConfirmDepth(I16Slice{0, 1}, 0)
}

func TestI16SliceReverse(t *testing.T) {
	ConfirmReverse := func(s, r I16Slice) {
		if s.Reverse(); !Equal(s, r) {
			t.Fatalf("Reverse() should be %v but is %v", r, s)
		}
	}
	ConfirmReverse(I16Slice{}, I16Slice{})
	ConfirmReverse(I16Slice{1}, I16Slice{1})
	ConfirmReverse(I16Slice{1, 2}, I16Slice{2, 1})
	ConfirmReverse(I16Slice{1, 2, 3}, I16Slice{3, 2, 1})
	ConfirmReverse(I16Slice{1, 2, 3, 4}, I16Slice{4, 3, 2, 1})
}

func TestI16SliceAppend(t *testing.T) {
	ConfirmAppend := func(s I16Slice, v interface{}, r I16Slice) {
		s.Append(v)
		if !r.Equal(s) {
			t.Fatalf("Append(%v) should be %v but is %v", v, r, s)
		}
	}

	ConfirmAppend(I16Slice{}, int16(0), I16Slice{0})

	ConfirmAppend(I16Slice{}, I16Slice{0}, I16Slice{0})
	ConfirmAppend(I16Slice{}, I16Slice{0, 1}, I16Slice{0, 1})
	ConfirmAppend(I16Slice{0, 1, 2}, I16Slice{3, 4}, I16Slice{0, 1, 2, 3, 4})
}

func TestI16SlicePrepend(t *testing.T) {
	ConfirmPrepend := func(s I16Slice, v interface{}, r I16Slice) {
		if s.Prepend(v); !r.Equal(s) {
			t.Fatalf("Prepend(%v) should be %v but is %v", v, r, s)
		}
	}

	ConfirmPrepend(I16Slice{}, int16(0), I16Slice{0})
	ConfirmPrepend(I16Slice{0}, int16(1), I16Slice{1, 0})

	ConfirmPrepend(I16Slice{}, I16Slice{0}, I16Slice{0})
	ConfirmPrepend(I16Slice{}, I16Slice{0, 1}, I16Slice{0, 1})
	ConfirmPrepend(I16Slice{0, 1, 2}, I16Slice{3, 4}, I16Slice{3, 4, 0, 1, 2})
}

func TestI16SliceRepeat(t *testing.T) {
	ConfirmRepeat := func(s I16Slice, count int, r I16Slice) {
		if x := s.Repeat(count); !x.Equal(r) {
			t.Fatalf("%v.Repeat(%v) should be %v but is %v", s, count, r, x)
		}
	}

	ConfirmRepeat(I16Slice{}, 5, I16Slice{})
	ConfirmRepeat(I16Slice{0}, 1, I16Slice{0})
	ConfirmRepeat(I16Slice{0}, 2, I16Slice{0, 0})
	ConfirmRepeat(I16Slice{0}, 3, I16Slice{0, 0, 0})
	ConfirmRepeat(I16Slice{0}, 4, I16Slice{0, 0, 0, 0})
	ConfirmRepeat(I16Slice{0}, 5, I16Slice{0, 0, 0, 0, 0})
}

func TestI16SliceCar(t *testing.T) {
	ConfirmCar := func(s I16Slice, r int16) {
		n := s.Car().(int16)
		if ok := n == r; !ok {
			t.Fatalf("head should be '%v' but is '%v'", r, n)
		}
	}
	ConfirmCar(I16Slice{1, 2, 3}, 1)
}

func TestI16SliceCdr(t *testing.T) {
	ConfirmCdr := func(s, r I16Slice) {
		if n := s.Cdr(); !n.Equal(r) {
			t.Fatalf("tail should be '%v' but is '%v'", r, n)
		}
	}
	ConfirmCdr(I16Slice{1, 2, 3}, I16Slice{2, 3})
}

func TestI16SliceRplaca(t *testing.T) {
	ConfirmRplaca := func(s I16Slice, v interface{}, r I16Slice) {
		if s.Rplaca(v); !s.Equal(r) {
			t.Fatalf("slice should be '%v' but is '%v'", r, s)
		}
	}
	ConfirmRplaca(I16Slice{1, 2, 3, 4, 5}, int16(0), I16Slice{0, 2, 3, 4, 5})
}

func TestI16SliceRplacd(t *testing.T) {
	ConfirmRplacd := func(s I16Slice, v interface{}, r I16Slice) {
		if s.Rplacd(v); !s.Equal(r) {
			t.Fatalf("slice should be '%v' but is '%v'", r, s)
		}
	}
	ConfirmRplacd(I16Slice{1, 2, 3, 4, 5}, nil, I16Slice{1})
	ConfirmRplacd(I16Slice{1, 2, 3, 4, 5}, int16(10), I16Slice{1, 10})
	ConfirmRplacd(I16Slice{1, 2, 3, 4, 5}, I16Slice{5, 4, 3, 2}, I16Slice{1, 5, 4, 3, 2})
	ConfirmRplacd(I16Slice{1, 2, 3, 4, 5, 6}, I16Slice{2, 4, 8, 16}, I16Slice{1, 2, 4, 8, 16})
}

func TestI16SliceFind(t *testing.T) {
	ConfirmFind := func(s I16Slice, v int16, i int) {
		if x, ok := s.Find(v); !ok && x != i {
			t.Fatalf("%v.Find(%v) should be %v but is %v", s, v, i, x)
		}
	}

	ConfirmFind(I16Slice{0, 1, 2, 3, 4}, 0, 0)
	ConfirmFind(I16Slice{0, 1, 2, 3, 4}, 1, 1)
	ConfirmFind(I16Slice{0, 1, 2, 4, 3}, 2, 2)
	ConfirmFind(I16Slice{0, 1, 2, 4, 3}, 3, 4)
	ConfirmFind(I16Slice{0, 1, 2, 4, 3}, 4, 3)
}

func TestI16SliceFindN(t *testing.T) {
	ConfirmFindN := func(s I16Slice, v int16, n int, i ISlice) {
		if x := s.FindN(v, n); !x.Equal(i) {
			t.Fatalf("%v.Find(%v, %v) should be %v but is %v", s, v, n, i, x)
		}
	}

	ConfirmFindN(I16Slice{1, 0, 1, 0, 1}, 2, 3, ISlice{})
	ConfirmFindN(I16Slice{1, 0, 1, 0, 1}, 1, 0, ISlice{0, 2, 4})
	ConfirmFindN(I16Slice{1, 0, 1, 0, 1}, 1, 1, ISlice{0})
	ConfirmFindN(I16Slice{1, 0, 1, 0, 1}, 1, 2, ISlice{0, 2})
	ConfirmFindN(I16Slice{1, 0, 1, 0, 1}, 1, 3, ISlice{0, 2, 4})
	ConfirmFindN(I16Slice{1, 0, 1, 0, 1}, 1, 4, ISlice{0, 2, 4})
}

func TestI16SliceKeepIf(t *testing.T) {
	ConfirmKeepIf := func(s I16Slice, f interface{}, r I16Slice) {
		if s.KeepIf(f); !r.Equal(s) {
			t.Fatalf("KeepIf(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmKeepIf(I16Slice{0, 1, 0, 3, 0, 5}, int16(0), I16Slice{0, 0, 0})
	ConfirmKeepIf(I16Slice{0, 1, 0, 3, 0, 5}, int16(1), I16Slice{1})
	ConfirmKeepIf(I16Slice{0, 1, 0, 3, 0, 5}, int16(6), I16Slice{})

	ConfirmKeepIf(I16Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int16(0) }, I16Slice{0, 0, 0})
	ConfirmKeepIf(I16Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int16(1) }, I16Slice{1})
	ConfirmKeepIf(I16Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int16(6) }, I16Slice{})

	ConfirmKeepIf(I16Slice{0, 1, 0, 3, 0, 5}, func(x int16) bool { return x == int16(0) }, I16Slice{0, 0, 0})
	ConfirmKeepIf(I16Slice{0, 1, 0, 3, 0, 5}, func(x int16) bool { return x == int16(1) }, I16Slice{1})
	ConfirmKeepIf(I16Slice{0, 1, 0, 3, 0, 5}, func(x int16) bool { return x == int16(6) }, I16Slice{})
}

func TestI16SliceReverseEach(t *testing.T) {
	var count	int16
	count = 9
	I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(i interface{}) {
		if i != count {
			t.Fatalf("0: element %v erroneously reported as %v", count, i)
		}
		count--
	})

	I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(index int, i interface{}) {
		if index != int(i.(int16)) {
			t.Fatalf("1: element %v erroneously reported as %v", index, i)
		}
	})

	I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(key, i interface{}) {
		if key.(int) != int(i.(int16)) {
			t.Fatalf("2: element %v erroneously reported as %v", key, i)
		}
	})

	count = 9
	I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(i int16) {
		if i != count {
			t.Fatalf("3: element %v erroneously reported as %v", count, i)
		}
		count--
	})

	I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(index int, i int16) {
		if int(i) != index {
			t.Fatalf("4: element %v erroneously reported as %v", index, i)
		}
	})

	I16Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(key interface{}, i int16) {
		if key.(int) != int(i) {
			t.Fatalf("5: element %v erroneously reported as %v", key, i)
		}
	})
}

func TestI16SliceReplaceIf(t *testing.T) {
	ConfirmReplaceIf := func(s I16Slice, f, v interface{}, r I16Slice) {
		if s.ReplaceIf(f, v); !r.Equal(s) {
			t.Fatalf("ReplaceIf(%v, %v) should be %v but is %v", f, v, r, s)
		}
	}

	ConfirmReplaceIf(I16Slice{0, 1, 0, 3, 0, 5}, int16(0), int16(1), I16Slice{1, 1, 1, 3, 1, 5})
	ConfirmReplaceIf(I16Slice{0, 1, 0, 3, 0, 5}, int16(1), int16(0), I16Slice{0, 0, 0, 3, 0, 5})
	ConfirmReplaceIf(I16Slice{0, 1, 0, 3, 0, 5}, int16(6), int16(0), I16Slice{0, 1, 0, 3, 0, 5})

	ConfirmReplaceIf(I16Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int16(0) }, int16(1), I16Slice{1, 1, 1, 3, 1, 5})
	ConfirmReplaceIf(I16Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int16(1) }, int16(0), I16Slice{0, 0, 0, 3, 0, 5})
	ConfirmReplaceIf(I16Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int16(6) }, int16(0), I16Slice{0, 1, 0, 3, 0, 5})

	ConfirmReplaceIf(I16Slice{0, 1, 0, 3, 0, 5}, func(x int16) bool { return x == int16(0) }, int16(1), I16Slice{1, 1, 1, 3, 1, 5})
	ConfirmReplaceIf(I16Slice{0, 1, 0, 3, 0, 5}, func(x int16) bool { return x == int16(1) }, int16(0), I16Slice{0, 0, 0, 3, 0, 5})
	ConfirmReplaceIf(I16Slice{0, 1, 0, 3, 0, 5}, func(x int16) bool { return x == int16(6) }, int16(0), I16Slice{0, 1, 0, 3, 0, 5})
}

func TestI16SliceReplace(t *testing.T) {
	ConfirmReplace := func(s I16Slice, v interface{}) {
		if s.Replace(v); !s.Equal(v) {
			t.Fatalf("Replace() should be %v but is %v", s, v)
		}
	}

	ConfirmReplace(I16Slice{0, 1, 2, 3, 4, 5}, I16Slice{9, 8, 7, 6, 5})
	ConfirmReplace(I16Slice{0, 1, 2, 3, 4, 5}, I16Slice{ 9, 8, 7, 6, 5 })
	ConfirmReplace(I16Slice{0, 1, 2, 3, 4, 5}, []int16{ 9, 8, 7, 6, 5 })
}

func TestI16SliceSelect(t *testing.T) {
	ConfirmSelect := func(s I16Slice, f interface{}, r I16Slice) {
		if x := s.Select(f); !r.Equal(x) {
			t.Fatalf("Select(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmSelect(I16Slice{0, 1, 0, 3, 0, 5}, int16(0), I16Slice{0, 0, 0})
	ConfirmSelect(I16Slice{0, 1, 0, 3, 0, 5}, int16(1), I16Slice{1})
	ConfirmSelect(I16Slice{0, 1, 0, 3, 0, 5}, int16(6), I16Slice{})

	ConfirmSelect(I16Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int16(0) }, I16Slice{0, 0, 0})
	ConfirmSelect(I16Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int16(1) }, I16Slice{1})
	ConfirmSelect(I16Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == int16(6) }, I16Slice{})

	ConfirmSelect(I16Slice{0, 1, 0, 3, 0, 5}, func(x int16) bool { return x == int16(0) }, I16Slice{0, 0, 0})
	ConfirmSelect(I16Slice{0, 1, 0, 3, 0, 5}, func(x int16) bool { return x == int16(1) }, I16Slice{1})
	ConfirmSelect(I16Slice{0, 1, 0, 3, 0, 5}, func(x int16) bool { return x == int16(6) }, I16Slice{})
}

func TestI16SliceUniq(t *testing.T) {
	ConfirmUniq := func(s, r I16Slice) {
		if s.Uniq(); !r.Equal(s) {
			t.Fatalf("Uniq() should be %v but is %v", r, s)
		}
	}

	ConfirmUniq(I16Slice{0, 0, 0, 0, 0, 0}, I16Slice{0})
	ConfirmUniq(I16Slice{0, 1, 0, 3, 0, 5}, I16Slice{0, 1, 3, 5})
}

func TestI16SlicePick(t *testing.T) {
	ConfirmPick := func(s I16Slice, i []int, r I16Slice) {
		if x := s.Pick(i...); !r.Equal(x) {
			t.Fatalf("%v.Pick(%v) should be %v but is %v", s, i, r, x)
		}
	}

	ConfirmPick(I16Slice{0, 1, 2, 3, 4, 5}, []int{}, I16Slice{})
	ConfirmPick(I16Slice{0, 1, 2, 3, 4, 5}, []int{ 0, 1 }, I16Slice{0, 1})
	ConfirmPick(I16Slice{0, 1, 2, 3, 4, 5}, []int{ 0, 3 }, I16Slice{0, 3})
	ConfirmPick(I16Slice{0, 1, 2, 3, 4, 5}, []int{ 0, 3, 4, 3 }, I16Slice{0, 3, 4, 3})
}

func TestI16SliceInsert(t *testing.T) {
	ConfirmInsert := func(s I16Slice, n int, v interface{}, r I16Slice) {
		if s.Insert(n, v); !r.Equal(s) {
			t.Fatalf("Insert(%v, %v) should be %v but is %v", n, v, r, s)
		}
	}

	ConfirmInsert(I16Slice{}, 0, int16(0), I16Slice{0})
	ConfirmInsert(I16Slice{}, 0, I16Slice{0}, I16Slice{0})
	ConfirmInsert(I16Slice{}, 0, I16Slice{0, 1}, I16Slice{0, 1})

	ConfirmInsert(I16Slice{0}, 0, int16(1), I16Slice{1, 0})
	ConfirmInsert(I16Slice{0}, 0, I16Slice{1}, I16Slice{1, 0})
	ConfirmInsert(I16Slice{0}, 1, int16(1), I16Slice{0, 1})
	ConfirmInsert(I16Slice{0}, 1, I16Slice{1}, I16Slice{0, 1})

	ConfirmInsert(I16Slice{0, 1, 2}, 0, int16(3), I16Slice{3, 0, 1, 2})
	ConfirmInsert(I16Slice{0, 1, 2}, 1, int16(3), I16Slice{0, 3, 1, 2})
	ConfirmInsert(I16Slice{0, 1, 2}, 2, int16(3), I16Slice{0, 1, 3, 2})
	ConfirmInsert(I16Slice{0, 1, 2}, 3, int16(3), I16Slice{0, 1, 2, 3})

	ConfirmInsert(I16Slice{0, 1, 2}, 0, I16Slice{3, 4}, I16Slice{3, 4, 0, 1, 2})
	ConfirmInsert(I16Slice{0, 1, 2}, 1, I16Slice{3, 4}, I16Slice{0, 3, 4, 1, 2})
	ConfirmInsert(I16Slice{0, 1, 2}, 2, I16Slice{3, 4}, I16Slice{0, 1, 3, 4, 2})
	ConfirmInsert(I16Slice{0, 1, 2}, 3, I16Slice{3, 4}, I16Slice{0, 1, 2, 3, 4})
}