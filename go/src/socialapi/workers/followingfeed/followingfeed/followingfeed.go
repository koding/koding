package followingfeed

import (
	"socialapi/models"
	"socialapi/request"

	"github.com/koding/logging"
	"github.com/streadway/amqp"
)

type Action func(*Controller, *models.ChannelMessage) error

type Controller struct {
	log logging.Logger
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
	return &Controller{
		log: log,
	}
}

func (f *Controller) MessageSaved(data *models.ChannelMessage) error {
	if res, _ := isEligible(data); !res {
		return nil
	}

	a := models.NewAccount()
	a.Id = data.AccountId
	_, err := a.FetchFollowerChannelIds(&request.Query{ShowExempt: true})
	if err != nil {
		return err
	}

	return nil
}

func (f *Controller) MessageUpdated(data *models.ChannelMessage) error {
	if res, _ := isEligible(data); !res {
		return nil
	}

	return nil

}

func (f *Controller) MessageDeleted(data *models.ChannelMessage) error {
	if res, _ := isEligible(data); !res {
		return nil
	}

	return nil
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
