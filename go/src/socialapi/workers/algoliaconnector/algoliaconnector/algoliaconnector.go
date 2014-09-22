package algoliaconnector

import (
	"errors"
	"fmt"
	"socialapi/models"
	"strconv"

	"github.com/algolia/algoliasearch-client-go/algoliasearch"
	"github.com/koding/logging"
	"github.com/streadway/amqp"
)

var (
	ErrAlgoliaObjectIdNotFound = errors.New("{\"message\":\"ObjectID does not exist\"}\n")
	ErrAlgoliaIndexNotExist    = errors.New("{\"message\":\"Index messages.test does not exist\"}\n")
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
	c.log.Error(err)
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
		"objectID": strconv.FormatInt(data.Id, 10),
		"name":     data.Name,
		"purpose":  data.Purpose,
	})
}

func (f *Controller) AccountSaved(data *models.Account) error {
	return f.insert("accounts", map[string]interface{}{
		"objectID": data.OldId,
		"nick":     data.Nick,
	})
}

func (f *Controller) MessageListSaved(listing *models.ChannelMessageList) error {
	message := models.NewChannelMessage()

	if err := message.ById(listing.MessageId); err != nil {
		return err
	}

	objectId := strconv.FormatInt(message.Id, 10)
	channelId := strconv.FormatInt(listing.ChannelId, 10)

	record, err := f.get("messages", objectId)
	if err != nil && err.Error() != ErrAlgoliaObjectIdNotFound.Error() &&
		err.Error() != ErrAlgoliaIndexNotExist.Error() {
		return err
	}

	if record == nil {
		return f.insert("messages", map[string]interface{}{
			"objectID": objectId,
			"body":     message.Body,
			"_tags":    []string{channelId},
		})
	}

	return f.partialUpdate("messages", map[string]interface{}{
		"objectID": objectId,
		"body":     message.Body,
		"_tags":    appendMessageTag(record, channelId),
	})
}

func (f *Controller) MessageListDeleted(listing *models.ChannelMessageList) error {
	index, err := f.indexes.Get("messages")
	if err != nil {
		return err
	}

	objectId := strconv.FormatInt(listing.MessageId, 10)

	record, err := f.get("messages", objectId)
	if err != nil && err.Error() != ErrAlgoliaObjectIdNotFound.Error() &&
		err.Error() != ErrAlgoliaIndexNotExist.Error() {
		return err
	}
	if len(record["_tags"].([]interface{})) == 1 {
		if _, err = index.DeleteObject(objectId); err != nil {
			return err
		}
		return nil
	}
	return f.partialUpdate("messages", map[string]interface{}{
		"objectID": objectId,
		"_tags":    removeMessageTag(record, strconv.FormatInt(listing.ChannelId, 10)),
	})
}

func (f *Controller) MessageUpdated(message *models.ChannelMessage) error {
	return f.partialUpdate("messages", map[string]interface{}{
		"objectID": strconv.FormatInt(message.Id, 10),
		"body":     message.Body,
	})
}
