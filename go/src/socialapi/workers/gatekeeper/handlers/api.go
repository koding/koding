package handlers

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/url"
	"socialapi/config"
	"socialapi/request"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/response"
	"socialapi/workers/gatekeeper/models"
	"socialapi/workers/helper"
	"sync"

	"github.com/koding/logging"
)

var (
	ErrInvalidRequest = errors.New("invalid request")
	pub               *models.Pubnub
)

type Handler struct {
	Realtime []models.Realtime
	logger   logging.Logger
}

func NewHandler(adapters ...models.Realtime) *Handler {

	handler := &Handler{
		Realtime: make([]models.Realtime, 0),
		logger:   helper.MustGetLogger(),
	}

	handler.Realtime = append(handler.Realtime, adapters...)

	return handler
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

func (h *Handler) Push(u *url.URL, _ http.Header, pm *models.PushMessage) (int, http.Header, interface{}, error) {
	id, err := request.GetId(u)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if ok := isRequestValid(id, pm); !ok {
		return response.NewBadRequest(nil)
	}

	// Fetch related channel first
	cr := new(models.ChannelRequest)
	cr.Id = id
	channelResponse, err := fetchChannelById(cr)
	if err != nil {
		return response.NewBadRequest(err)
	}

	pm.Channel = channelResponse
	pm.ChannelId = id
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

	return response.NewOK(pm)
}

func (h *Handler) UpdateInstance(u *url.URL, _ http.Header, um *models.UpdateInstanceMessage) (int, http.Header, interface{}, error) {
	token := u.Query().Get("token")
	if token == "" {
		return response.NewBadRequest(fmt.Errorf("Token is not set"))
	}
	um.Token = token

	var wg sync.WaitGroup
	for _, adapter := range h.Realtime {
		wg.Add(1)
		go func(r models.Realtime) {
			r.UpdateInstance(um)
			wg.Done()
		}(adapter)
	}

	wg.Wait()

	return response.NewOK(um)
}

func (h *Handler) NotifyUser(u *url.URL, _ http.Header, nm *models.NotificationMessage) (int, http.Header, interface{}, error) {
	nickname := u.Query().Get("nickname")
	if nickname == "" {
		return response.NewBadRequest(fmt.Errorf("Nickname is not set"))
	}
	nm.Nickname = nickname
	nm.EventName = "message"

	var wg sync.WaitGroup
	for _, adapter := range h.Realtime {
		wg.Add(1)
		go func(r models.Realtime) {
			r.NotifyUser(nm)
			wg.Done()
		}(adapter)
	}

	wg.Wait()

	return response.NewOK(nm)
}

func isRequestValid(id int64, req *models.PushMessage) bool {
	return id != 0 && req.EventName != ""
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
