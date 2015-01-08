package sets

import (
	"testing"
)

func TestI32String(t *testing.T) {
	ConfirmString := func(s i32set, r string) {
		if v := s.String(); r != v {
			t.Errorf("String() expected %v but produced %v", r, v)
		}
	}

	ConfirmString(I32Set(), "()")
	ConfirmString(I32Set(0, 1), "(0 1)")
	ConfirmString(I32Set(1, 0), "(0 1)")
	ConfirmString(I32Set(0, 1, 2, 3, 4), "(0 1 2 3 4)")
}

func TestI32Member(t *testing.T) {
	ConfirmMember := func(s i32set, x int32, r bool) {
		if v := s.Member(x); r != v {
			t.Errorf("%v.Member(%v) expected %v but produced %v", s, x, r, v)
		}
	}

	ConfirmMember(I32Set(), 0, false)
	ConfirmMember(I32Set(0), 0, true)
	ConfirmMember(I32Set(0, 1), 0, true)
	ConfirmMember(I32Set(0, 1), 1, true)
	ConfirmMember(I32Set(0, 1), 2, false)
}

func TestI32Equal(t *testing.T) {
	ConfirmEqual := func(s, x i32set, r bool) {
		if v := s.Equal(x); r != v {
			t.Errorf("%v.Equal(%v) expected %v but produced %v", s, x, r, v)
		}
	}

	ConfirmEqual(I32Set(), I32Set(), true)
	ConfirmEqual(I32Set(0), I32Set(), false)
	ConfirmEqual(I32Set(), I32Set(0), false)
	ConfirmEqual(I32Set(0), I32Set(0), true)
	ConfirmEqual(I32Set(0, 0), I32Set(0), true)
	ConfirmEqual(I32Set(0), I32Set(0, 0), true)
	ConfirmEqual(I32Set(0, 1), I32Set(0, 0), false)
	ConfirmEqual(I32Set(0, 1), I32Set(0, 1), true)
	ConfirmEqual(I32Set(0, 1), I32Set(1, 0), true)
	ConfirmEqual(I32Set(0, 1), I32Set(1, 1), false)
}

func TestI32Sum(t *testing.T) {
	ConfirmSum := func(s i32set, r int32) {
		if v := s.Sum(); r != v {
			t.Errorf("%v.Sum() expected %v but produced %v", s, r, v)
		}
	}

	ConfirmSum(I32Set(), 0)
	ConfirmSum(I32Set(0), 0)
	ConfirmSum(I32Set(0, 1), 1)
	ConfirmSum(I32Set(0, 1, 1), 1)
	ConfirmSum(I32Set(0, 1, 2), 3)
}

func TestI32Product(t *testing.T) {
	ConfirmProduct := func(s i32set, r int32) {
		if v := s.Product(); r != v {
			t.Errorf("%v.Sum() expected %v but produced %v", s, r, v)
		}
	}

	ConfirmProduct(I32Set(), 1)
	ConfirmProduct(I32Set(0), 0)
	ConfirmProduct(I32Set(0, 1), 0)
	ConfirmProduct(I32Set(1), 1)
	ConfirmProduct(I32Set(1, 1), 1)
	ConfirmProduct(I32Set(0, 1, 1), 0)
	ConfirmProduct(I32Set(0, 1, 2), 0)
	ConfirmProduct(I32Set(1, 2), 2)
	ConfirmProduct(I32Set(1, 2, 3), 6)
	ConfirmProduct(I32Set(1, 2, 3, 3), 6)
}