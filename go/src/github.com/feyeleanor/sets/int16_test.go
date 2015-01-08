package sets

import (
	"testing"
)

func TestI16String(t *testing.T) {
	ConfirmString := func(s i16set, r string) {
		if v := s.String(); r != v {
			t.Errorf("String() expected %v but produced %v", r, v)
		}
	}

	ConfirmString(I16Set(), "()")
	ConfirmString(I16Set(0, 1), "(0 1)")
	ConfirmString(I16Set(1, 0), "(0 1)")
	ConfirmString(I16Set(0, 1, 2, 3, 4), "(0 1 2 3 4)")
}

func TestI16Member(t *testing.T) {
	ConfirmMember := func(s i16set, x int16, r bool) {
		if v := s.Member(x); r != v {
			t.Errorf("%v.Member(%v) expected %v but produced %v", s, x, r, v)
		}
	}

	ConfirmMember(I16Set(), 0, false)
	ConfirmMember(I16Set(0), 0, true)
	ConfirmMember(I16Set(0, 1), 0, true)
	ConfirmMember(I16Set(0, 1), 1, true)
	ConfirmMember(I16Set(0, 1), 2, false)
}

func TestI16Equal(t *testing.T) {
	ConfirmEqual := func(s, x i16set, r bool) {
		if v := s.Equal(x); r != v {
			t.Errorf("%v.Equal(%v) expected %v but produced %v", s, x, r, v)
		}
	}

	ConfirmEqual(I16Set(), I16Set(), true)
	ConfirmEqual(I16Set(0), I16Set(), false)
	ConfirmEqual(I16Set(), I16Set(0), false)
	ConfirmEqual(I16Set(0), I16Set(0), true)
	ConfirmEqual(I16Set(0, 0), I16Set(0), true)
	ConfirmEqual(I16Set(0), I16Set(0, 0), true)
	ConfirmEqual(I16Set(0, 1), I16Set(0, 0), false)
	ConfirmEqual(I16Set(0, 1), I16Set(0, 1), true)
	ConfirmEqual(I16Set(0, 1), I16Set(1, 0), true)
	ConfirmEqual(I16Set(0, 1), I16Set(1, 1), false)
}

func TestI16Sum(t *testing.T) {
	ConfirmSum := func(s i16set, r int16) {
		if v := s.Sum(); r != v {
			t.Errorf("%v.Sum() expected %v but produced %v", s, r, v)
		}
	}

	ConfirmSum(I16Set(), 0)
	ConfirmSum(I16Set(0), 0)
	ConfirmSum(I16Set(0, 1), 1)
	ConfirmSum(I16Set(0, 1, 1), 1)
	ConfirmSum(I16Set(0, 1, 2), 3)
}

func TestI16Product(t *testing.T) {
	ConfirmProduct := func(s i16set, r int16) {
		if v := s.Product(); r != v {
			t.Errorf("%v.Sum() expected %v but produced %v", s, r, v)
		}
	}

	ConfirmProduct(I16Set(), 1)
	ConfirmProduct(I16Set(0), 0)
	ConfirmProduct(I16Set(0, 1), 0)
	ConfirmProduct(I16Set(1), 1)
	ConfirmProduct(I16Set(1, 1), 1)
	ConfirmProduct(I16Set(0, 1, 1), 0)
	ConfirmProduct(I16Set(0, 1, 2), 0)
	ConfirmProduct(I16Set(1, 2), 2)
	ConfirmProduct(I16Set(1, 2, 3), 6)
	ConfirmProduct(I16Set(1, 2, 3, 3), 6)
}