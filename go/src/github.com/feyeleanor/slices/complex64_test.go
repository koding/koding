package slices

import "testing"

func TestC64SliceString(t *testing.T) {
	ConfirmString := func(s C64Slice, r string) {
		if x := s.String(); x != r {
			t.Fatalf("%v erroneously serialised as '%v'", r, x)
		}
	}

	ConfirmString(C64Slice{}, "()")
	ConfirmString(C64Slice{0}, "((0+0i))")
	ConfirmString(C64Slice{0, 1}, "((0+0i) (1+0i))")
	ConfirmString(C64Slice{0, 1i}, "((0+0i) (0+1i))")
}

func TestC64SliceLen(t *testing.T) {
	ConfirmLength := func(s C64Slice, i int) {
		if x := s.Len(); x != i {
			t.Fatalf("%v.Len() should be %v but is %v", s, i, x)
		}
	}
	
	ConfirmLength(C64Slice{0}, 1)
	ConfirmLength(C64Slice{0, 1}, 2)
}

func TestC64SliceSwap(t *testing.T) {
	ConfirmSwap := func(s C64Slice, i, j int, r C64Slice) {
		if s.Swap(i, j); !r.Equal(s) {
			t.Fatalf("Swap(%v, %v) should be %v but is %v", i, j, r, s)
		}
	}
	ConfirmSwap(C64Slice{0, 1, 2}, 0, 1, C64Slice{1, 0, 2})
	ConfirmSwap(C64Slice{0, 1, 2}, 0, 2, C64Slice{2, 1, 0})
}

func TestC64SliceCut(t *testing.T) {
	ConfirmCut := func(s C64Slice, start, end int, r C64Slice) {
		if s.Cut(start, end); !r.Equal(s) {
			t.Fatalf("Cut(%v, %v) should be %v but is %v", start, end, r, s)
		}
	}

	ConfirmCut(C64Slice{0, 1, 2, 3, 4, 5}, 0, 1, C64Slice{1, 2, 3, 4, 5})
	ConfirmCut(C64Slice{0, 1, 2, 3, 4, 5}, 1, 2, C64Slice{0, 2, 3, 4, 5})
	ConfirmCut(C64Slice{0, 1, 2, 3, 4, 5}, 2, 3, C64Slice{0, 1, 3, 4, 5})
	ConfirmCut(C64Slice{0, 1, 2, 3, 4, 5}, 3, 4, C64Slice{0, 1, 2, 4, 5})
	ConfirmCut(C64Slice{0, 1, 2, 3, 4, 5}, 4, 5, C64Slice{0, 1, 2, 3, 5})
	ConfirmCut(C64Slice{0, 1, 2, 3, 4, 5}, 5, 6, C64Slice{0, 1, 2, 3, 4})

	ConfirmCut(C64Slice{0, 1, 2, 3, 4, 5}, -1, 1, C64Slice{1, 2, 3, 4, 5})
	ConfirmCut(C64Slice{0, 1, 2, 3, 4, 5}, 0, 2, C64Slice{2, 3, 4, 5})
	ConfirmCut(C64Slice{0, 1, 2, 3, 4, 5}, 1, 3, C64Slice{0, 3, 4, 5})
	ConfirmCut(C64Slice{0, 1, 2, 3, 4, 5}, 2, 4, C64Slice{0, 1, 4, 5})
	ConfirmCut(C64Slice{0, 1, 2, 3, 4, 5}, 3, 5, C64Slice{0, 1, 2, 5})
	ConfirmCut(C64Slice{0, 1, 2, 3, 4, 5}, 4, 6, C64Slice{0, 1, 2, 3})
	ConfirmCut(C64Slice{0, 1, 2, 3, 4, 5}, 5, 7, C64Slice{0, 1, 2, 3, 4})
}

