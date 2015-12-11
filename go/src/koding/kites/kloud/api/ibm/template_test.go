package ibm_test

import (
	"koding/kites/kloud/api/ibm"
	"testing"
)

func TestTagsMatches(t *testing.T) {
	cases := []struct {
		tags  ibm.Tags
		match ibm.Tags
		ok    bool
	}{{ // i=0
		tags:  ibm.Tags{"A": "B", "C": "D", "E": "F"},
		match: ibm.Tags{"C": "D"},
		ok:    true,
	}, { // i=1
		tags:  ibm.Tags{"Name": "koding-stable"},
		match: ibm.Tags{"Name": "koding-stable"},
		ok:    true,
	}, { // i=2
		tags:  ibm.Tags{"Name": "koding-stable"},
		match: ibm.Tags{"Name": "koding-stable-old"},
		ok:    false,
	}, { // i=3
		tags:  ibm.Tags{"Username": "rjeczalik"},
		match: ibm.Tags{"Username": ""},
		ok:    true,
	}, { // i=4
		tags:  ibm.Tags{"A": "B", "C": "D", "X": "F"},
		match: ibm.Tags{"A": "B", "C": "D", "E": "F"},
		ok:    false,
	}, { // i=5
		tags:  ibm.Tags{"mark_deleted": "", "foo": "bar"},
		match: ibm.Tags{"mark_deleted": "rjeczalik"},
		ok:    true,
	}, { // i =6
		tags:  ibm.Tags{"A": "B", "C": "D", "E": "F"},
		match: ibm.Tags{"A": "B", "C": "D", "E": "F"},
		ok:    true,
	}}
	for i, cas := range cases {
		ok := cas.tags.Matches(cas.match)
		if ok != cas.ok {
			t.Errorf("%d: want ok=%t; got %t", i, cas.ok, ok)
		}
	}
}
