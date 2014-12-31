package sets

import (
	"testing"
)

func TestUString(t *testing.T) {
	ConfirmString := func(s uset, r string) {
		if v := s.String(); r != v {
			t.Errorf("String() expected %v but produced %v", r, v)
		}
	}

	ConfirmString(USet(), "()")
	ConfirmString(USet(0, 1), "(0 1)")
	ConfirmString(USet(1, 0), "(0 1)")
	ConfirmString(USet(0, 1, 2, 3, 4), "(0 1 2 3 4)")
}

func TestUMember(t *testing.T) {
	ConfirmMember := func(s uset, x uint, r bool) {
		if v := s.Member(x); r != v {
			t.Errorf("%v.Member(%v) expected %v but produced %v", s, x, r, v)
		}
	}

	ConfirmMember(USet(), 0, false)
	ConfirmMember(USet(0), 0, true)
	ConfirmMember(USet(0, 1), 0, true)
	ConfirmMember(USet(0, 1), 1, true)
	ConfirmMember(USet(0, 1), 2, false)
}

func TestUEqual(t *testing.T) {
	ConfirmEqual := func(s, x uset, r bool) {
		if v := s.Equal(x); r != v {
			t.Errorf("%v.Equal(%v) expected %v but produced %v", s, x, r, v)
		}
	}

	ConfirmEqual(USet(), USet(), true)
	ConfirmEqual(USet(0), USet(), false)
	ConfirmEqual(USet(), USet(0), false)
	ConfirmEqual(USet(0), USet(0), true)
	ConfirmEqual(USet(0, 0), USet(0), true)
	ConfirmEqual(USet(0), USet(0, 0), true)
	ConfirmEqual(USet(0, 1), USet(0, 0), false)
	ConfirmEqual(USet(0, 1), USet(0, 1), true)
	ConfirmEqual(USet(0, 1), USet(1, 0), true)
	ConfirmEqual(USet(0, 1), USet(1, 1), false)
}

func TestUSum(t *testing.T) {
	ConfirmSum := func(s uset, r uint) {
		if v := s.Sum(); r != v {
			t.Errorf("%v.Sum() expected %v but produced %v", s, r, v)
		}
	}

	ConfirmSum(USet(), 0)
	ConfirmSum(USet(0), 0)
	ConfirmSum(USet(0, 1), 1)
	ConfirmSum(USet(0, 1, 1), 1)
	ConfirmSum(USet(0, 1, 2), 3)
}

func TestUProduct(t *testing.T) {
	ConfirmProduct := func(s uset, r uint) {
		if v := s.Product(); r != v {
			t.Errorf("%v.Sum() expected %v but produced %v", s, r, v)
		}
	}

	ConfirmProduct(USet(), 1)
	ConfirmProduct(USet(0), 0)
	ConfirmProduct(USet(0, 1), 0)
	ConfirmProduct(USet(1), 1)
	ConfirmProduct(USet(1, 1), 1)
	ConfirmProduct(USet(0, 1, 1), 0)
	ConfirmProduct(USet(0, 1, 2), 0)
	ConfirmProduct(USet(1, 2), 2)
	ConfirmProduct(USet(1, 2, 3), 6)
	ConfirmProduct(USet(1, 2, 3, 3), 6)
}