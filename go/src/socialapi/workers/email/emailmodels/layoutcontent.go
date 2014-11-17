package emailmodels

import (
	"bytes"
	"net/url"
	"socialapi/config"
	"socialapi/workers/email/templates"
	"text/template"
)

type LayoutContent struct {
	// Title used in head tag
	Title string
	// Body is all purpose main mail content field
	Body     string
	Hostname string
	ShowLink bool
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
		Hostname:       config.MustGet().Hostname,
	}
}

func (lc *LayoutContent) Render() (string, error) {
	mt := template.Must(template.New("main").Parse(templates.Layout))

	var doc bytes.Buffer
	if err := mt.Execute(&doc, lc); err != nil {
		return "", err
	}

	return doc.String(), nil
}
