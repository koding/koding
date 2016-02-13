package api

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/common/response"

	"github.com/nlopes/slack"

	"golang.org/x/oauth2"
	"gopkg.in/mgo.v2"
)

const slackAway = "away"

type Slack struct {
	OAuthConf *oauth2.Config
}

type SlackRequest struct {
	Token string
}

type SlackMessageRequest struct {
	SlackRequest
	Channel string
	Text    string
	Params  slack.PostMessageParameters
}

// Send & Callback handlers are used for slack oauth
// If we can get the token successfully, then we store user's token in mongo in Callback handler
func (s *Slack) Send(w http.ResponseWriter, req *http.Request) {
	url := s.OAuthConf.AuthCodeURL("state", oauth2.AccessTypeOffline)
	http.Redirect(w, req, url, http.StatusTemporaryRedirect)
}

func (s *Slack) Callback(u *url.URL, h http.Header, _ interface{}, c *models.Context) (int, http.Header, interface{}, error) {
	code := u.Query().Get("code")

	token, err := s.OAuthConf.Exchange(oauth2.NoContext, code)
	if err != nil {
		fmt.Printf("oauthConf.Exchange() failed with '%s'\n", err)
		return response.NewBadRequest(err)
	}

	user, err := modelhelper.GetUser(c.Client.Account.Nick)
	if err != nil && err != mgo.ErrNotFound {
		return response.NewBadRequest(err)
	}

	if err == mgo.ErrNotFound {
		return response.NewBadRequest(err)
	}

	if err := updateUserSlackToken(user, token.AccessToken); err != nil {
		return response.NewBadRequest(err)
	}

	fmt.Printf("TOKEN IS: %+v", token)
	return response.NewOK(nil)
}

//
// ListUsers & ListChannels & PostMessage handlers are used by client of koding
//

func (s *Slack) ListUsers(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	if !context.IsLoggedIn() {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}

	token, err := getSlackToken(context.Client.Account)
	if err != nil {
		return response.NewBadRequest(err)
	}

	return response.HandleResultAndError(getUsers(token))
}

func (s *Slack) ListChannels(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	if !context.IsLoggedIn() {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}

	token, err := getSlackToken(context.Client.Account)
	if err != nil {
		return response.NewBadRequest(err)
	}

	return response.HandleResultAndError(getChannels(token))
}

func (s *Slack) PostMessage(u *url.URL, h http.Header, req *SlackMessageRequest, context *models.Context) (int, http.Header, interface{}, error) {
	if !context.IsLoggedIn() {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}

	token, err := getSlackToken(context.Client.Account)
	if err != nil {
		return response.NewBadRequest(err)
	}
	req.Token = token
	return response.HandleResultAndError(postMessage(req))
}
