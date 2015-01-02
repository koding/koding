package sets

import (
	"testing"
)

func TestU32String(t *testing.T) {
	ConfirmString := func(s u32set, r string) {
		if v := s.String(); r != v {
			t.Errorf("String() expected %v but produced %v", r, v)
		}
	}

	ConfirmString(U32Set(), "()")
	ConfirmString(U32Set(0, 1), "(0 1)")
	ConfirmString(U32Set(1, 0), "(0 1)")
	ConfirmString(U32Set(0, 1, 2, 3, 4), "(0 1 2 3 4)")
}

func TestU32Member(t *testing.T) {
	ConfirmMember := func(s u32set, x uint32, r bool) {
		if v := s.Member(x); r != v {
			t.Errorf("%v.Member(%v) expected %v but produced %v", s, x, r, v)
		}
	}

	ConfirmMember(U32Set(), 0, false)
	ConfirmMember(U32Set(0), 0, true)
	ConfirmMember(U32Set(0, 1), 0, true)
	ConfirmMember(U32Set(0, 1), 1, true)
	ConfirmMember(U32Set(0, 1), 2, false)
}

func TestU32Equal(t *testing.T) {
	ConfirmEqual := func(s, x u32set, r bool) {
		if v := s.Equal(x); r != v {
			t.Errorf("%v.Equal(%v) expected %v but produced %v", s, x, r, v)
		}
	}

	ConfirmEqual(U32Set(), U32Set(), true)
	ConfirmEqual(U32Set(0), U32Set(), false)
	ConfirmEqual(U32Set(), U32Set(0), false)
	ConfirmEqual(U32Set(0), U32Set(0), true)
	ConfirmEqual(U32Set(0, 0), U32Set(0), true)
	ConfirmEqual(U32Set(0), U32Set(0, 0), true)
	ConfirmEqual(U32Set(0, 1), U32Set(0, 0), false)
	ConfirmEqual(U32Set(0, 1), U32Set(0, 1), true)
	ConfirmEqual(U32Set(0, 1), U32Set(1, 0), true)
	ConfirmEqual(U32Set(0, 1), U32Set(1, 1), false)
}

func TestU32Sum(t *testing.T) {
	ConfirmSum := func(s u32set, r uint32) {
		if v := s.Sum(); r != v {
			t.Errorf("%v.Sum() expected %v but produced %v", s, r, v)
		}
	}

	ConfirmSum(U32Set(), 0)
	ConfirmSum(U32Set(0), 0)
	ConfirmSum(U32Set(0, 1), 1)
	ConfirmSum(U32Set(0, 1, 1), 1)
	ConfirmSum(U32Set(0, 1, 2), 3)
}

func TestU32Product(t *testing.T) {
	ConfirmProduct := func(s u32set, r uint32) {
		if v := s.Product(); r != v {
			t.Errorf("%v.Sum() expected %v but produced %v", s, r, v)
		}
	}

	ConfirmProduct(U32Set(), 1)
	ConfirmProduct(U32Set(0), 0)
	ConfirmProduct(U32Set(0, 1), 0)
	ConfirmProduct(U32Set(1), 1)
	ConfirmProduct(U32Set(1, 1), 1)
	ConfirmProduct(U32Set(0, 1, 1), 0)
	ConfirmProduct(U32Set(0, 1, 2), 0)
	ConfirmProduct(U32Set(1, 2), 2)
	ConfirmProduct(U32Set(1, 2, 3), 6)
	ConfirmProduct(U32Set(1, 2, 3, 3), 6)
}