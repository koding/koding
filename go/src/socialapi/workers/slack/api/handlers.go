package api

import (
	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"

	"golang.org/x/oauth2"
)

// AddHandlers adds handlers for slack integration
func AddHandlers(m *mux.Mux, config *config.Config) {
	s := &Slack{
		Hostname:          config.Hostname,
		Protocol:          config.Protocol,
		VerificationToken: config.Slack.VerificationToken,
		OAuthConf: &oauth2.Config{
			ClientID:     config.Slack.ClientId,
			ClientSecret: config.Slack.ClientSecret,
			RedirectURL:  config.Slack.RedirectUri,
			Endpoint: oauth2.Endpoint{
				AuthURL:  "https://slack.com/oauth/authorize",
				TokenURL: "https://slack.com/api/oauth.access",
			},
			Scopes: []string{
				// channels.info
				// channels.list
				// Provides us to read public channel list of a team
				"channels:read",

				// chat.postMessage
				// Provides us to write a message to channel as a bot
				"chat:write:bot",

				// groups.info
				// groups.list
				// Provides us to list group channels of user
				"groups:read",

				// im.list
				// Provides us to list im channels of user
				"im:read",

				// mpim.list
				// Provides us to list mpim channels of user
				"mpim:read",

				// team.info
				// Provides us to get team info while creating a team at koding
				"team:read",

				// users.getPresence
				// users.info
				// Provides us the presence information which we use to list
				// online users at the top of the users list
				"users:read",

				// usergroups.list
				// usergroups.users.list
				// Provides us the list usergroups of user
				"usergroups:read",

				// includes bot user functionality. Unlike incoming-webhook and
				// commands, the bot scope grants your bot user access to a
				// subset of Web API methods.
				//
				// https://api.slack.com/bot-users#bot-methods
				// Provides us the bot functionality. Even tho bot has most of
				// the above scopes, slack's api is not consistent and sometimes
				// they send the response, sometimes they fail with missing
				// scope error
				"bot",
			},
		},
	}

	m.AddHandler(
		handler.Request{
			Handler:  s.Send,
			Name:     models.SlackOauthSend,
			Type:     handler.GetRequest,
			Endpoint: "/slack/oauth",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  s.Callback,
			Name:     models.SlackOauthCallback,
			Type:     handler.GetRequest,
			Endpoint: "/slack/oauth/callback",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  s.Success,
			Name:     models.SlackOauthSuccess,
			Type:     handler.GetRequest,
			Endpoint: "/slack/oauth/success",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  s.ListUsers,
			Name:     models.SlackListUsers,
			Type:     handler.GetRequest,
			Endpoint: "/slack/users",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  s.ListChannels,
			Name:     models.SlackListChannels,
			Type:     handler.GetRequest,
			Endpoint: "/slack/channels",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  s.TeamInfo,
			Name:     models.SlackTeamInfo,
			Type:     handler.GetRequest,
			Endpoint: "/slack/team",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  s.PostMessage,
			Name:     models.SlackPostMessage,
			Type:     handler.PostRequest,
			Endpoint: "/slack/message",
		},
	)

	m.AddUnscopedHandler(
		handler.Request{
			Handler:  s.SlashCommand,
			Name:     models.SlackSlashCommand,
			Type:     handler.PostRequest,
			Endpoint: "/slack/slash",
		},
	)
}
