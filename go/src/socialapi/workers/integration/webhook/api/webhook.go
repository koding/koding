package api

import (
	"fmt"
	"net/http"
	"net/url"
	"socialapi/config"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/common/response"
	"socialapi/workers/integration/webhook"
	"socialapi/workers/integration/webhook/services"
	"strconv"
	"strings"

	"github.com/koding/logging"
	"github.com/nu7hatch/gouuid"
)

const RevProxyPath = "/api/integration"

type Handler struct {
	log      logging.Logger
	bot      *webhook.Bot
	sf       *services.ServiceFactory
	RootPath string
}

func NewHandler(conf *config.Config, l logging.Logger) (*Handler, error) {
	bot, err := webhook.NewBot()
	if err != nil {
		return nil, err
	}

	rootPath := fmt.Sprintf("%s%s", conf.CustomDomain.Local, RevProxyPath)

	return &Handler{
		log:      l,
		bot:      bot,
		sf:       services.NewServiceFactory(),
		RootPath: rootPath,
	}, nil
}

func (h *Handler) Push(u *url.URL, header http.Header, r *PushRequest) (int, http.Header, interface{}, error) {
	val := u.Query().Get("token")
	r.Token = val

	if err := r.validate(); err != nil {
		return response.NewInvalidRequest(err)
	}

	// a short circuit for testing purposes
	if r.Token == "0bc752e0-03c5-4f29-8776-328e2e88e226" {
		return response.NewOK(response.NewSuccessResponse(nil))
	}

	channelIntegration, err := r.verify()
	if err == webhook.ErrChannelIntegrationNotFound {
		return response.NewAccessDenied(ErrTokenNotValid)
	}

	if err != nil {
		return response.NewBadRequest(err)
	}

	r.Message.ChannelIntegrationId = channelIntegration.Id

	// TODO check for group name match here

	if err := h.bot.SendMessage(&r.Message); err != nil {
		return response.NewBadRequest(err)
	}

	res := response.NewSuccessResponse(nil)

	return response.NewOK(res)
}

func (h *Handler) FetchBotChannel(u *url.URL, header http.Header, _ interface{}, c *models.Context) (int, http.Header, interface{}, error) {
	if !c.IsLoggedIn() {
		return response.NewInvalidRequest(models.ErrNotLoggedIn)
	}

	r := new(BotChannelRequest)

	r.Username = c.Client.Account.Nick
	r.GroupName = c.GroupName
	if err := r.validate(); err != nil {
		return response.NewInvalidRequest(err)
	}

	channel, err := h.fetchBotChannel(r)
	if err != nil {
		return response.NewBadRequest(err)
	}

	cc := models.NewChannelContainer()
	if err := cc.Fetch(channel.Id, &request.Query{AccountId: c.Client.Account.Id}); err != nil {
		return response.NewBadRequest(err)
	}

	if err := cc.PopulateWith(*channel, c.Client.Account.Id); err != nil {
		return response.NewBadRequest(err)
	}
	cc.AddUnreadCount(c.Client.Account.Id)

	cc.ParticipantsPreview = append([]string{h.bot.Account().OldId}, cc.ParticipantsPreview...)

	return response.NewOK(response.NewSuccessResponse(cc))
}

func (h *Handler) FetchGroupBotChannel(u *url.URL, header http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	token := u.Query().Get("token")
	if token == "" {
		return response.NewInvalidRequest(ErrTokenNotSet)
	}

	username := u.Query().Get("username")
	if username == "" {
		return response.NewInvalidRequest(ErrUsernameNotSet)
	}

	// this is just for testing this endpoint
	if username == "floydpepper" && token == "validtoken" {
		resp := map[string]string{
			"channelId": "42",
		}

		return response.NewOK(response.NewSuccessResponse(resp))
	}

	// validate token
	if _, err := uuid.ParseHex(strings.ToLower(token)); err != nil {
		return response.NewInvalidRequest(ErrTokenNotValid)
	}

	ci, err := webhook.Cache.ChannelIntegration.ByToken(token)
	if err != nil {
		if err == webhook.ErrChannelIntegrationNotFound {
			return response.NewInvalidRequest(err)
		}

		return response.NewBadRequest(err)
	}

	br := new(BotChannelRequest)
	br.Username = username
	br.GroupName = ci.GroupName
	c, err := h.fetchBotChannel(br)
	if err != nil {
		return response.NewBadRequest(err)
	}

	resp := map[string]string{
		"channelId": strconv.FormatInt(c.Id, 10),
	}

	return response.NewOK(response.NewSuccessResponse(resp))
}

func (h *Handler) fetchBotChannel(r *BotChannelRequest) (*models.Channel, error) {
	// check account existence
	acc, err := r.verifyAccount()
	if err != nil {
		return nil, err
	}

	// check group existence
	group, err := r.verifyGroup()
	if err != nil {
		return nil, err
	}

	// prevent sending bot messages when the user is not participant
	// of the given group
	canOpen, err := group.CanOpen(acc.Id)
	if err != nil {
		return nil, err
	}

	if !canOpen {
		return nil, ErrAccountIsNotParticipant
	}

	// now we can fetch the bot channel
	return h.bot.FetchBotChannel(acc, group)
}
