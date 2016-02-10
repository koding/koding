package api

import (
	"socialapi/config"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"

	"golang.org/x/oauth2"
)

func AddHandlers(m *mux.Mux, config *config.Config) {

	var (
		// You must register the app at https://github.com/settings/applications
		// Set callback to http://127.0.0.1:8080/github_oauth_cb
		// Set ClientId and ClientSecret to
		oauthConf = &oauth2.Config{
			// ClientID:     "20619428033.20787518977",
			ClientID:     config.Slack.ClientId,     //"20619428033.20787518977",
			ClientSecret: config.Slack.ClientSecret, // "1987edcacd657367fd1b3b0eb653f14b",
			Scopes:       []string{"incoming-webhook", "commands", "channels:write", "channels:read"},
			RedirectURL:  config.Slack.RedirectUri, // "https://ff820e2f.ngrok.io/slack_oauth",
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
}
