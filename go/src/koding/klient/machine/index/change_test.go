package index

import (
	"testing"
)

func TestChangeMetaCoalesce(t *testing.T) {
	tests := map[string]struct {
		A      ChangeMeta
		B      ChangeMeta
		Result ChangeMeta
	}{
		"UL+UL=UL": {
			A:      ChangeMetaUpdate | ChangeMetaLocal,
			B:      ChangeMetaUpdate | ChangeMetaLocal,
			Result: ChangeMetaUpdate | ChangeMetaLocal,
		},
		"DL+UL=DL": {
			A:      ChangeMetaRemove | ChangeMetaLocal,
			B:      ChangeMetaUpdate | ChangeMetaLocal,
			Result: ChangeMetaRemove | ChangeMetaLocal,
		},
		"DL+DL=DL": {
			A:      ChangeMetaRemove | ChangeMetaLocal,
			B:      ChangeMetaRemove | ChangeMetaLocal,
			Result: ChangeMetaRemove | ChangeMetaLocal,
		},
		"AL+UL=AL": {
			A:      ChangeMetaAdd | ChangeMetaLocal,
			B:      ChangeMetaUpdate | ChangeMetaLocal,
			Result: ChangeMetaAdd | ChangeMetaLocal,
		},
		"AL+DL=UL": {
			A:      ChangeMetaAdd | ChangeMetaLocal,
			B:      ChangeMetaRemove | ChangeMetaLocal,
			Result: ChangeMetaUpdate | ChangeMetaLocal,
		},
		"AL+AL=AL": {
			A:      ChangeMetaAdd | ChangeMetaLocal,
			B:      ChangeMetaAdd | ChangeMetaLocal,
			Result: ChangeMetaAdd | ChangeMetaLocal,
		},
		"UR+UL=UL": {
			A:      ChangeMetaUpdate | ChangeMetaRemote,
			B:      ChangeMetaUpdate | ChangeMetaLocal,
			Result: ChangeMetaUpdate | ChangeMetaLocal,
		},
		"UR+DL=DL": {
			A:      ChangeMetaUpdate | ChangeMetaRemote,
			B:      ChangeMetaRemove | ChangeMetaLocal,
			Result: ChangeMetaRemove | ChangeMetaLocal,
		},
		"UR+AL=UL": {
			A:      ChangeMetaUpdate | ChangeMetaRemote,
			B:      ChangeMetaAdd | ChangeMetaLocal,
			Result: ChangeMetaUpdate | ChangeMetaLocal,
		},
		"UR+UR=UR": {
			A:      ChangeMetaUpdate | ChangeMetaRemote,
			B:      ChangeMetaUpdate | ChangeMetaRemote,
			Result: ChangeMetaUpdate | ChangeMetaRemote,
		},
		"DR+UL=AL": {
			A:      ChangeMetaRemove | ChangeMetaRemote,
			B:      ChangeMetaUpdate | ChangeMetaLocal,
			Result: ChangeMetaAdd | ChangeMetaLocal,
		},
		"DR+DL=DL": {
			A:      ChangeMetaRemove | ChangeMetaRemote,
			B:      ChangeMetaRemove | ChangeMetaLocal,
			Result: ChangeMetaRemove | ChangeMetaLocal,
		},
		"DR+AL=AL": {
			A:      ChangeMetaRemove | ChangeMetaRemote,
			B:      ChangeMetaAdd | ChangeMetaLocal,
			Result: ChangeMetaAdd | ChangeMetaLocal,
		},
		"DR+UR=DR": {
			A:      ChangeMetaRemove | ChangeMetaRemote,
			B:      ChangeMetaUpdate | ChangeMetaRemote,
			Result: ChangeMetaRemove | ChangeMetaRemote,
		},
		"DR+DR=DR": {
			A:      ChangeMetaRemove | ChangeMetaRemote,
			B:      ChangeMetaRemove | ChangeMetaRemote,
			Result: ChangeMetaRemove | ChangeMetaRemote,
		},
		"AR+UL=UL": {
			A:      ChangeMetaAdd | ChangeMetaRemote,
			B:      ChangeMetaUpdate | ChangeMetaLocal,
			Result: ChangeMetaUpdate | ChangeMetaLocal,
		},
		"AR+DL=DL": {
			A:      ChangeMetaAdd | ChangeMetaRemote,
			B:      ChangeMetaRemove | ChangeMetaLocal,
			Result: ChangeMetaRemove | ChangeMetaLocal,
		},
		"AR+AL=UL": {
			A:      ChangeMetaAdd | ChangeMetaRemote,
			B:      ChangeMetaAdd | ChangeMetaLocal,
			Result: ChangeMetaUpdate | ChangeMetaLocal,
		},
		"AR+UR=AR": {
			A:      ChangeMetaAdd | ChangeMetaRemote,
			B:      ChangeMetaUpdate | ChangeMetaRemote,
			Result: ChangeMetaAdd | ChangeMetaRemote,
		},
		"AR+DR=UR": {
			A:      ChangeMetaAdd | ChangeMetaRemote,
			B:      ChangeMetaRemove | ChangeMetaRemote,
			Result: ChangeMetaUpdate | ChangeMetaRemote,
		},
		"AR+AR=AR": {
			A:      ChangeMetaAdd | ChangeMetaRemote,
			B:      ChangeMetaAdd | ChangeMetaRemote,
			Result: ChangeMetaAdd | ChangeMetaRemote,
		},
		"INV+A=AL": {
			A:      0,
			B:      ChangeMetaAdd,
			Result: ChangeMetaAdd | ChangeMetaLocal,
		},
		"AL+AL+OTHER META": {
			A:      ChangeMetaAdd | ChangeMetaLocal | ChangeMetaLarge,
			B:      ChangeMetaAdd | ChangeMetaLocal,
			Result: ChangeMetaAdd | ChangeMetaLocal | ChangeMetaLarge,
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
