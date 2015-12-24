package sl_test

import (
	"koding/kites/kloud/api/sl"
	"testing"
)

func TestTagsMatches(t *testing.T) {
	cases := []struct {
		tags  sl.Tags
		match sl.Tags
		ok    bool
	}{{ // i=0
		tags:  sl.Tags{"A": "B", "C": "D", "E": "F"},
		match: sl.Tags{"C": "D"},
		ok:    true,
	}, { // i=1
		tags:  sl.Tags{"Name": "koding-stable"},
		match: sl.Tags{"Name": "koding-stable"},
		ok:    true,
	}, { // i=2
		tags:  sl.Tags{"Name": "koding-stable"},
		match: sl.Tags{"Name": "koding-stable-old"},
		ok:    false,
	}, { // i=3
		tags:  sl.Tags{"Username": "rjeczalik"},
		match: sl.Tags{"Username": ""},
		ok:    true,
	}, { // i=4
		tags:  sl.Tags{"A": "B", "C": "D", "X": "F"},
		match: sl.Tags{"A": "B", "C": "D", "E": "F"},
		ok:    false,
	}, { // i=5
		tags:  sl.Tags{"mark_deleted": "", "foo": "bar"},
		match: sl.Tags{"mark_deleted": "rjeczalik"},
		ok:    true,
	}, { // i =6
		tags:  sl.Tags{"A": "B", "C": "D", "E": "F"},
		match: sl.Tags{"A": "B", "C": "D", "E": "F"},
		ok:    true,
	}, { // i=7
		tags:  sl.Tags{},
		match: sl.Tags{"Name": "koding-stable"},
		ok:    false,
	}}
	for i, cas := range cases {
		ok := cas.tags.Matches(cas.match)
		if ok != cas.ok {
			t.Errorf("%d: want ok=%t; got %t", i, cas.ok, ok)
		}
	}
}
