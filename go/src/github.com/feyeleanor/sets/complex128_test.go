package sets

import (
	"testing"
)

func TestC128String(t *testing.T) {
	ConfirmString := func(s c128set, r string) {
		if v := s.String(); r != v {
			t.Errorf("String() expected %v but produced %v", r, v)
		}
	}

	ConfirmString(C128Set(), "()")
	ConfirmString(C128Set(0, 1), "((0+0i) (1+0i))")
	ConfirmString(C128Set(1, 0), "((0+0i) (1+0i))")
	ConfirmString(C128Set(0, 1, 2, 3, 4), "((0+0i) (1+0i) (2+0i) (3+0i) (4+0i))")
}

func TestC128Member(t *testing.T) {
	ConfirmMember := func(s c128set, x complex128, r bool) {
		if v := s.Member(x); r != v {
			t.Errorf("%v.Member(%v) expected %v but produced %v", s, x, r, v)
		}
	}

	ConfirmMember(C128Set(), 0, false)
	ConfirmMember(C128Set(0), 0, true)
	ConfirmMember(C128Set(0, 1), 0, true)
	ConfirmMember(C128Set(0, 1), 1, true)
	ConfirmMember(C128Set(0, 1), 2, false)
}

func TestC128Equal(t *testing.T) {
	ConfirmEqual := func(s, x c128set, r bool) {
		if v := s.Equal(x); r != v {
			t.Errorf("%v.Equal(%v) expected %v but produced %v", s, x, r, v)
		}
	}

	ConfirmEqual(C128Set(), C128Set(), true)
	ConfirmEqual(C128Set(0), C128Set(), false)
	ConfirmEqual(C128Set(), C128Set(0), false)
	ConfirmEqual(C128Set(0), C128Set(0), true)
	ConfirmEqual(C128Set(0, 0), C128Set(0), true)
	ConfirmEqual(C128Set(0), C128Set(0, 0), true)
	ConfirmEqual(C128Set(0, 1), C128Set(0, 0), false)
	ConfirmEqual(C128Set(0, 1), C128Set(0, 1), true)
	ConfirmEqual(C128Set(0, 1), C128Set(1, 0), true)
	ConfirmEqual(C128Set(0, 1), C128Set(1, 1), false)
}

func TestC128Sum(t *testing.T) {
	ConfirmSum := func(s c128set, r complex128) {
		if v := s.Sum(); r != v {
			t.Errorf("%v.Sum() expected %v but produced %v", s, r, v)
		}
	}

	ConfirmSum(C128Set(), 0)
	ConfirmSum(C128Set(0), 0)
	ConfirmSum(C128Set(0, 1), 1)
	ConfirmSum(C128Set(0, 1, 1), 1)
	ConfirmSum(C128Set(0, 1, 2), 3)
}

func TestC128Product(t *testing.T) {
	ConfirmProduct := func(s c128set, r complex128) {
		if v := s.Product(); r != v {
			t.Errorf("%v.Sum() expected %v but produced %v", s, r, v)
		}
	}

	ConfirmProduct(C128Set(), 1)
	ConfirmProduct(C128Set(0), 0)
	ConfirmProduct(C128Set(0, 1), 0)
	ConfirmProduct(C128Set(1), 1)
	ConfirmProduct(C128Set(1, 1), 1)
	ConfirmProduct(C128Set(0, 1, 1), 0)
	ConfirmProduct(C128Set(0, 1, 2), 0)
	ConfirmProduct(C128Set(1, 2), 2)
	ConfirmProduct(C128Set(1, 2, 3), 6)
	ConfirmProduct(C128Set(1, 2, 3, 3), 6)
}