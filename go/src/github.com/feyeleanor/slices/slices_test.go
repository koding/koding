package slices

import "testing"

func TestPrepend(t *testing.T) {
	ConfirmPrepend := func(c C128Slice, v interface{}, r Equatable) {
		if Prepend(&c, v); !r.Equal(c) {
			t.Fatalf("Prepend(%v) should be %v but is %v", v, r, c)
		}
	}

	ConfirmPrepend(C128Slice{}, complex128(0), C128Slice{0})
	ConfirmPrepend(C128Slice{0}, complex128(1), C128Slice{1, 0})

	ConfirmPrepend(C128Slice{}, C128Slice{0}, C128Slice{0})
	ConfirmPrepend(C128Slice{}, C128Slice{0, 1}, C128Slice{0, 1})
	ConfirmPrepend(C128Slice{0, 1, 2}, C128Slice{3, 4}, C128Slice{3, 4, 0, 1, 2})
}

func TestAppend(t *testing.T) {
	ConfirmAppend := func(c C128Slice, v interface{}, r Equatable) {
		if Append(&c, v); !r.Equal(c) {
			t.Fatalf("Append(%v) should be %v but is %v", v, r, c)
		}
	}

	ConfirmAppend(C128Slice{}, complex128(0), C128Slice{0})
	ConfirmAppend(C128Slice{}, C128Slice{0}, C128Slice{0})
	ConfirmAppend(C128Slice{}, C128Slice{0, 1}, C128Slice{0, 1})
	ConfirmAppend(C128Slice{0, 1, 2}, C128Slice{3, 4}, C128Slice{0, 1, 2, 3, 4})

}

func TestClearAll(t *testing.T) {
	ConfirmClearAll := func(s, r interface{}) {
		if !ClearAll(s) {
			t.Fatalf("ClearAll(%v) is not Wipeable", s)
		}
		if !Equal(s, r) {
			t.Fatalf("ClearAll(%v) should be %v", s, r)
		}
	}

	ConfirmClearAll(C64Slice{0, 1, 2, 3, 4, 5}, C64Slice{0, 0, 0, 0, 0, 0})
	ConfirmClearAll(C128Slice{0, 1, 2, 3, 4, 5}, C128Slice{0, 0, 0, 0, 0, 0})
	ConfirmClearAll(F64Slice{0, 1, 2, 3, 4, 5}, F64Slice{0, 0, 0, 0, 0, 0})
	ConfirmClearAll(F64Slice{0, 1, 2, 3, 4, 5}, F64Slice{0, 0, 0, 0, 0, 0})
	ConfirmClearAll(ISlice{0, 1, 2, 3, 4, 5}, ISlice{0, 0, 0, 0, 0, 0})
	ConfirmClearAll(I8Slice{0, 1, 2, 3, 4, 5}, I8Slice{0, 0, 0, 0, 0, 0})
	ConfirmClearAll(I16Slice{0, 1, 2, 3, 4, 5}, I16Slice{0, 0, 0, 0, 0, 0})
	ConfirmClearAll(I32Slice{0, 1, 2, 3, 4, 5}, I32Slice{0, 0, 0, 0, 0, 0})
	ConfirmClearAll(I64Slice{0, 1, 2, 3, 4, 5}, I64Slice{0, 0, 0, 0, 0, 0})

	ConfirmClearAll(SSlice{"A", "B", "A", "B", "A"}, SSlice{"", "", "", "", ""})
	ConfirmClearAll(USlice{0, 1, 2, 3, 4, 5}, USlice{0, 0, 0, 0, 0, 0})
	ConfirmClearAll(U8Slice{0, 1, 2, 3, 4, 5}, U8Slice{0, 0, 0, 0, 0, 0})
	ConfirmClearAll(U16Slice{0, 1, 2, 3, 4, 5}, U16Slice{0, 0, 0, 0, 0, 0})
	ConfirmClearAll(U32Slice{0, 1, 2, 3, 4, 5}, U32Slice{0, 0, 0, 0, 0, 0})
	ConfirmClearAll(U64Slice{0, 1, 2, 3, 4, 5}, U64Slice{0, 0, 0, 0, 0, 0})
	ConfirmClearAll(ASlice{0, 1, 2, 3, 4, 5}, ASlice{0, 0, 0, 0, 0, 0})

	ConfirmClearAll(RList(0, 1, 2, 3, 4, 5), RList(nil, nil, nil, nil, nil, nil))
	ConfirmClearAll(Slice{0, 1, 2, 3, 4, 5}, Slice{nil, nil, nil, nil, nil, nil})
	ConfirmClearAll(VList(0, 1, 2, 3, 4, 5), VList(nil, nil, nil, nil, nil, nil))
}

