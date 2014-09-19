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

func getTags(record map[string]interface{}, channelId string) []string {
	if record == nil {
		return []string{channelId}
	}

	tags := (record["_tags"]).([]string)
	for _, ele := range tags {
		if ele == channelId {
			return tags
		}
	}

	return append(tags, channelId)
}
