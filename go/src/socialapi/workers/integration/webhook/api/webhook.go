package api

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"net/http"
	"net/url"
	"socialapi/config"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/response"
	"socialapi/workers/integration/webhook"
	"socialapi/workers/integration/webhook/services"

	"labix.org/v2/mgo"

	"github.com/koding/logging"
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

	if err := h.bot.SendMessage(&r.Message); err != nil {
		return response.NewBadRequest(err)
	}

	res := response.NewSuccessResponse(nil)

	return response.NewOK(res)
}

func (h *Handler) Prepare(u *url.URL, header http.Header, request services.ServiceInput) (int, http.Header, interface{}, error) {
	r := new(PrepareRequest)
	r.Data = &request

	token := u.Query().Get("token")
	r.Token = token
	name := u.Query().Get("name")
	r.Name = name

	if err := r.validate(); err != nil {
		return response.NewBadRequest(err)
	}

	_, err := r.verify()
	if err == webhook.ErrIntegrationNotFound {
		h.log.Warning("Could not find integration: %s", r.Name)
		return response.NewNotFound()
	}

	if err != nil {
		return response.NewBadRequest(err)
	}

	service, err := h.sf.Create(name, r.Data)
	if err != nil {
		return response.NewBadRequest(err)
	}

	errs := service.Validate(r.Data)
	if len(errs) > 0 {
		// TODO we need another bad request method here for showing validation errors
		return response.NewBadRequest(errs[0])
	}

	message := service.PrepareMessage(r.Data)

	endPoint := fmt.Sprintf("%s%s", h.RootPath, service.PrepareEndpoint(r.Token))
	pr := new(PushRequest)
	pr.Body = message

	so := service.Output(r.Data)
	pr.GroupName = so.GroupName

	channelId, err := h.fetchChannelId(so)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if channelId != 0 {
		pr.ChannelId = channelId
	}

	if err := push(endPoint, pr); err != nil {
		return response.NewBadRequest(err)
	}

	res := response.NewSuccessResponse(nil)

	return response.NewOK(res)
}

func (h *Handler) FetchBotChannel(u *url.URL, header http.Header, _ interface{}, c *models.Context) (int, http.Header, interface{}, error) {
	if !c.IsLoggedIn() {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}

	r := new(BotChannelRequest)

	r.Username = c.Client.Account.Nick
	r.GroupName = c.GroupName
	if err := r.validate(); err != nil {
		return response.NewBadRequest(err)
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

func (h *Handler) fetchChannelId(so *services.ServiceOutput) (int64, error) {

	if err := h.prepareUsername(so); err != nil {
		return 0, err
	}

	if so.Username == "" {
		return 0, nil
	}

	br := new(BotChannelRequest)
	br.Username = so.Username
	br.GroupName = so.GroupName
	c, err := h.fetchBotChannel(br)
	if err != nil {
		return 0, err
	}

	return c.Id, nil
}

func (h *Handler) prepareUsername(so *services.ServiceOutput) error {

	if so.Username != "" {
		return nil
	}

	if so.Email == "" {
		return nil
	}

	// TODO instead of fetching directly from mongo
	// we can fetch these via an endpoint
	user, err := modelhelper.FetchUserByEmail(so.Email)
	if err == mgo.ErrNotFound {
		return ErrEmailNotFound
	}

	if err != nil {
		return err
	}

	so.Username = user.Name

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

// TODO need to mock the endpoint. up till that time, this push method is
// defined like this
var push = func(endPoint string, pushRequest *PushRequest) error {

	// relay the cookie to other endpoint
	request := &handler.Request{
		Type:     "POST",
		Endpoint: endPoint,
		Body:     pushRequest,
		Headers: map[string]string{
			"Accept":       "application/json",
			"Content-Type": "application/json",
		},
	}

	resp, err := handler.DoRequest(request)
	if err != nil {
		return err
	}

	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return fmt.Errorf(resp.Status)
	}

	return nil
}
