package algoliaconnector

import (
	"errors"
	"fmt"
	"sync"
	"time"

	"github.com/algolia/algoliasearch-client-go/algoliasearch"
	"github.com/koding/logging"
	"github.com/streadway/amqp"
)

const (
	IndexAccounts = "accounts"

	UnretrievableAttributes = "unretrievableAttributes"
	AttributesToIndex       = "attributesToIndex"
)

var (
	ErrAlgoliaObjectIDNotFoundMsg = "ObjectID does not exist"
	ErrAlgoliaIndexNotExistMsg    = "Index messages.test does not exist"

	ErrTimeoutForSettings = errors.New("settings timed out")
)

type Settings struct {
	AttributesToIndex       []string
	UnretrievableAttributes []string
}

type IndexSetItem struct {
	Index    algoliasearch.Index
	Settings *Settings
}

type IndexSet map[string]*IndexSetItem

type Controller struct {
	log             logging.Logger
	client          algoliasearch.Client
	indexes         *IndexSet
	kodingChannelId string
}

func New(log logging.Logger, client algoliasearch.Client, indexSuffix string) *Controller {

	controller := &Controller{
		log:    log,
		client: client,
		indexes: &IndexSet{
			IndexAccounts: &IndexSetItem{
				Index: client.InitIndex(IndexAccounts + indexSuffix),
				Settings: &Settings{
					AttributesToIndex: []string{
						"nick",
						"email",
						"firstName",
						"lastName",
						"_tags",
					},
					UnretrievableAttributes: []string{"email"},
				},
			},
		},
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

func (i *IndexSetItem) MakeSureSettings(newSettings map[string]interface{}) error {
	task, err := i.Index.SetSettings(newSettings)
	if err != nil {
		return err
	}

	done := make(chan struct{})
	go func() {
		// make sure setting is propogated
		err = i.Index.WaitTask(task.TaskID)
		close(done)
	}()

	select {
	case <-done:
		return err
	case <-time.After(time.Second * 30):
		return ErrTimeoutForSettings
	}
}

func (i *IndexSet) GetIndex(name string) (algoliasearch.Index, error) {
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

func (c *Controller) InitAndDeleteIndex(name string) (interface{}, error) {
	index := c.client.InitIndex(name)
	return index.Delete()
}
func (c *Controller) ListIndexes() (interface{}, error) {
	return c.client.ListIndexes()

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

	settings, err := indexSet.Index.GetSettings()
	if err != nil {
		return err
	}

	var indexSettings []string
	switch settingName {
	case AttributesToIndex:
		indexSettings = settings.AttributesToIndex
	case UnretrievableAttributes:
		indexSettings = settings.UnretrievableAttributes
	}

	isSame := true
	for _, attributeToIndex := range newSettings {
		contains := false
		for _, currentAttribute := range indexSettings {
			if attributeToIndex == currentAttribute {
				contains = true
			}
		}

		if !contains {
			isSame = false
			break //  exit with the first condition
		}
	}

	if len(indexSettings) != len(newSettings) {
		isSame = false
	}

	if isSame {
		return nil
	}

	f.log.Info(
		"Previous (%+v) and Current (%+v) Setings of %s are not same for index %s, updating..",
		indexSettings,
		newSettings,
		settingName,
		indexName,
	)

	var setting algoliasearch.Map = make(map[string]interface{}, 0)
	setting[settingName] = newSettings
	return indexSet.MakeSureSettings(setting)
}

func (f *Controller) makeSureIndexSettings(settings map[string]interface{}, indexSet *IndexSetItem) error {
	task, err := indexSet.Index.SetSettings(settings)
	if err != nil {
		return err
	}

	done := make(chan struct{})
	go func() {
		// make sure setting is propogated
		err = indexSet.Index.WaitTask(task.TaskID)
		close(done)
	}()

	select {
	case <-done:
		return err
	case <-time.After(time.Second * 30):
		return errors.New("couldnt update index settings in 30 second")
	}
}
