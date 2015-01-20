package slices

import (
	"strconv"
	"testing"
)

func TestSSliceString(t *testing.T) {
	ConfirmString := func(s SSlice, r string) {
		if x := s.String(); x != r {
			t.Fatalf("%v erroneously serialised as '%v'", r, x)
		}
	}

	ConfirmString(SSlice{}, "()")
	ConfirmString(SSlice{"A"}, "(A)")
	ConfirmString(SSlice{"A", "B"}, "(A B)")
}

func TestSSliceLen(t *testing.T) {
	ConfirmLength := func(s SSlice, i int) {
		if x := s.Len(); x != i {
			t.Fatalf("%v.Len() should be %v but is %v", s, i, x)
		}
	}
	
	ConfirmLength(SSlice{"A"}, 1)
	ConfirmLength(SSlice{"A", "B"}, 2)
}

func TestSSliceSwap(t *testing.T) {
	ConfirmSwap := func(s SSlice, i, j int, r SSlice) {
		if s.Swap(i, j); !r.Equal(s) {
			t.Fatalf("Swap(%v, %v) should be %v but is %v", i, j, r, s)
		}
	}
	ConfirmSwap(SSlice{"A", "B", "C"}, 0, 1, SSlice{"B", "A", "C"})
	ConfirmSwap(SSlice{"A", "B", "C"}, 0, 2, SSlice{"C", "B", "A"})
}

func TestSSliceCompare(t *testing.T) {
	ConfirmCompare := func(s SSlice, i, j, r int) {
		if x := s.Compare(i, j); x != r {
			t.Fatalf("Compare(%v, %v) should be %v but is %v", i, j, r, x)
		}
	}

	ConfirmCompare(SSlice{"A", "B"}, 0, 0, IS_SAME_AS)
	ConfirmCompare(SSlice{"A", "B"}, 0, 1, IS_LESS_THAN)
	ConfirmCompare(SSlice{"A", "B"}, 1, 0, IS_GREATER_THAN)
}

func TestSSliceCut(t *testing.T) {
	ConfirmCut := func(s SSlice, start, end int, r SSlice) {
		if s.Cut(start, end); !r.Equal(s) {
			t.Fatalf("Cut(%v, %v) should be %v but is %v", start, end, r, s)
		}
	}

	ConfirmCut(SSlice{"A", "B", "C", "D", "E", "F"}, 0, 1, SSlice{"B", "C", "D", "E", "F"})
	ConfirmCut(SSlice{"A", "B", "C", "D", "E", "F"}, 1, 2, SSlice{"A", "C", "D", "E", "F"})
	ConfirmCut(SSlice{"A", "B", "C", "D", "E", "F"}, 2, 3, SSlice{"A", "B", "D", "E", "F"})
	ConfirmCut(SSlice{"A", "B", "C", "D", "E", "F"}, 3, 4, SSlice{"A", "B", "C", "E", "F"})
	ConfirmCut(SSlice{"A", "B", "C", "D", "E", "F"}, 4, 5, SSlice{"A", "B", "C", "D", "F"})
	ConfirmCut(SSlice{"A", "B", "C", "D", "E", "F"}, 5, 6, SSlice{"A", "B", "C", "D", "E"})

	ConfirmCut(SSlice{"A", "B", "C", "D", "E", "F"}, -1, 1, SSlice{"B", "C", "D", "E", "F"})
	ConfirmCut(SSlice{"A", "B", "C", "D", "E", "F"}, 0, 2, SSlice{"C", "D", "E", "F"})
	ConfirmCut(SSlice{"A", "B", "C", "D", "E", "F"}, 1, 3, SSlice{"A", "D", "E", "F"})
	ConfirmCut(SSlice{"A", "B", "C", "D", "E", "F"}, 2, 4, SSlice{"A", "B", "E", "F"})
	ConfirmCut(SSlice{"A", "B", "C", "D", "E", "F"}, 3, 5, SSlice{"A", "B", "C", "F"})
	ConfirmCut(SSlice{"A", "B", "C", "D", "E", "F"}, 4, 6, SSlice{"A", "B", "C", "D"})
	ConfirmCut(SSlice{"A", "B", "C", "D", "E", "F"}, 5, 7, SSlice{"A", "B", "C", "D", "E"})
}

