package integration

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"

	"github.com/koding/integration/services"
	"github.com/koding/logging"
)

const (
	proxyUrl = "/api/integration"
)

type Handler struct {
	RootPath string
	log      logging.Logger
	sf       *services.ServiceFactory
}

func NewHandler(l logging.Logger, rootPath string) *Handler {
	return &Handler{
		log:      l,
		sf:       services.NewServiceFactory(),
		RootPath: fmt.Sprintf("%s%s", rootPath, proxyUrl),
	}
}

func (h *Handler) Push(u *url.URL, header http.Header, request services.ServiceInput) (int, http.Header, interface{}, error) {
	token := u.Query().Get("token")
	name := u.Query().Get("name")

	if err := h.validate(name, token); err != nil {
		return NewBadRequest(err)
	}

	_, err := h.prepareRequest(name, token, &request)
	if err == services.ErrServiceNotFound {
		return NewNotFound(services.ErrServiceNotFound)
	}

	if err != nil {
		return NewBadRequest(err)
	}

	return NewOK(nil)
}

func (h *Handler) validate(name, token string) error {
	if token == "" {
		return ErrTokenNotSet
	}

	if name == "" {
		return ErrNameNotSet
	}

	return nil
}

// prepareRequests prepare the push request with given input data. When input data
// contains Username, it fetches the related bot channel id for that user
func (h *Handler) prepareRequest(name, token string, si *services.ServiceInput) (*PushRequest, error) {

	service, err := h.sf.Create(name, si)
	if err != nil {
		return nil, err
	}

	message, err := service.PrepareMessage(si)
	if err != nil {
		return nil, err
	}

	pr := new(PushRequest)
	pr.Body = message

	so := service.Output(si)
	pr.GroupName = so.GroupName

	// when username is given, it is directly sent to user as a KodingBot message
	if so.Username != "" {
		channelId, err := h.fetchBotChannelId(so.Username, token)
		if err != nil {
			return nil, err
		}
		pr.ChannelId = channelId
	}

	return pr, nil
}

// fetchBotChannelId retrieves the user's bot channel id within the given
// group context
func (h *Handler) fetchBotChannelId(username, token string) (int64, error) {

	endpoint := fmt.Sprintf("%s/botchannel/%s/user/%s", h.RootPath, token, username)
	resp, err := http.Get(endpoint)
	if err != nil {
		return 0, err
	}
	defer resp.Body.Close()

	if resp.StatusCode == 200 {
		var r BotChannelResponse
		err = json.NewDecoder(resp.Body).Decode(&r)

		return r.Data.ChannelId, err
	}

	return 0, parseError(resp)
}

func (h *Handler) push(token string, pr *PushRequest) error {

	endpoint := fmt.Sprintf("%s/push/%s", h.RootPath, token)
	reader, err := pr.Buffered()
	if err != nil {
		return err
	}

	resp, err := http.Post(endpoint, "application/json", reader)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return parseError(resp)
	}

	return nil
}
