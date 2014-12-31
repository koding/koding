package sets

import (
	"testing"
)

func TestAString(t *testing.T) {
	ConfirmString := func(s aset, r string) {
		if v := s.String(); r != v {
			t.Errorf("String() expected %v but produced %v", r, v)
		}
	}

	ConfirmString(ASet(), "()")
	ConfirmString(ASet(0, 1), "(0 1)")
	ConfirmString(ASet(1, 0), "(0 1)")
	ConfirmString(ASet(0, 1, 2, 3, 4), "(0 1 2 3 4)")
}

func TestAMember(t *testing.T) {
	ConfirmMember := func(s aset, x uintptr, r bool) {
		if v := s.Member(x); r != v {
			t.Errorf("%v.Member(%v) expected %v but produced %v", s, x, r, v)
		}
	}

	ConfirmMember(ASet(), 0, false)
	ConfirmMember(ASet(0), 0, true)
	ConfirmMember(ASet(0, 1), 0, true)
	ConfirmMember(ASet(0, 1), 1, true)
	ConfirmMember(ASet(0, 1), 2, false)
}

func TestAEqual(t *testing.T) {
	ConfirmEqual := func(s, x aset, r bool) {
		if v := s.Equal(x); r != v {
			t.Errorf("%v.Equal(%v) expected %v but produced %v", s, x, r, v)
		}
	}

	ConfirmEqual(ASet(), ASet(), true)
	ConfirmEqual(ASet(0), ASet(), false)
	ConfirmEqual(ASet(), ASet(0), false)
	ConfirmEqual(ASet(0), ASet(0), true)
	ConfirmEqual(ASet(0, 0), ASet(0), true)
	ConfirmEqual(ASet(0), ASet(0, 0), true)
	ConfirmEqual(ASet(0, 1), ASet(0, 0), false)
	ConfirmEqual(ASet(0, 1), ASet(0, 1), true)
	ConfirmEqual(ASet(0, 1), ASet(1, 0), true)
	ConfirmEqual(ASet(0, 1), ASet(1, 1), false)
}

func TestASum(t *testing.T) {
	ConfirmSum := func(s aset, r uintptr) {
		if v := s.Sum(); r != v {
			t.Errorf("%v.Sum() expected %v but produced %v", s, r, v)
		}
	}

	ConfirmSum(ASet(), 0)
	ConfirmSum(ASet(0), 0)
	ConfirmSum(ASet(0, 1), 1)
	ConfirmSum(ASet(0, 1, 1), 1)
	ConfirmSum(ASet(0, 1, 2), 3)
}

func TestAProduct(t *testing.T) {
	ConfirmProduct := func(s aset, r uintptr) {
		if v := s.Product(); r != v {
			t.Errorf("%v.Sum() expected %v but produced %v", s, r, v)
		}
	}

	ConfirmProduct(ASet(), 1)
	ConfirmProduct(ASet(0), 0)
	ConfirmProduct(ASet(0, 1), 0)
	ConfirmProduct(ASet(1), 1)
	ConfirmProduct(ASet(1, 1), 1)
	ConfirmProduct(ASet(0, 1, 1), 0)
	ConfirmProduct(ASet(0, 1, 2), 0)
	ConfirmProduct(ASet(1, 2), 2)
	ConfirmProduct(ASet(1, 2, 3), 6)
	ConfirmProduct(ASet(1, 2, 3, 3), 6)
}