package util

import (
	"fmt"
	"strings"
)

// QuoteSpacedStrings takes a slice of strings and quotes any that have spaces.
//
// It does not do any advanced cli parsing of an already quoted string.
func QuoteSpacedStrings(sourceStrings ...string) []string {
	ss := make([]string, len(sourceStrings))
	for i, s := range sourceStrings {
		if strings.Contains(s, " ") {
			s = fmt.Sprintf(`"%s"`, s)
		}
		ss[i] = s
	}

	return ss
}