func TestShuffle(t *testing.T) {
	ConfirmShuffle := func(s, r interface{}) {
		if Shuffle(s.(Deck)); Equal(s, r) {
			t.Fatalf("Shuffle(%v) should change order of elements", s)
		}
		if Sort(s); !Equal(s, r) {
			t.Fatalf("Shuffle() when sorted should be %v but is %v", r, s)
		}
	}

	ConfirmShuffle(C64Slice{0, 1, 2, 3, 4, 5}, C64Slice{0, 1, 2, 3, 4, 5})
	ConfirmShuffle(C128Slice{0, 1, 2, 3, 4, 5}, C128Slice{0, 1, 2, 3, 4, 5})
	ConfirmShuffle(F64Slice{0, 1, 2, 3, 4, 5}, F64Slice{0, 1, 2, 3, 4, 5})
	ConfirmShuffle(F64Slice{0, 1, 2, 3, 4, 5}, F64Slice{0, 1, 2, 3, 4, 5})
	ConfirmShuffle(ISlice{0, 1, 2, 3, 4, 5}, ISlice{0, 1, 2, 3, 4, 5})
	ConfirmShuffle(I8Slice{0, 1, 2, 3, 4, 5}, I8Slice{0, 1, 2, 3, 4, 5})
	ConfirmShuffle(I16Slice{0, 1, 2, 3, 4, 5}, I16Slice{0, 1, 2, 3, 4, 5})
	ConfirmShuffle(I32Slice{0, 1, 2, 3, 4, 5}, I32Slice{0, 1, 2, 3, 4, 5})
	ConfirmShuffle(I64Slice{0, 1, 2, 3, 4, 5}, I64Slice{0, 1, 2, 3, 4, 5})

	ConfirmShuffle(SSlice{"A", "B", "A", "B", "A"}, SSlice{"A", "A", "A", "B", "B"})
	ConfirmShuffle(USlice{0, 1, 2, 3, 4, 5}, USlice{0, 1, 2, 3, 4, 5})
	ConfirmShuffle(U8Slice{0, 1, 2, 3, 4, 5}, U8Slice{0, 1, 2, 3, 4, 5})
	ConfirmShuffle(U16Slice{0, 1, 2, 3, 4, 5}, U16Slice{0, 1, 2, 3, 4, 5})
	ConfirmShuffle(U32Slice{0, 1, 2, 3, 4, 5}, U32Slice{0, 1, 2, 3, 4, 5})
	ConfirmShuffle(U64Slice{0, 1, 2, 3, 4, 5}, U64Slice{0, 1, 2, 3, 4, 5})
	ConfirmShuffle(ASlice{0, 1, 2, 3, 4, 5}, ASlice{0, 1, 2, 3, 4, 5})
}

func TestShuffleWithoutSorting(t *testing.T) {
	ConfirmShuffle := func(s Deck, r interface{}) {
		if Shuffle(s); Equal(s, r) {
			t.Fatalf("Shuffle(%v) should change order of elements", s)
		}
	}
	t.Log("Implement Sort for RSlice")
	ConfirmShuffle(RList(0, 1, 2, 3, 4, 5), RList(0, 1, 2, 3, 4, 5))

	t.Log("Implement Sort for Slice")
	ConfirmShuffle(Slice{0, 1, 2, 3, 4, 5}, Slice{0, 1, 2, 3, 4, 5})

	t.Log("Implement Sort for VSlice")
	ConfirmShuffle(VList(0, 1, 2, 3, 4, 5), VList(0, 1, 2, 3, 4, 5))
}

func TestSort(t *testing.T) {
	ConfirmSort := func(s, r interface{}) {
		if ok := Sort(s); !ok || !Equal(s, r) {
			t.Fatalf("Sort() should be %v but is %v", r, s)
		}
	}

	ConfirmSort(F32Slice{3, 2, 1, 4, 5, 0}, F32Slice{0, 1, 2, 3, 4, 5})
	ConfirmSort(F64Slice{3, 2, 1, 4, 5, 0}, F64Slice{0, 1, 2, 3, 4, 5})
	ConfirmSort(I16Slice{3, 2, 1, 4, 5, 0}, I16Slice{0, 1, 2, 3, 4, 5})
	ConfirmSort(I32Slice{3, 2, 1, 4, 5, 0}, I32Slice{0, 1, 2, 3, 4, 5})
	ConfirmSort(I64Slice{3, 2, 1, 4, 5, 0}, I64Slice{0, 1, 2, 3, 4, 5})
	ConfirmSort(I8Slice{3, 2, 1, 4, 5, 0}, I8Slice{0, 1, 2, 3, 4, 5})
	ConfirmSort(ISlice{3, 2, 1, 4, 5, 0}, ISlice{0, 1, 2, 3, 4, 5})
	ConfirmSort(SSlice{"D", "C", "B", "E", "F", "A"}, SSlice{"A", "B", "C", "D", "E", "F"})
	ConfirmSort(U16Slice{3, 2, 1, 4, 5, 0}, U16Slice{0, 1, 2, 3, 4, 5})
	ConfirmSort(U32Slice{3, 2, 1, 4, 5, 0}, U32Slice{0, 1, 2, 3, 4, 5})
	ConfirmSort(U64Slice{3, 2, 1, 4, 5, 0}, U64Slice{0, 1, 2, 3, 4, 5})
	ConfirmSort(U8Slice{3, 2, 1, 4, 5, 0}, U8Slice{0, 1, 2, 3, 4, 5})
	ConfirmSort(USlice{3, 2, 1, 4, 5, 0}, USlice{0, 1, 2, 3, 4, 5})
	ConfirmSort(ASlice{3, 2, 1, 4, 5, 0}, ASlice{0, 1, 2, 3, 4, 5})
}