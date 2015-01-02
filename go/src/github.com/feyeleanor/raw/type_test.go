package raw

import "testing"

func TestConcreteValue(t *testing.T) { t.Log("Test not yet implemented") }
func TestMakeAddressable(t *testing.T) { t.Log("Test not yet implemented") }
func TestAssign(t *testing.T) { t.Log("Test not yet implemented") }

func TestCompatible(t *testing.T) {
	ConfirmCompatible := func(l, r interface{}) {
		switch {
		case !Compatible(l, r):		t.Fatalf("Compatible(%v, %v) should be true but is false", l, r)
		case !Compatible(r, l):		t.Fatalf("Compatible(%v, %v) should be true but is false", l, r)
		}
	}

	RefuteCompatible := func(l, r interface{}) {
		switch {
		case Compatible(l, r):		t.Fatalf("Compatible(%v, %v) should be false but is true", l, r)
		case Compatible(r, l):		t.Fatalf("Compatible(%v, %v) should be false but is true", l, r)
		}
	}

	ConfirmCompatible([]int{}, []int{})
	ConfirmCompatible([0]int{}, [0]int{})
	ConfirmCompatible([0]int{}, [1]int{})
	ConfirmCompatible([]int{ 0 }, [1]int{})

	RefuteCompatible([]int{}, []uint{})
	RefuteCompatible([0]int{}, [0]uint{})
	RefuteCompatible([0]int{}, [1]uint{})
	RefuteCompatible([]int{ 0 }, [1]uint{})

	ConfirmCompatible([]int{}, map[int]int{})
	ConfirmCompatible([0]int{}, map[int]int{})
	ConfirmCompatible([1]int{}, map[int]int{})
	ConfirmCompatible([]int{ 0 }, map[int]int{})
}