package configstore

// SetFlatKeyValue exports setFlatKeyValue for testing purposes.
func SetFlatKeyValue(m map[string]interface{}, key, value string) error {
	return setFlatKeyValue(m, key, value)
}
