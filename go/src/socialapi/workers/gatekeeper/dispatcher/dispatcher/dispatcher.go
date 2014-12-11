package dispatcher

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"socialapi/config"
	"socialapi/workers/common/handler"
	"socialapi/workers/gatekeeper/models"
	"socialapi/workers/helper"
	"sync"

	"github.com/koding/logging"
	"github.com/koding/rabbitmq"
	"github.com/streadway/amqp"
)

type Controller struct {
	Realtime []models.Realtime
	logger   logging.Logger
	rmqConn  *amqp.Connection
}

func NewController(rmqConn *rabbitmq.RabbitMQ, adapters ...models.Realtime) (*Controller, error) {

	rmqConn, err := rmqConn.Connect("NewGatekeeperController")
	if err != nil {
		return nil, err
	}

	handler := &Controller{
		Realtime: make([]models.Realtime, 0),
		logger:   helper.MustGetLogger(),
		rmqConn:  rmqConn.Conn(),
	}

	handler.Realtime = append(handler.Realtime, adapters...)

	return handler, nil
}

// DefaultErrHandler controls the errors, return false if an error occurred
func (c *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	c.logger.Error("an error occurred deleting gatekeeper event: %s", err)
	delivery.Ack(false)
	return false
}

// UpdateChannel sends channel update events
func (c *Controller) UpdateChannel(pm *models.PushMessage) error {
	if pm.ChannelId == 0 || pm.EventName == "" {
		c.logger.Error("Invalid request")
		return nil
	}

	cr := new(models.ChannelRequest)
	cr.Id = pm.ChannelId
	channelResponse, err := fetchChannelById(cr)
	if err != nil {
		return err
	}

	pm.Channel = channelResponse
	pm.Token = channelResponse.Token

	// TODO add timeout

	var wg sync.WaitGroup
	for _, adapter := range c.Realtime {
		wg.Add(1)
		go func(r models.Realtime) {
			r.Push(pm)
			wg.Done()
		}(adapter)
	}

	wg.Wait()

	return nil
}

// UpdateMessage sends message update events
func (c *Controller) UpdateMessage(um *models.UpdateInstanceMessage) error {
	if um.Token == "" {
		c.logger.Error("Token is not set")
		return nil
	}

	// TODO add timeout

	var wg sync.WaitGroup
	for _, adapter := range c.Realtime {
		wg.Add(1)
		go func(r models.Realtime) {
			r.UpdateInstance(um)
			wg.Done()
		}(adapter)
	}

	wg.Wait()

	return nil
}

// NotifyUser sends user notifications to related channel
func (c *Controller) NotifyUser(nm *models.NotificationMessage) error {
	if nm.Nickname == "" {
		c.logger.Error("Nickname is not set")
		return nil
	}
	nm.EventName = "message"

	// TODO add timeout

	var wg sync.WaitGroup
	for _, adapter := range c.Realtime {
		wg.Add(1)
		go func(r models.Realtime) {
			r.NotifyUser(nm)
			wg.Done()
		}(adapter)
	}

	wg.Wait()

	return nil
}

// TODO change this and send it from realtime worker. No need to fetch it again
func fetchChannelById(cr *models.ChannelRequest) (*models.ChannelResponse, error) {
	request := &handler.Request{
		Type:     handler.GetRequest,
		Endpoint: fmt.Sprintf("%s/channel/%d/fetch", config.MustGet().ProxyURL, cr.Id),
	}

	resp, err := handler.MakeRequest(request)
	if err != nil {
		return nil, err
	}

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf(resp.Status)
	}

	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	channelResponse := new(models.ChannelResponse)
	err = json.Unmarshal(body, channelResponse)
	if err != nil {
		return nil, err
	}

	return channelResponse, nil
}