func TestC64SliceTrim(t *testing.T) {
	ConfirmTrim := func(s C64Slice, start, end int, r C64Slice) {
		if s.Trim(start, end); !r.Equal(s) {
			t.Fatalf("Trim(%v, %v) should be %v but is %v", start, end, r, s)
		}
	}

	ConfirmTrim(C64Slice{0, 1, 2, 3, 4, 5}, 0, 1, C64Slice{0})
	ConfirmTrim(C64Slice{0, 1, 2, 3, 4, 5}, 1, 2, C64Slice{1})
	ConfirmTrim(C64Slice{0, 1, 2, 3, 4, 5}, 2, 3, C64Slice{2})
	ConfirmTrim(C64Slice{0, 1, 2, 3, 4, 5}, 3, 4, C64Slice{3})
	ConfirmTrim(C64Slice{0, 1, 2, 3, 4, 5}, 4, 5, C64Slice{4})
	ConfirmTrim(C64Slice{0, 1, 2, 3, 4, 5}, 5, 6, C64Slice{5})

	ConfirmTrim(C64Slice{0, 1, 2, 3, 4, 5}, -1, 1, C64Slice{0})
	ConfirmTrim(C64Slice{0, 1, 2, 3, 4, 5}, 0, 2, C64Slice{0, 1})
	ConfirmTrim(C64Slice{0, 1, 2, 3, 4, 5}, 1, 3, C64Slice{1, 2})
	ConfirmTrim(C64Slice{0, 1, 2, 3, 4, 5}, 2, 4, C64Slice{2, 3})
	ConfirmTrim(C64Slice{0, 1, 2, 3, 4, 5}, 3, 5, C64Slice{3, 4})
	ConfirmTrim(C64Slice{0, 1, 2, 3, 4, 5}, 4, 6, C64Slice{4, 5})
	ConfirmTrim(C64Slice{0, 1, 2, 3, 4, 5}, 5, 7, C64Slice{5})
}

func TestC64SliceDelete(t *testing.T) {
	ConfirmDelete := func(s C64Slice, index int, r C64Slice) {
		if s.Delete(index); !r.Equal(s) {
			t.Fatalf("Delete(%v) should be %v but is %v", index, r, s)
		}
	}

	ConfirmDelete(C64Slice{0, 1, 2, 3, 4, 5}, -1, C64Slice{0, 1, 2, 3, 4, 5})
	ConfirmDelete(C64Slice{0, 1, 2, 3, 4, 5}, 0, C64Slice{1, 2, 3, 4, 5})
	ConfirmDelete(C64Slice{0, 1, 2, 3, 4, 5}, 1, C64Slice{0, 2, 3, 4, 5})
	ConfirmDelete(C64Slice{0, 1, 2, 3, 4, 5}, 2, C64Slice{0, 1, 3, 4, 5})
	ConfirmDelete(C64Slice{0, 1, 2, 3, 4, 5}, 3, C64Slice{0, 1, 2, 4, 5})
	ConfirmDelete(C64Slice{0, 1, 2, 3, 4, 5}, 4, C64Slice{0, 1, 2, 3, 5})
	ConfirmDelete(C64Slice{0, 1, 2, 3, 4, 5}, 5, C64Slice{0, 1, 2, 3, 4})
	ConfirmDelete(C64Slice{0, 1, 2, 3, 4, 5}, 6, C64Slice{0, 1, 2, 3, 4, 5})
}

func TestC64SliceDeleteIf(t *testing.T) {
	ConfirmDeleteIf := func(s C64Slice, f interface{}, r C64Slice) {
		if s.DeleteIf(f); !r.Equal(s) {
			t.Fatalf("DeleteIf(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmDeleteIf(C64Slice{0, 1, 0, 3, 0, 5}, complex64(0), C64Slice{1, 3, 5})
	ConfirmDeleteIf(C64Slice{0, 1, 0, 3, 0, 5}, complex64(1), C64Slice{0, 0, 3, 0, 5})
	ConfirmDeleteIf(C64Slice{0, 1, 0, 3, 0, 5}, complex64(6), C64Slice{0, 1, 0, 3, 0, 5})

	ConfirmDeleteIf(C64Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == complex64(0) }, C64Slice{1, 3, 5})
	ConfirmDeleteIf(C64Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == complex64(1) }, C64Slice{0, 0, 3, 0, 5})
	ConfirmDeleteIf(C64Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == complex64(6) }, C64Slice{0, 1, 0, 3, 0, 5})

	ConfirmDeleteIf(C64Slice{0, 1, 0, 3, 0, 5}, func(x complex64) bool { return x == complex64(0) }, C64Slice{1, 3, 5})
	ConfirmDeleteIf(C64Slice{0, 1, 0, 3, 0, 5}, func(x complex64) bool { return x == complex64(1) }, C64Slice{0, 0, 3, 0, 5})
	ConfirmDeleteIf(C64Slice{0, 1, 0, 3, 0, 5}, func(x complex64) bool { return x == complex64(6) }, C64Slice{0, 1, 0, 3, 0, 5})
}

