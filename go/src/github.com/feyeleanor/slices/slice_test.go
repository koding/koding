package slices

import "github.com/feyeleanor/lists"
import "testing"

func TestSliceString(t *testing.T) {
	ConfirmString := func(s Slice, r string) {
		if x := s.String(); x != r {
			t.Fatalf("%v erroneously serialised as '%v'", r, x)
		}
	}

	ConfirmString(Slice{}, "()")
	ConfirmString(Slice{0}, "(0)")
	ConfirmString(Slice{0, 1}, "(0 1)")
	ConfirmString(Slice{Slice{0, 1}, 1}, "((0 1) 1)")
	ConfirmString(Slice{Slice{0, 1}, Slice{0, 1}}, "((0 1) (0 1))")
}

func TestSliceLen(t *testing.T) {
	ConfirmLength := func(s Slice, i int) {
		if x := s.Len(); x != i {
			t.Fatalf("%v.Len() should be %v but is %v", s, i, x)
		}
	}
	
	ConfirmLength(Slice{0}, 1)
	ConfirmLength(Slice{0, 1}, 2)
	ConfirmLength(Slice{Slice{0, 1}, 2}, 2)
	ConfirmLength(Slice{0, 1}, 2)
	ConfirmLength(Slice{Slice{0, 1}, 2}, 2)

	sxp := Slice{0, 1, Slice{2, Slice{3, 4, 5}}, Slice{6, 7, 8, 9}}
	ConfirmLength(sxp, 4)
	ConfirmLength(Slice{0, 1, Slice{2, Slice{3, 4, 5}}, sxp, Slice{6, 7, 8, 9}}, 5)
}

func TestSliceSwap(t *testing.T) {
	ConfirmSwap := func(s Slice, i, j int, r Slice) {
		if s.Swap(i, j); !r.Equal(s) {
			t.Fatalf("Swap(%v, %v) should be %v but is %v", i, j, r, s)
		}
	}
	ConfirmSwap(Slice{0, 1, 2}, 0, 1, Slice{1, 0, 2})
	ConfirmSwap(Slice{0, 1, 2}, 0, 2, Slice{2, 1, 0})
}

func TestSliceRestrictTo(t *testing.T) {
	ConfirmRestrictTo := func(s Slice, start, end int, r Slice) {
		if s.RestrictTo(start, end); !r.Equal(s) {
			t.Fatalf("Trim(%v, %v) should be %v but is %v", start, end, r, s)
		}
	}

	ConfirmRestrictTo(Slice{0, 1, 2, 3, 4, 5}, 0, 1, Slice{0})
	ConfirmRestrictTo(Slice{0, 1, 2, 3, 4, 5}, 1, 2, Slice{1})
	ConfirmRestrictTo(Slice{0, 1, 2, 3, 4, 5}, 2, 3, Slice{2})
	ConfirmRestrictTo(Slice{0, 1, 2, 3, 4, 5}, 3, 4, Slice{3})
	ConfirmRestrictTo(Slice{0, 1, 2, 3, 4, 5}, 4, 5, Slice{4})
	ConfirmRestrictTo(Slice{0, 1, 2, 3, 4, 5}, 5, 6, Slice{5})

	ConfirmRestrictTo(Slice{0, 1, 2, 3, 4, 5}, 0, 2, Slice{0, 1})
	ConfirmRestrictTo(Slice{0, 1, 2, 3, 4, 5}, 1, 3, Slice{1, 2})
	ConfirmRestrictTo(Slice{0, 1, 2, 3, 4, 5}, 2, 4, Slice{2, 3})
	ConfirmRestrictTo(Slice{0, 1, 2, 3, 4, 5}, 3, 5, Slice{3, 4})
	ConfirmRestrictTo(Slice{0, 1, 2, 3, 4, 5}, 4, 6, Slice{4, 5})
}

