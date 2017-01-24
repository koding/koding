package algoliaconnector

import "errors"

var ErrDataNotValid = errors.New("Algolia error: invalid data")

func (f *Controller) insert(indexName string, record map[string]interface{}) error {
	index, err := f.indexes.GetIndex(indexName)
	if err != nil {
		return err
	}
	_, err = index.AddObject(record)
	return err
}

// Delete removes a record from the given indexName
func (f *Controller) delete(indexName string, objectID string) error {
	index, err := f.indexes.GetIndex(indexName)
	if err != nil {
		return err
	}
	_, err = index.DeleteObject(objectID)
	return err
}

func (f *Controller) get(indexName string, objectId string) (map[string]interface{}, error) {
	index, err := f.indexes.GetIndex(indexName)
	if err != nil {
		return nil, err
	}

	record, err := index.GetObject(objectId, nil)
	if err != nil {
		return nil, err
	}

	return record, nil
}

func (f *Controller) partialUpdate(indexName string, record map[string]interface{}) error {
	index, err := f.indexes.GetIndex(indexName)
	if err != nil {
		return err
	}

	if _, err = index.PartialUpdateObject(record); err != nil {
		return err
	}

	return nil
}

// AddUniqueTag Adds a number or string element to an array based-attribute if it doesn’t exist
func (f *Controller) AddUniqueTag(indexName string, objectID, value interface{}) error {
	return f.tagAction("AddUnique", indexName, objectID, value)
}

// RemoveTag Removes the first element from an array-based attribute
func (f *Controller) RemoveTag(indexName string, objectID, value interface{}) error {
	return f.tagAction("Remove", indexName, objectID, value)
}

// AddTag Appends a number or string element to an array-based attribute
func (f *Controller) AddTag(indexName string, objectID, value interface{}) error {
	return f.tagAction("Add", indexName, objectID, value)
}

func (f *Controller) tagAction(action, indexName string, objectID, value interface{}) error {
	return f.partialUpdate(indexName, map[string]interface{}{
		"objectID": objectID,
		"_tags": map[string]interface{}{
			"_operation": action,
			"value":      value,
		},
	})
}