func TestC64SliceEach(t *testing.T) {
	var count	complex64
	C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(i interface{}) {
		if i != count {
			t.Fatalf("element %v erroneously reported as %v", count, i)
		}
		count++
	})

	C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(index int, i interface{}) {
		if index != int(real(i.(complex64))) {
			t.Fatalf("element %v erroneously reported as %v", index, i)
		}
	})

	C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(key, i interface{}) {
		if complex(float32(key.(int)), 0) != i {
			t.Fatalf("element %v erroneously reported as %v", key, i)
		}
	})

	count = 0
	C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(i complex64) {
		if i != count {
			t.Fatalf("element %v erroneously reported as %v", count, i)
		}
		count++
	})

	C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(index int, i complex64) {
		if int(real(i)) != index {
			t.Fatalf("element %v erroneously reported as %v", index, i)
		}
	})

	C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.Each(func(key interface{}, i complex64) {
		if key.(int) != int(real(i)) {
			t.Fatalf("element %v erroneously reported as %v", key, i)
		}
	})
}

func TestC64SliceWhile(t *testing.T) {
	ConfirmLimit := func(s C64Slice, l int, f interface{}) {
		if count := s.While(f); count != l {
			t.Fatalf("%v.While() should have iterated %v times not %v times", s, l, count)
		}
	}

	s := C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}
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
	ConfirmLimit(s, limit, func(i complex64) bool {
		if count == limit {
			return false
		}
		count++
		return true
	})

	ConfirmLimit(s, limit, func(index int, i complex64) bool {
		return index != limit
	})

	ConfirmLimit(s, limit, func(key interface{}, i complex64) bool {
		return key.(int) != limit
	})
}

func TestC64SliceUntil(t *testing.T) {
	ConfirmLimit := func(s C64Slice, l int, f interface{}) {
		if count := s.Until(f); count != l {
			t.Fatalf("%v.Until() should have iterated %v times not %v times", s, l, count)
		}
	}

	s := C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}
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
	ConfirmLimit(s, limit, func(i complex64) bool {
		if count == limit {
			return true
		}
		count++
		return false
	})

	ConfirmLimit(s, limit, func(index int, i complex64) bool {
		return index == limit
	})

	ConfirmLimit(s, limit, func(key interface{}, i complex64) bool {
		return key.(int) == limit
	})
}

func TestC64SliceBlockCopy(t *testing.T) {
	ConfirmBlockCopy := func(s C64Slice, destination, source, count int, r C64Slice) {
		s.BlockCopy(destination, source, count)
		if !r.Equal(s) {
			t.Fatalf("BlockCopy(%v, %v, %v) should be %v but is %v", destination, source, count, r, s)
		}
	}

	ConfirmBlockCopy(C64Slice{}, 0, 0, 1, C64Slice{})
	ConfirmBlockCopy(C64Slice{}, 1, 0, 1, C64Slice{})
	ConfirmBlockCopy(C64Slice{}, 0, 1, 1, C64Slice{})

	ConfirmBlockCopy(C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 0, 0, 4, C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 9, 9, 4, C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 9, 0, 4, C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 0})
	ConfirmBlockCopy(C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 0, 4, C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 10, 4, C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, 2, 4, C64Slice{0, 1, 2, 3, 4, 2, 3, 4, 5, 9})
	ConfirmBlockCopy(C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 2, 5, 4, C64Slice{0, 1, 5, 6, 7, 8, 6, 7, 8, 9})
}