func TestSliceCut(t *testing.T) {
	ConfirmCut := func(s Slice, start, end int, r Slice) {
		if s.Cut(start, end); !r.Equal(s) {
			t.Fatalf("Cut(%v, %v) should be %v but is %v", start, end, r, s)
		}
	}

	ConfirmCut(Slice{0, 1, 2, 3, 4, 5}, 0, 1, Slice{1, 2, 3, 4, 5})
	ConfirmCut(Slice{0, 1, 2, 3, 4, 5}, 1, 2, Slice{0, 2, 3, 4, 5})
	ConfirmCut(Slice{0, 1, 2, 3, 4, 5}, 2, 3, Slice{0, 1, 3, 4, 5})
	ConfirmCut(Slice{0, 1, 2, 3, 4, 5}, 3, 4, Slice{0, 1, 2, 4, 5})
	ConfirmCut(Slice{0, 1, 2, 3, 4, 5}, 4, 5, Slice{0, 1, 2, 3, 5})
	ConfirmCut(Slice{0, 1, 2, 3, 4, 5}, 5, 6, Slice{0, 1, 2, 3, 4})

	ConfirmCut(Slice{0, 1, 2, 3, 4, 5}, -1, 1, Slice{1, 2, 3, 4, 5})
	ConfirmCut(Slice{0, 1, 2, 3, 4, 5}, 0, 2, Slice{2, 3, 4, 5})
	ConfirmCut(Slice{0, 1, 2, 3, 4, 5}, 1, 3, Slice{0, 3, 4, 5})
	ConfirmCut(Slice{0, 1, 2, 3, 4, 5}, 2, 4, Slice{0, 1, 4, 5})
	ConfirmCut(Slice{0, 1, 2, 3, 4, 5}, 3, 5, Slice{0, 1, 2, 5})
	ConfirmCut(Slice{0, 1, 2, 3, 4, 5}, 4, 6, Slice{0, 1, 2, 3})
	ConfirmCut(Slice{0, 1, 2, 3, 4, 5}, 5, 7, Slice{0, 1, 2, 3, 4})
}

func TestSliceTrim(t *testing.T) {
	ConfirmTrim := func(s Slice, start, end int, r Slice) {
		if s.Trim(start, end); !r.Equal(s) {
			t.Fatalf("Trim(%v, %v) should be %v but is %v", start, end, r, s)
		}
	}

	ConfirmTrim(Slice{0, 1, 2, 3, 4, 5}, 0, 1, Slice{0})
	ConfirmTrim(Slice{0, 1, 2, 3, 4, 5}, 1, 2, Slice{1})
	ConfirmTrim(Slice{0, 1, 2, 3, 4, 5}, 2, 3, Slice{2})
	ConfirmTrim(Slice{0, 1, 2, 3, 4, 5}, 3, 4, Slice{3})
	ConfirmTrim(Slice{0, 1, 2, 3, 4, 5}, 4, 5, Slice{4})
	ConfirmTrim(Slice{0, 1, 2, 3, 4, 5}, 5, 6, Slice{5})

	ConfirmTrim(Slice{0, 1, 2, 3, 4, 5}, -1, 1, Slice{0})
	ConfirmTrim(Slice{0, 1, 2, 3, 4, 5}, 0, 2, Slice{0, 1})
	ConfirmTrim(Slice{0, 1, 2, 3, 4, 5}, 1, 3, Slice{1, 2})
	ConfirmTrim(Slice{0, 1, 2, 3, 4, 5}, 2, 4, Slice{2, 3})
	ConfirmTrim(Slice{0, 1, 2, 3, 4, 5}, 3, 5, Slice{3, 4})
	ConfirmTrim(Slice{0, 1, 2, 3, 4, 5}, 4, 6, Slice{4, 5})
	ConfirmTrim(Slice{0, 1, 2, 3, 4, 5}, 5, 7, Slice{5})
}

func TestSliceDelete(t *testing.T) {
	ConfirmDelete := func(s Slice, index int, r Slice) {
		if s.Delete(index); !r.Equal(s) {
			t.Fatalf("Delete(%v) should be %v but is %v", index, r, s)
		}
	}

	ConfirmDelete(Slice{0, 1, 2, 3, 4, 5}, -1, Slice{0, 1, 2, 3, 4, 5})
	ConfirmDelete(Slice{0, 1, 2, 3, 4, 5}, 0, Slice{1, 2, 3, 4, 5})
	ConfirmDelete(Slice{0, 1, 2, 3, 4, 5}, 1, Slice{0, 2, 3, 4, 5})
	ConfirmDelete(Slice{0, 1, 2, 3, 4, 5}, 2, Slice{0, 1, 3, 4, 5})
	ConfirmDelete(Slice{0, 1, 2, 3, 4, 5}, 3, Slice{0, 1, 2, 4, 5})
	ConfirmDelete(Slice{0, 1, 2, 3, 4, 5}, 4, Slice{0, 1, 2, 3, 5})
	ConfirmDelete(Slice{0, 1, 2, 3, 4, 5}, 5, Slice{0, 1, 2, 3, 4})
	ConfirmDelete(Slice{0, 1, 2, 3, 4, 5}, 6, Slice{0, 1, 2, 3, 4, 5})
}

