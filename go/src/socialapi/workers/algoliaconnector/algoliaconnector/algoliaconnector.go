package algoliaconnector

import (
	"fmt"
	"socialapi/models"
	"strconv"

	"github.com/algolia/algoliasearch-client-go/algoliasearch"
	"github.com/koding/logging"
	"github.com/streadway/amqp"
)

type IndexSet map[string]*algoliasearch.Index

type Controller struct {
	log     logging.Logger
	client  *algoliasearch.Client
	indexes *IndexSet
}

func (i *IndexSet) Get(name string) (*algoliasearch.Index, error) {
	index, ok := (*i)[name]
	if !ok {
		return nil, fmt.Errorf("Unknown index: '%s'", name)
	}
	return index, nil
}

func (t *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	// IDK what to do with this error; for now I will simply log it:
	return false
}

func New(log logging.Logger, client *algoliasearch.Client, indexSuffix string) *Controller {
	return &Controller{
		log:    log,
		client: client,
		indexes: &IndexSet{
			"topics":   client.InitIndex("topics" + indexSuffix),
			"accounts": client.InitIndex("accounts" + indexSuffix),
		},
	}
}

func (f *Controller) insert(indexName string, record map[string]interface{}) error {
	index, err := f.indexes.Get(indexName)
	if err != nil {
		return err
	}
	_, err = index.AddObject(record)
	return err
}

func (f *Controller) TopicSaved(data *models.Channel) error {
	if data.TypeConstant != models.Channel_TYPE_TOPIC {
		return nil
	}
	return f.insert("topics", map[string]interface{}{
		"name":     data.Name,
		"purpose":  data.Purpose,
		"objectID": strconv.FormatInt(data.Id, 10),
	})
}

func (f *Controller) AccountSaved(data *models.Account) error {
	return f.insert("accounts", map[string]interface{}{
		"nick":     data.Nick,
		"objectID": data.OldId,
	})
}
