package api

import (
	"fmt"
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