func TestC64SliceBlockClear(t *testing.T) {
	ConfirmBlockClear := func(s C64Slice, start, count int, r C64Slice) {
		s.BlockClear(start, count)
		if !r.Equal(s) {
			t.Fatalf("BlockClear(%v, %v) should be %v but is %v", start, count, r, s)
		}
	}

	ConfirmBlockClear(C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 0, 4, C64Slice{0, 0, 0, 0, 4, 5, 6, 7, 8, 9})
	ConfirmBlockClear(C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 4, C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockClear(C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, 4, C64Slice{0, 1, 2, 3, 4, 0, 0, 0, 0, 9})
}

func TestC64SliceOverwrite(t *testing.T) {
	ConfirmOverwrite := func(s C64Slice, offset int, v, r C64Slice) {
		s.Overwrite(offset, v)
		if !r.Equal(s) {
			t.Fatalf("Overwrite(%v, %v) should be %v but is %v", offset, v, r, s)
		}
	}

	ConfirmOverwrite(C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 0, C64Slice{10, 9, 8, 7}, C64Slice{10, 9, 8, 7, 4, 5, 6, 7, 8, 9})
	ConfirmOverwrite(C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, C64Slice{10, 9, 8, 7}, C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmOverwrite(C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, C64Slice{11, 12, 13, 14}, C64Slice{0, 1, 2, 3, 4, 11, 12, 13, 14, 9})
}

func TestC64SliceReallocate(t *testing.T) {
	ConfirmReallocate := func(s C64Slice, l, c int, r C64Slice) {
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

	ConfirmReallocate(C64Slice{}, 0, 10, make(C64Slice, 0, 10))
	ConfirmReallocate(C64Slice{0, 1, 2, 3, 4}, 3, 10, C64Slice{0, 1, 2})
	ConfirmReallocate(C64Slice{0, 1, 2, 3, 4}, 5, 10, C64Slice{0, 1, 2, 3, 4})
	ConfirmReallocate(C64Slice{0, 1, 2, 3, 4}, 10, 10, C64Slice{0, 1, 2, 3, 4, 0, 0, 0, 0, 0})
	ConfirmReallocate(C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 1, 5, C64Slice{0})
	ConfirmReallocate(C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, 5, C64Slice{0, 1, 2, 3, 4})
	ConfirmReallocate(C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 5, C64Slice{0, 1, 2, 3, 4})
}

func TestC64SliceExtend(t *testing.T) {
	ConfirmExtend := func(s C64Slice, n int, r C64Slice) {
		c := s.Cap()
		s.Extend(n)
		switch {
		case s.Len() != r.Len():	t.Fatalf("Extend(%v) len should be %v but is %v", n, r.Len(), s.Len())
		case s.Cap() != c + n:		t.Fatalf("Extend(%v) cap should be %v but is %v", n, c + n, s.Cap())
		case !r.Equal(s):			t.Fatalf("Extend(%v) should be %v but is %v", n, r, s)
		}
	}

	ConfirmExtend(C64Slice{}, 1, C64Slice{0})
	ConfirmExtend(C64Slice{}, 2, C64Slice{0, 0})
}

func TestC64SliceExpand(t *testing.T) {
	ConfirmExpand := func(s C64Slice, i, n int, r C64Slice) {
		c := s.Cap()
		s.Expand(i, n)
		switch {
		case s.Len() != r.Len():	t.Fatalf("Expand(%v, %v) len should be %v but is %v", i, n, r.Len(), s.Len())
		case s.Cap() != c + n:		t.Fatalf("Expand(%v, %v) cap should be %v but is %v", i, n, c + n, s.Cap())
		case !r.Equal(s):			t.Fatalf("Expand(%v, %v) should be %v but is %v", i, n, r, s)
		}
	}

	ConfirmExpand(C64Slice{}, -1, 1, C64Slice{0})
	ConfirmExpand(C64Slice{}, 0, 1, C64Slice{0})
	ConfirmExpand(C64Slice{}, 1, 1, C64Slice{0})
	ConfirmExpand(C64Slice{}, 0, 2, C64Slice{0, 0})

	ConfirmExpand(C64Slice{0, 1, 2}, -1, 2, C64Slice{0, 0, 0, 1, 2})
	ConfirmExpand(C64Slice{0, 1, 2}, 0, 2, C64Slice{0, 0, 0, 1, 2})
	ConfirmExpand(C64Slice{0, 1, 2}, 1, 2, C64Slice{0, 0, 0, 1, 2})
	ConfirmExpand(C64Slice{0, 1, 2}, 2, 2, C64Slice{0, 1, 0, 0, 2})
	ConfirmExpand(C64Slice{0, 1, 2}, 3, 2, C64Slice{0, 1, 2, 0, 0})
	ConfirmExpand(C64Slice{0, 1, 2}, 4, 2, C64Slice{0, 1, 2, 0, 0})
}

func TestC64SliceDepth(t *testing.T) {
	ConfirmDepth := func(s C64Slice, i int) {
		if x := s.Depth(); x != i {
			t.Fatalf("%v.Depth() should be %v but is %v", s, i, x)
		}
	}
	ConfirmDepth(C64Slice{0, 1}, 0)
}

func TestC64SliceReverse(t *testing.T) {
	ConfirmReverse := func(s, r C64Slice) {
		if s.Reverse(); !Equal(s, r) {
			t.Fatalf("Reverse() should be %v but is %v", r, s)
		}
	}
	ConfirmReverse(C64Slice{}, C64Slice{})
	ConfirmReverse(C64Slice{1}, C64Slice{1})
	ConfirmReverse(C64Slice{1, 2}, C64Slice{2, 1})
	ConfirmReverse(C64Slice{1, 2, 3}, C64Slice{3, 2, 1})
	ConfirmReverse(C64Slice{1, 2, 3, 4}, C64Slice{4, 3, 2, 1})
}

func TestC64SliceAppend(t *testing.T) {
	ConfirmAppend := func(s C64Slice, v interface{}, r C64Slice) {
		s.Append(v)
		if !r.Equal(s) {
			t.Fatalf("Append(%v) should be %v but is %v", v, r, s)
		}
	}

	ConfirmAppend(C64Slice{}, complex64(0), C64Slice{0})

	ConfirmAppend(C64Slice{}, C64Slice{0}, C64Slice{0})
	ConfirmAppend(C64Slice{}, C64Slice{0, 1}, C64Slice{0, 1})
	ConfirmAppend(C64Slice{0, 1, 2}, C64Slice{3, 4}, C64Slice{0, 1, 2, 3, 4})
}

func TestC64SlicePrepend(t *testing.T) {
	ConfirmPrepend := func(s C64Slice, v interface{}, r C64Slice) {
		if s.Prepend(v); !r.Equal(s) {
			t.Fatalf("Prepend(%v) should be %v but is %v", v, r, s)
		}
	}

	ConfirmPrepend(C64Slice{}, complex64(0), C64Slice{0})
	ConfirmPrepend(C64Slice{0}, complex64(1), C64Slice{1, 0})

	ConfirmPrepend(C64Slice{}, C64Slice{0}, C64Slice{0})
	ConfirmPrepend(C64Slice{}, C64Slice{0, 1}, C64Slice{0, 1})
	ConfirmPrepend(C64Slice{0, 1, 2}, C64Slice{3, 4}, C64Slice{3, 4, 0, 1, 2})
}

func TestC64SliceRepeat(t *testing.T) {
	ConfirmRepeat := func(s C64Slice, count int, r C64Slice) {
		if x := s.Repeat(count); !x.Equal(r) {
			t.Fatalf("%v.Repeat(%v) should be %v but is %v", s, count, r, x)
		}
	}

	ConfirmRepeat(C64Slice{}, 5, C64Slice{})
	ConfirmRepeat(C64Slice{0}, 1, C64Slice{0})
	ConfirmRepeat(C64Slice{0}, 2, C64Slice{0, 0})
	ConfirmRepeat(C64Slice{0}, 3, C64Slice{0, 0, 0})
	ConfirmRepeat(C64Slice{0}, 4, C64Slice{0, 0, 0, 0})
	ConfirmRepeat(C64Slice{0}, 5, C64Slice{0, 0, 0, 0, 0})
}

func TestC64SliceCar(t *testing.T) {
	ConfirmCar := func(s C64Slice, r complex64) {
		n := s.Car().(complex64)
		if ok := n == r; !ok {
			t.Fatalf("head should be '%v' but is '%v'", r, n)
		}
	}
	ConfirmCar(C64Slice{1, 2, 3}, 1)
}

func TestC64SliceCdr(t *testing.T) {
	ConfirmCdr := func(s, r C64Slice) {
		if n := s.Cdr(); !n.Equal(r) {
			t.Fatalf("tail should be '%v' but is '%v'", r, n)
		}
	}
	ConfirmCdr(C64Slice{1, 2, 3}, C64Slice{2, 3})
}

func TestC64SliceRplaca(t *testing.T) {
	ConfirmRplaca := func(s C64Slice, v interface{}, r C64Slice) {
		if s.Rplaca(v); !s.Equal(r) {
			t.Fatalf("slice should be '%v' but is '%v'", r, s)
		}
	}
	ConfirmRplaca(C64Slice{1, 2, 3, 4, 5}, complex64(0), C64Slice{0, 2, 3, 4, 5})
}

func TestC64SliceRplacd(t *testing.T) {
	ConfirmRplacd := func(s C64Slice, v interface{}, r C64Slice) {
		if s.Rplacd(v); !s.Equal(r) {
			t.Fatalf("slice should be '%v' but is '%v'", r, s)
		}
	}
	ConfirmRplacd(C64Slice{1, 2, 3, 4, 5}, nil, C64Slice{1})
	ConfirmRplacd(C64Slice{1, 2, 3, 4, 5}, complex64(10), C64Slice{1, 10})
	ConfirmRplacd(C64Slice{1, 2, 3, 4, 5}, C64Slice{5, 4, 3, 2}, C64Slice{1, 5, 4, 3, 2})
	ConfirmRplacd(C64Slice{1, 2, 3, 4, 5, 6}, C64Slice{2, 4, 8, 16}, C64Slice{1, 2, 4, 8, 16})
}

func TestC64SliceFind(t *testing.T) {
	ConfirmFind := func(s C64Slice, v complex64, i int) {
		if x, ok := s.Find(v); !ok || x != i {
			t.Fatalf("%v.Find(%v) should be %v but is %v", s, v, i, x)
		}
	}

	ConfirmFind(C64Slice{0, 1, 2, 3, 4}, 0, 0)
	ConfirmFind(C64Slice{0, 1, 2, 3, 4}, 1, 1)
	ConfirmFind(C64Slice{0, 1, 2, 4, 3}, 2, 2)
	ConfirmFind(C64Slice{0, 1, 2, 4, 3}, 3, 4)
	ConfirmFind(C64Slice{0, 1, 2, 4, 3}, 4, 3)
}

func TestC64SliceFindN(t *testing.T) {
	ConfirmFindN := func(s C64Slice, v complex64, n int, i ISlice) {
		if x := s.FindN(v, n); !x.Equal(i) {
			t.Fatalf("%v.Find(%v, %v) should be %v but is %v", s, v, n, i, x)
		}
	}

	ConfirmFindN(C64Slice{1, 0, 1, 0, 1}, 2, 3, ISlice{})
	ConfirmFindN(C64Slice{1, 0, 1, 0, 1}, 1, 0, ISlice{0, 2, 4})
	ConfirmFindN(C64Slice{1, 0, 1, 0, 1}, 1, 1, ISlice{0})
	ConfirmFindN(C64Slice{1, 0, 1, 0, 1}, 1, 2, ISlice{0, 2})
	ConfirmFindN(C64Slice{1, 0, 1, 0, 1}, 1, 3, ISlice{0, 2, 4})
	ConfirmFindN(C64Slice{1, 0, 1, 0, 1}, 1, 4, ISlice{0, 2, 4})
}

func TestC64SliceKeepIf(t *testing.T) {
	ConfirmKeepIf := func(s C64Slice, f interface{}, r C64Slice) {
		if s.KeepIf(f); !r.Equal(s) {
			t.Fatalf("KeepIf(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmKeepIf(C64Slice{0, 1, 0, 3, 0, 5}, complex64(0), C64Slice{0, 0, 0})
	ConfirmKeepIf(C64Slice{0, 1, 0, 3, 0, 5}, complex64(1), C64Slice{1})
	ConfirmKeepIf(C64Slice{0, 1, 0, 3, 0, 5}, complex64(6), C64Slice{})

	ConfirmKeepIf(C64Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == complex64(0) }, C64Slice{0, 0, 0})
	ConfirmKeepIf(C64Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == complex64(1) }, C64Slice{1})
	ConfirmKeepIf(C64Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == complex64(6) }, C64Slice{})

	ConfirmKeepIf(C64Slice{0, 1, 0, 3, 0, 5}, func(x complex64) bool { return x == complex64(0) }, C64Slice{0, 0, 0})
	ConfirmKeepIf(C64Slice{0, 1, 0, 3, 0, 5}, func(x complex64) bool { return x == complex64(1) }, C64Slice{1})
	ConfirmKeepIf(C64Slice{0, 1, 0, 3, 0, 5}, func(x complex64) bool { return x == complex64(6) }, C64Slice{})
}

func TestC64SliceReverseEach(t *testing.T) {
	var count	complex64
	count = 9
	C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(i interface{}) {
		if i != count {
			t.Fatalf("0: element %v erroneously reported as %v", count, i)
		}
		count--
	})

	C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(index int, i interface{}) {
		if index != int(real(i.(complex64))) {
			t.Fatalf("1: element %v erroneously reported as %v", index, i)
		}
	})

	C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(key, i interface{}) {
		if complex(float32(key.(int)), 0) != i {
			t.Fatalf("2: element %v erroneously reported as %v", key, i)
		}
	})

	count = 9
	C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(i complex64) {
		if i != count {
			t.Fatalf("3: element %v erroneously reported as %v", count, i)
		}
		count--
	})

	C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(index int, i complex64) {
		if int(real(i)) != index {
			t.Fatalf("4: element %v erroneously reported as %v", index, i)
		}
	})

	C64Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(key interface{}, i complex64) {
		if key.(int) != int(real(i)) {
			t.Fatalf("5: element %v erroneously reported as %v", key, i)
		}
	})
}