func TestSliceDeleteIf(t *testing.T) {
	ConfirmDeleteIf := func(s Slice, f interface{}, r Slice) {
		if s.DeleteIf(f); !r.Equal(s) {
			t.Fatalf("DeleteIf(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmDeleteIf(Slice{0, 1, 0, 3, 0, 5}, 0, Slice{1, 3, 5})
	ConfirmDeleteIf(Slice{0, 1, 0, 3, 0, 5}, 1, Slice{0, 0, 3, 0, 5})
	ConfirmDeleteIf(Slice{0, 1, 0, 3, 0, 5}, 6, Slice{0, 1, 0, 3, 0, 5})

	ConfirmDeleteIf(Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == 0 }, Slice{1, 3, 5})
	ConfirmDeleteIf(Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == 1 }, Slice{0, 0, 3, 0, 5})
	ConfirmDeleteIf(Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == 6 }, Slice{0, 1, 0, 3, 0, 5})
}

func TestSliceEach(t *testing.T) {
	count := 0
	s := Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}
	s.Each(func(i interface{}) {
		if i != count {
			t.Fatalf("element %v erroneously reported as %v", count, i)
		}
		count++
	})

	s.Each(func(index int, i interface{}) {
		if i != index {
			t.Fatalf("element %v erroneously reported as %v", index, i)
		}
	})

	s.Each(func(key, i interface{}) {
		if i != key {
			t.Fatalf("element %v erroneously reported as %v", key, i)
		}
	})
}

func TestSliceWhile(t *testing.T) {
	ConfirmLimit := func(s Slice, l int, f interface{}) {
		if count := s.While(f); count != l {
			t.Fatalf("%v.While() should have iterated %v times not %v times", s, l, count)
		}
	}

	s := Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}
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
}

func TestSliceUntil(t *testing.T) {
	ConfirmLimit := func(s Slice, l int, f interface{}) {
		if count := s.Until(f); count != l {
			t.Fatalf("%v.Until() should have iterated %v times not %v times", s, l, count)
		}
	}

	s := Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}
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
}

