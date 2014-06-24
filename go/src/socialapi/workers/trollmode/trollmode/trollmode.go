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

func (t *Controller) markMessagesAsTroll(cm *models.ChannelMessage, messageIds []int64) error {
	if len(messageIds) == 0 {
		return nil
	}

	for _, messageId := range messageIds {
		err := cm.UpdateMulti(
			map[string]interface{}{"id": messageId},
			map[string]interface{}{"meta_bits": 1},
		)
		if err != nil {
			return err
		}
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
