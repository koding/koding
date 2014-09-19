package algoliaconnector

func (f *Controller) insert(indexName string, record map[string]interface{}) error {
	index, err := f.indexes.Get(indexName)
	if err != nil {
		return err
	}
	_, err = index.AddObject(record)
	return err
}

func (f *Controller) get(indexName string, objectId string) (map[string]interface{}, error) {
	index, err := f.indexes.Get(indexName)
	if err != nil {
		return nil, err
	}

	record, err := index.GetObject(objectId)
	if err != nil {
		return nil, err
	}

	return (record).(map[string]interface{}), nil
}

func (f *Controller) partialUpdate(indexName string, record map[string]interface{}) error {
	index, err := f.indexes.Get("messages")
	if err != nil {
		return err
	}

	if _, err = index.PartialUpdateObject(record); err != nil {
		return err
	}

	return nil
}

func appendMessageTag(record map[string]interface{}, channelId string) []interface{} {
	if record == nil {
		return []interface{}{channelId}
	}

	tags := (record["_tags"]).([]interface{})
	for _, ele := range tags {
		if ele == channelId {
			return tags
		}
	}

	return append(tags, channelId)
}

func removeMessageTag(record map[string]interface{}, channelId string) []interface{} {
	if record == nil {
		return nil
	}

	filtered := make([]interface{}, 0)

	tags := (record["_tags"]).([]interface{})
	for _, ele := range tags {
		id := ele.(string)
		if id == channelId {
			continue
		}
		filtered = append(filtered, id)
	}

	return filtered
}
