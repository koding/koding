package emailnotifier

import (
	"bytes"
	"fmt"
	"html/template"
	"net/url"
	"socialapi/config"
	"socialapi/workers/notification/models"
	"time"
)

var (
	mainTemplateFile        = "../socialapi/workers/emailnotifier/templates/main.tmpl"
	footerTemplateFile      = "../socialapi/workers/emailnotifier/templates/footer.tmpl"
	contentTemplateFile     = "../socialapi/workers/emailnotifier/templates/content.tmpl"
	gravatarTemplateFile    = "../socialapi/workers/emailnotifier/templates/gravatar.tmpl"
	groupTemplateFile       = "../socialapi/workers/emailnotifier/templates/group.tmpl"
	previewTemplateFile     = "../socialapi/workers/emailnotifier/templates/preview.tmpl"
	objectTemplateFile      = "../socialapi/workers/emailnotifier/templates/object.tmpl"
	unsubscribeTemplateFile = "../socialapi/workers/emailnotifier/templates/unsubscribe.tmpl"
)

type NotificationContainer struct {
	Activity        *models.NotificationActivity
	Content         *models.NotificationContent
	AccountId       int64
	Message         string
	Slug            string
	ActivityMessage string
	ObjectType      string
	Group           GroupContent
	CreatedAt       time.Time
}

type EventContent struct {
	// event content
	ActivityTime string
	ActorContact UserContact
	Action       string
	Size         int
	Slug         string
	Uri          string
	ObjectType   string
	Group        GroupContent
	Message      string
}

type MailContent struct {
	CurrentDate string
	FirstName   string
	Description string
	Uri         string
	ContentLink string
	Content     template.HTML
	Unsubscribe *UnsubscribeContent
}

type UnsubscribeContent struct {
	Token       string
	ContentType string
	Recipient   string
}

type GroupContent struct {
	Slug string
	Name string
}

func renderInstantTemplate(uc *UserContact, nc *NotificationContainer) (string, error) {
	ec, err := buildEventContent(nc)
	if err != nil {
		return "", err
	}
	content := renderContentTemplate(ec, nc)

	return renderTemplate(uc, nc.Content.TypeConstant, content, nc.CreatedAt)
}

func renderDailyTemplate(uc *UserContact, containers []*NotificationContainer) (string, error) {
	var contents string
	for _, nc := range containers {
		ec, err := buildEventContent(nc)
		if err != nil {
			continue
		}
		c := renderContentTemplate(ec, nc)
		contents = c + contents
	}

	return renderTemplate(uc, "daily", contents, time.Now())
}

func renderTemplate(uc *UserContact, contentType, content string, date time.Time) (string, error) {
	t := template.Must(template.ParseFiles(
		mainTemplateFile, footerTemplateFile, unsubscribeTemplateFile))
	mc := buildMailContent(uc, contentType, getMonthAndDay(date))

	mc.Content = template.HTML(content)

	var doc bytes.Buffer
	if err := t.Execute(&doc, mc); err != nil {
		return "", err
	}

	return doc.String(), nil
}

func buildMailContent(uc *UserContact, contentType string, currentDate string) *MailContent {
	return &MailContent{
		FirstName:   uc.FirstName,
		CurrentDate: currentDate,
		Unsubscribe: &UnsubscribeContent{
			Token:       uc.Token,
			ContentType: contentType,
			Recipient:   url.QueryEscape(uc.Email),
		},
		Uri: config.Get().Uri,
	}
}

func buildEventContent(nc *NotificationContainer) (*EventContent, error) {
	ec := &EventContent{
		Action:       nc.ActivityMessage,
		ActivityTime: prepareTime(nc),
		Uri:          config.Get().Uri,
		Slug:         nc.Slug,
		Message:      nc.Message,
		Group:        nc.Group,
		ObjectType:   nc.ObjectType,
		Size:         20,
	}

	actor, err := fetchUserContact(nc.Activity.ActorId)
	if err != nil {
		return nil, fmt.Errorf("an error occurred while retrieving actor details", err)
	}
	ec.ActorContact = *actor

	return ec, nil
}

func appendGroupTemplate(t *template.Template, nc *NotificationContainer) {
	var groupTemplate *template.Template
	if nc.Group.Name == "" || nc.Group.Slug == "koding" {
		groupTemplate = getEmptyTemplate()
	} else {
		groupTemplate = template.Must(
			template.ParseFiles(groupTemplateFile))
	}

	t.AddParseTree("group", groupTemplate.Tree)
}

func renderContentTemplate(ec *EventContent, nc *NotificationContainer) string {
	t := template.Must(template.ParseFiles(contentTemplateFile, gravatarTemplateFile))
	appendPreviewTemplate(t, nc)
	appendGroupTemplate(t, nc)

	buf := bytes.NewBuffer([]byte{})
	t.ExecuteTemplate(buf, "content", ec)

	return buf.String()
}

func appendPreviewTemplate(t *template.Template, nc *NotificationContainer) {
	var previewTemplate, objectTemplate *template.Template
	if nc.Message == "" {
		previewTemplate = getEmptyTemplate()
		objectTemplate = getEmptyTemplate()
	} else {
		previewTemplate = template.Must(template.ParseFiles(previewTemplateFile))
		objectTemplate = template.Must(template.ParseFiles(objectTemplateFile))
	}

	t.AddParseTree("preview", previewTemplate.Tree)
	t.AddParseTree("object", objectTemplate.Tree)
}

func getEmptyTemplate() *template.Template {
	return template.Must(template.New("").Parse(""))
}

func prepareDateTime(nc *NotificationContainer) (string, string) {
	layoutDate := "Jan 02"
	layoutTime := "15:04"

	return nc.Notification.ActivatedAt.Format(layoutDate),
		nc.Notification.ActivatedAt.Format(layoutTime)
}

func prepareSubject(nc *NotificationContainer) string {
	t, err := nc.Content.GetContentType()
	if err != nil {
		return ""
	}

	return t.GetDefinition()
}
