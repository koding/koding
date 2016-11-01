package models

import "testing"

func TestUnifyStringSlice(t *testing.T) {
	testData := []struct {
		slice    []string
		expected []string
	}{
		{
			[]string{"team", "all"},
			[]string{"team", "all"},
		},
		{
			[]string{""},
			[]string{""},
		},
		{
			[]string{"admins", "admins", "ff"},
			[]string{"admins", "ff"},
		},
		{
			[]string{"admins", "team", "admins"},
			[]string{"admins", "team"},
		},
	}

	for _, test := range testData {
		responses := StringSliceUnique(test.slice)
		exists := false
		for _, response := range responses {
			for _, exc := range test.expected {
				if exc == response {
					exists = true
					break
				}
			}
		}

		if !exists {
			t.Fatalf("expected to exist but doesnt. got %+v", responses)
		}

		if len(test.expected) != len(responses) {
			t.Fatalf("%s. expected: %+v, got: %+v", "expected lengths are not same", test.expected, responses)
		}
	}
}
