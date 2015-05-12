package emailmodels

import (
	"net/url"
	"socialapi/config"
)

type LayoutContent struct {
	// Title used in head tag
	Title string
	// Body is all purpose main mail content field
	Body string
	// Information is used as first sentence of email
	Information string
	Hostname    string
	ShowLink    bool
	// Token used for unsubscription
	Token string
	// RecipientEmail used for unsubscription
	RecipientEmail string
	// ContentType used for unsubscription
	ContentType string
	FirstName   string
}

func NewLayoutContent(u *UserContact, contentType, body string) *LayoutContent {
	// do not show content type specific unsubscription link for daily emails
	showLink := contentType != "daily"

	return &LayoutContent{
		FirstName:      u.FirstName,
		Token:          u.Token,
		Body:           body,
		ShowLink:       showLink,
		ContentType:    contentType,
		RecipientEmail: url.QueryEscape(u.Email),
		Hostname:       config.MustGet().Protocol + "//" + config.MustGet().Hostname,
	}
}
