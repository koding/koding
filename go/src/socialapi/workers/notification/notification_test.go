package notification

import "testing"

func TestCleanup(t *testing.T) {
	testData := []struct {
		definition string
		usernames  []string
		expected   []string
	}{
		{
			"should remove aliases",
			[]string{"team", "all"},
			[]string{"all"},
		},
		{
			"should return same usernames",
			[]string{"foo", "bar", "zaar"},
			[]string{"foo", "bar", "zaar"},
		},
		{
			"should remove duplicates",
			[]string{"admins", "admins", "ff"},
			[]string{"admins", "ff"},
		},
		{
			"should remove specific ones if have a general one",
			[]string{"admins", "admins", "team"},
			[]string{"all"},
		},
		{
			"should reduce to global alias",
			[]string{"team", "all", "group"},
			[]string{"all"},
		},
		{
			// some of the admins may not be in the channel
			"should keep channel and admins",
			[]string{"channel", "bar", "admins"},
			[]string{"channel", "bar", "admins"},
		},
	}

	for _, test := range testData {
		responses := cleanup(test.usernames)
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
			t.Fatalf("%s. expected: %+v, got: %+v", test.definition, responses)
		}

		if len(test.expected) != len(responses) {
			t.Fatalf("%s, %s. expected: %+v, got: %+v", test.definition, "expected lengths are not same", test.expected, responses)
		}
	}
}
