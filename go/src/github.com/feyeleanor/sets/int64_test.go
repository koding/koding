package sets

import (
	"testing"
)

func TestI64String(t *testing.T) {
	ConfirmString := func(s i64set, r string) {
		if v := s.String(); r != v {
			t.Errorf("String() expected %v but produced %v", r, v)
		}
	}

	ConfirmString(I64Set(), "()")
	ConfirmString(I64Set(0, 1), "(0 1)")
	ConfirmString(I64Set(1, 0), "(0 1)")
	ConfirmString(I64Set(0, 1, 2, 3, 4), "(0 1 2 3 4)")
}

func TestI64Member(t *testing.T) {
	ConfirmMember := func(s i64set, x int64, r bool) {
		if v := s.Member(x); r != v {
			t.Errorf("%v.Member(%v) expected %v but produced %v", s, x, r, v)
		}
	}

	ConfirmMember(I64Set(), 0, false)
	ConfirmMember(I64Set(0), 0, true)
	ConfirmMember(I64Set(0, 1), 0, true)
	ConfirmMember(I64Set(0, 1), 1, true)
	ConfirmMember(I64Set(0, 1), 2, false)
}

func TestI64Equal(t *testing.T) {
	ConfirmEqual := func(s, x i64set, r bool) {
		if v := s.Equal(x); r != v {
			t.Errorf("%v.Equal(%v) expected %v but produced %v", s, x, r, v)
		}
	}

	ConfirmEqual(I64Set(), I64Set(), true)
	ConfirmEqual(I64Set(0), I64Set(), false)
	ConfirmEqual(I64Set(), I64Set(0), false)
	ConfirmEqual(I64Set(0), I64Set(0), true)
	ConfirmEqual(I64Set(0, 0), I64Set(0), true)
	ConfirmEqual(I64Set(0), I64Set(0, 0), true)
	ConfirmEqual(I64Set(0, 1), I64Set(0, 0), false)
	ConfirmEqual(I64Set(0, 1), I64Set(0, 1), true)
	ConfirmEqual(I64Set(0, 1), I64Set(1, 0), true)
	ConfirmEqual(I64Set(0, 1), I64Set(1, 1), false)
}

func TestI64Sum(t *testing.T) {
	ConfirmSum := func(s i64set, r int64) {
		if v := s.Sum(); r != v {
			t.Errorf("%v.Sum() expected %v but produced %v", s, r, v)
		}
	}

	ConfirmSum(I64Set(), 0)
	ConfirmSum(I64Set(0), 0)
	ConfirmSum(I64Set(0, 1), 1)
	ConfirmSum(I64Set(0, 1, 1), 1)
	ConfirmSum(I64Set(0, 1, 2), 3)
}

func TestI64Product(t *testing.T) {
	ConfirmProduct := func(s i64set, r int64) {
		if v := s.Product(); r != v {
			t.Errorf("%v.Sum() expected %v but produced %v", s, r, v)
		}
	}

	ConfirmProduct(I64Set(), 1)
	ConfirmProduct(I64Set(0), 0)
	ConfirmProduct(I64Set(0, 1), 0)
	ConfirmProduct(I64Set(1), 1)
	ConfirmProduct(I64Set(1, 1), 1)
	ConfirmProduct(I64Set(0, 1, 1), 0)
	ConfirmProduct(I64Set(0, 1, 2), 0)
	ConfirmProduct(I64Set(1, 2), 2)
	ConfirmProduct(I64Set(1, 2, 3), 6)
	ConfirmProduct(I64Set(1, 2, 3, 3), 6)
}