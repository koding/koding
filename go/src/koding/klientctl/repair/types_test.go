package repair

import "fmt"

type fakeRepairer struct {
	// Incremented count of calls to the given method
	StatusCount int
	RepairCount int

	// Fails if the incremented XCount field is smaller than this field.
	StatusFailUntil int
	RepairFailUntil int
}

func (r *fakeRepairer) String() string {
	return "fakerepairer"
}

func (r *fakeRepairer) Status() error {
	r.StatusCount++
	if r.StatusCount < r.StatusFailUntil {
		return fmt.Errorf(
			"Status was set to fail for request %d.", r.StatusCount,
		)
	}
	return nil
}

func (r *fakeRepairer) Repair() error {
	r.RepairCount++
	if r.RepairCount < r.RepairFailUntil {
		return fmt.Errorf(
			"Repair was set to fail for request %d.", r.RepairCount,
		)
	}
	return nil
}
