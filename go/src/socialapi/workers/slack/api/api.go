package api

import (
	"errors"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/common/response"
	"strings"

	"github.com/nlopes/slack"

	"golang.org/x/oauth2"
	"gopkg.in/mgo.v2"
)

const slackAway = "away"

// Slack holds runtime config for slack OAuth system
type Slack struct {
	Hostname  string
	Protocol  string
	OAuthConf *oauth2.Config
}

// SlackMessageRequest carries message creation request from client side
type SlackMessageRequest struct {
	Channel string
	Text    string
	Params  slack.PostMessageParameters
}

// Send initiates Slack OAuth
func (s *Slack) Send(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	if !context.IsLoggedIn() {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}

	session, err := models.Cache.Session.ById(context.Client.SessionID)
	if err != nil {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}

	url := s.OAuthConf.AuthCodeURL(session.Id.Hex(), oauth2.AccessTypeOffline)
	h.Set("Location", url)
	return http.StatusTemporaryRedirect, h, nil, nil

}

// Callback handler is used for handling redirection requests from Slack API
//
// If we can get the token successfully, then we store user's token in mongo in
// Callback handler
func (s *Slack) Callback(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	state := u.Query().Get("state")
	if state == "" {
		return response.NewBadRequest(errors.New("state is not set"))
	}

	session, err := modelhelper.GetSessionById(state)
	if err != nil {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}

	redirectURL, err := url.Parse(s.OAuthConf.RedirectURL)
	if err != nil {
		return response.NewBadRequest(err)
	}

	// we want to redirect slacks redirection into our success handler with team
	// name included in the redirection url, this is required because user does
	// not need to be logged in plain koding.com doamin
	// eg: dev.koding.com:8090/api/social/slack/oauth/callback?<query params>
	// 			should be redirected to
	// 		teamname.dev.koding.com:8090/api/social/slack/oauth/success?<query params>

	// set incoming request's query params into redirected url
	redirectURL.RawQuery = u.Query().Encode()

	// change subdomain if not only it is koding
	if session.GroupName != models.Channel_KODING_NAME {
		// set team's subdomain
		redirectURL.Host = fmt.Sprintf("%s.%s", session.GroupName, redirectURL.Host)
	}

	// replace 'callback' with 'success'
	redirectURL.Path = strings.Replace(redirectURL.Path, "callback", "success", -1)

	h.Set("Location", redirectURL.String())
	return http.StatusTemporaryRedirect, h, nil, nil
}

// Success handler is used for handling redirection requests from Callback handler
//
// We need this for handling the internal redirection of team requests
func (s *Slack) Success(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	// get session data from state
	state := u.Query().Get("state")
	if state == "" {
		return response.NewBadRequest(errors.New("state is not set"))
	}

	session, err := modelhelper.GetSessionById(state)
	if err != nil {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}

	// get user info
	user, err := modelhelper.GetUser(session.Username)
	if err != nil && err != mgo.ErrNotFound {
		return response.NewBadRequest(err)
	}

	if err == mgo.ErrNotFound {
		return response.NewBadRequest(err)
	}

	// start exchanging code for a token
	code := u.Query().Get("code")
	if code == "" {
		return response.NewBadRequest(errors.New("code is not set"))
	}

	token, err := s.OAuthConf.Exchange(oauth2.NoContext, code)
	if err != nil {
		return response.NewBadRequest(err)
	}

	// update the slack data
	if err := updateUserSlackToken(user, session.GroupName, token.AccessToken); err != nil {
		return response.NewBadRequest(err)
	}

	h.Set("Location", "/Admin/Invitations/Slack")
	return http.StatusTemporaryRedirect, h, nil, nil
}

// ListUsers lists users of a slack team
func (s *Slack) ListUsers(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	if !context.IsLoggedIn() {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}

	token, err := getSlackToken(context)
	if err != nil {
		return response.NewBadRequest(err)
	}

	return response.HandleResultAndError(getUsers(token))
}

// ListChannels lists the channels of a slack team
func (s *Slack) ListChannels(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	if !context.IsLoggedIn() {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}

	token, err := getSlackToken(context)
	if err != nil {
		return response.NewBadRequest(err)
	}

	return response.HandleResultAndError(getChannels(token))
}

// TeamInfo shows basic info regarding a slack team
func (s *Slack) TeamInfo(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	if !context.IsLoggedIn() {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}

	token, err := getSlackToken(context)
	if err != nil {
		return response.NewBadRequest(err)
	}

	return response.HandleResultAndError(getTeamInfo(token))
}

// PostMessage posts a message to a slack channel/group
func (s *Slack) PostMessage(u *url.URL, h http.Header, req *SlackMessageRequest, context *models.Context) (int, http.Header, interface{}, error) {
	if !context.IsLoggedIn() {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}

	token, err := getSlackToken(context)
	if err != nil {
		return response.NewBadRequest(err)
	}
	return response.HandleResultAndError(postMessage(token, req))
}
