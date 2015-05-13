package api

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	socialapimodels "socialapi/models"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/response"
	"socialapi/workers/realtime/models"
	"time"

	"github.com/koding/logging"
)

type Handler struct {
	pubnub *models.PubNub
	logger logging.Logger
}

func NewHandler(p *models.PubNub, l logging.Logger) *Handler {
	return &Handler{
		pubnub: p,
		logger: l,
	}
}

// SubscribeChannel checks users channel accessability and regarding to that
// grants channel access for them
func (h *Handler) SubscribeChannel(u *url.URL, header http.Header, req *models.Channel, context *socialapimodels.Context) (int, http.Header, interface{}, error) {
	if !context.IsLoggedIn() {
		return response.NewBadRequest(socialapimodels.ErrNotLoggedIn)
	}

	req.Group = context.GroupName // override group name
	res, err := checkParticipation(u, header, req)
	if err != nil {
		return response.NewAccessDenied(err)
	}

	// user has access permission, now authenticate user to channel via pubnub
	a := new(models.Authenticate)
	a.Channel = models.NewPrivateMessageChannel(*res.Channel)
	a.Account = res.Account
	a.Account.Token = res.AccountToken

	err = h.pubnub.Authenticate(a)
	if err != nil {
		return response.NewBadRequest(err)
	}

	return responseWithCookie(req, a.Account.Token)
}

// SubscribeNotification grants notification channel access for user. User information is
// fetched from session
func (h *Handler) SubscribeNotification(u *url.URL, header http.Header, temp *models.Account, context *socialapimodels.Context) (int, http.Header, interface{}, error) {
	if !context.IsLoggedIn() {
		return response.NewBadRequest(socialapimodels.ErrNotLoggedIn)
	}

	account := context.Client.Account

	// authenticate user to their notification channel
	a := new(models.Authenticate)
	a.Channel = models.NewNotificationChannel(account)
	a.Account = account

	// TODO need async requests. Re-try in case of an error
	err = h.pubnub.Authenticate(a)
	if err != nil {
		return response.NewBadRequest(err)
	}

	return responseWithCookie(temp, account.Token)
}

func (h *Handler) GetToken(u *url.URL, header http.Header, req *models.Account, context *socialapimodels.Context) (int, http.Header, interface{}, error) {
	if !context.IsLoggedIn() {
		return response.NewBadRequest(socialapimodels.ErrNotLoggedIn)
	}

	return responseWithCookie(req, context.Client.Account.Token)
}

func responseWithCookie(req interface{}, token string) (int, http.Header, interface{}, error) {
	expires := time.Now().AddDate(5, 0, 0)
	cookie := &http.Cookie{
		Name:    "realtimeToken",
		Value:   token,
		Path:    "/",
		Expires: expires,
	}

	return response.NewOKWithCookie(req, []*http.Cookie{cookie})
}

// TODO needs a better request handler
func checkParticipation(u *url.URL, header http.Header, cr *models.Channel) (*models.CheckParticipationResponse, error) {
	// relay the cookie to other endpoint
	cookie := header.Get("Cookie")
	request := &handler.Request{
		Type:     "GET",
		Endpoint: "/api/social/channel/checkparticipation",
		Params: map[string]string{
			"name":      cr.Name,
			"groupName": cr.Group,
			"type":      cr.Type,
		},
		Cookie: cookie,
	}

	// TODO update this requester
	resp, err := handler.MakeRequest(request)
	if err != nil {
		return nil, err
	}

	// Need a better response
	if resp.StatusCode != 200 {
		return nil, fmt.Errorf(resp.Status)
	}

	var cpr models.CheckParticipationResponse
	err = json.NewDecoder(resp.Body).Decode(&cpr)
	resp.Body.Close()
	if err != nil {
		return nil, err
	}

	return &cpr, nil
}
