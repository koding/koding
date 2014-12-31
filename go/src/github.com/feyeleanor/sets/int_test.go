package sets

import (
	"testing"
)

func TestIString(t *testing.T) {
	ConfirmString := func(s iset, r string) {
		if v := s.String(); r != v {
			t.Errorf("String() expected %v but produced %v", r, v)
		}
	}

	ConfirmString(ISet(), "()")
	ConfirmString(ISet(0, 1), "(0 1)")
	ConfirmString(ISet(1, 0), "(0 1)")
	ConfirmString(ISet(0, 1, 2, 3, 4), "(0 1 2 3 4)")
}

func TestIMember(t *testing.T) {
	ConfirmMember := func(s iset, x int, r bool) {
		if v := s.Member(x); r != v {
			t.Errorf("%v.Member(%v) expected %v but produced %v", s, x, r, v)
		}
	}

	ConfirmMember(ISet(), 0, false)
	ConfirmMember(ISet(0), 0, true)
	ConfirmMember(ISet(0, 1), 0, true)
	ConfirmMember(ISet(0, 1), 1, true)
	ConfirmMember(ISet(0, 1), 2, false)
}

func TestIEqual(t *testing.T) {
	ConfirmEqual := func(s, x iset, r bool) {
		if v := s.Equal(x); r != v {
			t.Errorf("%v.Equal(%v) expected %v but produced %v", s, x, r, v)
		}
	}

	ConfirmEqual(ISet(), ISet(), true)
	ConfirmEqual(ISet(0), ISet(), false)
	ConfirmEqual(ISet(), ISet(0), false)
	ConfirmEqual(ISet(0), ISet(0), true)
	ConfirmEqual(ISet(0, 0), ISet(0), true)
	ConfirmEqual(ISet(0), ISet(0, 0), true)
	ConfirmEqual(ISet(0, 1), ISet(0, 0), false)
	ConfirmEqual(ISet(0, 1), ISet(0, 1), true)
	ConfirmEqual(ISet(0, 1), ISet(1, 0), true)
	ConfirmEqual(ISet(0, 1), ISet(1, 1), false)
}

func TestISum(t *testing.T) {
	ConfirmSum := func(s iset, r int) {
		if v := s.Sum(); r != v {
			t.Errorf("%v.Sum() expected %v but produced %v", s, r, v)
		}
	}

	ConfirmSum(ISet(), 0)
	ConfirmSum(ISet(0), 0)
	ConfirmSum(ISet(0, 1), 1)
	ConfirmSum(ISet(0, 1, 1), 1)
	ConfirmSum(ISet(0, 1, 2), 3)
}

func TestIProduct(t *testing.T) {
	ConfirmProduct := func(s iset, r int) {
		if v := s.Product(); r != v {
			t.Errorf("%v.Sum() expected %v but produced %v", s, r, v)
		}
	}

	ConfirmProduct(ISet(), 1)
	ConfirmProduct(ISet(0), 0)
	ConfirmProduct(ISet(0, 1), 0)
	ConfirmProduct(ISet(1), 1)
	ConfirmProduct(ISet(1, 1), 1)
	ConfirmProduct(ISet(0, 1, 1), 0)
	ConfirmProduct(ISet(0, 1, 2), 0)
	ConfirmProduct(ISet(1, 2), 2)
	ConfirmProduct(ISet(1, 2, 3), 6)
	ConfirmProduct(ISet(1, 2, 3, 3), 6)
}