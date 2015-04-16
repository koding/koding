package api

import (
	"errors"
	"net/http"
	"net/url"
	"socialapi/workers/common/response"
	"socialapi/workers/integration/webhook"

	"github.com/koding/logging"
)

var (
	ErrBodyNotSet    = errors.New("body is not set")
	ErrChannelNotSet = errors.New("channel is not set")
	ErrTokenNotSet   = errors.New("token is not set")
	ErrGroupNotSet   = errors.New("group name is not set")
	ErrTokenNotValid = errors.New("token is not valid")
)

type WebhookRequest struct {
	*webhook.Message
	GroupName string
	Token     string
}

type Handler struct {
	log logging.Logger
	bot *webhook.Bot
}

func NewHandler(l logging.Logger) (*Handler, error) {
	bot, err := webhook.NewBot()
	if err != nil {
		return nil, err
	}

	return &Handler{
		log: l,
		bot: bot,
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

func (r *WebhookRequest) validate() error {
	if r.Token == "" {
		return ErrTokenNotSet
	}

	if r.Body == "" {
		return ErrBodyNotSet
	}

	// TODO we don't need this ChannelName, it will remain
	// until we add TeamInteraction tables
	if r.ChannelId == 0 {
		return ErrChannelNotSet
	}

	if r.GroupName == "" {
		return ErrGroupNotSet
	}

	return nil
}

func (r *WebhookRequest) verify() (*webhook.ChannelIntegration, error) {
	ti := webhook.NewChannelIntegration()
	err := ti.ByToken(r.Token)
	if err != nil {
		return nil, err
	}

	return ti, nil
}
