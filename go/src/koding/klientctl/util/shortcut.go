package util

import "strings"

// MatchFullOrShortcut matches string in a slice of strings if full string is
// in the slice or if the beginning of item in the slice.
func MatchFullOrShortcut(items []string, name string) (string, bool) {
	var (
		match   string
		matched bool
	)

	for _, item := range items {
		if item == name {
			return item, true
		}

		if strings.HasPrefix(item, name) {
			match = item
			matched = true
		}
	}

	return match, matched
}
