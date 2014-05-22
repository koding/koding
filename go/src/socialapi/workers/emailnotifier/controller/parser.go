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

func renderTemplate(uc *UserContact, nc *NotificationContainer) (string, error) {
	t := template.Must(template.ParseFiles(
		mainTemplateFile, footerTemplateFile, contentTemplateFile,
		gravatarTemplateFile, unsubscribeTemplateFile))
	mc, err := buildMailContent(uc, nc)
	t = appendPreviewTemplate(t, nc)
	t = appendGroupTemplate(t, nc)

	if err != nil {
		return "", err
	}

	var doc bytes.Buffer
	if err := t.Execute(&doc, mc); err != nil {
		return "", err
	}

	return doc.String(), nil
}

func buildMailContent(uc *UserContact, nc *NotificationContainer) (*MailContent, error) {
	mc := &MailContent{
		FirstName:   uc.FirstName,
		Size:        20,
		Slug:        nc.Slug,
		Message:     nc.Message,
		Action:      nc.ActivityMessage,
		ObjectType:  nc.ObjectType,
		Group:       nc.Group,
		Token:       nc.Token,
		ContentType: nc.Content.TypeConstant,
		Recipient:   url.QueryEscape(uc.Email),
	}

	mc.CurrentDate, mc.ActivityTime = prepareDateTime(nc)
	mc.Uri = config.Get().Uri

	actor, err := fetchUserContact(nc.Activity.ActorId)
	if err != nil {
		return nil, fmt.Errorf("an error occurred while retrieving actor details", err)
	}
	mc.ActorContact = *actor

	return mc, nil
}

func appendGroupTemplate(t *template.Template, nc *NotificationContainer) *template.Template {
	var groupTemplate *template.Template
	if nc.Group.Name == "" || nc.Group.Slug == "koding" {
		groupTemplate = getEmptyTemplate()
	} else {
		groupTemplate = template.Must(
			template.ParseFiles(groupTemplateFile))
	}

	t.AddParseTree("group", groupTemplate.Tree)

	return t
}

func appendPreviewTemplate(t *template.Template, nc *NotificationContainer) *template.Template {
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

	return t
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
