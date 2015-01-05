package slices

import (
	"testing"
	"fmt"
)

type Errno int

func (e Errno) Error() (err string) {
	return fmt.Sprintf("(E%v)", int(e))
}

const (
	E0 = Errno(iota)
	E1
	E2
	E3
	E4
)

func TestESliceString(t *testing.T) {
	ConfirmString := func(s ESlice, r string) {
		if x := s.String(); x != r {
			t.Fatalf("%v erroneously serialised as '%v'", r, x)
		}
	}

	ConfirmString(ESlice{}, "()")
	ConfirmString(ESlice{E0}, "((E0))")
	ConfirmString(ESlice{E0, E1}, "((E0) (E1))")
}

func TestESliceLen(t *testing.T) {
	ConfirmLength := func(s ESlice, i int) {
		if x := s.Len(); x != i {
			t.Fatalf("%v.Len() should be %v but is %v", s, i, x)
		}
	}
	
	ConfirmLength(ESlice{E0}, 1)
	ConfirmLength(ESlice{E0, E1}, 2)
}

func TestESliceSwap(t *testing.T) {
	ConfirmSwap := func(s ESlice, i, j int, r ESlice) {
		if s.Swap(i, j); !r.Equal(s) {
			t.Fatalf("Swap(%v, %v) should be %v but is %v", i, j, r, s)
		}
	}
	ConfirmSwap(ESlice{E0, E1, E2}, 0, 1, ESlice{E1, E0, E2})
	ConfirmSwap(ESlice{E0, E1, E2}, 0, 2, ESlice{E2, E1, E0})
}

func TestESliceCut(t *testing.T) {
	ConfirmCut := func(s ESlice, start, end int, r ESlice) {
		if s.Cut(start, end); !r.Equal(s) {
			t.Fatalf("Cut(%v, %v) should be %v but is %v", start, end, r, s)
		}
	}

	ConfirmCut(ESlice{E0, E1, E2, E3, E4}, 0, 1, ESlice{E1, E2, E3, E4})
	ConfirmCut(ESlice{E0, E1, E2, E3, E4}, 1, 2, ESlice{E0, E2, E3, E4})
	ConfirmCut(ESlice{E0, E1, E2, E3, E4}, 2, 3, ESlice{E0, E1, E3, E4})
	ConfirmCut(ESlice{E0, E1, E2, E3, E4}, 3, 4, ESlice{E0, E1, E2, E4})
	ConfirmCut(ESlice{E0, E1, E2, E3, E4}, 4, 5, ESlice{E0, E1, E2, E3})

	ConfirmCut(ESlice{E0, E1, E2, E3, E4}, -1, 1, ESlice{E1, E2, E3, E4})
	ConfirmCut(ESlice{E0, E1, E2, E3, E4}, 0, 2, ESlice{E2, E3, E4})
	ConfirmCut(ESlice{E0, E1, E2, E3, E4}, 1, 3, ESlice{E0, E3, E4})
	ConfirmCut(ESlice{E0, E1, E2, E3, E4}, 2, 4, ESlice{E0, E1, E4})
	ConfirmCut(ESlice{E0, E1, E2, E3, E4}, 3, 5, ESlice{E0, E1, E2})
	ConfirmCut(ESlice{E0, E1, E2, E3, E4}, 4, 6, ESlice{E0, E1, E2, E3})
}

