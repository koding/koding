package webhook

import (
	"errors"
	"net/http"
	"net/url"
	"socialapi/workers/common/response"

	"github.com/koding/logging"
)

var (
	ErrBodyNotSet    = errors.New("body is not set")
	ErrChannelNotSet = errors.New("channel is not set")
	ErrTokenNotSet   = errors.New("token is not set")
)

type WebhookRequest struct {
	Body        string
	ChannelName string
	Token       string
}

type Handler struct {
	log logging.Logger
}

func NewHandler(l logging.Logger) *Handler {
	return &Handler{
		log: l,
	}
}

func (h *Handler) Push(u *url.URL, header http.Header, r *WebhookRequest) (int, http.Header, interface{}, error) {
	val := u.Query().Get("token")
	r.Token = val

	if err := validateRequest(r); err != nil {
		return response.NewBadRequest(err)
	}

	isVerified, err := verifyRequest(r)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if !isVerified {
		return response.NewAccessDenied(errors.New(""))
	}

	return response.NewNotImplemented()
}

func validateRequest(r *WebhookRequest) error {
	if r.Token == "" {
		return ErrTokenNotSet
	}

	if r.Body == "" {
		return ErrBodyNotSet
	}

	if r.ChannelName == "" {
		return ErrChannelNotSet
	}

	return nil

}

var verifyRequest = func(r *WebhookRequest) (bool, error) {
	return false, nil
}
