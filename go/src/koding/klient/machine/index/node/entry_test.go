package node_test

import (
	"fmt"
	"testing"

	"koding/klient/machine/index/node"
)

func TestEntryPromiseString(t *testing.T) {
	tests := []struct {
		EP     node.EntryPromise
		Result string
	}{
		{
			// 0 //
			EP:     node.EntryPromiseVirtual,
			Result: "V---",
		},
		{
			// 1 //
			EP:     node.EntryPromiseVirtual | node.EntryPromiseDel,
			Result: "V--D",
		},
		{
			// 2 //
			EP:     node.EntryPromiseAdd,
			Result: "-A--",
		},
		{
			// 3 //
			EP:     0,
			Result: "----",
		},
	}

	for i, test := range tests {
		test := test // Capture range variable.
		t.Run(fmt.Sprintf("test_no_%d", i), func(t *testing.T) {
			t.Parallel()

			if got := test.EP.String(); got != test.Result {
				t.Errorf("want ep string = %q; got %q", test.Result, got)
			}
		})
	}
}
