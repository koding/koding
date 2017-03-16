package index_test

import (
	"fmt"
	"math/rand"
	"sync"
	"testing"
	"time"

	"koding/klient/machine/index"
)

func init() {
	// initialize pseudo random number generator.
	rand.Seed(time.Now().UnixNano())
}

func TestChangeMetaCoalesce(t *testing.T) {
	tests := map[string]struct {
		A      index.ChangeMeta
		B      index.ChangeMeta
		Result index.ChangeMeta
	}{
		"UL_UL_UL": {
			A:      index.ChangeMetaUpdate | index.ChangeMetaLocal,
			B:      index.ChangeMetaUpdate | index.ChangeMetaLocal,
			Result: index.ChangeMetaUpdate | index.ChangeMetaLocal,
		},
		"DL_UL_DL": {
			A:      index.ChangeMetaRemove | index.ChangeMetaLocal,
			B:      index.ChangeMetaUpdate | index.ChangeMetaLocal,
			Result: index.ChangeMetaRemove | index.ChangeMetaLocal,
		},
		"DL_DL_DL": {
			A:      index.ChangeMetaRemove | index.ChangeMetaLocal,
			B:      index.ChangeMetaRemove | index.ChangeMetaLocal,
			Result: index.ChangeMetaRemove | index.ChangeMetaLocal,
		},
		"AL_UL_AL": {
			A:      index.ChangeMetaAdd | index.ChangeMetaLocal,
			B:      index.ChangeMetaUpdate | index.ChangeMetaLocal,
			Result: index.ChangeMetaAdd | index.ChangeMetaLocal,
		},
		"AL_DL_UL": {
			A:      index.ChangeMetaAdd | index.ChangeMetaLocal,
			B:      index.ChangeMetaRemove | index.ChangeMetaLocal,
			Result: index.ChangeMetaUpdate | index.ChangeMetaLocal,
		},
		"AL_AL_AL": {
			A:      index.ChangeMetaAdd | index.ChangeMetaLocal,
			B:      index.ChangeMetaAdd | index.ChangeMetaLocal,
			Result: index.ChangeMetaAdd | index.ChangeMetaLocal,
		},
		"UR_UL_UL": {
			A:      index.ChangeMetaUpdate | index.ChangeMetaRemote,
			B:      index.ChangeMetaUpdate | index.ChangeMetaLocal,
			Result: index.ChangeMetaUpdate | index.ChangeMetaLocal,
		},
		"UR_DL_DL": {
			A:      index.ChangeMetaUpdate | index.ChangeMetaRemote,
			B:      index.ChangeMetaRemove | index.ChangeMetaLocal,
			Result: index.ChangeMetaRemove | index.ChangeMetaLocal,
		},
		"UR_AL_UL": {
			A:      index.ChangeMetaUpdate | index.ChangeMetaRemote,
			B:      index.ChangeMetaAdd | index.ChangeMetaLocal,
			Result: index.ChangeMetaUpdate | index.ChangeMetaLocal,
		},
		"UR_UR_UR": {
			A:      index.ChangeMetaUpdate | index.ChangeMetaRemote,
			B:      index.ChangeMetaUpdate | index.ChangeMetaRemote,
			Result: index.ChangeMetaUpdate | index.ChangeMetaRemote,
		},
		"DR_UL_AL": {
			A:      index.ChangeMetaRemove | index.ChangeMetaRemote,
			B:      index.ChangeMetaUpdate | index.ChangeMetaLocal,
			Result: index.ChangeMetaAdd | index.ChangeMetaLocal,
		},
		"DR_DL_DL": {
			A:      index.ChangeMetaRemove | index.ChangeMetaRemote,
			B:      index.ChangeMetaRemove | index.ChangeMetaLocal,
			Result: index.ChangeMetaRemove | index.ChangeMetaLocal,
		},
		"DR_AL_AL": {
			A:      index.ChangeMetaRemove | index.ChangeMetaRemote,
			B:      index.ChangeMetaAdd | index.ChangeMetaLocal,
			Result: index.ChangeMetaAdd | index.ChangeMetaLocal,
		},
		"DR_UR_DR": {
			A:      index.ChangeMetaRemove | index.ChangeMetaRemote,
			B:      index.ChangeMetaUpdate | index.ChangeMetaRemote,
			Result: index.ChangeMetaRemove | index.ChangeMetaRemote,
		},
		"DR_DR_DR": {
			A:      index.ChangeMetaRemove | index.ChangeMetaRemote,
			B:      index.ChangeMetaRemove | index.ChangeMetaRemote,
			Result: index.ChangeMetaRemove | index.ChangeMetaRemote,
		},
		"AR_UL_UL": {
			A:      index.ChangeMetaAdd | index.ChangeMetaRemote,
			B:      index.ChangeMetaUpdate | index.ChangeMetaLocal,
			Result: index.ChangeMetaUpdate | index.ChangeMetaLocal,
		},
		"AR_DL_DL": {
			A:      index.ChangeMetaAdd | index.ChangeMetaRemote,
			B:      index.ChangeMetaRemove | index.ChangeMetaLocal,
			Result: index.ChangeMetaRemove | index.ChangeMetaLocal,
		},
		"AR_AL_UL": {
			A:      index.ChangeMetaAdd | index.ChangeMetaRemote,
			B:      index.ChangeMetaAdd | index.ChangeMetaLocal,
			Result: index.ChangeMetaUpdate | index.ChangeMetaLocal,
		},
		"AR_UR_AR": {
			A:      index.ChangeMetaAdd | index.ChangeMetaRemote,
			B:      index.ChangeMetaUpdate | index.ChangeMetaRemote,
			Result: index.ChangeMetaAdd | index.ChangeMetaRemote,
		},
		"AR_DR_UR": {
			A:      index.ChangeMetaAdd | index.ChangeMetaRemote,
			B:      index.ChangeMetaRemove | index.ChangeMetaRemote,
			Result: index.ChangeMetaUpdate | index.ChangeMetaRemote,
		},
		"AR_AR_AR": {
			A:      index.ChangeMetaAdd | index.ChangeMetaRemote,
			B:      index.ChangeMetaAdd | index.ChangeMetaRemote,
			Result: index.ChangeMetaAdd | index.ChangeMetaRemote,
		},
		"INV_A_AL": {
			A:      0,
			B:      index.ChangeMetaAdd,
			Result: index.ChangeMetaAdd | index.ChangeMetaLocal,
		},
	}

	for name, test := range tests {
		test := test // Capture range variable.
		t.Run(name, func(t *testing.T) {
			t.Parallel()

			older, newer := test.A, test.B
			if older.Coalesce(newer); older != test.Result {
				t.Errorf("want meta = %b; got %b", test.Result, older)
			}

			// Order of Coalescing should not matter.
			older, newer = test.B, test.A
			if older.Coalesce(newer); older != test.Result {
				t.Errorf("want meta = %b; got %b", test.Result, older)
			}
		})
	}
}

