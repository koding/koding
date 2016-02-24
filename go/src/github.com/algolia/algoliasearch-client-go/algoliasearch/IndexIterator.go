package algoliasearch

import (
	"errors"
)

type IndexIterator struct {
	answer interface{}
	params interface{}
	pos    int
	index  *Index
}

func (it *IndexIterator) Next() (interface{}, error) {
	var err error
	for err == nil {
		hits := it.answer.(map[string]interface{})["hits"].([]interface{})
		if it.pos < len(hits) {
			it.pos++
			return hits[it.pos-1], nil
		}
		if cursor, ok := it.GetCursor(); ok && len(cursor) > 0 {
			err = it.loadNextPage()
			continue
		}
		return nil, errors.New("End of the index reached")
	}
	return nil, err
}

func (it *IndexIterator) GetCursor() (string, bool) {
	cursor, ok := it.answer.(map[string]interface{})["cursor"]
	cursorStr := ""
	if cursor != nil {
		cursorStr = cursor.(string)
	}
	return cursorStr, ok
}

func (it *IndexIterator) loadNextPage() error {
	it.pos = 0
	cursor, _ := it.GetCursor()
	answer, err := it.index.BrowseFrom(it.params, cursor)
	it.answer = answer
	return err
}
