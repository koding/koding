package algoliaconnector

import (
	"errors"
	"fmt"
	"socialapi/models"
	"socialapi/request"
	"strconv"
	"sync"
	"time"

	"github.com/algolia/algoliasearch-client-go/algoliasearch"
	"github.com/koding/logging"
	"github.com/streadway/amqp"
)

const (
	IndexMessages = "messages"
	IndexTopics   = "topics"
	IndexAccounts = "accounts"

	UnretrievableAttributes = "unretrievableAttributes"
	AttributesToIndex       = "attributesToIndex"
)

var (
	ErrAlgoliaObjectIdNotFoundMsg = "ObjectID does not exist"
	ErrAlgoliaIndexNotExistMsg    = "Index messages.test does not exist"
)

type Settings struct {
	AttributesToIndex       []string
	UnretrievableAttributes []string
}

type IndexSetItem struct {
	Index    *algoliasearch.Index
	Settings *Settings
}

type IndexSet map[string]*IndexSetItem

type Controller struct {
	log             logging.Logger
	client          *algoliasearch.Client
	indexes         *IndexSet
	kodingChannelId string
}

func New(log logging.Logger, client *algoliasearch.Client, indexSuffix string) *Controller {
	// TODO later on listen channel_participant_added event and remove this koding channel fetch
	c := models.NewChannel()
	q := request.NewQuery()
	q.GroupName = "koding"
	q.Name = "public"
	q.Type = models.Channel_TYPE_GROUP

	channel, err := c.ByName(q)
	if err != nil {
		log.Error("Could not fetch koding channel: %s:", err)
	}
	var channelId string
	if channel.Id != 0 {
		channelId = strconv.FormatInt(channel.Id, 10)
	}

	controller := &Controller{
		log:    log,
		client: client,
		indexes: &IndexSet{
			IndexTopics: &IndexSetItem{
				Index: client.InitIndex(IndexTopics + indexSuffix),
				Settings: &Settings{
					// empty slice means all properties will be searchable
					AttributesToIndex: []string{},
				},
			},
			IndexAccounts: &IndexSetItem{
				Index: client.InitIndex(IndexAccounts + indexSuffix),
				Settings: &Settings{
					AttributesToIndex: []string{
						"nick",
						"email",
						"_tags",
					},
					UnretrievableAttributes: []string{"email"},
				},
			},
			IndexMessages: &IndexSetItem{
				Index: client.InitIndex(IndexMessages + indexSuffix),
				Settings: &Settings{
					AttributesToIndex: []string{},
				},
			},
		},
		kodingChannelId: channelId,
	}

	return controller
}

func (i *IndexSet) Get(name string) (*IndexSetItem, error) {
	indexItem, ok := (*i)[name]
	if !ok {
		return nil, fmt.Errorf("Unknown indexItem: '%s'", name)
	}

	return indexItem, nil
}

func (i *IndexSet) GetIndex(name string) (*algoliasearch.Index, error) {
	indexItem, ok := (*i)[name]
	if !ok {
		return nil, fmt.Errorf("Unknown indexItem: '%s'", name)
	}

	return indexItem.Index, nil
}

func (c *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	c.log.Error(err.Error())
	return false
}

func (f *Controller) Init() error {
	var wg sync.WaitGroup
	for name, index := range *(f.indexes) {
		wg.Add(1)

		go func(name string, index *IndexSetItem) {
			if err := f.makeSureStringSliceSettings(name, UnretrievableAttributes, index.Settings.UnretrievableAttributes); err != nil {
				f.log.Error("indexName: %s, settings name: %s, Err: %s", name, UnretrievableAttributes, err.Error())
			}

			if err := f.makeSureStringSliceSettings(name, AttributesToIndex, index.Settings.AttributesToIndex); err != nil {
				f.log.Error("indexName: %s, settings name: %s, Err: %s", name, AttributesToIndex, err.Error())
			}
			wg.Done()
		}(name, index)
	}

	wg.Wait()

	f.log.Info("Init done!")
	return nil
}

func (f *Controller) makeSureStringSliceSettings(indexName string, settingName string, newSettings []string) error {
	indexSet, err := f.indexes.Get(indexName)
	if err != nil {
		return err
	}

	settingsinter, err := indexSet.Index.GetSettings()
	if err != nil {
		return err
	}

	settings, ok := settingsinter.(map[string]interface{})
	if !ok {
		settings = make(map[string]interface{})
	}

	indexSettings, ok := settings[settingName]
	if !ok {
		indexSettings = make([]interface{}, 0)
	}

	indexSettingsIntSlices, ok := indexSettings.([]interface{})
	if !ok {
		indexSettingsIntSlices = make([]interface{}, 0)
	}

	isSame := true
	for _, attributeToIndex := range newSettings {
		contains := false
		for _, currentAttribute := range indexSettingsIntSlices {
			if attributeToIndex == currentAttribute.(string) {
				contains = true
			}
		}

		if !contains {
			isSame = false
			break //  exit with the first condition
		}
	}

	if len(indexSettingsIntSlices) != len(newSettings) {
		isSame = false
	}

	if !isSame {
		f.log.Info(
			"Previous (%+v) and Current (%+v) Setings of %s are not same for index %s, updating..",
			indexSettingsIntSlices,
			newSettings,
			settingName,
			indexName,
		)
		settings[settingName] = newSettings
		return f.updateIndexSetting(settings, indexSet)
	}

	return err
}

func (f *Controller) updateIndexSetting(settings map[string]interface{}, indexSet *IndexSetItem) error {
	task, err := indexSet.Index.SetSettings(settings)
	if err != nil {
		return err
	}

	done := make(chan struct{})
	go func() {
		// make sure setting is propogated
		_, err = indexSet.Index.WaitTask(task)
		close(done)
	}()

	select {
	case <-done:
		return err
	case <-time.After(time.Second * 30):
		return errors.New("couldnt update index settings in 30 second")
	}
}
