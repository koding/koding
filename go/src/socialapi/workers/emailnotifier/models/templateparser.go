package models

import (
	"bytes"
	"fmt"
	"html/template"
	"net/url"

	"socialapi/config"
	"socialapi/workers/emailnotifier/templates"
	"strings"
	"time"

	"github.com/webcitizen/juice"
)

const (
	DATEFORMAT = "Jan 02"
	TIMEFORMAT = "15:04"
)

type TemplateParser struct {
	UserContact *UserContact
}

func NewTemplateParser() *TemplateParser {
	return &TemplateParser{}
}

func (tp *TemplateParser) RenderInstantTemplate(mc *MailerContainer) (string, error) {
	if err := tp.validateTemplateParser(); err != nil {
		return "", err
	}

	ec, err := buildEventContent(mc)
	if err != nil {
		return "", err
	}
	content := tp.renderContentTemplate(ec, mc)

	return tp.renderTemplate(mc.Content.GetDefinition(), content, "", mc.CreatedAt)
}

func (tp *TemplateParser) RenderDailyTemplate(containers []*MailerContainer) (string, error) {
	if err := tp.validateTemplateParser(); err != nil {
		return "", err
	}

	var contents string
	for _, mc := range containers {
		ec, err := buildEventContent(mc)
		if err != nil {
			continue
		}
		c := tp.renderContentTemplate(ec, mc)
		contents = c + contents
	}

	return tp.renderTemplate(
		"daily",
		contents,
		"Here what's happened in Koding today!",
		time.Now())
}

func (tp *TemplateParser) validateTemplateParser() error {
	if tp.UserContact == nil {
		return fmt.Errorf("TemplateParser UserContact is not set")
	}

	return nil
}

func (tp *TemplateParser) inlineCss(content string) string {
	css := []byte(templates.Style)
	rules := juice.Parse(css)
	output := juice.Inline(strings.NewReader(content), rules)

	return output
}

func (tp *TemplateParser) renderTemplate(contentType, content, description string, date time.Time) (string, error) {

	ut := template.Must(template.New("unsubscribe").Parse(templates.Unsubscribe))
	ft := template.Must(template.New("footer").Parse(templates.Footer))
	mt := template.Must(template.New("main").Parse(templates.Main))

	mt.AddParseTree("unsubscribe", ut.Tree)
	mt.AddParseTree("footer", ft.Tree)

	mc := tp.buildMailContent(contentType, getMonthAndDay(date))

	mc.Content = template.HTML(content)
	mc.Description = description

	var doc bytes.Buffer
	if err := mt.Execute(&doc, mc); err != nil {
		return "", err
	}

	output := tp.inlineCss(doc.String())

	return output, nil
}

func (tp *TemplateParser) buildMailContent(contentType string, currentDate string) *MailContent {
	return &MailContent{
		FirstName:   tp.UserContact.FirstName,
		CurrentDate: currentDate,
		Unsubscribe: &UnsubscribeContent{
			Token:       tp.UserContact.Token,
			ShowLink:    contentType != "daily", // do not show link for daily emails
			ContentType: contentType,
			Recipient:   url.QueryEscape(tp.UserContact.Email),
		},
		Uri: config.MustGet().Hostname,
	}
}

func buildEventContent(mc *MailerContainer) (*EventContent, error) {
	ec := &EventContent{
		Action:       mc.ActivityMessage,
		ActivityTime: prepareTime(mc),
		Uri:          config.MustGet().Hostname,
		Slug:         mc.Slug,
		Message:      mc.Message,
		Group:        mc.Group,
		ObjectType:   mc.ObjectType,
		Size:         20,
	}

	actor, err := FetchUserContact(mc.Activity.ActorId)
	if err != nil {
		return nil, fmt.Errorf("an error occurred while retrieving actor details", err)
	}
	ec.ActorContact = *actor

	return ec, nil
}

func appendGroupTemplate(t *template.Template, mc *MailerContainer) {
	var groupTemplate *template.Template
	if mc.Group.Name == "" || mc.Group.Slug == "koding" {
		groupTemplate = getEmptyTemplate()
	} else {
		groupTemplate = template.Must(template.New("group").Parse(templates.Group))
	}

	t.AddParseTree("group", groupTemplate.Tree)
}

func (tp *TemplateParser) renderContentTemplate(ec *EventContent, mc *MailerContainer) string {
	ct := template.Must(template.New("content").Parse(templates.Content))
	gt := template.Must(template.New("gravatar").Parse(templates.Gravatar))
	ct.AddParseTree("gravatar", gt.Tree)

	appendPreviewTemplate(ct, mc)
	appendGroupTemplate(ct, mc)

	buf := bytes.NewBuffer([]byte{})
	ct.ExecuteTemplate(buf, "content", ec)

	return buf.String()
}

func appendPreviewTemplate(t *template.Template, mc *MailerContainer) {
	var previewTemplate, contentLinkTemplate *template.Template
	if mc.Message == "" {
		previewTemplate = getEmptyTemplate()
		contentLinkTemplate = getEmptyTemplate()
	} else {
		previewTemplate = template.Must(template.New("preview").Parse(templates.Preview))
		contentLinkTemplate = template.Must(template.New("contentLink").Parse(templates.ContentLink))
	}

	t.AddParseTree("preview", previewTemplate.Tree)
	t.AddParseTree("contentLink", contentLinkTemplate.Tree)
}

func getEmptyTemplate() *template.Template {
	return template.Must(template.New("").Parse(""))
}

func getMonthAndDay(t time.Time) string {
	return t.Format(DATEFORMAT)
}

func prepareDate(mc *MailerContainer) string {
	return mc.Activity.CreatedAt.Format(DATEFORMAT)
}

func prepareTime(mc *MailerContainer) string {
	return mc.Activity.CreatedAt.Format(TIMEFORMAT)
}
