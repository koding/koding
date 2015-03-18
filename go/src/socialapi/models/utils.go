package models

// IsIn checks if the first param is in the following ones
func IsIn(s string, ts ...string) bool {
	for _, t := range ts {
		if t == s {
			return true
		}
	}

	return false
}