func TestSSliceTrim(t *testing.T) {
	ConfirmTrim := func(s SSlice, start, end int, r SSlice) {
		if s.Trim(start, end); !r.Equal(s) {
			t.Fatalf("Trim(%v, %v) should be %v but is %v", start, end, r, s)
		}
	}

	ConfirmTrim(SSlice{"A", "B", "C", "D", "E", "F"}, 0, 1, SSlice{"A"})
	ConfirmTrim(SSlice{"A", "B", "C", "D", "E", "F"}, 1, 2, SSlice{"B"})
	ConfirmTrim(SSlice{"A", "B", "C", "D", "E", "F"}, 2, 3, SSlice{"C"})
	ConfirmTrim(SSlice{"A", "B", "C", "D", "E", "F"}, 3, 4, SSlice{"D"})
	ConfirmTrim(SSlice{"A", "B", "C", "D", "E", "F"}, 4, 5, SSlice{"E"})
	ConfirmTrim(SSlice{"A", "B", "C", "D", "E", "F"}, 5, 6, SSlice{"F"})

	ConfirmTrim(SSlice{"A", "B", "C", "D", "E", "F"}, -1, 1, SSlice{"A"})
	ConfirmTrim(SSlice{"A", "B", "C", "D", "E", "F"}, 0, 2, SSlice{"A", "B"})
	ConfirmTrim(SSlice{"A", "B", "C", "D", "E", "F"}, 1, 3, SSlice{"B", "C"})
	ConfirmTrim(SSlice{"A", "B", "C", "D", "E", "F"}, 2, 4, SSlice{"C", "D"})
	ConfirmTrim(SSlice{"A", "B", "C", "D", "E", "F"}, 3, 5, SSlice{"D", "E"})
	ConfirmTrim(SSlice{"A", "B", "C", "D", "E", "F"}, 4, 6, SSlice{"E", "F"})
	ConfirmTrim(SSlice{"A", "B", "C", "D", "E", "F"}, 5, 7, SSlice{"F"})
}

func TestSSliceDelete(t *testing.T) {
	ConfirmDelete := func(s SSlice, index int, r SSlice) {
		if s.Delete(index); !r.Equal(s) {
			t.Fatalf("Delete(%v) should be %v but is %v", index, r, s)
		}
	}

	ConfirmDelete(SSlice{"A", "B", "C", "D", "E", "F"}, -1, SSlice{"A", "B", "C", "D", "E", "F"})
	ConfirmDelete(SSlice{"A", "B", "C", "D", "E", "F"}, 0, SSlice{"B", "C", "D", "E", "F"})
	ConfirmDelete(SSlice{"A", "B", "C", "D", "E", "F"}, 1, SSlice{"A", "C", "D", "E", "F"})
	ConfirmDelete(SSlice{"A", "B", "C", "D", "E", "F"}, 2, SSlice{"A", "B", "D", "E", "F"})
	ConfirmDelete(SSlice{"A", "B", "C", "D", "E", "F"}, 3, SSlice{"A", "B", "C", "E", "F"})
	ConfirmDelete(SSlice{"A", "B", "C", "D", "E", "F"}, 4, SSlice{"A", "B", "C", "D", "F"})
	ConfirmDelete(SSlice{"A", "B", "C", "D", "E", "F"}, 5, SSlice{"A", "B", "C", "D", "E"})
	ConfirmDelete(SSlice{"A", "B", "C", "D", "E", "F"}, 6, SSlice{"A", "B", "C", "D", "E", "F"})
}