func TestESliceTrim(t *testing.T) {
	ConfirmTrim := func(s ESlice, start, end int, r ESlice) {
		if s.Trim(start, end); !r.Equal(s) {
			t.Fatalf("Trim(%v, %v) should be %v but is %v", start, end, r, s)
		}
	}

	ConfirmTrim(ESlice{E0, E1, E2, E3, E4}, 0, 1, ESlice{E0})
	ConfirmTrim(ESlice{E0, E1, E2, E3, E4}, 1, 2, ESlice{E1})
	ConfirmTrim(ESlice{E0, E1, E2, E3, E4}, 2, 3, ESlice{E2})
	ConfirmTrim(ESlice{E0, E1, E2, E3, E4}, 3, 4, ESlice{E3})
	ConfirmTrim(ESlice{E0, E1, E2, E3, E4}, 4, 5, ESlice{E4})

	ConfirmTrim(ESlice{E0, E1, E2, E3, E4}, -1, 1, ESlice{E0})
	ConfirmTrim(ESlice{E0, E1, E2, E3, E4}, 0, 2, ESlice{E0, E1})
	ConfirmTrim(ESlice{E0, E1, E2, E3, E4}, 1, 3, ESlice{E1, E2})
	ConfirmTrim(ESlice{E0, E1, E2, E3, E4}, 2, 4, ESlice{E2, E3})
	ConfirmTrim(ESlice{E0, E1, E2, E3, E4}, 3, 5, ESlice{E3, E4})
	ConfirmTrim(ESlice{E0, E1, E2, E3, E4}, 4, 6, ESlice{E4})
}

func TestESliceDelete(t *testing.T) {
	ConfirmDelete := func(s ESlice, index int, r ESlice) {
		if s.Delete(index); !r.Equal(s) {
			t.Fatalf("Delete(%v) should be %v but is %v", index, r, s)
		}
	}

	ConfirmDelete(ESlice{E0, E1, E2, E3, E4}, -1, ESlice{E0, E1, E2, E3, E4})
	ConfirmDelete(ESlice{E0, E1, E2, E3, E4}, 0, ESlice{E1, E2, E3, E4})
	ConfirmDelete(ESlice{E0, E1, E2, E3, E4}, 1, ESlice{E0, E2, E3, E4})
	ConfirmDelete(ESlice{E0, E1, E2, E3, E4}, 2, ESlice{E0, E1, E3, E4})
	ConfirmDelete(ESlice{E0, E1, E2, E3, E4}, 3, ESlice{E0, E1, E2, E4})
	ConfirmDelete(ESlice{E0, E1, E2, E3, E4}, 4, ESlice{E0, E1, E2, E3})
	ConfirmDelete(ESlice{E0, E1, E2, E3, E4}, 5, ESlice{E0, E1, E2, E3, E4})
}

