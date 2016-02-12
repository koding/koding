package api

import (
	"fmt"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/common/response"
	"sync"
	"time"

	"github.com/nlopes/slack"

	"golang.org/x/oauth2"
)

const slackAway = "away"

type Slack struct {
	OAuthConf *oauth2.Config
}

func (s *Slack) Send(w http.ResponseWriter, req *http.Request) {
	url := s.OAuthConf.AuthCodeURL("state", oauth2.AccessTypeOffline)
	http.Redirect(w, req, url, http.StatusTemporaryRedirect)
}

func (s *Slack) Callback(w http.ResponseWriter, req *http.Request) {

	// state := req.FormValue("state")
	// if state != oauthStateString {
	// 	fmt.Printf("invalid oauth state, expected '%s', got '%s'\n", oauthStateString, state)
	// 	http.Redirect(w, req, "/", http.StatusTemporaryRedirect)
	// 	return
	// }
	code := req.FormValue("code")
	token, err := s.OAuthConf.Exchange(oauth2.NoContext, code)
	if err != nil {
		fmt.Printf("oauthConf.Exchange() failed with '%s'\n", err)
		http.Redirect(w, req, "/", http.StatusTemporaryRedirect)
		return
	}

	fmt.Printf("TOKEN IS: %+v", token)
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

func (s *Slack) ListUsers(u *url.URL, h http.Header, req *SlackRequest, context *models.Context) (int, http.Header, interface{}, error) {
	return response.HandleResultAndError(s.getUsers(req.Token))
}

func (s *Slack) ListChannels(u *url.URL, h http.Header, req *SlackRequest, context *models.Context) (int, http.Header, interface{}, error) {
	return response.HandleResultAndError(s.getChannels(req.Token))
}

func (s *Slack) PostMessage(u *url.URL, h http.Header, req *SlackMessageRequest, context *models.Context) (int, http.Header, interface{}, error) {
	return response.HandleResultAndError(s.postMessage(req))
}

type SlackUser struct {
	slack.User
	LastActivity *time.Time `json:"lastActivity,omitempty"`
}

type SlackChannelsResponse struct {
	Groups   []slack.Group   `json:"groups,omitempty"`
	Channels []slack.Channel `json:"channels,omitempty"`
}

func (s *Slack) getChannels(token string) (*SlackChannelsResponse, error) {
	api := slack.New(token)
	var groups []slack.Group
	var channels []slack.Channel
	var gerr, cerr error
	var wg sync.WaitGroup
	wg.Add(2)

	go func() {
		groups, gerr = api.GetGroups(true)
		wg.Done()
	}()

	go func() {
		channels, cerr = api.GetChannels(true)
		wg.Done()
	}()

	wg.Wait()

	if gerr != nil {
		return nil, gerr
	}

	if cerr != nil {
		return nil, cerr
	}

	return &SlackChannelsResponse{
		Groups:   groups,
		Channels: channels,
	}, nil
}

func (s *Slack) getUsers(token string) ([]SlackUser, error) {
	api := slack.New(token)
	allusers, err := api.GetUsers()
	if err != nil {
		return nil, err
	}

	var activeUsers []SlackUser
	for _, u := range allusers {
		// no need to add deleted users
		if u.Deleted {
			continue
		}

		// filter bots
		if u.IsBot {
			continue
		}

		p, err := api.GetUserPresence(u.ID)
		if err != nil {
			return nil, err
		}

		var lastActive *time.Time
		if p != nil {
			// set presence info
			u.Presence = p.Presence

			// LastActivity works inconsistently
			// if u.Presence != slackAway {
			// 	LastActiveTime := p.LastActivity.Time()
			// 	lastActive = &LastActiveTime
			// }
		}

		au := SlackUser{u, lastActive}

		activeUsers = append(activeUsers, au)
	}

	return activeUsers, nil
}

func (s *Slack) postMessage(req *SlackMessageRequest) (string, error) {
	api := slack.New(req.Token)
	_, id, err := api.PostMessage(req.Channel, req.Text, req.Params)
	return id, err
}
