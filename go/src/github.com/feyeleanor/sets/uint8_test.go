package sets

import (
	"testing"
)

func TestU8String(t *testing.T) {
	ConfirmString := func(s u8set, r string) {
		if v := s.String(); r != v {
			t.Errorf("String() expected %v but produced %v", r, v)
		}
	}

	ConfirmString(U8Set(), "()")
	ConfirmString(U8Set(0, 1), "(0 1)")
	ConfirmString(U8Set(1, 0), "(0 1)")
	ConfirmString(U8Set(0, 1, 2, 3, 4), "(0 1 2 3 4)")
}

func TestU8Member(t *testing.T) {
	ConfirmMember := func(s u8set, x uint8, r bool) {
		if v := s.Member(x); r != v {
			t.Errorf("%v.Member(%v) expected %v but produced %v", s, x, r, v)
		}
	}

	ConfirmMember(U8Set(), 0, false)
	ConfirmMember(U8Set(0), 0, true)
	ConfirmMember(U8Set(0, 1), 0, true)
	ConfirmMember(U8Set(0, 1), 1, true)
	ConfirmMember(U8Set(0, 1), 2, false)
}

func TestU8Equal(t *testing.T) {
	ConfirmEqual := func(s, x u8set, r bool) {
		if v := s.Equal(x); r != v {
			t.Errorf("%v.Equal(%v) expected %v but produced %v", s, x, r, v)
		}
	}

	ConfirmEqual(U8Set(), U8Set(), true)
	ConfirmEqual(U8Set(0), U8Set(), false)
	ConfirmEqual(U8Set(), U8Set(0), false)
	ConfirmEqual(U8Set(0), U8Set(0), true)
	ConfirmEqual(U8Set(0, 0), U8Set(0), true)
	ConfirmEqual(U8Set(0), U8Set(0, 0), true)
	ConfirmEqual(U8Set(0, 1), U8Set(0, 0), false)
	ConfirmEqual(U8Set(0, 1), U8Set(0, 1), true)
	ConfirmEqual(U8Set(0, 1), U8Set(1, 0), true)
	ConfirmEqual(U8Set(0, 1), U8Set(1, 1), false)
}

func TestU8Sum(t *testing.T) {
	ConfirmSum := func(s u8set, r uint8) {
		if v := s.Sum(); r != v {
			t.Errorf("%v.Sum() expected %v but produced %v", s, r, v)
		}
	}

	ConfirmSum(U8Set(), 0)
	ConfirmSum(U8Set(0), 0)
	ConfirmSum(U8Set(0, 1), 1)
	ConfirmSum(U8Set(0, 1, 1), 1)
	ConfirmSum(U8Set(0, 1, 2), 3)
}

func TestU8Product(t *testing.T) {
	ConfirmProduct := func(s u8set, r uint8) {
		if v := s.Product(); r != v {
			t.Errorf("%v.Sum() expected %v but produced %v", s, r, v)
		}
	}

	ConfirmProduct(U8Set(), 1)
	ConfirmProduct(U8Set(0), 0)
	ConfirmProduct(U8Set(0, 1), 0)
	ConfirmProduct(U8Set(1), 1)
	ConfirmProduct(U8Set(1, 1), 1)
	ConfirmProduct(U8Set(0, 1, 1), 0)
	ConfirmProduct(U8Set(0, 1, 2), 0)
	ConfirmProduct(U8Set(1, 2), 2)
	ConfirmProduct(U8Set(1, 2, 3), 6)
	ConfirmProduct(U8Set(1, 2, 3, 3), 6)
}