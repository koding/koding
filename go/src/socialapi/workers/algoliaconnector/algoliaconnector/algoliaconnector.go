package algoliaconnector

import (
	"fmt"
	"socialapi/models"
	"strconv"

	"github.com/algolia/algoliasearch-client-go/algoliasearch"
	"github.com/koding/bongo"
	"github.com/koding/logging"
	"github.com/streadway/amqp"
)

const (
	ErrAlgoliaObjectIdNotFound = "{\"message\":\"ObjectID does not exist\"}\n" // are you kidding me?
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
	fmt.Println(err)
	return false
}

func New(log logging.Logger, client *algoliasearch.Client, indexSuffix string) *Controller {
	return &Controller{
		log:    log,
		client: client,
		indexes: &IndexSet{
			"topics":   client.InitIndex("topics" + indexSuffix),
			"accounts": client.InitIndex("accounts" + indexSuffix),
			"messages": client.InitIndex("messages" + indexSuffix),
		},
	}
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

func (f *Controller) MessageSaved(listing *models.ChannelMessageList) error {
	message := models.NewChannelMessage()

	err := message.One(&bongo.Query{
		Selector: map[string]interface{}{"id": listing.MessageId}})

	if err != nil {
		return err
	}

	objectId := strconv.FormatInt(message.Id, 10)
	channelId := strconv.FormatInt(listing.ChannelId, 10)

	record, err := f.get("messages", objectId)
	if err != nil && err.Error() != ErrAlgoliaObjectIdNotFound {
		return err
	}

	if record == nil {
		return f.insert("messages", map[string]interface{}{
			"body":     message.Body,
			"objectID": objectId,
			"_tags":    []string{channelId},
		})
	}

	return f.partialUpdate("messages", map[string]interface{}{
		"body":     message.Body,
		"objectID": objectId,
		"_tags":    appendMessageTag(record, channelId),
	})
}

func (f *Controller) MessageDeleted(listing *models.ChannelMessageList) error {
	index, err := f.indexes.Get("messages")
	if err != nil {
		return err
	}
	if _, err = index.DeleteObject(strconv.FormatInt(listing.MessageId, 10)); err != nil {
		return err
	}
	return nil
}

func (f *Controller) MessageUpdated(message *models.ChannelMessage) error {
	return f.partialUpdate("messages", map[string]interface{}{
		"objectID": strconv.FormatInt(message.Id, 10),
		"body":     message.Body,
	})
}