func TestSliceBlockCopy(t *testing.T) {
	ConfirmBlockCopy := func(s Slice, destination, source, count int, r Slice) {
		s.BlockCopy(destination, source, count)
		if !r.Equal(s) {
			t.Fatalf("BlockCopy(%v, %v, %v) should be %v but is %v", destination, source, count, r, s)
		}
	}

	ConfirmBlockCopy(Slice{}, 0, 0, 1, Slice{})
	ConfirmBlockCopy(Slice{}, 1, 0, 1, Slice{})
	ConfirmBlockCopy(Slice{}, 0, 1, 1, Slice{})

	ConfirmBlockCopy(Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 0, 0, 4, Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 0, 9, 4, Slice{9, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 9, 0, 4, Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 0})
	ConfirmBlockCopy(Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 0, 4, Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 10, 4, Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockCopy(Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, 2, 4, Slice{0, 1, 2, 3, 4, 2, 3, 4, 5, 9})
	ConfirmBlockCopy(Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 2, 5, 4, Slice{0, 1, 5, 6, 7, 8, 6, 7, 8, 9})
}

func TestSliceBlockClear(t *testing.T) {
	ConfirmBlockClear := func(s Slice, start, count int, r Slice) {
		s.BlockClear(start, count)
		if !r.Equal(s) {
			t.Fatalf("BlockClear(%v, %v) should be %v but is %v", start, count, r, s)
		}
	}

	ConfirmBlockClear(Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 0, 4, Slice{nil, nil, nil, nil, 4, 5, 6, 7, 8, 9})
	ConfirmBlockClear(Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 4, Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmBlockClear(Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, 4, Slice{0, 1, 2, 3, 4, nil, nil, nil, nil, 9})
}

func TestSliceOverwrite(t *testing.T) {
	ConfirmOverwrite := func(s Slice, offset int, v, r Slice) {
		s.Overwrite(offset, v)
		if !r.Equal(s) {
			t.Fatalf("Overwrite(%v, %v) should be %v but is %v", offset, v, r, s)
		}
	}

	ConfirmOverwrite(Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 0, Slice{10, 9, 8, 7}, Slice{10, 9, 8, 7, 4, 5, 6, 7, 8, 9})
	ConfirmOverwrite(Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, Slice{10, 9, 8, 7}, Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9})
	ConfirmOverwrite(Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, Slice{11, 12, 13, 14}, Slice{0, 1, 2, 3, 4, 11, 12, 13, 14, 9})
}

func TestSliceReallocate(t *testing.T) {
	ConfirmReallocate := func(s Slice, l, c int, r Slice) {
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

	ConfirmReallocate(Slice{}, 0, 10, make(Slice, 0, 10))
	ConfirmReallocate(Slice{0, 1, 2, 3, 4}, 3, 10, Slice{0, 1, 2})
	ConfirmReallocate(Slice{0, 1, 2, 3, 4}, 5, 10, Slice{0, 1, 2, 3, 4})
	ConfirmReallocate(Slice{0, 1, 2, 3, 4}, 10, 10, Slice{0, 1, 2, 3, 4, nil, nil, nil, nil, nil})
	ConfirmReallocate(Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 1, 5, Slice{0})
	ConfirmReallocate(Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 5, 5, Slice{0, 1, 2, 3, 4})
	ConfirmReallocate(Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 10, 5, Slice{0, 1, 2, 3, 4})
}

func TestSliceExtend(t *testing.T) {
	ConfirmExtend := func(s Slice, n int, r Slice) {
		c := s.Cap()
		s.Extend(n)
		switch {
		case s.Len() != r.Len():	t.Fatalf("Extend(%v) len should be %v but is %v", n, r.Len(), s.Len())
		case s.Cap() != c + n:		t.Fatalf("Extend(%v) cap should be %v but is %v", n, c + n, s.Cap())
		case !r.Equal(s):			t.Fatalf("Extend(%v) should be %v but is %v", n, r, s)
		}
	}

	ConfirmExtend(Slice{}, 1, Slice{nil})
	ConfirmExtend(Slice{}, 2, Slice{nil, nil})
}

func TestSliceExpand(t *testing.T) {
	ConfirmExpand := func(s Slice, i, n int, r Slice) {
		c := s.Cap()
		s.Expand(i, n)
		switch {
		case s.Len() != r.Len():	t.Fatalf("Expand(%v, %v) len should be %v but is %v", i, n, r.Len(), s.Len())
		case s.Cap() != c + n:		t.Fatalf("Expand(%v, %v) cap should be %v but is %v", i, n, c + n, s.Cap())
		case !r.Equal(s):			t.Fatalf("Expand(%v, %v) should be %v but is %v", i, n, r, s)
		}
	}

	ConfirmExpand(Slice{}, -1, 1, Slice{nil})
	ConfirmExpand(Slice{}, 0, 1, Slice{nil})
	ConfirmExpand(Slice{}, 1, 1, Slice{nil})
	ConfirmExpand(Slice{}, 0, 2, Slice{nil, nil})

	ConfirmExpand(Slice{0, 1, 2}, -1, 2, Slice{nil, nil, 0, 1, 2})
	ConfirmExpand(Slice{0, 1, 2}, 0, 2, Slice{nil, nil, 0, 1, 2})
	ConfirmExpand(Slice{0, 1, 2}, 1, 2, Slice{0, nil, nil, 1, 2})
	ConfirmExpand(Slice{0, 1, 2}, 2, 2, Slice{0, 1, nil, nil, 2})
	ConfirmExpand(Slice{0, 1, 2}, 3, 2, Slice{0, 1, 2, nil, nil})
	ConfirmExpand(Slice{0, 1, 2}, 4, 2, Slice{0, 1, 2, nil, nil})
}

func TestSliceDepth(t *testing.T) {
	ConfirmDepth := func(s Slice, i int) {
		if x := s.Depth(); x != i {
			t.Fatalf("%v.Depth() should be %v but is %v", s, i, x)
		}
	}
	ConfirmDepth(Slice{0, 1}, 0)
	ConfirmDepth(Slice{Slice{0, 1}, 2}, 1)
	ConfirmDepth(Slice{0, Slice{1, 2}}, 1)
	ConfirmDepth(Slice{0, 1, Slice{2, Slice{3, 4, 5}}}, 2)

	sxp := Slice{0, 1,
				Slice{2, Slice{3, 4, 5}},
				Slice{6, Slice{7, Slice{8, Slice{9, 0}}}},
				Slice{2, Slice{3, 4, 5}}}
	ConfirmDepth(sxp, 4)

	rxp := Slice{0, sxp, sxp}
	ConfirmDepth(rxp, 5)
	ConfirmDepth(Slice{rxp, sxp}, 6)
	t.Log("Need tests for circular recursive Slice?")
}

func TestSliceReverse(t *testing.T) {
	ConfirmReverse := func(s, r Slice) {
		if s.Reverse(); !Equal(s, r) {
			t.Fatalf("Reverse() should be %v but is %v", r, s)
		}
	}
	ConfirmReverse(Slice{}, Slice{})
	ConfirmReverse(Slice{1}, Slice{1})
	ConfirmReverse(Slice{1, 2}, Slice{2, 1})
	ConfirmReverse(Slice{1, 2, 3}, Slice{3, 2, 1})
	ConfirmReverse(Slice{1, 2, 3, 4}, Slice{4, 3, 2, 1})
}

func TestSliceAppend(t *testing.T) {
	ConfirmAppend := func(s Slice, v interface{}, r Slice) {
		if s.Append(v); !r.Equal(s) {
			t.Fatalf("Append(%v) should be %v but is %v", v, r, s)
		}
	}

	ConfirmAppend(Slice{}, 0, Slice{0})
	ConfirmAppend(Slice{}, Slice{0}, Slice{0})
	ConfirmAppend(Slice{}, Slice{0, 1}, Slice{0, 1})
	ConfirmAppend(Slice{0, 1, 2}, Slice{3, 4}, Slice{0, 1, 2, 3, 4})
}

func TestSlicePrepend(t *testing.T) {
	ConfirmPrepend := func(s Slice, v interface{}, r Slice) {
		if s.Prepend(v); !r.Equal(s) {
			t.Fatalf("Prepend(%v) should be %v but is %v", v, r, s)
		}
	}

	ConfirmPrepend(Slice{}, 0, Slice{0})
	ConfirmPrepend(Slice{0}, 1, Slice{1, 0})

	ConfirmPrepend(Slice{}, Slice{0}, Slice{0})
	ConfirmPrepend(Slice{}, Slice{0, 1}, Slice{0, 1})
	ConfirmPrepend(Slice{0, 1, 2}, Slice{3, 4}, Slice{3, 4, 0, 1, 2})
}

func TestSliceAppendSlice(t *testing.T) {
	ConfirmAppendSlice := func(s Slice, v interface{}, r Slice) {
		if s.AppendSlice(v); !r.Equal(s) {
			t.Fatalf("AppendSlice(%v) should be %v but is %v", v, r, s)
		}
	}

	ConfirmAppendSlice(Slice{}, Slice{0, 1}, Slice{Slice{0, 1}})
	ConfirmAppendSlice(Slice{0, 1, 2}, Slice{3, 4}, Slice{0, 1, 2, Slice{3, 4}})
}

func TestSlicePrependSlice(t *testing.T) {
	ConfirmPrependSlice := func(s Slice, v interface{}, r Slice) {
		if s.PrependSlice(v); !r.Equal(s) {
			t.Fatalf("PrependSlice(%v) should be %v but is %v", v, r, s)
		}
	}

	ConfirmPrependSlice(Slice{}, Slice{0, 1}, Slice{Slice{0, 1}})
	ConfirmPrependSlice(Slice{0, 1, 2}, Slice{3, 4}, Slice{Slice{3, 4}, 0, 1, 2})
}

func TestSliceRepeat(t *testing.T) {
	ConfirmRepeat := func(s Slice, count int, r Slice) {
		if x := s.Repeat(count); !x.Equal(r) {
			t.Fatalf("%v.Repeat(%v) should be %v but is %v", s, count, r, x)
		}
	}

	ConfirmRepeat(Slice{}, 5, Slice{})
	ConfirmRepeat(Slice{0}, 1, Slice{0})
	ConfirmRepeat(Slice{0}, 2, Slice{0, 0})
	ConfirmRepeat(Slice{0}, 3, Slice{0, 0, 0})
	ConfirmRepeat(Slice{0}, 4, Slice{0, 0, 0, 0})
	ConfirmRepeat(Slice{0}, 5, Slice{0, 0, 0, 0, 0})
}

func TestSliceFlatten(t *testing.T) {
	ConfirmFlatten := func(s, r Slice) {
		if s.Flatten(); !s.Equal(r) {
			t.Fatalf("%v should be %v", s, r)
		}
	}
	ConfirmFlatten(Slice{}, Slice{})
	ConfirmFlatten(Slice{1}, Slice{1})
	ConfirmFlatten(Slice{1, Slice{2}}, Slice{1, 2})
	ConfirmFlatten(Slice{1, Slice{2, Slice{3}}}, Slice{1, 2, 3})
	ConfirmFlatten(Slice{1, 2, Slice{3, Slice{4, 5}, Slice{6, Slice{7, 8, 9}, Slice{10, 11}}}}, Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11})

	ConfirmFlatten(Slice{0, lists.List(1, 2, Slice{3, 4})}, Slice{0, lists.List(1, 2, Slice{3, 4})})
	ConfirmFlatten(Slice{0, lists.List(1, 2, lists.List(3, 4))}, Slice{0, lists.List(1, 2, 3, 4)})

	ConfirmFlatten(Slice{0, lists.Loop(1, 2)}, Slice{0, lists.Loop(1, 2)})
	ConfirmFlatten(Slice{0, lists.List(1, lists.Loop(2, 3))}, Slice{0, lists.List(1, 2, 3)})

	ConfirmFlatten(Slice{0, lists.List(1, 2, lists.Loop(3, 4))}, Slice{0, lists.List(1, 2, 3, 4)})
	ConfirmFlatten(Slice{3, 4, Slice{5, 6, 7}}, Slice{3, 4, 5, 6, 7})
	ConfirmFlatten(Slice{0, lists.Loop(1, 2, Slice{3, 4, Slice{5, 6, 7}})}, Slice{0, lists.Loop(1, 2, Slice{3, 4, 5, 6, 7})})

	sxp := Slice{1, 2, Slice{3, Slice{4, 5}, Slice{6, Slice{7, 8, 9}, Slice{10, 11}}}}
	rxp := Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}
	sxp.Flatten()
	if !rxp.Equal(sxp) {
		t.Fatalf("Flatten failed: %v", sxp)
	}

	rxp = Slice{1, 2, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 3, 4, 5, 6, 7, 8, 9, 10, 11, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}
	sxp = Slice{1, 2, sxp, Slice{3, Slice{4, 5}, Slice{6, Slice{7, 8, 9}, Slice{10, 11}, sxp}}}
	sxp.Flatten()
	if !rxp.Equal(sxp) {
		t.Fatalf("Flatten failed with explicit expansions: %v", sxp)
	}
}

