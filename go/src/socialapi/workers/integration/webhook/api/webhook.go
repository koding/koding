package api

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"net/http"
	"net/url"
	"socialapi/config"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/common/response"
	"socialapi/workers/integration/webhook"
	"strconv"
	"strings"

	"github.com/jinzhu/gorm"
	"github.com/koding/integration/helpers"
	"github.com/koding/logging"
	"github.com/koding/redis"
	uuid "github.com/satori/go.uuid"
)

type Handler struct {
	log      logging.Logger
	bot      *webhook.Bot
	redis    *redis.RedisSession
	rootPath string
	conf     *config.Config
}

func NewHandler(conf *config.Config, redis *redis.RedisSession, l logging.Logger) (*Handler, error) {
	bot, err := webhook.NewBot()
	if err != nil {
		return nil, err
	}

	return &Handler{
		log:      l,
		bot:      bot,
		redis:    redis,
		rootPath: conf.CustomDomain.Local,
		conf:     conf,
	}, nil
}

// Push fetches the channel integration with given token, and pushes message to
// channel defined in related channel integration
func (h *Handler) Push(u *url.URL, header http.Header, r *PushRequest) (int, http.Header, interface{}, error) {
	val := u.Query().Get("token")
	r.Token = val

	// validate against empty message body or token
	if err := r.validate(); err != nil {
		return response.NewInvalidRequest(err)
	}

	channelIntegration, err := r.fetchChannelIntegration()
	if err == webhook.ErrChannelIntegrationNotFound {
		return response.NewAccessDenied(ErrTokenNotValid)
	}

	if err != nil {
		return response.NewBadRequest(err)
	}

	if channelIntegration.IsDisabled {
		// there is 10 sec posibility that integration would be disabled but we
		// can still process the incoming messages
		return response.NewOK(response.NewSuccessResponse(nil))
	}

	r.Message.ChannelIntegrationId = channelIntegration.Id
	r.Message.ChannelId = channelIntegration.ChannelId

	// we can save the message to db now
	if err := h.bot.SaveMessage(&r.Message); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(response.NewSuccessResponse(nil))
}

func (h *Handler) GetSettings(u *url.URL, header http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	token := u.Query().Get("token")
	if token == "" {
		return response.NewInvalidRequest(ErrTokenNotSet)
	}

	// validate token
	if _, err := uuid.FromString(strings.ToLower(token)); err != nil {
		return response.NewInvalidRequest(ErrTokenNotValid)
	}

	ci, err := webhook.Cache.ChannelIntegration.ByToken(token)
	if err != nil {
		if err == webhook.ErrChannelIntegrationNotFound {
			return response.NewInvalidRequest(err)
		}

		return response.NewBadRequest(err)
	}

	return response.NewOK(response.NewSuccessResponse(ci))
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
	if _, err := uuid.FromString(strings.ToLower(token)); err != nil {
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

// List fetches the integrations from db
func (h *Handler) List(u *url.URL, header http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	i := webhook.NewIntegration()
	q := &request.Query{
		Exclude: map[string]interface{}{
			"isPublished": false,
		},
	}

	ints, err := i.List(q)
	if err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(response.NewSuccessResponse(ints))
}

// Get returns one integration specified by the query parameter name
func (h *Handler) Get(u *url.URL, header http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	name := u.Query().Get("name")
	i := webhook.NewIntegration()
	err := i.ByName(name)
	if err == webhook.ErrIntegrationNotFound {
		return response.NewNotFound()
	}

	if err != nil {
		return response.NewBadRequest(err)
	}

	if !i.IsPublished {
		return response.NewNotFound()
	}

	return response.NewOK(response.NewSuccessResponse(i))
}

// RegenerateToken generates a new token for the given ChannelIntegration
func (h *Handler) RegenerateToken(u *url.URL, header http.Header, i *webhook.ChannelIntegration, ctx *models.Context) (int, http.Header, interface{}, error) {
	if !ctx.IsLoggedIn() {
		return response.NewInvalidRequest(models.ErrNotLoggedIn)
	}

	ci := webhook.NewChannelIntegration()
	if err := ci.ById(i.Id); err != nil {
		return response.NewBadRequest(err)
	}

	// user should be in the same group to be able to modify the integration
	if ci.GroupName != ctx.GroupName {
		return response.NewBadRequest(ErrInvalidGroup)
	}

	if err := ci.RegenerateToken(); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(response.NewSuccessResponse(ci))
}

// CreateChannelIntegration creates the channel integration with creatorId,
// groupName, channelId, and integrationId. It generates a random token and
// saves id. Optional parameters are assigned via UpdateChannelIntegration
// handler.
func (h *Handler) CreateChannelIntegration(u *url.URL, header http.Header, i *webhook.ChannelIntegration, ctx *models.Context) (int, http.Header, interface{}, error) {
	if !ctx.IsLoggedIn() {
		return response.NewInvalidRequest(models.ErrNotLoggedIn)
	}

	i.CreatorId = ctx.Client.Account.Id
	i.GroupName = ctx.GroupName
	if err := i.Validate(); err != nil {
		return response.NewInvalidRequest(err)
	}

	// check if the given channel is exist and can be opened by the requester
	if err := h.isChannelValid(i.ChannelId, ctx.Client.Account.Id); err != nil {
		return response.NewBadRequest(err)
	}

	if err := i.Create(); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(response.NewSuccessResponse(i))
}

// GetChannelIntegration returns the channel integration with given id. Also it
// fetches the external data if it is needed
func (h *Handler) GetChannelIntegration(u *url.URL, header http.Header, _ interface{}, ctx *models.Context) (int, http.Header, interface{}, error) {
	id, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewInvalidRequest(err)
	}

	if !ctx.IsLoggedIn() {
		return response.NewInvalidRequest(models.ErrNotLoggedIn)
	}

	ci := webhook.NewChannelIntegration()
	if err := ci.ById(id); err != nil {
		return response.NewBadRequest(err)
	}

	if ci.GroupName != ctx.GroupName {
		return response.NewBadRequest(ErrInvalidGroup)
	}

	cic := webhook.NewChannelIntegrationContainer(ci)
	cic.ChannelIntegration = ci
	if err := cic.Populate(); err != nil {
		return response.NewBadRequest(err)
	}

	i, err := webhook.Cache.Integration.ById(ci.IntegrationId)
	if err != nil {
		return response.NewBadRequest(err)
	}
	cic.Integration = i

	return response.NewOK(response.NewSuccessResponse(cic))
}

// UpdateChannelIntegration updates the channel integration with ChannelId,
// Settings, Description, IsDisabled parameters
func (h *Handler) UpdateChannelIntegration(u *url.URL, header http.Header, i *webhook.ChannelIntegration, ctx *models.Context) (int, http.Header, interface{}, error) {
	id, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewInvalidRequest(err)
	}

	if !ctx.IsLoggedIn() {
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

	oldSettings := ci.Settings

	if i.ChannelId != 0 {
		ci.ChannelId = i.ChannelId
	}

	if i.Settings != nil {
		ci.Settings = i.Settings
	}

	if i.Description != "" {
		ci.Description = i.Description
	}

	ci.IsDisabled = i.IsDisabled

	// send updated integration parameters to middleware Configure endpoint
	if err := h.Configure(ci, ctx, oldSettings); err != nil {
		return response.NewBadRequest(err)
	}

	// finally update the db
	if err := ci.Update(); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewDefaultOK()
}

// DeleteChannelIntegration deletes the integration with the given id.
func (h *Handler) DeleteChannelIntegration(u *url.URL, header http.Header, i *webhook.ChannelIntegration, ctx *models.Context) (int, http.Header, interface{}, error) {
	id, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewInvalidRequest(err)
	}

	if !ctx.IsLoggedIn() {
		return response.NewInvalidRequest(models.ErrNotLoggedIn)
	}

	ci := webhook.NewChannelIntegration()
	if err := ci.ById(id); err != nil {
		return response.NewBadRequest(err)
	}

	groupChannel, err := models.Cache.Channel.ByGroupName(ci.GroupName)
	if err != nil {
		return response.NewBadRequest(err)
	}

	isParticipant, err := groupChannel.IsParticipant(ctx.Client.Account.Id)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if !isParticipant {
		return response.NewBadRequest(models.ErrParticipantNotFound)
	}

	if err := ci.Delete(); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewDefaultOK()
}

