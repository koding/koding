// Package api provides endpoints for topic moderation system
package api

import (
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
	"socialapi/workers/common/response"
	"socialapi/workers/email/emailsender"
)

// AddHandlers added the internal handlers to the given Muxer
func AddHandlers(m *mux.Mux) {
	m.AddHandler(
		handler.Request{
			Handler:  PublishEvent,
			Name:     models.MailPublishEvent,
			Type:     handler.PostRequest,
			Endpoint: "/private/mail/publish",
		},
	)
}

func PublishEvent(u *url.URL, h http.Header, req *emailsender.Mail) (int, http.Header, interface{}, error) {
	if err := emailsender.Send(req); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewDefaultOK()
}