func TestSliceCar(t *testing.T) {
	ConfirmCar := func(s Slice, r interface{}) {
		var ok bool
		n := s.Car()
		switch n := n.(type) {
		case Equatable:		ok = n.Equal(r)
		default:			ok = n == r
		}
		if !ok {
			t.Fatalf("head should be '%v' but is '%v'", r, n)
		}
	}
	ConfirmCar(Slice{1, 2, 3}, 1)
	ConfirmCar(Slice{Slice{10, 20}, 2, 3}, Slice{10, 20})
}

func TestSliceCdr(t *testing.T) {
	ConfirmCdr := func(s, r Slice) {
		if n := s.Cdr(); !n.Equal(r) {
			t.Fatalf("tail should be '%v' but is '%v'", r, n)
		}
	}
	ConfirmCdr(Slice{1, 2, 3}, Slice{2, 3})
}

func TestSliceRplaca(t *testing.T) {
	ConfirmRplaca := func(s Slice, v interface{}, r Slice) {
		if s.Rplaca(v); !s.Equal(r) {
			t.Fatalf("slice should be '%v' but is '%v'", r, s)
		}
	}
	ConfirmRplaca(Slice{1, 2, 3, 4, 5}, 0, Slice{0, 2, 3, 4, 5})
	ConfirmRplaca(Slice{1, 2, 3, 4, 5}, Slice{1, 2, 3}, Slice{Slice{1, 2, 3}, 2, 3, 4, 5})
}

