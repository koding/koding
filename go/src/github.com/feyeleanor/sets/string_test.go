package sets

import (
	"testing"
)

func TestSString(t *testing.T) {
	ConfirmString := func(s sset, r string) {
		if v := s.String(); r != v {
			t.Errorf("String() expected %v but produced %v", r, v)
		}
	}

	ConfirmString(SSet(), "()")
	ConfirmString(SSet("A", "B"), "(A B)")
	ConfirmString(SSet("B", "A"), "(A B)")
	ConfirmString(SSet("A", "B", "C", "D", "E"), "(A B C D E)")
}

func TestSMember(t *testing.T) {
	ConfirmMember := func(s sset, x string, r bool) {
		if v := s.Member(x); r != v {
			t.Errorf("%v.Member(%v) expected %v but produced %v", s, x, r, v)
		}
	}

	ConfirmMember(SSet(), "A", false)
	ConfirmMember(SSet("A"), "A", true)
	ConfirmMember(SSet("A", "B"), "A", true)
	ConfirmMember(SSet("A", "B"), "B", true)
	ConfirmMember(SSet("A", "B"), "C", false)
}

func TestSEqual(t *testing.T) {
	ConfirmEqual := func(s, x sset, r bool) {
		if v := s.Equal(x); r != v {
			t.Errorf("%v.Equal(%v) expected %v but produced %v", s, x, r, v)
		}
	}

	ConfirmEqual(SSet(), SSet(), true)
	ConfirmEqual(SSet("A"), SSet(), false)
	ConfirmEqual(SSet(), SSet("A"), false)
	ConfirmEqual(SSet("A"), SSet("A"), true)
	ConfirmEqual(SSet("A", "A"), SSet("A"), true)
	ConfirmEqual(SSet("A"), SSet("A", "A"), true)
	ConfirmEqual(SSet("A", "B"), SSet("A", "A"), false)
	ConfirmEqual(SSet("A", "B"), SSet("A", "B"), true)
	ConfirmEqual(SSet("A", "B"), SSet("B", "A"), true)
	ConfirmEqual(SSet("A", "B"), SSet("B", "B"), false)
}