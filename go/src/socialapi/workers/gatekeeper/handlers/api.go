package handlers

import (
	"encoding/json"
	"errors"
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

var (
	ErrInvalidRequest = errors.New("invalid request")
	pub               *models.Pubnub
)

type Handler struct {
	Realtime []models.Realtime
	logger   logging.Logger
	rmqConn  *amqp.Connection
}

func NewHandler(rmqConn *rabbitmq.RabbitMQ, adapters ...models.Realtime) (*Handler, error) {
	// connnects to RabbitMQ
	rmqConn, err := rmqConn.Connect("NewGatekeeperController")
	if err != nil {
		return nil, err
	}

	handler := &Handler{
		Realtime: make([]models.Realtime, 0),
		logger:   helper.MustGetLogger(),
		rmqConn:  rmqConn.Conn(),
	}

	handler.Realtime = append(handler.Realtime, adapters...)

	return handler, nil
}

// DefaultErrHandler controls the errors, return false if an error occurred
func (r *Handler) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	r.logger.Error("an error occurred deleting gatekeeper event: %s", err)
	delivery.Ack(false)
	return false
}

// func (h *Handler) Authenticate(u *url.URL, header http.Header, req *models.ChannelRequest) (int, http.Header, interface{}, error) {
// 	if err := checkParticipation(u, header, req); err != nil {
// 		return response.NewAccessDenied(err)
// 	}

// 	// user has access permission, now authenticate user to channel via pubnub
// 	if err := h.Realtime.Authenticate(req); err != nil {
// 		return response.NewBadRequest(err)
// 	}

// 	return response.NewOK(req)
// }

func (h *Handler) UpdateChannel(pm *models.PushMessage) error {
	if ok := isRequestValid(pm); !ok {
		h.logger.Error("Invalid request")
		return nil
	}

	// Fetch related channel first
	cr := new(models.ChannelRequest)
	cr.Id = pm.ChannelId
	channelResponse, err := fetchChannelById(cr)
	if err != nil {
		return err
	}

	pm.Channel = channelResponse
	pm.Token = channelResponse.Token

	var wg sync.WaitGroup
	for _, adapter := range h.Realtime {
		wg.Add(1)
		go func(r models.Realtime) {
			r.Push(pm)
			wg.Done()
		}(adapter)
	}

	wg.Wait()

	return nil
}

func isRequestValid(req *models.PushMessage) bool {
	return req.ChannelId != 0 && req.EventName != ""
}

// func checkParticipation(u *url.URL, header http.Header, cr *models.ChannelRequest) error {

// 	cookie := header.Get("Cookie")
// 	request := &models.Request{
// 		Method:   "GET",
// 		Endpoint: "/channel/checkparticipation",
// 		Params: map[string]string{
// 			"name":  cr.Name,
// 			"group": cr.Group,
// 			"type":  cr.Type,
// 		},
// 		Cookie: cookie,
// 	}

// 	resp, err := MakeRequest(request)
// 	if err != nil {
// 		return err
// 	}

// 	// Need a better response
// 	if resp.StatusCode != 200 {
// 		return fmt.Errorf(resp.Status)
// 	}

// 	return nil
// }

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

func authenticate(req *models.ChannelRequest) error {

	return fmt.Errorf("not implemented")
}