func TestSliceRplacd(t *testing.T) {
	ConfirmRplacd := func(s Slice, v interface{}, r Slice) {
		if s.Rplacd(v); !s.Equal(r) {
			t.Fatalf("slice should be '%v' but is '%v'", r, s)
		}
	}
	ConfirmRplacd(Slice{1, 2, 3, 4, 5}, nil, Slice{1})
	ConfirmRplacd(Slice{1, 2, 3, 4, 5}, 10, Slice{1, 10})
	ConfirmRplacd(Slice{1, 2, 3, 4, 5}, Slice{5, 4, 3, 2}, Slice{1, 5, 4, 3, 2})
	ConfirmRplacd(Slice{1, 2, 3, 4, 5, 6}, Slice{2, 4, 8, 16}, Slice{1, 2, 4, 8, 16})
}

func TestSliceFind(t *testing.T) {
	ConfirmFind := func(s Slice, v interface{}, i int) {
		if x, ok := s.Find(v); !ok || x != i {
			t.Fatalf("%v.Find(%v) should be %v but is %v", s, v, i, x)
		}
	}

	ConfirmFind(Slice{0, 1, 2, 3, 4}, 0, 0)
	ConfirmFind(Slice{0, 1, 2, 3, 4}, 1, 1)
	ConfirmFind(Slice{0, 1, 2, 4, 3}, 2, 2)
	ConfirmFind(Slice{0, 1, 2, 4, 3}, 3, 4)
	ConfirmFind(Slice{0, 1, 2, 4, 3}, 4, 3)
}

