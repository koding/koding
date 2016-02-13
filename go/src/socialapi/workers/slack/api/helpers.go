package api

import (
	kodingmodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"socialapi/models"
	"socialapi/workers/common/sem"
	"sync"
	"time"

	"github.com/nlopes/slack"
	"gopkg.in/mgo.v2/bson"
)

type SlackUser struct {
	slack.User
	LastActivity *time.Time `json:"lastActivity,omitempty"`
}

type SlackChannelsResponse struct {
	Groups   []slack.Group   `json:"groups,omitempty"`
	Channels []slack.Channel `json:"channels,omitempty"`
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

	activeUsersChan := make(chan SlackUser) // idk the total valid number

	sem := sem.New(20) // run 20 goroutines concurrently
	var wg sync.WaitGroup
	wg.Add(len(allusers))

	var activeUsers []SlackUser
	go func() {
		for t := range activeUsersChan {
			activeUsers = append(activeUsers, t)
		}
	}()

	for _, u := range allusers {
		sem.Lock()
		go func(u slack.User) {
			defer sem.Unlock()
			defer wg.Done()

			// no need to add deleted users
			if u.Deleted {
				return
			}

			// filter bots
			if u.IsBot {
				return
			}

			// even if we get error from slack api set it to nil
			var lastActive *time.Time

			// presence information is optional, so we can skip the errored ones
			p, err := api.GetUserPresence(u.ID)
			if err != nil || p == nil {
				activeUsersChan <- SlackUser{u, lastActive}
				return
			}

			// set presence info
			u.Presence = p.Presence

			// LastActivity works inconsistently
			// if u.Presence != slackAway {
			//  LastActiveTime := p.LastActivity.Time()
			//  lastActive = &LastActiveTime
			// }

			activeUsersChan <- SlackUser{u, lastActive}
		}(u)
	}

	wg.Wait()
	close(activeUsersChan)

	return activeUsers, nil
}

func postMessage(req *SlackMessageRequest) (string, error) {
	api := slack.New(req.Token)
	_, id, err := api.PostMessage(req.Channel, req.Text, req.Params)
	return id, err
}

func updateUserSlackToken(user *kodingmodels.User, m string) error {
	selector := bson.M{"username": user.Name}
	update := bson.M{"foreignAuth.slack.token": m}

	return modelhelper.UpdateUser(selector, update)
}

// getSlackToken fetches the user's slack token with user's accountID
func getSlackToken(acc *models.Account) (string, error) {
	var token string

	user, err := modelhelper.GetUser(acc.Nick)
	if err != nil {
		return token, err
	}

	token = user.ForeignAuth.Slack.Token

	if token == "" {
		return token, models.ErrTokenIsNotFound
	}

	return token, nil
}
