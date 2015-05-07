package algoliaconnector

import (
	"errors"
	"socialapi/models"
)

func (f *Controller) ChannelLinkCreated(cl *models.ChannelLink) error {
	if err := f.validateSynonymRequest(cl); err != nil {
		f.log.Error("CreateSynonym validateSynonymRequest err: %s", err.Error())
		return nil
	}

	// check channel types
	rootChannel, err := models.Cache.Channel.ById(cl.RootId)
	if err != nil {
		return err
	}

	leafChannels, err := rootChannel.FetchLeaves()
	if err != nil {
		return err
	}

	leafNames := make([]string, len(leafChannels)+1) // +1 for root channel
	// add root channel to the first part
	leafNames[0] = rootChannel.Name

	for i, leafChannel := range leafChannels {
		leafNames[i+1] = leafChannel.Name
	}

	if err := f.addSynonym(IndexMessages, leafNames...); err != nil {
		return err
	}

	return f.addSynonym(IndexTopics, leafNames...)
}

func (f *Controller) validateSynonymRequest(cl *models.ChannelLink) error {
	// check required variables
	if cl == nil {
		return errors.New("channel link is not set (nil)")
	}

	if cl.Id == 0 {
		return errors.New("id is not set")
	}

	if cl.RootId == 0 {
		return errors.New("root id is not set")
	}

	if cl.LeafId == 0 {
		return errors.New("leaf id is not set")
	}

	// check channel types
	rootChannel, err := models.ChannelById(cl.RootId)
	if err != nil {
		return err
	}

	if !isValidChannelType(rootChannel) {
		return errors.New("root is not valid type for synonym")
	}

	leafChannel, err := models.ChannelById(cl.LeafId)
	if err != nil {
		return err
	}

	if !isValidChannelType(leafChannel) {
		return errors.New("leaf is not valid type for synonym")
	}

	return nil
}

func isValidChannelType(c *models.Channel) bool {
	return models.IsIn(
		c.TypeConstant,
		// type constant should be one of followings
		models.Channel_TYPE_TOPIC,
		models.Channel_TYPE_LINKED_TOPIC,
	)
}

// addSynonym adds given synonym pairs to the given index. do not worry about
// duplicate synonyms, algolia handles them perfectly
func (f *Controller) addSynonym(indexName string, synonyms ...string) error {
	// TODO - this get & use pattern is very prone to race conditions
	synonymsSlice, err := f.getSynonyms(indexName)

	// append it to the previous ones, if there is any
	settings := make(map[string]interface{})
	settings["synonyms"] = append(synonymsSlice, synonyms)

	index, err := f.indexes.Get(indexName)
	if err != nil {
		return err
	}

	_, err = index.SetSettings(settings)
	return err
}

func (f *Controller) getSynonyms(indexName string) ([][]string, error) {
	index, err := f.indexes.Get(indexName)
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