func TestSliceFindN(t *testing.T) {
	ConfirmFindN := func(s Slice, v interface{}, n int, i ISlice) {
		if x := s.FindN(v, n); !x.Equal(i) {
			t.Fatalf("%v.Find(%v, %v) should be %v but is %v", s, v, n, i, x)
		}
	}

	ConfirmFindN(Slice{1, 0, 1, 0, 1}, 2, 3, ISlice{})
	ConfirmFindN(Slice{1, 0, 1, 0, 1}, 1, 0, ISlice{0, 2, 4})
	ConfirmFindN(Slice{1, 0, 1, 0, 1}, 1, 1, ISlice{0})
	ConfirmFindN(Slice{1, 0, 1, 0, 1}, 1, 2, ISlice{0, 2})
	ConfirmFindN(Slice{1, 0, 1, 0, 1}, 1, 3, ISlice{0, 2, 4})
	ConfirmFindN(Slice{1, 0, 1, 0, 1}, 1, 4, ISlice{0, 2, 4})
}

func TestSliceKeepIf(t *testing.T) {
	ConfirmKeepIf := func(s Slice, f interface{}, r Slice) {
		if s.KeepIf(f); !r.Equal(s) {
			t.Fatalf("KeepIf(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmKeepIf(Slice{0, 1, 0, 3, 0, 5}, 0, Slice{0, 0, 0})
	ConfirmKeepIf(Slice{0, 1, 0, 3, 0, 5}, 1, Slice{1})
	ConfirmKeepIf(Slice{0, 1, 0, 3, 0, 5}, 6, Slice{})

	ConfirmKeepIf(Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == 0 }, Slice{0, 0, 0})
	ConfirmKeepIf(Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == 1 }, Slice{1})
	ConfirmKeepIf(Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == 6 }, Slice{})

	ConfirmKeepIf(Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == 0 }, Slice{0, 0, 0})
	ConfirmKeepIf(Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == 1 }, Slice{1})
	ConfirmKeepIf(Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == 6 }, Slice{})
}

func TestSliceReverseEach(t *testing.T) {
	var count	int
	count = 9
	Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(i interface{}) {
		if i != count {
			t.Fatalf("0: element %v erroneously reported as %v", count, i)
		}
		count--
	})

	Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(index int, i interface{}) {
		if index != i.(int) {
			t.Fatalf("1: element %v erroneously reported as %v", index, i)
		}
	})

	Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(key, i interface{}) {
		if interface{}(key.(int)) != i {
			t.Fatalf("2: element %v erroneously reported as %v", key, i)
		}
	})

	count = 9
	Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(i interface{}) {
		if i != count {
			t.Fatalf("3: element %v erroneously reported as %v", count, i)
		}
		count--
	})

	Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(index int, i interface{}) {
		if i.(int) != index {
			t.Fatalf("4: element %v erroneously reported as %v", index, i)
		}
	})

	Slice{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}.ReverseEach(func(key interface{}, i interface{}) {
		if key.(int) != i.(int) {
			t.Fatalf("5: element %v erroneously reported as %v", key, i)
		}
	})
}

func TestSliceReplaceIf(t *testing.T) {
	ConfirmReplaceIf := func(s Slice, f, v interface{}, r Slice) {
		if s.ReplaceIf(f, v); !r.Equal(s) {
			t.Fatalf("ReplaceIf(%v, %v) should be %v but is %v", f, v, r, s)
		}
	}

	ConfirmReplaceIf(Slice{0, 1, 0, 3, 0, 5}, 0, 1, Slice{1, 1, 1, 3, 1, 5})
	ConfirmReplaceIf(Slice{0, 1, 0, 3, 0, 5}, 1, 0, Slice{0, 0, 0, 3, 0, 5})
	ConfirmReplaceIf(Slice{0, 1, 0, 3, 0, 5}, 6, 0, Slice{0, 1, 0, 3, 0, 5})

	ConfirmReplaceIf(Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == 0 }, 1, Slice{1, 1, 1, 3, 1, 5})
	ConfirmReplaceIf(Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == 1 }, 0, Slice{0, 0, 0, 3, 0, 5})
	ConfirmReplaceIf(Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == 6 }, 0, Slice{0, 1, 0, 3, 0, 5})
}