func TestC64SliceReplaceIf(t *testing.T) {
	ConfirmReplaceIf := func(s C64Slice, f, v interface{}, r C64Slice) {
		if s.ReplaceIf(f, v); !r.Equal(s) {
			t.Fatalf("ReplaceIf(%v, %v) should be %v but is %v", f, v, r, s)
		}
	}

	ConfirmReplaceIf(C64Slice{0, 1, 0, 3, 0, 5}, complex64(0), complex64(1), C64Slice{1, 1, 1, 3, 1, 5})
	ConfirmReplaceIf(C64Slice{0, 1, 0, 3, 0, 5}, complex64(1), complex64(0), C64Slice{0, 0, 0, 3, 0, 5})
	ConfirmReplaceIf(C64Slice{0, 1, 0, 3, 0, 5}, complex64(6), complex64(0), C64Slice{0, 1, 0, 3, 0, 5})

	ConfirmReplaceIf(C64Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == complex64(0) }, complex64(1), C64Slice{1, 1, 1, 3, 1, 5})
	ConfirmReplaceIf(C64Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == complex64(1) }, complex64(0), C64Slice{0, 0, 0, 3, 0, 5})
	ConfirmReplaceIf(C64Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == complex64(6) }, complex64(0), C64Slice{0, 1, 0, 3, 0, 5})

	ConfirmReplaceIf(C64Slice{0, 1, 0, 3, 0, 5}, func(x complex64) bool { return x == complex64(0) }, complex64(1), C64Slice{1, 1, 1, 3, 1, 5})
	ConfirmReplaceIf(C64Slice{0, 1, 0, 3, 0, 5}, func(x complex64) bool { return x == complex64(1) }, complex64(0), C64Slice{0, 0, 0, 3, 0, 5})
	ConfirmReplaceIf(C64Slice{0, 1, 0, 3, 0, 5}, func(x complex64) bool { return x == complex64(6) }, complex64(0), C64Slice{0, 1, 0, 3, 0, 5})
}

