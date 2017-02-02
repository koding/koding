package api

import (
	"fmt"
	kodingmodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"net/url"
	"socialapi/models"
	"sync"
	"time"

	"github.com/gorilla/schema"
	"github.com/nlopes/slack"
	"gopkg.in/mgo.v2/bson"
)

// SlackUser holds custom properties apart from slack' api response
type SlackUser struct {
	slack.User
	LastActivity *time.Time `json:"lastActivity,omitempty"`
}

// SlackChannelsResponse holds data type to return as a channels request
type SlackChannelsResponse struct {
	Groups   []slack.Group   `json:"groups,omitempty"`
	Channels []slack.Channel `json:"channels,omitempty"`
}

// SlashCommand stores incoming slash command requests
type SlashCommand struct {
	Command     string         `schema:"command"`
	Token       string         `schema:"token"`
	TeamID      string         `schema:"team_id"`
	TeamDomain  string         `schema:"team_domain,omitempty"`
	ChannelID   string         `schema:"channel_id"`
	ChannelName string         `schema:"channel_name"`
	Timestamp   slack.JSONTime `schema:"timestamp,omitempty"`
	UserID      string         `schema:"user_id"`
	UserName    string         `schema:"user_name"`
	Text        string         `schema:"text,omitempty"`
	TriggerWord string         `schema:"trigger_word,omitempty"`
	ServiceID   string         `schema:"service_id,omitempty"`
	ResponseURL string         `schema:"response_url,omitempty"`
	BotID       string         `schema:"bot_id,omitempty"`
	BotName     string         `schema:"bot_name,omitempty"`
	Robot       string
}

func newSlashCommandFromURLValues(postForm url.Values) (*SlashCommand, error) {
	d := schema.NewDecoder()
	d.IgnoreUnknownKeys(true)

	c := &SlashCommand{}
	if err := d.Decode(c, postForm); err != nil {
		return nil, err
	}

	if len(c.Command) > 0 {
		c.Robot = c.Command[1:]
	}

	return c, nil
}

// getOnlyChannels send a request to the slack with user's token & gets the channels
func getOnlyChannels(token string) (*SlackChannelsResponse, error) {
	api := slack.New(token)
	var channels []slack.Channel

	channels, err := api.GetChannels(true)
	if err != nil {
		return nil, err
	}

	return &SlackChannelsResponse{
		Channels: channels,
	}, nil
}

// getChannels send a request to the slack with user's token & gets the channels
func getChannels(token string) (*SlackChannelsResponse, error) {
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

func getUsers(token string) ([]SlackUser, error) {
	api := slack.New(token)
	allusers, err := api.GetUsers()
	if err != nil {
		return nil, err
	}

	resultChan := make(chan SlackUser)
	workChan := make(chan slack.User)

	// produce the work
	go func() {
		for _, u := range allusers {
			workChan <- u
		}

		close(workChan)
	}()

	// start consuming
	var wg sync.WaitGroup
	const concurrency = 20
	for i := 0; i < concurrency; i++ {
		wg.Add(1)
		go func() {
			processPresence(api, workChan, resultChan)
			wg.Done()
		}()
	}

	// mark we are done
	go func() {
		wg.Wait()
		close(resultChan)
	}()

	// collect result set
	var activeUsers []SlackUser
	for t := range resultChan {
		activeUsers = append(activeUsers, t)
	}

	return activeUsers, nil
}

func processPresence(api *slack.Client, workChan chan slack.User, resultChan chan SlackUser) {
	for u := range workChan {
		if u.ID == "" {
			continue
		}

		// no need to add deleted users
		if u.Deleted {
			continue
		}

		// filter bots
		if u.IsBot {
			continue
		}

		// even if we get error from slack api set it to nil
		var lastActive *time.Time

		// presence information is optional, so we can skip the errored ones
		p, err := api.GetUserPresence(u.ID)
		if err != nil || p == nil {
			resultChan <- SlackUser{u, lastActive}
			continue
		}

		// set presence info
		u.Presence = p.Presence

		resultChan <- SlackUser{u, lastActive}
	}
}

func postMessage(token string, req *SlackMessageRequest) (string, error) {
	api := slack.New(token)
	_, id, err := api.PostMessage(req.Channel, req.Text, req.Params)
	return id, err
}

func getTeamInfo(token string) (*slack.TeamInfo, error) {
	api := slack.New(token)
	info, err := api.GetTeamInfo()
	if err != nil {
		return nil, err
	}

	return info, nil
}

func updateUserSlackToken(user *kodingmodels.User, groupName string, m string) error {
	selector := bson.M{"username": user.Name}
	key := fmt.Sprintf("foreignAuth.slack.%s.token", groupName)
	update := bson.M{key: m}

	return modelhelper.UpdateUser(selector, update)
}

// getSlackToken fetches the user's slack token with user's accountID
func getSlackToken(context *models.Context) (string, error) {
	var token string

	user, err := modelhelper.GetUser(context.Client.Account.Nick)
	if err != nil {
		return token, err
	}

	groupName := context.GroupName

	if user.ForeignAuth.Slack != nil {
		if gName, ok := user.ForeignAuth.Slack[groupName]; ok {
			if gName.Token != "" {
				return gName.Token, nil
			}
		}
	}

	return token, models.ErrTokenIsNotFound

}

func getAnySlackTokenWithGroup(context *models.Context) (string, error) {
	var token string
	groupName := context.GroupName

	users, err := modelhelper.GetAnySlackTokenWithGroup(groupName)
	if err != nil {
		return token, err
	}

	for _, user := range users {
		if user.ForeignAuth.Slack != nil {
			if gName, ok := user.ForeignAuth.Slack[groupName]; ok {
				if gName.Token != "" {
					return gName.Token, nil
				}
			}
		}
	}

	return token, models.ErrTokenIsNotFound
}

// getSlackTokenWithContext fetches the token of user,
// if it doesn't exists, then checks the anyone's token from user's group
func getSlackTokenWithContext(context *models.Context) (string, error) {
	token, err := getSlackToken(context)
	if err != nil || token == "" {
		token, err = getAnySlackTokenWithGroup(context)
	}

	return token, err
}