func TestSSliceDeleteIf(t *testing.T) {
	ConfirmDeleteIf := func(s SSlice, f interface{}, r SSlice) {
		if s.DeleteIf(f); !r.Equal(s) {
			t.Fatalf("DeleteIf(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmDeleteIf(SSlice{"A", "B", "A", "C", "A", "E"}, string("A"), SSlice{"B", "C", "E"})
	ConfirmDeleteIf(SSlice{"A", "B", "A", "C", "A", "E"}, string("B"), SSlice{"A", "A", "C", "A", "E"})
	ConfirmDeleteIf(SSlice{"A", "B", "A", "C", "A", "E"}, string("F"), SSlice{"A", "B", "A", "C", "A", "E"})

	ConfirmDeleteIf(SSlice{"A", "B", "A", "C", "A", "E"}, func(x interface{}) bool { return x == "A" }, SSlice{"B", "C", "E"})
	ConfirmDeleteIf(SSlice{"A", "B", "A", "C", "A", "E"}, func(x interface{}) bool { return x == "B" }, SSlice{"A", "A", "C", "A", "E"})
	ConfirmDeleteIf(SSlice{"A", "B", "A", "C", "A", "E"}, func(x interface{}) bool { return x == "F" }, SSlice{"A", "B", "A", "C", "A", "E"})

	ConfirmDeleteIf(SSlice{"A", "B", "A", "C", "A", "E"}, func(x string) bool { return x == "A" }, SSlice{"B", "C", "E"})
	ConfirmDeleteIf(SSlice{"A", "B", "A", "C", "A", "E"}, func(x string) bool { return x == "B" }, SSlice{"A", "A", "C", "A", "E"})
	ConfirmDeleteIf(SSlice{"A", "B", "A", "C", "A", "E"}, func(x string) bool { return x == "F" }, SSlice{"A", "B", "A", "C", "A", "E"})
}

func TestSSliceEach(t *testing.T) {
	count := 0
	s := SSlice{"A", "B", "C", "D", "E", "F"}
	s.Each(func(i interface{}) {
		if i != string([]byte{ byte(count) + "A"[0] }) {
			t.Fatalf("element %v erroneously reported as %v", count, i)
		}
		count++
	})

	s.Each(func(index int, i interface{}) {
		if i != string([]byte{ byte(index) + "A"[0] }) {
			t.Fatalf("element %v erroneously reported as %v", index, i)
		}
	})

	s.Each(func(key, i interface{}) {
		if i != string([]byte{ byte(key.(int)) + "A"[0] }) {
			t.Fatalf("element %v erroneously reported as %v", key, i)
		}
	})

	count = 0
	s.Each(func(i string) {
		if i != string([]byte{ byte(count) + "A"[0] }) {
			t.Fatalf("element %v erroneously reported as %v", count, i)
		}
		count++
	})

	s.Each(func(index int, i string) {
		if i != string([]byte{ byte(index) + "A"[0] }) {
			t.Fatalf("element %v erroneously reported as %v", index, i)
		}
	})

	s.Each(func(key interface{}, i string) {
		if i != string([]byte{ byte(key.(int)) + "A"[0] }) {
			t.Fatalf("element %v erroneously reported as %v", key, i)
		}
	})
}

func TestSSliceWhile(t *testing.T) {
	ConfirmLimit := func(s SSlice, l int, f interface{}) {
		if count := s.While(f); count != l {
			t.Fatalf("%v.While() should have iterated %v times not %v times", s, l, count)
		}
	}

	s := SSlice{"A", "B", "C", "D", "E", "F"}
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
	ConfirmLimit(s, limit, func(i string) bool {
		if count == limit {
			return false
		}
		count++
		return true
	})

	ConfirmLimit(s, limit, func(index int, i string) bool {
		return index != limit
	})

	ConfirmLimit(s, limit, func(key interface{}, i string) bool {
		return key.(int) != limit
	})
}

func TestSSliceUntil(t *testing.T) {
	ConfirmLimit := func(s SSlice, l int, f interface{}) {
		if count := s.Until(f); count != l {
			t.Fatalf("%v.Until() should have iterated %v times not %v times", s, l, count)
		}
	}

	s := SSlice{"A", "B", "C", "D", "E", "F"}
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
	ConfirmLimit(s, limit, func(i string) bool {
		if count == limit {
			return true
		}
		count++
		return false
	})

	ConfirmLimit(s, limit, func(index int, i string) bool {
		return index == limit
	})

	ConfirmLimit(s, limit, func(key interface{}, i string) bool {
		return key.(int) == limit
	})
}

func TestSSliceBlockCopy(t *testing.T) {
	ConfirmBlockCopy := func(s SSlice, destination, source, count int, r SSlice) {
		s.BlockCopy(destination, source, count)
		if !r.Equal(s) {
			t.Fatalf("BlockCopy(%v, %v, %v) should be %v but is %v", destination, source, count, r, s)
		}
	}

	ConfirmBlockCopy(SSlice{}, 0, 0, 1, SSlice{})
	ConfirmBlockCopy(SSlice{}, 1, 0, 1, SSlice{})
	ConfirmBlockCopy(SSlice{}, 0, 1, 1, SSlice{})

	ConfirmBlockCopy(SSlice{"A", "B", "C", "D", "E", "F"}, 0, 0, 4, SSlice{"A", "B", "C", "D", "E", "F"})
	ConfirmBlockCopy(SSlice{"A", "B", "C", "D", "E", "F"}, 5, 0, 4, SSlice{"A", "B", "C", "D", "E", "A"})
	ConfirmBlockCopy(SSlice{"A", "B", "C", "D", "E", "F"}, 6, 0, 4, SSlice{"A", "B", "C", "D", "E", "F"})
	ConfirmBlockCopy(SSlice{"A", "B", "C", "D", "E", "F"}, 0, 6, 4, SSlice{"A", "B", "C", "D", "E", "F"})
	ConfirmBlockCopy(SSlice{"A", "B", "C", "D", "E", "F"}, 6, 6, 4, SSlice{"A", "B", "C", "D", "E", "F"})
	ConfirmBlockCopy(SSlice{"A", "B", "C", "D", "E", "F"}, 4, 2, 2, SSlice{"A", "B", "C", "D", "C", "D"})
	ConfirmBlockCopy(SSlice{"A", "B", "C", "D", "E", "F"}, 2, 4, 4, SSlice{"A", "B", "E", "F", "E", "F"})
}

func TestSSliceBlockClear(t *testing.T) {
	ConfirmBlockClear := func(s SSlice, start, count int, r SSlice) {
		s.BlockClear(start, count)
		if !r.Equal(s) {
			t.Fatalf("BlockClear(%v, %v) should be %v but is %v", start, count, r, s)
		}
	}

	ConfirmBlockClear(SSlice{"A", "B", "C", "D", "E", "F"}, 0, 4, SSlice{"", "", "", "", "E", "F"})
	ConfirmBlockClear(SSlice{"A", "B", "C", "D", "E", "F"}, 1, 4, SSlice{"A", "", "", "", "", "F"})
	ConfirmBlockClear(SSlice{"A", "B", "C", "D", "E", "F"}, 2, 4, SSlice{"A", "B", "", "", "", ""})
}

func TestSSliceOverwrite(t *testing.T) {
	ConfirmOverwrite := func(s SSlice, offset int, v, r SSlice) {
		s.Overwrite(offset, v)
		if !r.Equal(s) {
			t.Fatalf("Overwrite(%v, %v) should be %v but is %v", offset, v, r, s)
		}
	}

	ConfirmOverwrite(SSlice{"A", "B", "C", "D", "E", "F"}, 0, SSlice{"Z", "Y", "X"}, SSlice{"Z", "Y", "X", "D", "E", "F"})
	ConfirmOverwrite(SSlice{"A", "B", "C", "D", "E", "F"}, 6, SSlice{"Z", "Y", "X"}, SSlice{"A", "B", "C", "D", "E", "F"})
	ConfirmOverwrite(SSlice{"A", "B", "C", "D", "E", "F"}, 2, SSlice{"Z", "Y", "X"}, SSlice{"A", "B", "Z", "Y", "X", "F"})
}

func TestSSliceReallocate(t *testing.T) {
	ConfirmReallocate := func(s SSlice, l, c int, r SSlice) {
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

	ConfirmReallocate(SSlice{}, 0, 10, make(SSlice, 0, 10))
	ConfirmReallocate(SSlice{"A", "B", "C", "D", "E", "F"}, 3, 10, SSlice{"A", "B", "C"})
	ConfirmReallocate(SSlice{"A", "B", "C", "D", "E", "F"}, 6, 10, SSlice{"A", "B", "C", "D", "E", "F"})
	ConfirmReallocate(SSlice{"A", "B", "C", "D", "E", "F"}, 10, 10, SSlice{"A", "B", "C", "D", "E", "F", "", "", "", ""})
	ConfirmReallocate(SSlice{"A", "B", "C", "D", "E", "F"}, 1, 3, SSlice{"A"})
	ConfirmReallocate(SSlice{"A", "B", "C", "D", "E", "F"}, 3, 3, SSlice{"A", "B", "C"})
	ConfirmReallocate(SSlice{"A", "B", "C", "D", "E", "F"}, 6, 3, SSlice{"A", "B", "C"})
}

func TestSSliceExtend(t *testing.T) {
	ConfirmExtend := func(s SSlice, n int, r SSlice) {
		c := s.Cap()
		s.Extend(n)
		switch {
		case s.Len() != r.Len():	t.Fatalf("Extend(%v) len should be %v but is %v", n, r.Len(), s.Len())
		case s.Cap() != c + n:		t.Fatalf("Extend(%v) cap should be %v but is %v", n, c + n, s.Cap())
		case !r.Equal(s):			t.Fatalf("Extend(%v) should be %v but is %v", n, r, s)
		}
	}

	ConfirmExtend(SSlice{}, 1, SSlice{""})
	ConfirmExtend(SSlice{}, 2, SSlice{"", ""})
}

func TestSSliceExpand(t *testing.T) {
	ConfirmExpand := func(s SSlice, i, n int, r SSlice) {
		c := s.Cap()
		s.Expand(i, n)
		switch {
		case s.Len() != r.Len():	t.Fatalf("Expand(%v, %v) len should be %v but is %v", i, n, r.Len(), s.Len())
		case s.Cap() != c + n:		t.Fatalf("Expand(%v, %v) cap should be %v but is %v", i, n, c + n, s.Cap())
		case !r.Equal(s):			t.Fatalf("Expand(%v, %v) should be %v but is %v", i, n, r, s)
		}
	}

	ConfirmExpand(SSlice{}, -1, 1, SSlice{""})
	ConfirmExpand(SSlice{}, 0, 1, SSlice{""})
	ConfirmExpand(SSlice{}, 1, 1, SSlice{""})
	ConfirmExpand(SSlice{}, 0, 2, SSlice{"", ""})

	ConfirmExpand(SSlice{"A", "B", "C"}, -1, 2, SSlice{"", "", "A", "B", "C"})
	ConfirmExpand(SSlice{"A", "B", "C"}, 0, 2, SSlice{"", "", "A", "B", "C"})
	ConfirmExpand(SSlice{"A", "B", "C"}, 1, 2, SSlice{"A", "", "", "B", "C"})
	ConfirmExpand(SSlice{"A", "B", "C"}, 2, 2, SSlice{"A", "B", "", "", "C"})
	ConfirmExpand(SSlice{"A", "B", "C"}, 3, 2, SSlice{"A", "B", "C", "", ""})
	ConfirmExpand(SSlice{"A", "B", "C"}, 4, 2, SSlice{"A", "B", "C", "", ""})
}

func TestSSliceDepth(t *testing.T) {
	ConfirmDepth := func(s SSlice, i int) {
		if x := s.Depth(); x != i {
			t.Fatalf("%v.Depth() should be %v but is %v", s, i, x)
		}
	}
	ConfirmDepth(SSlice{"A", "B"}, 0)
}

func TestSSliceReverse(t *testing.T) {
	ConfirmReverse := func(s, r SSlice) {
		if s.Reverse(); !Equal(s, r) {
			t.Fatalf("Reverse() should be %v but is %v", r, s)
		}
	}
	ConfirmReverse(SSlice{}, SSlice{})
	ConfirmReverse(SSlice{"A"}, SSlice{"A"})
	ConfirmReverse(SSlice{"A", "B"}, SSlice{"B", "A"})
	ConfirmReverse(SSlice{"A", "B", "C"}, SSlice{"C", "B", "A"})
	ConfirmReverse(SSlice{"A", "B", "C", "D"}, SSlice{"D", "C", "B", "A"})
}

func TestSSliceAppend(t *testing.T) {
	ConfirmAppend := func(s SSlice, v interface{}, r SSlice) {
		s.Append(v)
		if !r.Equal(s) {
			t.Fatalf("Append(%v) should be %v but is %v", v, r, s)
		}
	}

	ConfirmAppend(SSlice{}, "A", SSlice{"A"})

	ConfirmAppend(SSlice{}, SSlice{"A"}, SSlice{"A"})
	ConfirmAppend(SSlice{}, SSlice{"A", "B"}, SSlice{"A", "B"})
	ConfirmAppend(SSlice{"A", "B", "C"}, SSlice{"D", "E", "F"}, SSlice{"A", "B", "C", "D", "E", "F"})
}

func TestSSlicePrepend(t *testing.T) {
	ConfirmPrepend := func(s SSlice, v interface{}, r SSlice) {
		if s.Prepend(v); !r.Equal(s) {
			t.Fatalf("Prepend(%v) should be %v but is %v", v, r, s)
		}
	}

	ConfirmPrepend(SSlice{}, "A", SSlice{"A"})
	ConfirmPrepend(SSlice{"A"}, "B", SSlice{"B", "A"})

	ConfirmPrepend(SSlice{}, SSlice{"A"}, SSlice{"A"})
	ConfirmPrepend(SSlice{}, SSlice{"A", "B"}, SSlice{"A", "B"})
	ConfirmPrepend(SSlice{"A", "B", "C"}, SSlice{"D", "E", "F"}, SSlice{"D", "E", "F", "A", "B", "C"})
}

func TestSSliceRepeat(t *testing.T) {
	ConfirmRepeat := func(s SSlice, count int, r SSlice) {
		if x := s.Repeat(count); !x.Equal(r) {
			t.Fatalf("%v.Repeat(%v) should be %v but is %v", s, count, r, x)
		}
	}

	ConfirmRepeat(SSlice{}, 5, SSlice{})
	ConfirmRepeat(SSlice{"A"}, 1, SSlice{"A"})
	ConfirmRepeat(SSlice{"A"}, 2, SSlice{"A", "A"})
	ConfirmRepeat(SSlice{"A"}, 3, SSlice{"A", "A", "A"})
	ConfirmRepeat(SSlice{"A"}, 4, SSlice{"A", "A", "A", "A"})
	ConfirmRepeat(SSlice{"A"}, 5, SSlice{"A", "A", "A", "A", "A"})
}

func TestSSliceFlatten(t *testing.T) {
	ConfirmRepeat := func(s, r SSlice) {
		sstring := s.String()
		s.Flatten()
		if !s.Equal(r) {
			t.Fatalf("%v.Flatten() should be %v but is %v", sstring, r, s)
		}
	}

	ConfirmRepeat(SSlice{}, SSlice{})
	ConfirmRepeat(SSlice{"A"}, SSlice{"A"})
	ConfirmRepeat(SSlice{"A", "B"}, SSlice{"AB"})
	ConfirmRepeat(SSlice{"A", "B", "C"}, SSlice{"ABC"})
}

func TestSSliceCar(t *testing.T) {
	ConfirmCar := func(s SSlice, r string) {
		n := s.Car()
		if ok := n == r; !ok {
			t.Fatalf("head should be '%v' but is '%v'", r, n)
		}
	}
	ConfirmCar(SSlice{"A", "B", "C", "D", "E", "F"}, "A")
}

func TestSSliceCdr(t *testing.T) {
	ConfirmCdr := func(s, r SSlice) {
		if n := s.Cdr(); !n.Equal(r) {
			t.Fatalf("tail should be '%v' but is '%v'", r, n)
		}
	}
	ConfirmCdr(SSlice{"A", "B", "C", "D", "E", "F"}, SSlice{"B", "C", "D", "E", "F"})
}

func TestSSliceRplaca(t *testing.T) {
	ConfirmRplaca := func(s SSlice, v interface{}, r SSlice) {
		if s.Rplaca(v); !s.Equal(r) {
			t.Fatalf("slice should be '%v' but is '%v'", r, s)
		}
	}
	ConfirmRplaca(SSlice{"A", "B", "C", "D", "E", "F"}, "B", SSlice{"B", "B", "C", "D", "E", "F"})
}

func TestSSliceRplacd(t *testing.T) {
	ConfirmRplacd := func(s SSlice, v interface{}, r SSlice) {
		if s.Rplacd(v); !s.Equal(r) {
			t.Fatalf("slice should be '%v' but is '%v'", r, s)
		}
	}
	ConfirmRplacd(SSlice{"A", "B", "C", "D", "E", "F"}, nil, SSlice{"A"})
	ConfirmRplacd(SSlice{"A", "B", "C", "D", "E", "F"}, "B", SSlice{"A", "B"})
	ConfirmRplacd(SSlice{"A", "B", "C", "D", "E", "F"}, SSlice{"F", "E", "D", "C"}, SSlice{"A", "F", "E", "D", "C"})
}

func TestSSliceFind(t *testing.T) {
	ConfirmFind := func(s SSlice, v string, i int) {
		if x, ok := s.Find(v); !ok || x != i {
			t.Fatalf("%v.Find(%v) should be %v but is %v", s, v, i, x)
		}
	}

	ConfirmFind(SSlice{"A", "B", "C", "E", "D"}, "A", 0)
	ConfirmFind(SSlice{"A", "B", "C", "E", "D"}, "B", 1)
	ConfirmFind(SSlice{"A", "B", "C", "E", "D"}, "C", 2)
	ConfirmFind(SSlice{"A", "B", "C", "E", "D"}, "D", 4)
	ConfirmFind(SSlice{"A", "B", "C", "E", "D"}, "E", 3)
}

func TestSSliceFindN(t *testing.T) {
	ConfirmFindN := func(s SSlice, v string, n int, i ISlice) {
		if x := s.FindN(v, n); !x.Equal(i) {
			t.Fatalf("%v.Find(%v, %v) should be %v but is %v", s, v, n, i, x)
		}
	}

	ConfirmFindN(SSlice{"A", "B", "A", "B", "A"}, "C", 3, ISlice{})
	ConfirmFindN(SSlice{"A", "B", "A", "B", "A"}, "A", 0, ISlice{0, 2, 4})
	ConfirmFindN(SSlice{"A", "B", "A", "B", "A"}, "A", 1, ISlice{0})
	ConfirmFindN(SSlice{"A", "B", "A", "B", "A"}, "A", 2, ISlice{0, 2})
	ConfirmFindN(SSlice{"A", "B", "A", "B", "A"}, "A", 3, ISlice{0, 2, 4})
	ConfirmFindN(SSlice{"A", "B", "A", "B", "A"}, "A", 4, ISlice{0, 2, 4})
}

func TestSSliceKeepIf(t *testing.T) {
	ConfirmKeepIf := func(s SSlice, f interface{}, r SSlice) {
		if s.KeepIf(f); !r.Equal(s) {
			t.Fatalf("KeepIf(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmKeepIf(SSlice{"A", "B", "A", "B", "A"}, "A", SSlice{"A", "A", "A"})
	ConfirmKeepIf(SSlice{"A", "B", "A", "B", "A"}, "B", SSlice{"B", "B"})
	ConfirmKeepIf(SSlice{"A", "B", "A", "B", "A"}, "C", SSlice{})

	ConfirmKeepIf(SSlice{"A", "B", "A", "B", "A"}, func(x interface{}) bool { return x == "A" }, SSlice{"A", "A", "A"})
	ConfirmKeepIf(SSlice{"A", "B", "A", "B", "A"}, func(x interface{}) bool { return x == "B" }, SSlice{"B", "B"})
	ConfirmKeepIf(SSlice{"A", "B", "A", "B", "A"}, func(x interface{}) bool { return x == "C" }, SSlice{})

	ConfirmKeepIf(SSlice{"A", "B", "A", "B", "A"}, func(x string) bool { return x == "A" }, SSlice{"A", "A", "A"})
	ConfirmKeepIf(SSlice{"A", "B", "A", "B", "A"}, func(x string) bool { return x == "B" }, SSlice{"B", "B"})
	ConfirmKeepIf(SSlice{"A", "B", "A", "B", "A"}, func(x string) bool { return x == "C" }, SSlice{})
}

func TestSSliceReverseEach(t *testing.T) {
	var count	int
	count = 9
	SSlice{"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"}.ReverseEach(func(i interface{}) {
		v, _ := strconv.Atoi(i.(string))
		if v != count {
			t.Fatalf("0: element %v erroneously reported as %v", count, i)
		}
		count--
	})

	SSlice{"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"}.ReverseEach(func(index int, i interface{}) {
		v, _ := strconv.Atoi(i.(string))
		if index != v {
			t.Fatalf("1: element %v erroneously reported as %v", index, i)
		}
	})

	SSlice{"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"}.ReverseEach(func(key, i interface{}) {
		v, _ := strconv.Atoi(i.(string))
		if key.(int) != v {
			t.Fatalf("2: element %v erroneously reported as %v", key, i)
		}
	})

	count = 9
	SSlice{"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"}.ReverseEach(func(i string) {
		v, _ := strconv.Atoi(i)
		if v != count {
			t.Fatalf("3: element %v erroneously reported as %v", count, i)
		}
		count--
	})

	SSlice{"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"}.ReverseEach(func(index int, i string) {
		v, _ := strconv.Atoi(i)
		if v != index {
			t.Fatalf("4: element %v erroneously reported as %v", index, i)
		}
	})

	SSlice{"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"}.ReverseEach(func(key interface{}, i string) {
		v, _ := strconv.Atoi(i)
		if key.(int) != v {
			t.Fatalf("5: element %v erroneously reported as %v", key, i)
		}
	})
}

func TestSSliceReplaceIf(t *testing.T) {
	ConfirmReplaceIf := func(s SSlice, f, v interface{}, r SSlice) {
		if s.ReplaceIf(f, v); !r.Equal(s) {
			t.Fatalf("ReplaceIf(%v, %v) should be %v but is %v", f, v, r, s)
		}
	}

	ConfirmReplaceIf(SSlice{"A", "B", "A", "B", "A"}, "A", "B", SSlice{"B", "B", "B", "B", "B"})
	ConfirmReplaceIf(SSlice{"A", "B", "A", "B", "A"}, "B", "A", SSlice{"A", "A", "A", "A", "A"})
	ConfirmReplaceIf(SSlice{"A", "B", "A", "B", "A"}, "X", "A", SSlice{"A", "B", "A", "B", "A"})

	ConfirmReplaceIf(SSlice{"A", "B", "A", "B", "A"}, func(x interface{}) bool { return x == "A" }, "B", SSlice{"B", "B", "B", "B", "B"})
	ConfirmReplaceIf(SSlice{"A", "B", "A", "B", "A"}, func(x interface{}) bool { return x == "B" }, "A", SSlice{"A", "A", "A", "A", "A"})
	ConfirmReplaceIf(SSlice{"A", "B", "A", "B", "A"}, func(x interface{}) bool { return x == "Z" }, "A", SSlice{"A", "B", "A", "B", "A"})

	ConfirmReplaceIf(SSlice{"A", "B", "A", "B", "A"}, func(x string) bool { return x == "A" }, "B", SSlice{"B", "B", "B", "B", "B"})
	ConfirmReplaceIf(SSlice{"A", "B", "A", "B", "A"}, func(x string) bool { return x == "B" }, "A", SSlice{"A", "A", "A", "A", "A"})
	ConfirmReplaceIf(SSlice{"A", "B", "A", "B", "A"}, func(x string) bool { return x == "Z" }, "A", SSlice{"A", "B", "A", "B", "A"})
}

func TestSSliceReplace(t *testing.T) {
	ConfirmReplace := func(s SSlice, v interface{}) {
		if s.Replace(v); !s.Equal(v) {
			t.Fatalf("Replace() should be %v but is %v", s, v)
		}
	}

	ConfirmReplace(SSlice{"A", "B", "A", "B", "A"}, SSlice{"B", "C", "D", "C", "B"})
	ConfirmReplace(SSlice{"A", "B", "A", "B", "A"}, SSlice{ "B", "C", "D", "C", "B" })
	ConfirmReplace(SSlice{"A", "B", "A", "B", "A"}, []string{"B", "C", "D", "C", "B"})
}

func TestSSliceSelect(t *testing.T) {
	ConfirmSelect := func(s SSlice, f interface{}, r SSlice) {
		if x := s.Select(f); !r.Equal(x) {
			t.Fatalf("Select(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmSelect(SSlice{"A", "B", "A", "B", "A"}, "A", SSlice{"A", "A", "A"})
	ConfirmSelect(SSlice{"A", "B", "A", "B", "A"}, "B", SSlice{"B", "B"})
	ConfirmSelect(SSlice{"A", "B", "A", "B", "A"}, "Z", SSlice{})

	ConfirmSelect(SSlice{"A", "B", "A", "B", "A"}, func(x interface{}) bool { return x == "A" }, SSlice{"A", "A", "A"})
	ConfirmSelect(SSlice{"A", "B", "A", "B", "A"}, func(x interface{}) bool { return x == "B" }, SSlice{"B", "B"})
	ConfirmSelect(SSlice{"A", "B", "A", "B", "A"}, func(x interface{}) bool { return x == "Z" }, SSlice{})

	ConfirmSelect(SSlice{"A", "B", "A", "B", "A"}, func(x string) bool { return x == "A" }, SSlice{"A", "A", "A"})
	ConfirmSelect(SSlice{"A", "B", "A", "B", "A"}, func(x string) bool { return x == "B" }, SSlice{"B", "B"})
	ConfirmSelect(SSlice{"A", "B", "A", "B", "A"}, func(x string) bool { return x == "Z" }, SSlice{})
}

func TestSSliceUniq(t *testing.T) {
	ConfirmUniq := func(s, r SSlice) {
		if s.Uniq(); !r.Equal(s) {
			t.Fatalf("Uniq() should be %v but is %v", r, s)
		}
	}

	ConfirmUniq(SSlice{"A", "A", "A", "A", "A"}, SSlice{"A"})
	ConfirmUniq(SSlice{"A", "B", "A", "B", "C"}, SSlice{"A", "B", "C"})
}

func TestSSlicePick(t *testing.T) {
	ConfirmPick := func(s SSlice, i []int, r SSlice) {
		if x := s.Pick(i...); !r.Equal(x) {
			t.Fatalf("%v.Pick(%v) should be %v but is %v", s, i, r, x)
		}
	}

	ConfirmPick(SSlice{"A", "B", "A", "B", "A"}, []int{}, SSlice{})
	ConfirmPick(SSlice{"A", "B", "A", "B", "A"}, []int{ 0, 1 }, SSlice{"A", "B"})
	ConfirmPick(SSlice{"A", "B", "A", "B", "A"}, []int{ 0, 3 }, SSlice{"A", "B"})
	ConfirmPick(SSlice{"A", "B", "A", "B", "A"}, []int{ 0, 3, 4, 3 }, SSlice{"A", "B", "A", "B"})
}

func TestSSliceInsert(t *testing.T) {
	ConfirmInsert := func(s SSlice, n int, v interface{}, r SSlice) {
		if s.Insert(n, v); !r.Equal(s) {
			t.Fatalf("Insert(%v, %v) should be %v but is %v", n, v, r, s)
		}
	}

	ConfirmInsert(SSlice{}, 0, "A", SSlice{"A"})
	ConfirmInsert(SSlice{}, 0, SSlice{"A"}, SSlice{"A"})
	ConfirmInsert(SSlice{}, 0, SSlice{"A", "B", "A", "B", "A"}, SSlice{"A", "B", "A", "B", "A"})

	ConfirmInsert(SSlice{"A"}, 0, "B", SSlice{"B", "A"})
	ConfirmInsert(SSlice{"A"}, 1, "B", SSlice{"A", "B"})
	ConfirmInsert(SSlice{"A"}, 0, SSlice{"B"}, SSlice{"B", "A"})
	ConfirmInsert(SSlice{"A"}, 1, SSlice{"B"}, SSlice{"A", "B"})

	ConfirmInsert(SSlice{"A", "B", "C"}, 0, "X", SSlice{"X", "A", "B", "C"})
	ConfirmInsert(SSlice{"A", "B", "C"}, 1, "X", SSlice{"A", "X", "B", "C"})
	ConfirmInsert(SSlice{"A", "B", "C"}, 2, "X", SSlice{"A", "B", "X", "C"})
	ConfirmInsert(SSlice{"A", "B", "C"}, 3, "X", SSlice{"A", "B", "C", "X"})

	ConfirmInsert(SSlice{"A", "B", "C"}, 0, SSlice{"X", "Y"}, SSlice{"X", "Y", "A", "B", "C"})
	ConfirmInsert(SSlice{"A", "B", "C"}, 1, SSlice{"X", "Y"}, SSlice{"A", "X", "Y", "B", "C"})
	ConfirmInsert(SSlice{"A", "B", "C"}, 2, SSlice{"X", "Y"}, SSlice{"A", "B", "X", "Y", "C"})
	ConfirmInsert(SSlice{"A", "B", "C"}, 3, SSlice{"X", "Y"}, SSlice{"A", "B", "C", "X", "Y"})
}