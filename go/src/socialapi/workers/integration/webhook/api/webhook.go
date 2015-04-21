package api

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/response"
	"socialapi/workers/integration/webhook"
	"socialapi/workers/integration/webhook/services"

	"github.com/koding/logging"
)

var (
	ErrBodyNotSet    = errors.New("body is not set")
	ErrChannelNotSet = errors.New("channel is not set")
	ErrTokenNotSet   = errors.New("token is not set")
	ErrGroupNotSet   = errors.New("group name is not set")
	ErrTokenNotValid = errors.New("token is not valid")
	ErrNameNotSet    = errors.New("name is not set")
	ErrNameNotValid  = errors.New("name is not valid")
)

type Handler struct {
	log logging.Logger
	bot *webhook.Bot
	sf  *services.ServiceFactory
}

func NewHandler(l logging.Logger) (*Handler, error) {
	bot, err := webhook.NewBot()
	if err != nil {
		return nil, err
	}

	return &Handler{
		log: l,
		bot: bot,
		sf:  services.NewServiceFactory(),
	}, nil
}

func (h *Handler) Push(u *url.URL, header http.Header, r *WebhookRequest) (int, http.Header, interface{}, error) {
	val := u.Query().Get("token")
	r.Token = val

	if err := r.validate(); err != nil {
		return response.NewBadRequest(err)
	}

	channelIntegration, err := r.verify()
	if err == webhook.ErrChannelIntegrationNotFound {
		return response.NewAccessDenied(ErrTokenNotValid)
	}

	if err != nil {
		return response.NewBadRequest(err)
	}

	r.Message.ChannelIntegrationId = channelIntegration.Id

	if err := h.bot.SendMessage(r.Message); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(nil)
}

func (h *Handler) Prepare(u *url.URL, header http.Header, r *PrepareRequest) (int, http.Header, interface{}, error) {
	token := u.Query().Get("token")
	r.Token = token
	name := u.Query().Get("name")
	r.Name = name

	if err := r.validate(); err != nil {
		return response.NewBadRequest(err)
	}

	_, err := r.verify()
	if err == webhook.ErrIntegrationNotFound {
		return response.NewNotFound()
	}

	if err != nil {
		return response.NewBadRequest(err)
	}

	service, err := h.sf.Create(name)
	if err != nil {
		return response.NewBadRequest(err)
	}

	errs := service.Validate(r.Data)
	if len(errs) > 0 {
		// TODO we need another bad request method here for showing validation errors
		return response.NewBadRequest(errs[0])
	}

	message := service.PrepareMessage(r.Data)

	endPoint := service.PrepareEndpoint(r.Token)
	pushRequest := make(map[string]string)
	pushRequest["body"] = message

	if r.Username != "" {
		// fetch user bot channel
		// pushRequest["channelId"] = x
	}

	if err := push(endPoint, pushRequest); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(nil)
}

// TODO need to mock the endpoint. up till that time, this push method is
// defined like this
var push = func(endPoint string, pushRequest map[string]string) error {

	// relay the cookie to other endpoint
	request := &handler.Request{
		Type:     "POST",
		Endpoint: endPoint,
		Params:   pushRequest,
	}

	resp, err := handler.MakeRequest(request)
	if err != nil {
		return err
	}

	// Need a better response
	if resp.StatusCode != 200 {
		return fmt.Errorf(resp.Status)
	}

	var cpr models.CheckParticipationResponse
	err = json.NewDecoder(resp.Body).Decode(&cpr)
	resp.Body.Close()
	if err != nil {
		return err
	}

	return nil
}
