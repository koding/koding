package api

import (
	"net/http"
	"net/url"
	"socialapi/config"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/common/response"
	"socialapi/workers/integration/webhook"
	"strconv"
	"strings"

	"github.com/koding/logging"
	"github.com/koding/redis"
	"github.com/nu7hatch/gouuid"
)

const RevProxyPath = "/api/integration"

type Handler struct {
	log   logging.Logger
	bot   *webhook.Bot
	redis *redis.RedisSession
}

func NewHandler(conf *config.Config, redis *redis.RedisSession, l logging.Logger) (*Handler, error) {
	bot, err := webhook.NewBot()
	if err != nil {
		return nil, err
	}

	return &Handler{
		log:   l,
		bot:   bot,
		redis: redis,
	}, nil
}

func (h *Handler) Push(u *url.URL, header http.Header, r *PushRequest) (int, http.Header, interface{}, error) {
	val := u.Query().Get("token")
	r.Token = val

	if err := r.validate(); err != nil {
		return response.NewInvalidRequest(err)
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

func (h *Handler) List(u *url.URL, header http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	i := webhook.NewIntegration()
	q := &request.Query{
		Exclude: map[string]interface{}{
			"isPrivate": true,
		},
	}

	ints, err := i.List(q)
	if err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(response.NewSuccessResponse(ints))
}

func (h *Handler) RegenerateToken(u *url.URL, header http.Header, i *webhook.ChannelIntegration, ctx *models.Context) (int, http.Header, interface{}, error) {
	ci := webhook.NewChannelIntegration()
	if err := ci.ById(i.Id); err != nil {
		return response.NewBadRequest(err)
	}

	if i.GroupName != ctx.GroupName {
		return response.NewBadRequest(ErrInvalidGroup)
	}

	if err := ci.RegenerateToken(); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(response.NewSuccessResponse(ci))
}

func (h *Handler) CreateChannelIntegration(u *url.URL, header http.Header, i *webhook.ChannelIntegration, ctx *models.Context) (int, http.Header, interface{}, error) {
	if ok := ctx.IsLoggedIn(); !ok {
		return response.NewInvalidRequest(models.ErrNotLoggedIn)
	}

	i.CreatorId = ctx.Client.Account.Id
	i.GroupName = ctx.GroupName
	if err := i.Validate(); err != nil {
		return response.NewInvalidRequest(err)
	}

	if err := h.isChannelValid(i.ChannelId, ctx.Client.Account.Id); err != nil {
		return response.NewBadRequest(err)
	}

	if err := i.Create(); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(response.NewSuccessResponse(i))
}

func (h *Handler) UpdateChannelIntegration(u *url.URL, header http.Header, i *webhook.ChannelIntegration, ctx *models.Context) (int, http.Header, interface{}, error) {
	id, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewInvalidRequest(err)
	}

	if ok := ctx.IsLoggedIn(); !ok {
		return response.NewInvalidRequest(models.ErrNotLoggedIn)
	}

	if i.ChannelId == 0 {
		return response.NewInvalidRequest(models.ErrChannelIdIsNotSet)
	}

	if err := h.isChannelValid(i.ChannelId, ctx.Client.Account.Id); err != nil {
		return response.NewBadRequest(err)
	}

	ci := webhook.NewChannelIntegration()
	if err := ci.ById(id); err != nil {
		return response.NewBadRequest(err)
	}

	ci.ChannelId = i.ChannelId
	ci.Settings = i.Settings
	ci.Description = i.Description
	ci.IsDisabled = i.IsDisabled

	if err := ci.Update(); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewDefaultOK()
}

func (h *Handler) isChannelValid(channelId, accountId int64) error {
	c := models.NewChannel()
	if err := c.ById(channelId); err != nil {
		return err
	}

	ok, err := c.CanOpen(accountId)
	if err != nil {
		return err
	}

	if !ok {
		return models.ErrCannotOpenChannel
	}

	return nil
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
