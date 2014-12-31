package sets

import (
	"testing"
)

func TestC64String(t *testing.T) {
	ConfirmString := func(s c64set, r string) {
		if v := s.String(); r != v {
			t.Errorf("String() expected %v but produced %v", r, v)
		}
	}

	ConfirmString(C64Set(), "()")
	ConfirmString(C64Set(0, 1), "((0+0i) (1+0i))")
	ConfirmString(C64Set(1, 0), "((0+0i) (1+0i))")
	ConfirmString(C64Set(0, 1, 2, 3, 4), "((0+0i) (1+0i) (2+0i) (3+0i) (4+0i))")
}

func TestC64Member(t *testing.T) {
	ConfirmMember := func(s c64set, x complex64, r bool) {
		if v := s.Member(x); r != v {
			t.Errorf("%v.Member(%v) expected %v but produced %v", s, x, r, v)
		}
	}

	ConfirmMember(C64Set(), 0, false)
	ConfirmMember(C64Set(0), 0, true)
	ConfirmMember(C64Set(0, 1), 0, true)
	ConfirmMember(C64Set(0, 1), 1, true)
	ConfirmMember(C64Set(0, 1), 2, false)
}

func TestC64Equal(t *testing.T) {
	ConfirmEqual := func(s, x c64set, r bool) {
		if v := s.Equal(x); r != v {
			t.Errorf("%v.Equal(%v) expected %v but produced %v", s, x, r, v)
		}
	}

	ConfirmEqual(C64Set(), C64Set(), true)
	ConfirmEqual(C64Set(0), C64Set(), false)
	ConfirmEqual(C64Set(), C64Set(0), false)
	ConfirmEqual(C64Set(0), C64Set(0), true)
	ConfirmEqual(C64Set(0, 0), C64Set(0), true)
	ConfirmEqual(C64Set(0), C64Set(0, 0), true)
	ConfirmEqual(C64Set(0, 1), C64Set(0, 0), false)
	ConfirmEqual(C64Set(0, 1), C64Set(0, 1), true)
	ConfirmEqual(C64Set(0, 1), C64Set(1, 0), true)
	ConfirmEqual(C64Set(0, 1), C64Set(1, 1), false)
}

func TestC64Sum(t *testing.T) {
	ConfirmSum := func(s c64set, r complex64) {
		if v := s.Sum(); r != v {
			t.Errorf("%v.Sum() expected %v but produced %v", s, r, v)
		}
	}

	ConfirmSum(C64Set(), 0)
	ConfirmSum(C64Set(0), 0)
	ConfirmSum(C64Set(0, 1), 1)
	ConfirmSum(C64Set(0, 1, 1), 1)
	ConfirmSum(C64Set(0, 1, 2), 3)
}

func TestC64Product(t *testing.T) {
	ConfirmProduct := func(s c64set, r complex64) {
		if v := s.Product(); r != v {
			t.Errorf("%v.Sum() expected %v but produced %v", s, r, v)
		}
	}

	ConfirmProduct(C64Set(), 1)
	ConfirmProduct(C64Set(0), 0)
	ConfirmProduct(C64Set(0, 1), 0)
	ConfirmProduct(C64Set(1), 1)
	ConfirmProduct(C64Set(1, 1), 1)
	ConfirmProduct(C64Set(0, 1, 1), 0)
	ConfirmProduct(C64Set(0, 1, 2), 0)
	ConfirmProduct(C64Set(1, 2), 2)
	ConfirmProduct(C64Set(1, 2, 3), 6)
	ConfirmProduct(C64Set(1, 2, 3, 3), 6)
}