package algoliaconnector

import (
	"fmt"
	"socialapi/models"
	"socialapi/request"
	"strconv"

	"github.com/algolia/algoliasearch-client-go/algoliasearch"
	"github.com/koding/logging"
	"github.com/streadway/amqp"
)

const (
	IndexMessages = "messages"
	IndexTopics   = "topics"
	IndexAccounts = "accounts"
)

var (
	ErrAlgoliaObjectIdNotFoundMsg = "ObjectID does not exist"
	ErrAlgoliaIndexNotExistMsg    = "Index messages.test does not exist"
)

type IndexSet map[string]*algoliasearch.Index

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

	return &Controller{
		log:    log,
		client: client,
		indexes: &IndexSet{
			IndexTopics:   client.InitIndex(IndexTopics + indexSuffix),
			IndexAccounts: client.InitIndex(IndexAccounts + indexSuffix),
			IndexMessages: client.InitIndex(IndexMessages + indexSuffix),
		},
		kodingChannelId: channelId,
	}
}

func (i *IndexSet) Get(name string) (*algoliasearch.Index, error) {
	index, ok := (*i)[name]
	if !ok {
		return nil, fmt.Errorf("Unknown index: '%s'", name)
	}

	return index, nil
}

func (c *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	c.log.Error(err.Error())
	return false
}
