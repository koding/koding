package sets

import (
	"testing"
)

func TestI8String(t *testing.T) {
	ConfirmString := func(s i8set, r string) {
		if v := s.String(); r != v {
			t.Errorf("String() expected %v but produced %v", r, v)
		}
	}

	ConfirmString(I8Set(), "()")
	ConfirmString(I8Set(0, 1), "(0 1)")
	ConfirmString(I8Set(1, 0), "(0 1)")
	ConfirmString(I8Set(0, 1, 2, 3, 4), "(0 1 2 3 4)")
}

func TestI8Member(t *testing.T) {
	ConfirmMember := func(s i8set, x int8, r bool) {
		if v := s.Member(x); r != v {
			t.Errorf("%v.Member(%v) expected %v but produced %v", s, x, r, v)
		}
	}

	ConfirmMember(I8Set(), 0, false)
	ConfirmMember(I8Set(0), 0, true)
	ConfirmMember(I8Set(0, 1), 0, true)
	ConfirmMember(I8Set(0, 1), 1, true)
	ConfirmMember(I8Set(0, 1), 2, false)
}

func TestI8Equal(t *testing.T) {
	ConfirmEqual := func(s, x i8set, r bool) {
		if v := s.Equal(x); r != v {
			t.Errorf("%v.Equal(%v) expected %v but produced %v", s, x, r, v)
		}
	}

	ConfirmEqual(I8Set(), I8Set(), true)
	ConfirmEqual(I8Set(0), I8Set(), false)
	ConfirmEqual(I8Set(), I8Set(0), false)
	ConfirmEqual(I8Set(0), I8Set(0), true)
	ConfirmEqual(I8Set(0, 0), I8Set(0), true)
	ConfirmEqual(I8Set(0), I8Set(0, 0), true)
	ConfirmEqual(I8Set(0, 1), I8Set(0, 0), false)
	ConfirmEqual(I8Set(0, 1), I8Set(0, 1), true)
	ConfirmEqual(I8Set(0, 1), I8Set(1, 0), true)
	ConfirmEqual(I8Set(0, 1), I8Set(1, 1), false)
}

func TestI8Sum(t *testing.T) {
	ConfirmSum := func(s i8set, r int8) {
		if v := s.Sum(); r != v {
			t.Errorf("%v.Sum() expected %v but produced %v", s, r, v)
		}
	}

	ConfirmSum(I8Set(), 0)
	ConfirmSum(I8Set(0), 0)
	ConfirmSum(I8Set(0, 1), 1)
	ConfirmSum(I8Set(0, 1, 1), 1)
	ConfirmSum(I8Set(0, 1, 2), 3)
}

func TestI8Product(t *testing.T) {
	ConfirmProduct := func(s i8set, r int8) {
		if v := s.Product(); r != v {
			t.Errorf("%v.Sum() expected %v but produced %v", s, r, v)
		}
	}

	ConfirmProduct(I8Set(), 1)
	ConfirmProduct(I8Set(0), 0)
	ConfirmProduct(I8Set(0, 1), 0)
	ConfirmProduct(I8Set(1), 1)
	ConfirmProduct(I8Set(1, 1), 1)
	ConfirmProduct(I8Set(0, 1, 1), 0)
	ConfirmProduct(I8Set(0, 1, 2), 0)
	ConfirmProduct(I8Set(1, 2), 2)
	ConfirmProduct(I8Set(1, 2, 3), 6)
	ConfirmProduct(I8Set(1, 2, 3, 3), 6)
}