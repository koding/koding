package amazon

func (a *Amazon) AddTag(instanceID, key, value string) error {
	return a.Client.AddTag(instanceID, key, value)
}

func (a *Amazon) AddTags(instanceID string, tags map[string]string) error {
	return a.Client.AddTags(instanceID, tags)
}
