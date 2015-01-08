package sets

import (
	"testing"
)

func TestU64String(t *testing.T) {
	ConfirmString := func(s u64set, r string) {
		if v := s.String(); r != v {
			t.Errorf("String() expected %v but produced %v", r, v)
		}
	}

	ConfirmString(U64Set(), "()")
	ConfirmString(U64Set(0, 1), "(0 1)")
	ConfirmString(U64Set(1, 0), "(0 1)")
	ConfirmString(U64Set(0, 1, 2, 3, 4), "(0 1 2 3 4)")
}

func TestU64Member(t *testing.T) {
	ConfirmMember := func(s u64set, x uint64, r bool) {
		if v := s.Member(x); r != v {
			t.Errorf("%v.Member(%v) expected %v but produced %v", s, x, r, v)
		}
	}

	ConfirmMember(U64Set(), 0, false)
	ConfirmMember(U64Set(0), 0, true)
	ConfirmMember(U64Set(0, 1), 0, true)
	ConfirmMember(U64Set(0, 1), 1, true)
	ConfirmMember(U64Set(0, 1), 2, false)
}

func TestU64Equal(t *testing.T) {
	ConfirmEqual := func(s, x u64set, r bool) {
		if v := s.Equal(x); r != v {
			t.Errorf("%v.Equal(%v) expected %v but produced %v", s, x, r, v)
		}
	}

	ConfirmEqual(U64Set(), U64Set(), true)
	ConfirmEqual(U64Set(0), U64Set(), false)
	ConfirmEqual(U64Set(), U64Set(0), false)
	ConfirmEqual(U64Set(0), U64Set(0), true)
	ConfirmEqual(U64Set(0, 0), U64Set(0), true)
	ConfirmEqual(U64Set(0), U64Set(0, 0), true)
	ConfirmEqual(U64Set(0, 1), U64Set(0, 0), false)
	ConfirmEqual(U64Set(0, 1), U64Set(0, 1), true)
	ConfirmEqual(U64Set(0, 1), U64Set(1, 0), true)
	ConfirmEqual(U64Set(0, 1), U64Set(1, 1), false)
}

func TestU64Sum(t *testing.T) {
	ConfirmSum := func(s u64set, r uint64) {
		if v := s.Sum(); r != v {
			t.Errorf("%v.Sum() expected %v but produced %v", s, r, v)
		}
	}

	ConfirmSum(U64Set(), 0)
	ConfirmSum(U64Set(0), 0)
	ConfirmSum(U64Set(0, 1), 1)
	ConfirmSum(U64Set(0, 1, 1), 1)
	ConfirmSum(U64Set(0, 1, 2), 3)
}

func TestU64Product(t *testing.T) {
	ConfirmProduct := func(s u64set, r uint64) {
		if v := s.Product(); r != v {
			t.Errorf("%v.Sum() expected %v but produced %v", s, r, v)
		}
	}

	ConfirmProduct(U64Set(), 1)
	ConfirmProduct(U64Set(0), 0)
	ConfirmProduct(U64Set(0, 1), 0)
	ConfirmProduct(U64Set(1), 1)
	ConfirmProduct(U64Set(1, 1), 1)
	ConfirmProduct(U64Set(0, 1, 1), 0)
	ConfirmProduct(U64Set(0, 1, 2), 0)
	ConfirmProduct(U64Set(1, 2), 2)
	ConfirmProduct(U64Set(1, 2, 3), 6)
	ConfirmProduct(U64Set(1, 2, 3, 3), 6)
}