func TestESliceDeleteIf(t *testing.T) {
	ConfirmDeleteIf := func(s ESlice, f interface{}, r ESlice) {
		if s.DeleteIf(f); !r.Equal(s) {
			t.Fatalf("DeleteIf(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmDeleteIf(ESlice{E0, E1, E0, E3, E0, E4}, E0, ESlice{E1, E3, E4})
	ConfirmDeleteIf(ESlice{E0, E1, E0, E3, E0, E4}, E1, ESlice{E0, E0, E3, E0, E4})
	ConfirmDeleteIf(ESlice{E0, E1, E0, E3, E0, E4}, Errno(6), ESlice{E0, E1, E0, E3, E0, E4})

	ConfirmDeleteIf(ESlice{E0, E1, E0, E3, E0, E4}, func(x interface{}) bool { return x == E0 }, ESlice{E1, E3, E4})
	ConfirmDeleteIf(ESlice{E0, E1, E0, E3, E0, E4}, func(x interface{}) bool { return x == E1 }, ESlice{E0, E0, E3, E0, E4})
	ConfirmDeleteIf(ESlice{E0, E1, E0, E3, E0, E4}, func(x interface{}) bool { return x == Errno(6) }, ESlice{E0, E1, E0, E3, E0, E4})

	ConfirmDeleteIf(ESlice{E0, E1, E0, E3, E0, E4}, func(x error) bool { return x == E0 }, ESlice{E1, E3, E4})
	ConfirmDeleteIf(ESlice{E0, E1, E0, E3, E0, E4}, func(x error) bool { return x == E1 }, ESlice{E0, E0, E3, E0, E4})
	ConfirmDeleteIf(ESlice{E0, E1, E0, E3, E0, E4}, func(x error) bool { return x == Errno(6) }, ESlice{E0, E1, E0, E3, E0, E4})
}

func TestESliceEach(t *testing.T) {
	var count	Errno
	ESlice{E0, E1, E2, E3, E4}.Each(func(i interface{}) {
		if i != count {
			t.Fatalf("element %v erroneously reported as %v", count, i)
		}
		count++
	})

	ESlice{E0, E1, E2, E3, E4}.Each(func(index int, i interface{}) {
		if Errno(index) != i {
			t.Fatalf("element %v erroneously reported as %v", index, i)
		}
	})

	ESlice{E0, E1, E2, E3, E4}.Each(func(key, i interface{}) {
		if Errno(key.(int)) != i {
			t.Fatalf("element %v erroneously reported as %v", key, i)
		}
	})

	count = 0
	ESlice{E0, E1, E2, E3, E4}.Each(func(i error) {
		if i != count {
			t.Fatalf("element %v erroneously reported as %v", count, i)
		}
		count++
	})

	ESlice{E0, E1, E2, E3, E4}.Each(func(index int, i error) {
		if i != Errno(index) {
			t.Fatalf("element %v erroneously reported as %v", index, i)
		}
	})

	ESlice{E0, E1, E2, E3, E4}.Each(func(key interface{}, i error) {
		if Errno(key.(int)) != i {
			t.Fatalf("element %v erroneously reported as %v", key, i)
		}
	})
}

func TestESliceWhile(t *testing.T) {
	ConfirmLimit := func(s ESlice, l int, f interface{}) {
		if count := s.While(f); count != l {
			t.Fatalf("%v.While() should have iterated %v times not %v times", s, l, count)
		}
	}

	s := ESlice{E0, E1, E0, E3, E0, E4}
	count := 0
	limit := 3
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
	ConfirmLimit(s, limit, func(i error) bool {
		if count == limit {
			return false
		}
		count++
		return true
	})

	ConfirmLimit(s, limit, func(index int, i error) bool {
		return index != limit
	})

	ConfirmLimit(s, limit, func(key interface{}, i error) bool {
		return key.(int) != limit
	})
}

func TestESliceUntil(t *testing.T) {
	ConfirmLimit := func(s ESlice, l int, f interface{}) {
		if count := s.Until(f); count != l {
			t.Fatalf("%v.Until() should have iterated %v times not %v times", s, l, count)
		}
	}

	s := ESlice{E0, E1, E0, E3, E0, E4}
	count := 0
	limit := 3
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
	ConfirmLimit(s, limit, func(i error) bool {
		if count == limit {
			return true
		}
		count++
		return false
	})

	ConfirmLimit(s, limit, func(index int, i error) bool {
		return index == limit
	})

	ConfirmLimit(s, limit, func(key interface{}, i error) bool {
		return key.(int) == limit
	})
}

func TestESliceBlockCopy(t *testing.T) {
	ConfirmBlockCopy := func(s ESlice, destination, source, count int, r ESlice) {
		s.BlockCopy(destination, source, count)
		if !r.Equal(s) {
			t.Fatalf("BlockCopy(%v, %v, %v) should be %v but is %v", destination, source, count, r, s)
		}
	}

	ConfirmBlockCopy(ESlice{}, 0, 0, 1, ESlice{})
	ConfirmBlockCopy(ESlice{}, 1, 0, 1, ESlice{})
	ConfirmBlockCopy(ESlice{}, 0, 1, 1, ESlice{})

	ConfirmBlockCopy(ESlice{E0, E1, E2, E3, E4}, 0, 0, 4, ESlice{E0, E1, E2, E3, E4})
	ConfirmBlockCopy(ESlice{E0, E1, E2, E3, E4}, 5, 5, 4, ESlice{E0, E1, E2, E3, E4})
	ConfirmBlockCopy(ESlice{E0, E1, E2, E3, E4}, 4, 0, 4, ESlice{E0, E1, E2, E3, E0})
	ConfirmBlockCopy(ESlice{E0, E1, E2, E3, E4}, 5, 0, 4, ESlice{E0, E1, E2, E3, E4})
	ConfirmBlockCopy(ESlice{E0, E1, E2, E3, E4}, 3, 2, 4, ESlice{E0, E1, E2, E2, E3})
	ConfirmBlockCopy(ESlice{E0, E1, E2, E3, E4}, 2, 5, 4, ESlice{E0, E1, E2, E3, E4})
}

func TestESliceBlockClear(t *testing.T) {
	ConfirmBlockClear := func(s ESlice, start, count int, r ESlice) {
		s.BlockClear(start, count)
		if !r.Equal(s) {
			t.Fatalf("BlockClear(%v, %v) should be %v but is %v", start, count, r, s)
		}
	}

	ConfirmBlockClear(ESlice{E0, E1, E2, E3, E4}, 0, 4, ESlice{nil, nil, nil, nil, E4})
	ConfirmBlockClear(ESlice{E0, E1, E2, E3, E4}, 10, 4, ESlice{E0, E1, E2, E3, E4})
	ConfirmBlockClear(ESlice{E0, E1, E2, E3, E4}, 5, 4, ESlice{E0, E1, E2, E3, E4})
}

func TestESliceOverwrite(t *testing.T) {
	ConfirmOverwrite := func(s ESlice, offset int, v, r ESlice) {
		s.Overwrite(offset, v)
		if !r.Equal(s) {
			t.Fatalf("Overwrite(%v, %v) should be %v but is %v", offset, v, r, s)
		}
	}

	ConfirmOverwrite(ESlice{E0, E1, E2, E3, E4}, 0, ESlice{E4, E3}, ESlice{E4, E3, E2, E3, E4})
	ConfirmOverwrite(ESlice{E0, E1, E2, E3, E4}, 5, ESlice{E4, E3}, ESlice{E0, E1, E2, E3, E4})
	ConfirmOverwrite(ESlice{E0, E1, E2, E3, E4}, 3, ESlice{E4, E3}, ESlice{E0, E1, E2, E4, E3})
}

func TestESliceReallocate(t *testing.T) {
	ConfirmReallocate := func(s ESlice, l, c int, r ESlice) {
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

	ConfirmReallocate(ESlice{}, 0, 10, make(ESlice, 0, 10))
	ConfirmReallocate(ESlice{E0, E1, E2, E3, E4}, 3, 10, ESlice{E0, E1, E2})
	ConfirmReallocate(ESlice{E0, E1, E2, E3, E4}, 5, 10, ESlice{E0, E1, E2, E3, E4})
	ConfirmReallocate(ESlice{E0, E1, E2, E3, E4}, 10, 10, ESlice{E0, E1, E2, E3, E4, nil, nil, nil, nil, nil})
	ConfirmReallocate(ESlice{E0, E1, E2, E3, E4}, 1, 5, ESlice{E0})
	ConfirmReallocate(ESlice{E0, E1, E2, E3, E4}, 5, 5, ESlice{E0, E1, E2, E3, E4})
	ConfirmReallocate(ESlice{E0, E1, E2, E3, E4}, 10, 5, ESlice{E0, E1, E2, E3, E4})
}

func TestESliceExtend(t *testing.T) {
	ConfirmExtend := func(s ESlice, n int, r ESlice) {
		c := s.Cap()
		s.Extend(n)
		switch {
		case s.Len() != r.Len():	t.Fatalf("Extend(%v) len should be %v but is %v", n, r.Len(), s.Len())
		case s.Cap() != c + n:		t.Fatalf("Extend(%v) cap should be %v but is %v", n, c + n, s.Cap())
		case !r.Equal(s):			t.Fatalf("Extend(%v) should be %v but is %v", n, r, s)
		}
	}

	ConfirmExtend(ESlice{}, 1, ESlice{nil})
	ConfirmExtend(ESlice{}, 2, ESlice{nil, nil})
}

func TestESliceExpand(t *testing.T) {
	ConfirmExpand := func(s ESlice, i, n int, r ESlice) {
		c := s.Cap()
		s.Expand(i, n)
		switch {
		case s.Len() != r.Len():	t.Fatalf("Expand(%v, %v) len should be %v but is %v", i, n, r.Len(), s.Len())
		case s.Cap() != c + n:		t.Fatalf("Expand(%v, %v) cap should be %v but is %v", i, n, c + n, s.Cap())
		case !r.Equal(s):			t.Fatalf("Expand(%v, %v) should be %v but is %v", i, n, r, s)
		}
	}

	ConfirmExpand(ESlice{}, -1, 1, ESlice{nil})
	ConfirmExpand(ESlice{}, 0, 1, ESlice{nil})
	ConfirmExpand(ESlice{}, 1, 1, ESlice{nil})
	ConfirmExpand(ESlice{}, 0, 2, ESlice{nil, nil})

	ConfirmExpand(ESlice{E0, E1, E2}, -1, 2, ESlice{nil, nil, E0, E1, E2})
	ConfirmExpand(ESlice{E0, E1, E2}, 0, 2, ESlice{nil, nil, E0, E1, E2})
	ConfirmExpand(ESlice{E0, E1, E2}, 1, 2, ESlice{E0, nil, nil, E1, E2})
	ConfirmExpand(ESlice{E0, E1, E2}, 2, 2, ESlice{E0, E1, nil, nil, E2})
	ConfirmExpand(ESlice{E0, E1, E2}, 3, 2, ESlice{E0, E1, E2, nil, nil})
	ConfirmExpand(ESlice{E0, E1, E2}, 4, 2, ESlice{E0, E1, E2, nil, nil})
}

func TestESliceReverse(t *testing.T) {
	ConfirmReverse := func(s, r ESlice) {
		if s.Reverse(); !Equal(s, r) {
			t.Fatalf("Reverse() should be %v but is %v", r, s)
		}
	}
	ConfirmReverse(ESlice{}, ESlice{})
	ConfirmReverse(ESlice{E1}, ESlice{E1})
	ConfirmReverse(ESlice{E1, E2}, ESlice{E2, E1})
	ConfirmReverse(ESlice{E1, E2, E3}, ESlice{E3, E2, E1})
	ConfirmReverse(ESlice{E1, E2, E3, E4}, ESlice{E4, E3, E2, E1})
}

func TestESliceCar(t *testing.T) {
	ConfirmCar := func(s ESlice, r error) {
		n := s.Car().(error)
		if ok := n == r; !ok {
			t.Fatalf("head should be '%v' but is '%v'", r, n)
		}
	}
	ConfirmCar(ESlice{E1, E2, E3}, E1)
}

func TestESliceCdr(t *testing.T) {
	ConfirmCdr := func(s, r ESlice) {
		if n := s.Cdr(); !n.Equal(r) {
			t.Fatalf("tail should be '%v' but is '%v'", r, n)
		}
	}
	ConfirmCdr(ESlice{E1, E2, E3}, ESlice{E2, E3})
}

func TestESliceRplaca(t *testing.T) {
	ConfirmRplaca := func(s ESlice, v interface{}, r ESlice) {
		if s.Rplaca(v); !s.Equal(r) {
			t.Fatalf("slice should be '%v' but is '%v'", r, s)
		}
	}
	ConfirmRplaca(ESlice{E1, E2, E3, E4}, E0, ESlice{E0, E2, E3, E4})
}

func TestESliceRplacd(t *testing.T) {
	ConfirmRplacd := func(s ESlice, v interface{}, r ESlice) {
		if s.Rplacd(v); !s.Equal(r) {
			t.Fatalf("slice should be '%v' but is '%v'", r, s)
		}
	}
	ConfirmRplacd(ESlice{E0, E1, E2, E3, E4}, nil, ESlice{E0})
	ConfirmRplacd(ESlice{E0, E1, E2, E3, E4}, E0, ESlice{E0, E0})
	ConfirmRplacd(ESlice{E0, E1, E2, E3, E4}, ESlice{E4, E3}, ESlice{E0, E4, E3})
	ConfirmRplacd(ESlice{E0, E1, E2, E3, E4}, ESlice{E2, E4}, ESlice{E0, E2, E4})
}

func TestESliceFind(t *testing.T) {
	ConfirmFind := func(s ESlice, v error, i int) {
		if x, ok := s.Find(v); !ok || x != i {
			t.Fatalf("%v.Find(%v) should be %v but is %v", s, v, i, x)
		}
	}

	ConfirmFind(ESlice{E0, E1, E2, E3, E4}, E0, 0)
	ConfirmFind(ESlice{E0, E1, E2, E3, E4}, E1, 1)
	ConfirmFind(ESlice{E0, E1, E2, E3, E4}, E2, 2)
	ConfirmFind(ESlice{E0, E1, E2, E3, E4}, E3, 3)
	ConfirmFind(ESlice{E0, E1, E2, E3, E4}, E4, 4)
}

func TestESliceFindN(t *testing.T) {
	ConfirmFindN := func(s ESlice, v error, n int, i ISlice) {
		if x := s.FindN(v, n); !x.Equal(i) {
			t.Fatalf("%v.Find(%v, %v) should be %v but is %v", s, v, n, i, x)
		}
	}

	ConfirmFindN(ESlice{E1, E0, E1, E0, E1}, E2, 3, ISlice{})
	ConfirmFindN(ESlice{E1, E0, E1, E0, E1}, E1, 0, ISlice{0, 2, 4})
	ConfirmFindN(ESlice{E1, E0, E1, E0, E1}, E1, 1, ISlice{0})
	ConfirmFindN(ESlice{E1, E0, E1, E0, E1}, E1, 2, ISlice{0, 2})
	ConfirmFindN(ESlice{E1, E0, E1, E0, E1}, E1, 3, ISlice{0, 2, 4})
	ConfirmFindN(ESlice{E1, E0, E1, E0, E1}, E1, 4, ISlice{0, 2, 4})
}

func TestESliceKeepIf(t *testing.T) {
	ConfirmKeepIf := func(s ESlice, f interface{}, r ESlice) {
		if s.KeepIf(f); !r.Equal(s) {
			t.Fatalf("KeepIf(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmKeepIf(ESlice{E0, E1, E0, E3, E0, E4}, E0, ESlice{E0, E0, E0})
	ConfirmKeepIf(ESlice{E0, E1, E0, E3, E0, E4}, E1, ESlice{E1})
	ConfirmKeepIf(ESlice{E0, E1, E0, E3, E0, E4}, Errno(6), ESlice{})

	ConfirmKeepIf(ESlice{E0, E1, E0, E3, E0, E4}, func(x interface{}) bool { return x == E0 }, ESlice{E0, E0, E0})
	ConfirmKeepIf(ESlice{E0, E1, E0, E3, E0, E4}, func(x interface{}) bool { return x == E1 }, ESlice{E1})
	ConfirmKeepIf(ESlice{E0, E1, E0, E3, E0, E4}, func(x interface{}) bool { return x == Errno(6) }, ESlice{})

	ConfirmKeepIf(ESlice{E0, E1, E0, E3, E0, E4}, func(x error) bool { return x == E0 }, ESlice{E0, E0, E0})
	ConfirmKeepIf(ESlice{E0, E1, E0, E3, E0, E4}, func(x error) bool { return x == E1 }, ESlice{E1})
	ConfirmKeepIf(ESlice{E0, E1, E0, E3, E0, E4}, func(x error) bool { return x == Errno(6) }, ESlice{})
}

func TestESliceReverseEach(t *testing.T) {
	var count	Errno
	count = E4
	ESlice{E0, E1, E2, E3, E4}.ReverseEach(func(i interface{}) {
		if i != count {
			t.Fatalf("0: element %v erroneously reported as %v", count, i)
		}
		count--
	})

	ESlice{E0, E1, E2, E3, E4}.ReverseEach(func(index int, i interface{}) {
		if Errno(index) != i {
			t.Fatalf("1: element %v erroneously reported as %v", index, i)
		}
	})

	ESlice{E0, E1, E2, E3, E4}.ReverseEach(func(key, i interface{}) {
		if Errno(key.(int)) != i {
			t.Fatalf("2: element %v erroneously reported as %v", key, i)
		}
	})

	count = E4
	ESlice{E0, E1, E2, E3, E4}.ReverseEach(func(i error) {
		if i != count {
			t.Fatalf("3: element %v erroneously reported as %v", count, i)
		}
		count--
	})

	ESlice{E0, E1, E2, E3, E4}.ReverseEach(func(index int, i error) {
		if i != Errno(index) {
			t.Fatalf("4: element %v erroneously reported as %v", index, i)
		}
	})

	ESlice{E0, E1, E2, E3, E4}.ReverseEach(func(key interface{}, i error) {
		if Errno(key.(int)) != i {
			t.Fatalf("5: element %v erroneously reported as %v", key, i)
		}
	})
}

func TestESliceReplaceIf(t *testing.T) {
	ConfirmReplaceIf := func(s ESlice, f, v interface{}, r ESlice) {
		if s.ReplaceIf(f, v); !r.Equal(s) {
			t.Fatalf("ReplaceIf(%v, %v) should be %v but is %v", f, v, r, s)
		}
	}

	ConfirmReplaceIf(ESlice{E0, E1, E0, E3, E0, E4}, E0, E1, ESlice{E1, E1, E1, E3, E1, E4})
	ConfirmReplaceIf(ESlice{E0, E1, E0, E3, E0, E4}, E1, E0, ESlice{E0, E0, E0, E3, E0, E4})
	ConfirmReplaceIf(ESlice{E0, E1, E0, E3, E0, E4}, Errno(6), E0, ESlice{E0, E1, E0, E3, E0, E4})

	ConfirmReplaceIf(ESlice{E0, E1, E0, E3, E0, E4}, func(x interface{}) bool { return x == E0 }, E1, ESlice{E1, E1, E1, E3, E1, E4})
	ConfirmReplaceIf(ESlice{E0, E1, E0, E3, E0, E4}, func(x interface{}) bool { return x == E1 }, E0, ESlice{E0, E0, E0, E3, E0, E4})
	ConfirmReplaceIf(ESlice{E0, E1, E0, E3, E0, E4}, func(x interface{}) bool { return x == Errno(6) }, E0, ESlice{E0, E1, E0, E3, E0, E4})

	ConfirmReplaceIf(ESlice{E0, E1, E0, E3, E0, E4}, func(x error) bool { return x == E0 }, E1, ESlice{E1, E1, E1, E3, E1, E4})
	ConfirmReplaceIf(ESlice{E0, E1, E0, E3, E0, E4}, func(x error) bool { return x == E1 }, E0, ESlice{E0, E0, E0, E3, E0, E4})
	ConfirmReplaceIf(ESlice{E0, E1, E0, E3, E0, E4}, func(x error) bool { return x == Errno(6) }, E0, ESlice{E0, E1, E0, E3, E0, E4})
}

func TestESliceReplace(t *testing.T) {
	ConfirmReplace := func(s ESlice, v interface{}) {
		if s.Replace(v); !s.Equal(v) {
			t.Fatalf("Replace() should be %v but is %v", s, v)
		}
	}

	ConfirmReplace(ESlice{E0, E1, E2, E3, E4}, ESlice{E4, E3, E2, E1, E0})
	ConfirmReplace(ESlice{E0, E1, E2, E3, E4}, ESlice{E4, E3, E2, E1, E0})
	ConfirmReplace(ESlice{E0, E1, E2, E3, E4}, []error{E4, E3, E2, E1, E0})
}

func TestESliceSelect(t *testing.T) {
	ConfirmSelect := func(s ESlice, f interface{}, r ESlice) {
		if x := s.Select(f); !r.Equal(x) {
			t.Fatalf("Select(%v) should be %v but is %v", f, r, s)
		}
	}

	ConfirmSelect(ESlice{E0, E1, E0, E3, E0, E4}, E0, ESlice{E0, E0, E0})
	ConfirmSelect(ESlice{E0, E1, E0, E3, E0, E4}, E1, ESlice{E1})
	ConfirmSelect(ESlice{E0, E1, E0, E3, E0, E4}, Errno(6), ESlice{})

	ConfirmSelect(ESlice{E0, E1, E0, E3, E0, E4}, func(x interface{}) bool { return x == E0 }, ESlice{E0, E0, E0})
	ConfirmSelect(ESlice{E0, E1, E0, E3, E0, E4}, func(x interface{}) bool { return x == E1 }, ESlice{E1})
	ConfirmSelect(ESlice{E0, E1, E0, E3, E0, E4}, func(x interface{}) bool { return x == Errno(6) }, ESlice{})

	ConfirmSelect(ESlice{E0, E1, E0, E3, E0, E4}, func(x error) bool { return x == E0 }, ESlice{E0, E0, E0})
	ConfirmSelect(ESlice{E0, E1, E0, E3, E0, E4}, func(x error) bool { return x == E1 }, ESlice{E1})
	ConfirmSelect(ESlice{E0, E1, E0, E3, E0, E4}, func(x error) bool { return x == Errno(6) }, ESlice{})
}

func TestESliceUniq(t *testing.T) {
	ConfirmUniq := func(s, r ESlice) {
		if s.Uniq(); !r.Equal(s) {
			t.Fatalf("Uniq() should be %v but is %v", r, s)
		}
	}

	ConfirmUniq(ESlice{E0, E0, E0, E0, E0, E0}, ESlice{E0})
	ConfirmUniq(ESlice{E0, E1, E0, E3, E0, E4}, ESlice{E0, E1, E3, E4})
}

func TestESlicePick(t *testing.T) {
	ConfirmPick := func(s ESlice, i []int, r ESlice) {
		if x := s.Pick(i...); !r.Equal(x) {
			t.Fatalf("%v.Pick(%v) should be %v but is %v", s, i, r, x)
		}
	}

	ConfirmPick(ESlice{E0, E1, E0, E3, E0, E4}, []int{}, ESlice{})
	ConfirmPick(ESlice{E0, E1, E0, E3, E0, E4}, []int{0, 1}, ESlice{E0, E1})
	ConfirmPick(ESlice{E0, E1, E0, E3, E0, E4}, []int{0, 3}, ESlice{E0, E3})
	ConfirmPick(ESlice{E0, E1, E0, E3, E0, E4}, []int{0, 3, 4, 3}, ESlice{E0, E3, E0, E3})
}

func TestESliceInsert(t *testing.T) {
	ConfirmInsert := func(s ESlice, n int, v interface{}, r ESlice) {
		if s.Insert(n, v); !r.Equal(s) {
			t.Fatalf("Insert(%v, %v) should be %v but is %v", n, v, r, s)
		}
	}

	ConfirmInsert(ESlice{}, 0, E0, ESlice{E0})
	ConfirmInsert(ESlice{}, 0, ESlice{E0}, ESlice{E0})
	ConfirmInsert(ESlice{}, 0, ESlice{E0, E1}, ESlice{E0, E1})

	ConfirmInsert(ESlice{E0}, 0, E1, ESlice{E1, E0})
	ConfirmInsert(ESlice{E0}, 0, ESlice{E1}, ESlice{E1, E0})
	ConfirmInsert(ESlice{E0}, 1, E1, ESlice{E0, E1})
	ConfirmInsert(ESlice{E0}, 1, ESlice{E1}, ESlice{E0, E1})

	ConfirmInsert(ESlice{E0, E1, E2}, 0, E3, ESlice{E3, E0, E1, E2})
	ConfirmInsert(ESlice{E0, E1, E2}, 1, E3, ESlice{E0, E3, E1, E2})
	ConfirmInsert(ESlice{E0, E1, E2}, 2, E3, ESlice{E0, E1, E3, E2})
	ConfirmInsert(ESlice{E0, E1, E2}, 3, E3, ESlice{E0, E1, E2, E3})

	ConfirmInsert(ESlice{E0, E1, E2}, 0, ESlice{E3, E4}, ESlice{E3, E4, E0, E1, E2})
	ConfirmInsert(ESlice{E0, E1, E2}, 1, ESlice{E3, E4}, ESlice{E0, E3, E4, E1, E2})
	ConfirmInsert(ESlice{E0, E1, E2}, 2, ESlice{E3, E4}, ESlice{E0, E1, E3, E4, E2})
	ConfirmInsert(ESlice{E0, E1, E2}, 3, ESlice{E3, E4}, ESlice{E0, E1, E2, E3, E4})
}