package algoliaconnector

// addSynonym adds given synonym pairs to the given index. do not worry about
// duplicate synonyms, algolia handles them perfectly
func (f *Controller) addSynonym(indexName string, synonyms ...string) error {
	// TODO - this get & use pattern is very prone to race conditions
	synonymsSlice, err := f.getSynonyms(indexName)

	// append it to the previous ones, if there is any
	settings := make(map[string]interface{})
	settings["synonyms"] = append(synonymsSlice, synonyms)

	index, err := f.indexes.GetIndex(indexName)
	if err != nil {
		return err
	}

	_, err = index.SetSettings(settings)
	return err
}

func (f *Controller) getSynonyms(indexName string) ([][]string, error) {
	index, err := f.indexes.GetIndex(indexName)
	if err != nil {
		return nil, err
	}

	settingsinter, err := index.GetSettings()
	if err != nil {
		return nil, err
	}

	settings, ok := settingsinter.(map[string]interface{})
	if !ok {
		settings = make(map[string]interface{})
	}

	// define the initial synonymns
	synonyms := make([][]string, 0)

	synonymsSettings, ok := settings["synonyms"]
	if !ok {
		return synonyms, nil
	}

	// just for converting []interface{[]interface} to [][]string

	// infact it is [][]string
	synonymIntSlices, ok := synonymsSettings.([]interface{})
	if !ok {
		return synonyms, nil
	}

	for _, synonymIntSlice := range synonymIntSlices {

		synonymInt, ok := synonymIntSlice.([]interface{})
		if !ok {
			return synonyms, nil
		}

		pair := make([]string, 0)
		for _, tag := range synonymInt {
			pair = append(pair, tag.(string))
		}

		synonyms = append(synonyms, pair)
	}

	// if we have previous ones, use it
	return synonyms, nil
}