// Configure configures a webhook when integration settings authorizable field is
// true. It sends current and updated settings to middleware service, and all CRUD
// operation decisions are left to middleware, depending on updated fields.
//
// Besides, if middleware configure returns a response, we update settings map
// with returned key/value pairs.
func (h *Handler) Configure(ci *webhook.ChannelIntegration, ctx *models.Context, oldSettings gorm.Hstore) error {
	i, err := webhook.Cache.Integration.ById(ci.IntegrationId)
	if err != nil {
		return err
	}

	var authorizable bool
	err = i.GetSettings("authorizable", &authorizable)
	if err == webhook.ErrSettingNotFound {
		return nil
	}

	if err != nil {
		return err
	}

	// we can early return here
	if !authorizable {
		return nil
	}

	endpoint := fmt.Sprintf("%s/api/webhook/configure/%s", h.rootPath, i.Name)
	creq := new(helpers.ConfigureRequest)

	nick := ctx.Client.Account.Nick
	user, err := modelhelper.GetUser(nick)
	if err != nil {
		return err
	}

	// get current account's foreign auth credentials from db
	creq.UserToken = user.ForeignAuth.GetAccessToken(i.Name)
	creq.ServiceToken = ci.Token
	creq.Settings = helpers.Settings(ci.Settings)
	creq.OldSettings = helpers.Settings(oldSettings)

	body, err := json.Marshal(creq)
	if err != nil {
		return err
	}

	reader := bytes.NewReader(body)

	resp, err := http.Post(endpoint, "application/json", reader)
	defer func() {
		if resp != nil {
			resp.Body.Close()
		}
	}()

	if err != nil {
		return err
	}

	if resp.StatusCode >= 300 {
		return errors.New(resp.Status)
	}

	cr := helpers.ConfigureResponse{}
	if err := json.NewDecoder(resp.Body).Decode(&cr); err != nil {
		return err
	}

	// when user does not define any events, by default github api sets it
	// as ["push"] event array. for this reason we are updating stored event
	// with service response when it is needed
	for k, v := range cr {
		if err := ci.AddSettings(k, v); err != nil {
			h.log.Error("Could not update field %s:%s", k, err)
		}
	}

	return nil
}

// ListChannelIntegrations lists channel integrations for the given group
func (h *Handler) ListChannelIntegrations(u *url.URL, header http.Header, _ interface{}, ctx *models.Context) (int, http.Header, interface{}, error) {
	if !ctx.IsLoggedIn() {
		return response.NewInvalidRequest(models.ErrNotLoggedIn)
	}

	ics := webhook.NewIntegrationContainers()
	if err := ics.Populate(ctx.GroupName); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(response.NewSuccessResponse(ics))
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
