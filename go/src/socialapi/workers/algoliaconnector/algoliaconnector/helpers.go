package algoliaconnector

import "errors"

var ErrDataNotValid = errors.New("Algolia error: invalid data")

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

	castRecord, ok := record.(map[string]interface{})
	if !ok {
		return nil, ErrDataNotValid
	}

	return castRecord, nil
}

func (f *Controller) partialUpdate(indexName string, record map[string]interface{}) error {
	index, err := f.indexes.Get(indexName)
	if err != nil {
		return err
	}

	if _, err = index.PartialUpdateObject(record); err != nil {
		return err
	}

	return nil
}

func removeTag(record map[string]interface{}, channelId string) []interface{} {
	if record == nil {
		return []interface{}{}
	}

	tagsDoc, ok := record["_tags"]
	if !ok {
		return []interface{}{}
	}

	tags, ok := tagsDoc.([]interface{})
	if !ok {
		return []interface{}{}
	}

	newTags := make([]interface{}, 0)
	for _, ele := range tags {
		if ele != channelId {
			newTags = append(newTags, ele)
		}
	}

	return newTags
}

func appendTag(record map[string]interface{}, channelId string) []interface{} {
	if record == nil {
		return []interface{}{channelId}
	}

	tagsDoc, ok := record["_tags"]
	if !ok {
		return []interface{}{channelId}
	}

	tags, ok := tagsDoc.([]interface{})
	if !ok {
		return []interface{}{channelId}
	}
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

	tagsDoc, ok := record["_tags"]
	if !ok {
		return nil
	}

	tags, ok := tagsDoc.([]interface{})
	if !ok {
		return nil
	}

	for _, ele := range tags {
		id := ele.(string)
		if id == channelId {
			continue
		}
		filtered = append(filtered, id)
	}

	return filtered
}