func TestC64SliceReplace(t *testing.T) {
	ConfirmReplace := func(s C64Slice, v interface{}) {
		if s.Replace(v); !s.Equal(v) {
			t.Fatalf("Replace() should be %v but is %v", s, v)
		}
	}

	ConfirmReplace(C64Slice{0, 1, 2, 3, 4, 5}, C64Slice{9, 8, 7, 6, 5})
	ConfirmReplace(C64Slice{0, 1, 2, 3, 4, 5}, []complex64{9, 8, 7, 6, 5})
}

func TestC64SliceSelect(t *testing.T) {
	ConfirmSelect := func(s C64Slice, f interface{}, r C64Slice) {
		if x := s.Select(f); !r.Equal(x) {
			t.Fatalf("Select(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmSelect(C64Slice{0, 1, 0, 3, 0, 5}, complex64(0), C64Slice{0, 0, 0})
	ConfirmSelect(C64Slice{0, 1, 0, 3, 0, 5}, complex64(1), C64Slice{1})
	ConfirmSelect(C64Slice{0, 1, 0, 3, 0, 5}, complex64(6), C64Slice{})

	ConfirmSelect(C64Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == complex64(0) }, C64Slice{0, 0, 0})
	ConfirmSelect(C64Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == complex64(1) }, C64Slice{1})
	ConfirmSelect(C64Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == complex64(6) }, C64Slice{})

	ConfirmSelect(C64Slice{0, 1, 0, 3, 0, 5}, func(x complex64) bool { return x == complex64(0) }, C64Slice{0, 0, 0})
	ConfirmSelect(C64Slice{0, 1, 0, 3, 0, 5}, func(x complex64) bool { return x == complex64(1) }, C64Slice{1})
	ConfirmSelect(C64Slice{0, 1, 0, 3, 0, 5}, func(x complex64) bool { return x == complex64(6) }, C64Slice{})
}

