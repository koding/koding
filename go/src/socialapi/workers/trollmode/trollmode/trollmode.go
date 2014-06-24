package trollmode

import (
	"encoding/json"
	"errors"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/common/manager"

	"github.com/koding/logging"
	"github.com/koding/worker"
	"github.com/streadway/amqp"
)

const (
	MarkedAsTroll   = "api.account_marked_as_troll"
	UnMarkedAsTroll = "api.account_unmarked_as_troll"
)

func NewManager(controller worker.ErrHandler) *manager.Manager {
	m := manager.New()
	m.Controller(controller)
	m.HandleFunc(MarkedAsTroll, (*Controller).MarkedAsTroll)
	m.HandleFunc(UnMarkedAsTroll, (*Controller).UnMarkedAsTroll)
	return m
}

type Controller struct {
	log logging.Logger
}

func NewController(log logging.Logger) *Controller {
	return &Controller{
		log: log,
	}
}

func (t *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	if delivery.Redelivered {
		t.log.Error("Redelivered message gave error again, putting to maintenance queue", err)
		delivery.Ack(false)
		return true
	}

	t.log.Error("an error occured putting message back to queue", err)
	delivery.Nack(false, true)
	return false
}

func (t *Controller) MarkedAsTroll(account *models.Account) error {
	if err := t.validateRequest(account); err != nil {
		t.log.Error("Validation failed for marking troll; skipping, err: %s ", err.Error())
		return nil
	}

	return t.processsAllMessagesAsTroll(account.Id)
}

func (t *Controller) validateRequest(account *models.Account) error {
	if account == nil {
		return errors.New("account is not set (nil)")
	}

	if account.Id == 0 {
		return errors.New("account id is not set")
	}

	return nil
}

func (t *Controller) processsAllMessagesAsTroll(accountId int64) error {
	query := &request.Query{
		Type:      models.ChannelMessage_TYPE_POST,
		AccountId: accountId,
func (c *Controller) markChannels(account *models.Account) error {
	var processCount = 100
	var skip = 0
	var erroredChannels []models.Channel

	ch := models.NewChannel()
	q := &bongo.Query{
		Selector: map[string]interface{}{
			"creator_id":    account.Id,
			"type_constant": models.Channel_TYPE_PRIVATE_MESSAGE,
			// 0 means safe
			"meta_bits": models.Safe,
		},
		Pagination: *bongo.NewPagination(processCount, 0),
	}

	for {
		// set skip everytime here
		q.Pagination.Skip = skip
		var channels []models.Channel
		if err := ch.Some(&channels, q); err != nil {
			return err
		}

		// we processed all messages
		if len(channels) <= 0 {
			break
		}

		for i, channel := range channels {
			channel.MetaBits.MarkTroll()
			if err := channel.Update(); err != nil {
				c.log.Error(err.Error())
				erroredChannels = append(erroredChannels, channels[i])
			}
		}

		// increment skip count
		skip = processCount + skip
	}

	if len(erroredChannels) != 0 {
		err := errors.New(fmt.Sprintf("some errors: %v", erroredChannels))
		c.log.Error(err.Error())
		return err
	}

	return nil
}

func (c *Controller) markParticipations(account *models.Account) error {
	var processCount = 100
	var skip = 0
	var erroredChannelParticipants []models.ChannelParticipant

	cp := models.NewChannelParticipant()
	q := &bongo.Query{
		Selector: map[string]interface{}{
			"account_id": account.Id,
			// 0 means safe
			"meta_bits": models.Safe,
		},
		Pagination: *bongo.NewPagination(processCount, 0),
	}

	for {

		// set skip everytime here
		q.Pagination.Skip = skip
		var channelParticipants []models.ChannelParticipant
		if err := cp.Some(&channelParticipants, q); err != nil {
			return err
		}

		// we processed all channel participants
		if len(channelParticipants) <= 0 {
			break
		}

		for i, channelParticipant := range channelParticipants {
			channelParticipant.MetaBits.MarkTroll()
			if err := channelParticipant.Update(); err != nil {
				c.log.Error(err.Error())
				erroredChannelParticipants = append(erroredChannelParticipants, channelParticipants[i])
			}
		}

		// increment skip count
		skip = processCount + skip
	}

	if len(erroredChannelParticipants) != 0 {
		err := errors.New(fmt.Sprintf("some errors: %v", erroredChannelParticipants))
		c.log.Error(err.Error())
		return err
	}

	return nil
}
	cm := models.NewChannelMessage()
	totalMessageCount, err := cm.FetchTotalMessageCount(query)
	if err != nil {
		return err
	}

	// no need to continue if user doesnt have any channel message
	if totalMessageCount == 0 {
		t.log.Notice("Account %d doesnt have any post messages", accountId)
		return nil
	}

	processCount := 100

	for i := 0; totalMessageCount <= 0; {
		query.Limit = processCount
		query.Skip = processCount * i

		messageIds, err := cm.FetchMessageIds(query)
		if err != nil {
			return err
		}

		if len(messageIds) == 0 {
			return nil
		}

		err = t.markMessagesAsTroll(cm, messageIds)
		if err != nil {
			return err
		}

		totalMessageCount = totalMessageCount - processCount
		i++
	}

	return nil

}

func (c *Controller) markInteractions(account *models.Account) error {
	var processCount = 100
	var skip = 0
	var erroredInteractions []models.Interaction

	i := models.NewInteraction()
	q := &bongo.Query{
		Selector: map[string]interface{}{
			"account_id": account.Id,
			// 0 means safe
			"meta_bits": models.Safe,
		},
		Pagination: *bongo.NewPagination(processCount, 0),
	}

	for {
		// set skip everytime here
		q.Pagination.Skip = skip
		var interactions []models.Interaction
		if err := i.Some(&interactions, q); err != nil {
			return err
		}

		// we processed all channel participants
		if len(interactions) <= 0 {
			break
		}

		for i, interaction := range interactions {
			interaction.MetaBits.MarkTroll()
			if err := interaction.Update(); err != nil {
				c.log.Error(err.Error())
				erroredInteractions = append(erroredInteractions, interactions[i])
			}
		}

		// increment skip count
		skip = processCount + skip
	}

	if len(erroredInteractions) != 0 {
		err := errors.New(fmt.Sprintf("some errors: %v", erroredInteractions))
		c.log.Error(err.Error())
		return err
	}

	return nil
}

func (t *Controller) UnMarkedAsTroll(account *models.Account) error {
	t.log.Critical("un marked as troll ehehe %v", account)
	return nil
}

func mapMessage(data []byte) (*models.Account, error) {
	cm := models.NewAccount()
	if err := json.Unmarshal(data, cm); err != nil {
		return nil, err
	}

	return cm, nil
}