func TestChangeMetaCoalesceConcurrent(t *testing.T) {
	const workersN = 10

	var wg sync.WaitGroup
	cmC := make(chan index.ChangeMeta)
	cm := index.ChangeMeta(0)

	wg.Add(workersN)
	for i := 0; i < workersN; i++ {
		go func() {
			defer wg.Done()

			for newer := range cmC {
				cm.Coalesce(newer)
			}
		}()
	}

	// Initialize array with N >> 1 invalid changes and one valid. This should
	// always result with valid change after coalescing.
	var cms = make([]index.ChangeMeta, 2000)
	cms[rand.Intn(len(cms))] = index.ChangeMetaAdd
	for i := range cms {
		cmC <- cms[i]
	}

	close(cmC)
	wg.Wait()

	if want := index.ChangeMetaAdd | index.ChangeMetaLocal; cm != want {
		t.Errorf("want cm = %b; got %b", want, cm)
	}
}

func TestChangeCoalesceConcurrent(t *testing.T) {
	const workersN = 10

	// The oldest change in this test.
	oldest := index.NewChange("change", index.PriorityHigh, 0)

	var wg sync.WaitGroup
	cC := make(chan *index.Change)
	c := index.NewChange("change", index.PriorityMedium, index.ChangeMetaUpdate)

	wg.Add(workersN)
	for i := 0; i < workersN; i++ {
		go func() {
			defer wg.Done()

			for newer := range cC {
				c.Coalesce(newer)
			}
		}()
	}

	var cs = make([]*index.Change, 200)
	randIdx := rand.Intn(len(cs))
	newest := index.NewChange("change", index.PriorityLow, index.ChangeMetaRemove)
	for i := range cs {
		if i == randIdx {
			cC <- newest
		} else {
			cC <- oldest
		}
	}

	close(cC)
	wg.Wait()

	if want, cm := index.ChangeMetaRemove|index.ChangeMetaLocal, c.Meta(); cm != want {
		t.Errorf("want cm = %b; got %b", want, cm)
	}

	if want, caun := newest.CreatedAtUnixNano(), c.CreatedAtUnixNano(); caun != want {
		t.Errorf("want caun = %d; got %d", want, caun)
	}

	if want, cp := index.PriorityHigh, c.Priority(); cp != want {
		t.Errorf("want cp = %b; got %b", want, cp)
	}
}

