package history_test

import (
	"fmt"
	"testing"
	"time"

	"koding/klient/machine/index"
	"koding/klient/machine/mount/sync/discard"
	"koding/klient/machine/mount/sync/history"
	"koding/klient/machine/mount/sync/synctest"
)

func TestHistory(t *testing.T) {
	const historySize = 5

	changes := []struct {
		Change *index.Change
		RecLen int
	}{
		{
			Change: nil,
			RecLen: 0,
		},
		{
			Change: index.NewChange("a/", index.PriorityLow, 0),
			RecLen: 3,
		},
		{
			Change: index.NewChange("b/", index.PriorityMedium, 0),
			RecLen: historySize,
		},
		{
			Change: index.NewChange("c/", index.PriorityHigh, 0),
			RecLen: historySize,
		},
	}

	h := history.NewHistory(discard.NewDiscard(), historySize)

	for i, change := range changes {
		tLeft := time.Now().UTC()

		if change.Change != nil {
			if err := synctest.ExecChange(h, change.Change, time.Second); err != nil {
				t.Fatalf("want err = nil; got %v (i:%d)", err, i)
			}
		}

		recs := h.Get()
		if len(recs) != change.RecLen {
			t.Fatalf("want recs len = %d; got %d (i:%d)", change.RecLen, len(recs), i)
		}

		// Check creation time of last three elements stored in returned slice.
		// Each new event should add at least three new entries to the buffer.
		// Here we check if they were added and if they are at the right place.
		maxIndex := len(recs) - 1
		for j := maxIndex; j >= 0 && maxIndex-j < 3; j-- {
			if err := timeBetween(recs[j].CreatedAt, tLeft, time.Now().UTC()); err != nil {
				t.Fatalf("want err = nil; got %v (i:%d,j:%d)", err, i, j)
			}
		}
	}
}

// timeBetween returns error when provided time stamp is not between tLeft and
// tRight. tRight must be greater than tLeft.
func timeBetween(t, tLeft, tRight time.Time) error {
	if d := t.Sub(tLeft); d < 0 {
		return fmt.Errorf("time %v is is before time %v (%v)", t, tLeft, -d)
	}
	if d := t.Sub(tRight); d > 0 {
		return fmt.Errorf("time %v is after time %v (%v)", t, tRight, d)
	}

	return nil
}
