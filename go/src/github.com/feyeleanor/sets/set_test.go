package sets

import (
	"testing"
)

func TestSetString(t *testing.T) {
	ConfirmString := func(s vset, r string) {
		if v := s.String(); r != v {
			t.Errorf("String() expected %v but produced %v", r, v)
		}
	}

	ConfirmString(VSet(), "()")
//	ConfirmString(VSet("A", "B"), "(A B)")
//	ConfirmString(VSet("B", "A"), "(A B)")
//	ConfirmString(VSet("A", "B", "C", "D", "E"), "(A B C D E)")
}

func TestSetMember(t *testing.T) {
	ConfirmMember := func(s vset, x string, r bool) {
		if v := s.Member(x); r != v {
			t.Errorf("%v.Member(%v) expected %v but produced %v", s, x, r, v)
		}
	}

	ConfirmMember(VSet(), "A", false)
	ConfirmMember(VSet("A"), "A", true)
	ConfirmMember(VSet("A", "B"), "A", true)
	ConfirmMember(VSet("A", "B"), "B", true)
	ConfirmMember(VSet("A", "B"), "C", false)
}

func TestSetEqual(t *testing.T) {
	ConfirmEqual := func(s, x vset, r bool) {
		if v := s.Equal(x); r != v {
			t.Errorf("%v.Equal(%v) expected %v but produced %v", s, x, r, v)
		}
	}

	ConfirmEqual(VSet(), VSet(), true)
	ConfirmEqual(VSet("A"), VSet(), false)
	ConfirmEqual(VSet(), VSet("A"), false)
	ConfirmEqual(VSet("A"), VSet("A"), true)
	ConfirmEqual(VSet("A", "A"), VSet("A"), true)
	ConfirmEqual(VSet("A"), VSet("A", "A"), true)
	ConfirmEqual(VSet("A", "B"), VSet("A", "A"), false)
	ConfirmEqual(VSet("A", "B"), VSet("A", "B"), true)
	ConfirmEqual(VSet("A", "B"), VSet("B", "A"), true)
	ConfirmEqual(VSet("A", "B"), VSet("B", "B"), false)
}