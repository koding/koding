package api

import (
	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"

	"golang.org/x/oauth2"
)

func AddHandlers(m *mux.Mux, config *config.Config) {

	var (
		oauthConf = &oauth2.Config{
			ClientID:     config.Slack.ClientId,
			ClientSecret: config.Slack.ClientSecret,
			Scopes: []string{
				// channels.info
				// channels.list
				"channels:read",

				// chat.postMessage
				"chat:write:bot",

				// groups.info
				// groups.list
				"groups:read",

				// im.list
				"im:read",

				// mpim.list
				"mpim:read",

				// team.info
				"team:read",

				// usergroups.list
				// usergroups.users.list
				"usergroups:read",

				// users.getPresence
				// users.info
				"users:read",

				// allows teams to easily install an incoming webhook that can
				// post from your app to a single Slack channel.
				"incoming-webhook",

				// allows teams to install slash commands bundled in your Slack
				// app.
				"commands",

				// includes bot user functionality. Unlike incoming-webhook and
				// commands, the bot scope grants your bot user access to a
				// subset of Web API methods.
				//
				// https://api.slack.com/bot-users#bot-methods
				"bot",
			},
			RedirectURL: config.Slack.RedirectUri,
			Endpoint: oauth2.Endpoint{
				AuthURL:  "https://slack.com/oauth/authorize",
				TokenURL: "https://slack.com/api/oauth.access",
			}, // https://slack.com/oauth/authorize
		}
	)

	s := &Slack{
		OAuthConf: oauthConf,
	}
	// add a new messages to the channel
	m.AddUnscopedHandler(
		handler.Request{
			Handler:  s.Send,
			Type:     handler.GetRequest,
			Endpoint: "/slack/oauth",
		},
	)

	// add a new messages to the channel
	m.AddUnscopedHandler(
		handler.Request{
			Handler:  s.Callback,
			Type:     handler.GetRequest,
			Endpoint: "/slack/oauth/callback",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  s.ListUsers,
			Name:     models.SlackListUsers,
			Type:     handler.PostRequest,
			Endpoint: "/slack/users",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  s.ListChannels,
			Name:     models.SlackListChannels,
			Type:     handler.PostRequest,
			Endpoint: "/slack/channels",
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
}