func TestSimilar(t *testing.T) {
	tests := map[string]struct {
		A      index.ChangeMeta
		B      index.ChangeMeta
		Result bool
	}{
		"UL is UL": {
			A:      index.ChangeMetaUpdate | index.ChangeMetaLocal,
			B:      index.ChangeMetaUpdate | index.ChangeMetaLocal,
			Result: true,
		},
		"U is UL": {
			A:      index.ChangeMetaUpdate,
			B:      index.ChangeMetaUpdate | index.ChangeMetaLocal,
			Result: true,
		},
		"UL is U": {
			A:      index.ChangeMetaUpdate | index.ChangeMetaLocal,
			B:      index.ChangeMetaUpdate,
			Result: true,
		},
		"UR is not UL": {
			A:      index.ChangeMetaUpdate | index.ChangeMetaRemote,
			B:      index.ChangeMetaUpdate | index.ChangeMetaLocal,
			Result: false,
		},
		"UL is not UR": {
			A:      index.ChangeMetaUpdate | index.ChangeMetaLocal,
			B:      index.ChangeMetaUpdate | index.ChangeMetaRemote,
			Result: false,
		},
		"AL is not DL": {
			A:      index.ChangeMetaAdd | index.ChangeMetaLocal,
			B:      index.ChangeMetaRemove | index.ChangeMetaLocal,
			Result: false,
		},
		"UL is not DL": {
			A:      index.ChangeMetaUpdate | index.ChangeMetaLocal,
			B:      index.ChangeMetaRemove | index.ChangeMetaLocal,
			Result: false,
		},
	}

	for name, test := range tests {
		test := test // Capture range variable.
		t.Run(name, func(t *testing.T) {
			t.Parallel()

			if similar := index.Similar(test.A, test.B); similar != test.Result {
				t.Errorf("want similar = %t; got %t", test.Result, similar)
			}
		})
	}
}

func TestChangeMetaString(t *testing.T) {
	tests := []struct {
		CM     index.ChangeMeta
		Result string
	}{
		{
			// 0 //
			CM:     index.ChangeMetaUpdate | index.ChangeMetaLocal,
			Result: "L---u",
		},
		{
			// 1 //
			CM:     index.ChangeMetaUpdate | index.ChangeMetaLocal | index.ChangeMetaRemote,
			Result: "LR--u",
		},
		{
			// 2 //
			CM:     index.ChangeMetaAdd | index.ChangeMetaRemote,
			Result: "-Ra--",
		},
		{
			// 3 //
			CM:     0,
			Result: "-----",
		},
		{
			// 4 //
			CM:     index.ChangeMetaRemove,
			Result: "---d-",
		},
	}

	for i, test := range tests {
		test := test // Capture range variable.
		t.Run(fmt.Sprintf("test_no_%d", i), func(t *testing.T) {
			t.Parallel()

			if got := test.CM.String(); got != test.Result {
				t.Errorf("want cm string = %q; got %q", test.Result, got)
			}
		})
	}
}
