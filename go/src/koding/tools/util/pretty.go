package util

import (
	"encoding/json"
	"fmt"
)

// PrettyJSON is a wrapper for a JSON-encoded slice
// of bytes that implements fmt.Stringer, which
// pretty-prints the json.
type PrettyJSON []byte

// String implements the fmt.Stringer interface.
func (p PrettyJSON) String() string {
	var v interface{}

	if err := json.Unmarshal([]byte(p), &v); err != nil {
		return fmt.Sprintf("!JSON(%s)", []byte(p))
	}

	p, err := json.MarshalIndent(v, "", "\t")
	if err != nil {
		return fmt.Sprintf("!JSON(%s)", []byte(p))
	}

	return string(p)
}
