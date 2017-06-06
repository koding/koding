package utils

// AssertStringSliceElementsEqual
func AssertStringSliceElementsEqual(first, second []string) bool {
	if len(first) != len(second) {
		return false
	}

	if len(first) == 0 && len(second) == 0 {
		return true
	}

	for _, f := range first {
		firstFound := false

		for _, s := range second {
			if f == s {
				firstFound = true
			}
		}

		if firstFound == false {
			return false
		}
	}

	return true
}