func TestC64SliceUniq(t *testing.T) {
	ConfirmUniq := func(s, r C64Slice) {
		if s.Uniq(); !r.Equal(s) {
			t.Fatalf("Uniq() should be %v but is %v", r, s)
		}
	}

	ConfirmUniq(C64Slice{0, 0, 0, 0, 0, 0}, C64Slice{0})
	ConfirmUniq(C64Slice{0, 1, 0, 3, 0, 5}, C64Slice{0, 1, 3, 5})
}

func TestC64SlicePick(t *testing.T) {
	ConfirmPick := func(s C64Slice, i []int, r C64Slice) {
		if x := s.Pick(i...); !r.Equal(x) {
			t.Fatalf("%v.Pick(%v) should be %v but is %v", s, i, r, x)
		}
	}

	ConfirmPick(C64Slice{0, 1, 2, 3, 4, 5}, []int{}, C64Slice{})
	ConfirmPick(C64Slice{0, 1, 2, 3, 4, 5}, []int{ 0, 1 }, C64Slice{0, 1})
	ConfirmPick(C64Slice{0, 1, 2, 3, 4, 5}, []int{ 0, 3 }, C64Slice{0, 3})
	ConfirmPick(C64Slice{0, 1, 2, 3, 4, 5}, []int{ 0, 3, 4, 3 }, C64Slice{0, 3, 4, 3})
}

