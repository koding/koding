package tunnelproxy

import "testing"

func TestGenName(t *testing.T) {
	cases := map[string]map[string]struct{}{
		"a":   nil,
		"b":   {"a": {}, "c": {}},
		"c":   {"a": {}, "b": {}},
		"ac":  {"a": {}, "b": {}, "c": {}},
		"bcc": {"a": {}, "b": {}, "c": {}, "ac": {}, "bc": {}, "cc": {}, "acc": {}},
	}

	for want, taken := range cases {
		got := genName('a', 'c', taken)
		if want != got {
			t.Errorf("got %s, want %s", got, want)
		}
	}
}
