package followingfeed

import (
	"encoding/json"
	"fmt"
	"socialapi/models"

	"github.com/koding/logging"
	"github.com/koding/worker"
	"github.com/streadway/amqp"
)

type Action func(*Controller, *models.ChannelMessage) error

type Controller struct {
	routes map[string]Action
	log    logging.Logger
}

func (f *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	if delivery.Redelivered {
		f.log.Error("Redelivered message gave error again, putting to maintenance queue", err)
		delivery.Ack(false)
		return true
	}

	f.log.Error("an error occured putting message back to queue", err)
	delivery.Nack(false, true)
	return false
}

func New(log logging.Logger) *Controller {
	ffc := &Controller{
		log: log,
	}

	routes := map[string]Action{
		"channel_message_created": (*Controller).MessageSaved,
		"channel_message_update":  (*Controller).MessageUpdated,
		"channel_message_deleted": (*Controller).MessageDeleted,
	}

	ffc.routes = routes

	return ffc
}

func (f *Controller) HandleEvent(event string, data []byte) error {
	f.log.Debug("New Event Received %s", event)
	handler, ok := f.routes[event]
	if !ok {
		return worker.HandlerNotFoundErr
	}

	cm, err := mapMessage(data)
	if err != nil {
		return err
	}

	res, err := isEligible(cm)
	if err != nil {
		return err
	}

	if !res {
		return nil
	}

	return handler(f, cm)
}

func (f *Controller) MessageSaved(data *models.ChannelMessage) error {
	a := models.NewAccount()
	a.Id = data.AccountId
	channelIds, err := a.FetchFollowerChannelIds()
	if err != nil {
		return err
	}
	fmt.Println(channelIds)
	return nil
}

func (f *Controller) MessageUpdated(data *models.ChannelMessage) error {
	fmt.Println("update", data.InitialChannelId)

	return nil

}

func (f *Controller) MessageDeleted(data *models.ChannelMessage) error {
	fmt.Println("delete", data.InitialChannelId)

	return nil
}

func mapMessage(data []byte) (*models.ChannelMessage, error) {
	cm := models.NewChannelMessage()
	if err := json.Unmarshal(data, cm); err != nil {
		return nil, err
	}

	return cm, nil
}

func isEligible(cm *models.ChannelMessage) (bool, error) {
	if cm.InitialChannelId == 0 {
		return false, nil
	}

	if cm.TypeConstant != models.ChannelMessage_TYPE_POST {
		return false, nil
	}

	return isChannelEligible(cm)
}

func isChannelEligible(cm *models.ChannelMessage) (bool, error) {
	c, err := fetchChannel(cm.InitialChannelId)
	if err != nil {
		return false, err
	}

	if c.Name != models.Channel_KODING_NAME {
		return false, nil
	}

	return true, nil
}

// todo add caching here
func fetchChannel(channelId int64) (*models.Channel, error) {
	c := models.NewChannel()
	// todo - fetch only name here
	if err := c.ById(channelId); err != nil {
		return nil, err
	}

	return c, nil
}
