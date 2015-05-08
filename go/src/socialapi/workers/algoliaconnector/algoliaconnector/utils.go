package algoliaconnector

import "encoding/json"

// IsAlgoliaError checks if the given algolia error string and given messages
// are same according their data structure
func IsAlgoliaError(err error, message string) bool {
	if err == nil {
		return false
	}

	v := &algoliaErrorRes{}

	if err := json.Unmarshal([]byte(err.Error()), v); err != nil {
		return false
	}

	if v.Message == message {
		return true
	}

	return false
}

type algoliaErrorRes struct {
	Message string `json:"message"`
	// Status  int    `json:"status"`
}
