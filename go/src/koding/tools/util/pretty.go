package util

import (
	"encoding/json"
	"fmt"
)

// LazyJSON gives a wrapper for an arbitrary value
// that implements fmt.Stringer, which pretty-prints
// the JSON-encoded representation of the value.
func LazyJSON(v interface{}) fmt.Stringer {
	return lazyJSON{v: v}
}

type lazyJSON struct {
	v interface{}
}

// String implements the fmt.Stringer interface.
func (l lazyJSON) String() string {
	vv := l.v

	switch v := l.v.(type) {
	case string:
		if err := json.Unmarshal([]byte(v), &vv); err != nil {
			return fmt.Sprintf("!JSON(%v)", l.v)
		}
	case []byte:
		if err := json.Unmarshal(v, &vv); err != nil {
			return fmt.Sprintf("!JSON(%v)", l.v)
		}
	}

	p, err := json.MarshalIndent(vv, "", "\t")
	if err != nil {
		return fmt.Sprintf("!JSON(%v)", l.v)
	}

	return string(p)
}
