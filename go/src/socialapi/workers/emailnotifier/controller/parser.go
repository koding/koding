package emailnotifier

import (
	"bytes"
	"fmt"
	"html/template"
	"socialapi/config"
	"socialapi/workers/notification/models"
)

type NotificationContainer struct {
	Activity        *models.NotificationActivity
	Content         *models.NotificationContent
	Notification    *models.Notification
	Message         string
	Slug            string
	ActivityMessage string
}

type MailContent struct {
	TurnOffLink  string
	CurrentDate  string
	FirstName    string
	Description  string
	Size         int
	Uri          string
	ActorContact UserContact
	// event content
	ActivityTime string
	Avatar       string
	Sender       string
	Action       string
	ContentLink  string
	Group        string
	Preview      string
	Slug         string
}

func renderTemplate(uc *UserContact, nc *NotificationContainer) (string, error) {
	// TODO change this directory structure
	t := template.Must(template.ParseFiles(
		"../socialapi/workers/emailnotifier/templates/main.tmpl",
		"../socialapi/workers/emailnotifier/templates/footer.tmpl",
		"../socialapi/workers/emailnotifier/templates/content.tmpl",
		"../socialapi/workers/emailnotifier/templates/gravatar.tmpl",
		"../socialapi/workers/emailnotifier/templates/preview.tmpl"))
	mc, err := buildMailContent(uc, nc)
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
		FirstName: uc.FirstName,
		Size:      20,
		Preview:   nc.Message,
		Slug:      nc.Slug,
		Action:    nc.ActivityMessage,
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
