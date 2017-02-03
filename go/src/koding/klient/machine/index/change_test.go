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
		"UL_UL_UL": {
			A:      ChangeMetaUpdate | ChangeMetaLocal,
			B:      ChangeMetaUpdate | ChangeMetaLocal,
			Result: ChangeMetaUpdate | ChangeMetaLocal,
		},
		"DL_UL_DL": {
			A:      ChangeMetaRemove | ChangeMetaLocal,
			B:      ChangeMetaUpdate | ChangeMetaLocal,
			Result: ChangeMetaRemove | ChangeMetaLocal,
		},
		"DL_DL_DL": {
			A:      ChangeMetaRemove | ChangeMetaLocal,
			B:      ChangeMetaRemove | ChangeMetaLocal,
			Result: ChangeMetaRemove | ChangeMetaLocal,
		},
		"AL_UL_AL": {
			A:      ChangeMetaAdd | ChangeMetaLocal,
			B:      ChangeMetaUpdate | ChangeMetaLocal,
			Result: ChangeMetaAdd | ChangeMetaLocal,
		},
		"AL_DL_UL": {
			A:      ChangeMetaAdd | ChangeMetaLocal,
			B:      ChangeMetaRemove | ChangeMetaLocal,
			Result: ChangeMetaUpdate | ChangeMetaLocal,
		},
		"AL_AL_AL": {
			A:      ChangeMetaAdd | ChangeMetaLocal,
			B:      ChangeMetaAdd | ChangeMetaLocal,
			Result: ChangeMetaAdd | ChangeMetaLocal,
		},
		"UR_UL_UL": {
			A:      ChangeMetaUpdate | ChangeMetaRemote,
			B:      ChangeMetaUpdate | ChangeMetaLocal,
			Result: ChangeMetaUpdate | ChangeMetaLocal,
		},
		"UR_DL_DL": {
			A:      ChangeMetaUpdate | ChangeMetaRemote,
			B:      ChangeMetaRemove | ChangeMetaLocal,
			Result: ChangeMetaRemove | ChangeMetaLocal,
		},
		"UR_AL_UL": {
			A:      ChangeMetaUpdate | ChangeMetaRemote,
			B:      ChangeMetaAdd | ChangeMetaLocal,
			Result: ChangeMetaUpdate | ChangeMetaLocal,
		},
		"UR_UR_UR": {
			A:      ChangeMetaUpdate | ChangeMetaRemote,
			B:      ChangeMetaUpdate | ChangeMetaRemote,
			Result: ChangeMetaUpdate | ChangeMetaRemote,
		},
		"DR_UL_AL": {
			A:      ChangeMetaRemove | ChangeMetaRemote,
			B:      ChangeMetaUpdate | ChangeMetaLocal,
			Result: ChangeMetaAdd | ChangeMetaLocal,
		},
		"DR_DL_DL": {
			A:      ChangeMetaRemove | ChangeMetaRemote,
			B:      ChangeMetaRemove | ChangeMetaLocal,
			Result: ChangeMetaRemove | ChangeMetaLocal,
		},
		"DR_AL_AL": {
			A:      ChangeMetaRemove | ChangeMetaRemote,
			B:      ChangeMetaAdd | ChangeMetaLocal,
			Result: ChangeMetaAdd | ChangeMetaLocal,
		},
		"DR_UR_DR": {
			A:      ChangeMetaRemove | ChangeMetaRemote,
			B:      ChangeMetaUpdate | ChangeMetaRemote,
			Result: ChangeMetaRemove | ChangeMetaRemote,
		},
		"DR_DR_DR": {
			A:      ChangeMetaRemove | ChangeMetaRemote,
			B:      ChangeMetaRemove | ChangeMetaRemote,
			Result: ChangeMetaRemove | ChangeMetaRemote,
		},
		"AR_UL_UL": {
			A:      ChangeMetaAdd | ChangeMetaRemote,
			B:      ChangeMetaUpdate | ChangeMetaLocal,
			Result: ChangeMetaUpdate | ChangeMetaLocal,
		},
		"AR_DL_DL": {
			A:      ChangeMetaAdd | ChangeMetaRemote,
			B:      ChangeMetaRemove | ChangeMetaLocal,
			Result: ChangeMetaRemove | ChangeMetaLocal,
		},
		"AR_AL_UL": {
			A:      ChangeMetaAdd | ChangeMetaRemote,
			B:      ChangeMetaAdd | ChangeMetaLocal,
			Result: ChangeMetaUpdate | ChangeMetaLocal,
		},
		"AR_UR_AR": {
			A:      ChangeMetaAdd | ChangeMetaRemote,
			B:      ChangeMetaUpdate | ChangeMetaRemote,
			Result: ChangeMetaAdd | ChangeMetaRemote,
		},
		"AR_DR_UR": {
			A:      ChangeMetaAdd | ChangeMetaRemote,
			B:      ChangeMetaRemove | ChangeMetaRemote,
			Result: ChangeMetaUpdate | ChangeMetaRemote,
		},
		"AR_AR_AR": {
			A:      ChangeMetaAdd | ChangeMetaRemote,
			B:      ChangeMetaAdd | ChangeMetaRemote,
			Result: ChangeMetaAdd | ChangeMetaRemote,
		},
		"INV_A_AL": {
			A:      0,
			B:      ChangeMetaAdd,
			Result: ChangeMetaAdd | ChangeMetaLocal,
		},
		"AL_AL_OTHER META": {
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