func TestSliceReplace(t *testing.T) {
	ConfirmReplace := func(s Slice, v interface{}) {
		if s.Replace(v); !s.Equal(v) {
			t.Fatalf("Replace() should be %v but is %v", s, v)
		}
	}

	ConfirmReplace(Slice{0, 1, 2, 3, 4, 5}, Slice{9, 8, 7, 6, 5})
	ConfirmReplace(Slice{0, 1, 2, 3, 4, 5}, Slice{9, 8, 7, 6, 5})
	ConfirmReplace(Slice{0, 1, 2, 3, 4, 5}, []interface{}{9, 8, 7, 6, 5})
}

func TestSliceSelect(t *testing.T) {
	ConfirmSelect := func(s Slice, f interface{}, r Slice) {
		if x := s.Select(f); !r.Equal(x) {
			t.Fatalf("Select(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmSelect(Slice{0, 1, 0, 3, 0, 5}, 0, Slice{0, 0, 0})
	ConfirmSelect(Slice{0, 1, 0, 3, 0, 5}, 1, Slice{1})
	ConfirmSelect(Slice{0, 1, 0, 3, 0, 5}, 6, Slice{})

	ConfirmSelect(Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == 0 }, Slice{0, 0, 0})
	ConfirmSelect(Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == 1 }, Slice{1})
	ConfirmSelect(Slice{0, 1, 0, 3, 0, 5}, func(x interface{}) bool { return x == 6 }, Slice{})
}

func TestSliceUniq(t *testing.T) {
	ConfirmUniq := func(s, r Slice) {
		if s.Uniq(); !r.Equal(s) {
			t.Fatalf("Uniq() should be %v but is %v", r, s)
		}
	}

	ConfirmUniq(Slice{0, 0, 0, 0, 0, 0}, Slice{0})
	ConfirmUniq(Slice{0, 1, 0, 3, 0, 5}, Slice{0, 1, 3, 5})
}

func TestSlicePick(t *testing.T) {
	ConfirmPick := func(s Slice, i []int, r Slice) {
		if x := s.Pick(i...); !r.Equal(x) {
			t.Fatalf("%v.Pick(%v) should be %v but is %v", s, i, r, x)
		}
	}

	ConfirmPick(Slice{0, 1, 2, 3, 4, 5}, []int{}, Slice{})
	ConfirmPick(Slice{0, 1, 2, 3, 4, 5}, []int{ 0, 1 }, Slice{0, 1})
	ConfirmPick(Slice{0, 1, 2, 3, 4, 5}, []int{ 0, 3 }, Slice{0, 3})
	ConfirmPick(Slice{0, 1, 2, 3, 4, 5}, []int{ 0, 3, 4, 3 }, Slice{0, 3, 4, 3})
}

func TestSliceInsert(t *testing.T) {
	ConfirmInsert := func(s Slice, n int, v interface{}, r Slice) {
		if s.Insert(n, v); !r.Equal(s) {
			t.Fatalf("Insert(%v, %v) should be %v but is %v", n, v, r, s)
		}
	}

	ConfirmInsert(Slice{}, 0, 0, Slice{0})
	ConfirmInsert(Slice{}, 0, Slice{0}, Slice{0})
	ConfirmInsert(Slice{}, 0, Slice{0, 1}, Slice{0, 1})

	ConfirmInsert(Slice{0}, 0, 1, Slice{1, 0})
	ConfirmInsert(Slice{0}, 0, Slice{1}, Slice{1, 0})
	ConfirmInsert(Slice{0}, 1, 1, Slice{0, 1})
	ConfirmInsert(Slice{0}, 1, Slice{1}, Slice{0, 1})

	ConfirmInsert(Slice{0, 1, 2}, 0, 3, Slice{3, 0, 1, 2})
	ConfirmInsert(Slice{0, 1, 2}, 1, 3, Slice{0, 3, 1, 2})
	ConfirmInsert(Slice{0, 1, 2}, 2, 3, Slice{0, 1, 3, 2})
	ConfirmInsert(Slice{0, 1, 2}, 3, 3, Slice{0, 1, 2, 3})

	ConfirmInsert(Slice{0, 1, 2}, 0, Slice{3, 4}, Slice{3, 4, 0, 1, 2})
	ConfirmInsert(Slice{0, 1, 2}, 1, Slice{3, 4}, Slice{0, 3, 4, 1, 2})
	ConfirmInsert(Slice{0, 1, 2}, 2, Slice{3, 4}, Slice{0, 1, 3, 4, 2})
	ConfirmInsert(Slice{0, 1, 2}, 3, Slice{3, 4}, Slice{0, 1, 2, 3, 4})
}