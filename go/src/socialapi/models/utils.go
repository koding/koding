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

// UnifyStringSlice removes duplicates from a string slice
func UnifyStringSlice(ss []string) []string {
	mss := make(map[string]struct{})

	for _, s := range ss {
		mss[s] = struct{}{}
	}

	// convert it to string slice
	res := make([]string, 0)
	for ms := range mss {
		res = append(res, ms)
	}

	return res
}
