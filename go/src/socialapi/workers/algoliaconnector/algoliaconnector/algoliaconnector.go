package algoliaconnector

import (
	"encoding/json"
	"errors"
	"fmt"
	"socialapi/models"
	"socialapi/request"
	"strconv"
	"time"

	"github.com/algolia/algoliasearch-client-go/algoliasearch"
	"github.com/koding/logging"
	"github.com/streadway/amqp"
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

// IsAlgoliaError checks if the given algolia error string and given messages
// are same according their data structure
func IsAlgoliaError(err error, message string) bool {
	if err == nil {
		return false
	}

	v := &algoliaErrorRes{}

	if err := json.Unmarshal([]byte(err.Error()), v); err != nil {
		return false
	}

	if v.Message == message {
		return true
	}

	return false
}

type algoliaErrorRes struct {
	Message string `json:"message"`
	Status  int    `json:"status"`
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
			"topics":   client.InitIndex("topics" + indexSuffix),
			"accounts": client.InitIndex("accounts" + indexSuffix),
			"messages": client.InitIndex("messages" + indexSuffix),
		},
		kodingChannelId: channelId,
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
		"_tags":    []string{f.kodingChannelId},
	})
}

func (f *Controller) MessageListSaved(listing *models.ChannelMessageList) error {
	message := models.NewChannelMessage()

	if err := message.ById(listing.MessageId); err != nil {
		return err
	}

	// no need to index join/leave messages
	if message.TypeConstant != models.ChannelMessage_TYPE_POST &&
		message.TypeConstant != models.ChannelMessage_TYPE_REPLY {
		return nil
	}

	objectId := strconv.FormatInt(message.Id, 10)
	channelId := strconv.FormatInt(listing.ChannelId, 10)

	record, err := f.get("messages", objectId)
	if err != nil &&
		!IsAlgoliaError(err, ErrAlgoliaObjectIdNotFoundMsg) &&
		!IsAlgoliaError(err, ErrAlgoliaIndexNotExistMsg) {
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
		"_tags":    appendTag(record, channelId),
	})
}

func (f *Controller) MessageListDeleted(listing *models.ChannelMessageList) error {
	index, err := f.indexes.Get("messages")
	if err != nil {
		return err
	}

	objectId := strconv.FormatInt(listing.MessageId, 10)

	record, err := f.get("messages", objectId)
	if err != nil &&
		!IsAlgoliaError(err, ErrAlgoliaObjectIdNotFoundMsg) &&
		!IsAlgoliaError(err, ErrAlgoliaIndexNotExistMsg) {
		return err
	}

	if tags, ok := record["_tags"]; ok {
		if t, ok := tags.([]interface{}); ok && len(t) == 1 {
			if _, err = index.DeleteObject(objectId); err != nil {
				return err
			}
			return nil
		}
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

const accountIndexName = "accounts"

// ParticipantDeleted operates with the participant deleted events, removes
// deleted tag from algolia document
func (f *Controller) ParticipantDeleted(p *models.ChannelParticipant) error {
	// if status of the participant is left, then just notify the current user
	if p.StatusConstant != models.ChannelParticipant_STATUS_LEFT {
		f.log.Debug("Ignoring participant (%d) update channel event(status not left)", p.AccountId)
		return nil
	}

	err := f.handleParticipantOperation(p, removeTag)
	if err != nil {
		f.log.Error("err while handling participant deleted event: %s", err.Error())
	}

	return err
}

// ParticipantCreated operates with the participant createad event, adds new
// tag to the algolia document
func (f *Controller) ParticipantCreated(p *models.ChannelParticipant) error {
	err := f.handleParticipantOperation(p, appendTag)
	if err != nil {
		f.log.Error("err while handling participant created event: %s", err.Error())
	}

	return err
}

func (f *Controller) handleParticipantOperation(p *models.ChannelParticipant, tagOperator func(record map[string]interface{}, channelId string) []interface{}) error {
	if p.ChannelId == 0 {
		return nil
	}

	if p.AccountId == 0 {
		return nil
	}

	a := models.NewAccount()
	if err := a.ById(p.AccountId); err != nil {
		f.log.Error("err while fetching account: %s", err.Error())
		return nil
	}

	if a.Id == 0 {
		f.log.Critical("account found but id is 0 %+v", a)
		return nil
	}

	record, err := f.get(accountIndexName, a.OldId)
	if err != nil &&
		!IsAlgoliaError(err, ErrAlgoliaObjectIdNotFoundMsg) &&
		!IsAlgoliaError(err, ErrAlgoliaIndexNotExistMsg) {
		return err
	}

	if record == nil {
		// first create the account
		if err := f.AccountSaved(a); err != nil {
			return err
		}

		// make sure account is there, before start processing it
		err := makeSureAccount(f, a.OldId, func(record map[string]interface{}, err error) bool {
			if err != nil {
				return false
			}

			if record == nil {
				return false
			}

			return true
		})
		if err != nil {
			return err
		}
	}

	record, err = f.get(accountIndexName, a.OldId)
	if err != nil {
		return err
	}

	channelId := strconv.FormatInt(p.ChannelId, 10)

	return f.partialUpdate(accountIndexName, map[string]interface{}{
		"objectID": a.OldId,
		"_tags":    tagOperator(record, channelId),
	})
}

var errDeadline = errors.New("deadline reached")

// makeSureAccount checks if the given id's get request returns the desired
// err, it will re-try every 100ms until deadline of 2 minutes reached. Algolia
// doesnt index the records right away, so try to go to a desired state
func makeSureAccount(handler *Controller, id string, f func(map[string]interface{}, error) bool) error {
	deadLine := time.After(time.Minute * 2)
	tick := time.Tick(time.Millisecond * 100)
	for {
		select {
		case <-tick:
			record, err := handler.get("accounts", id)
			if f(record, err) {
				return nil
			}
		case <-deadLine:
			return errDeadline
		}
	}
}