func TestC64SliceInsert(t *testing.T) {
	ConfirmInsert := func(s C64Slice, n int, v interface{}, r C64Slice) {
		if s.Insert(n, v); !r.Equal(s) {
			t.Fatalf("Insert(%v, %v) should be %v but is %v", n, v, r, s)
		}
	}

	ConfirmInsert(C64Slice{}, 0, complex64(0), C64Slice{0})
	ConfirmInsert(C64Slice{}, 0, C64Slice{0}, C64Slice{0})
	ConfirmInsert(C64Slice{}, 0, C64Slice{0, 1}, C64Slice{0, 1})

	ConfirmInsert(C64Slice{0}, 0, complex64(1), C64Slice{1, 0})
	ConfirmInsert(C64Slice{0}, 0, C64Slice{1}, C64Slice{1, 0})
	ConfirmInsert(C64Slice{0}, 1, complex64(1), C64Slice{0, 1})
	ConfirmInsert(C64Slice{0}, 1, C64Slice{1}, C64Slice{0, 1})

	ConfirmInsert(C64Slice{0, 1, 2}, 0, complex64(3), C64Slice{3, 0, 1, 2})
	ConfirmInsert(C64Slice{0, 1, 2}, 1, complex64(3), C64Slice{0, 3, 1, 2})
	ConfirmInsert(C64Slice{0, 1, 2}, 2, complex64(3), C64Slice{0, 1, 3, 2})
	ConfirmInsert(C64Slice{0, 1, 2}, 3, complex64(3), C64Slice{0, 1, 2, 3})

	ConfirmInsert(C64Slice{0, 1, 2}, 0, C64Slice{3, 4}, C64Slice{3, 4, 0, 1, 2})
	ConfirmInsert(C64Slice{0, 1, 2}, 1, C64Slice{3, 4}, C64Slice{0, 3, 4, 1, 2})
	ConfirmInsert(C64Slice{0, 1, 2}, 2, C64Slice{3, 4}, C64Slice{0, 1, 3, 4, 2})
	ConfirmInsert(C64Slice{0, 1, 2}, 3, C64Slice{3, 4}, C64Slice{0, 1, 2, 3, 4})
}

func TestC64SlicePop(t *testing.T) {
	ConfirmPop := func(s C64Slice, x complex64, r C64Slice) {
		switch v, ok := s.Pop(); {
		case !ok:
			t.Fatalf("%v.Pop() should succeed but failed", s)
		case v != x:
			t.Fatalf("%v.Pop() should yield %v but yielded %v", s, x, v)
		case !r.Equal(s):
			t.Fatalf("%v.Pop() should leave %v", s, r)
		}
	}

	RefutePop := func(s C64Slice) {
		if v, ok := s.Pop(); ok {
			t.Fatalf("%v.Pop() should fail but succeeded yielding %v", s, v)
		}
	}

	RefutePop(C64Slice{})
	ConfirmPop(C64Slice{0}, 0, C64Slice{})
	ConfirmPop(C64Slice{0, 1}, 1, C64Slice{0})
}