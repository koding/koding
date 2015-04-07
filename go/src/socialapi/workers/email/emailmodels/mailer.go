package emailmodels

import (
	"errors"
	"fmt"
	"socialapi/models"
	"socialapi/workers/email/emailsender"
	"time"
)

const VERSION = " v1"

type Mailer struct {
	UserContact *UserContact
	Mail        *emailsender.Mail
	Information string
}

func NewMailer(a *models.Account) (*Mailer, error) {
	// Fetch user contact
	uc, err := FetchUserContactWithToken(a.Id)
	if err != nil {
		return nil, err
	}

	return &Mailer{
		UserContact: uc,
		Mail:        emailsender.NewEmptyMail(),
	}, nil
}

func (m *Mailer) SendMail(contentType, body, subject string) error {
	if m.Mail == nil {
		m.Mail = emailsender.NewEmptyMail()
	}

	m.Mail.Text = body
	m.Mail.Subject = subject

	if err := m.validateMailer(); err != nil {
		return err
	}

	if err := m.UserContact.GenerateToken(contentType); err != nil {
		return err
	}

	content, err := m.prepareContentWithLayout(contentType)
	if err != nil {
		return err
	}

	fullname := fmt.Sprintf("%s %s", m.UserContact.FirstName, m.UserContact.LastName)
	m.Mail.HTML = content
	m.Mail.To = m.UserContact.Email
	m.Mail.ToName = fullname

	m.Mail.Properties = emailsender.NewProperties()
	m.Mail.Properties.Username = m.UserContact.Username

	if err := emailsender.Send(m.Mail); err != nil {
		return err
	}

	return nil

}

func (m *Mailer) prepareContentWithLayout(contentType string) (string, error) {
	lc := NewLayoutContent(m.UserContact, contentType, m.Mail.Text)
	lc.Information = m.Information

	return lc.Render()
}

func (m *Mailer) validateMailer() error {
	if m.Mail.Text == "" {
		return errors.New("Mailer body is not set")
	}

	if m.Mail.Subject == "" {
		return errors.New("Mailer subject is not set")
	}

	if m.UserContact == nil {
		return errors.New("User contact settings is not set")
	}

	return nil
}

func (m *MailerNotification) SendMail() error {
	mail := emailsender.NewEmptyMail()
	mail.Subject = m.MessageType + VERSION
	mail.To = m.Email

	mail.Properties = emailsender.NewProperties()
	mail.Properties.Username = m.Username

	mail.Properties.Options = m.ToMap()

	return emailsender.Send(mail)
}

type MailerNotification struct {
	FirstName   string
	Username    string
	Email       string
	MessageType string
	Messages    []*NotificationMessage
}

func (m *MailerNotification) ToMap() map[string]interface{} {
	messages := []map[string]string{}

	for _, msg := range m.Messages {
		messages = append(messages, msg.ToMap())
	}

	return map[string]interface{}{
		"messages": messages, "firstName": m.FirstName,
	}
}

type NotificationMessage struct {
	CreatedAt       time.Time
	Actor           string
	Message         string
	ActivityMessage string
	ObjectType      string
	TimezoneOffset  int
}

func (n *NotificationMessage) ToMap() map[string]string {
	return map[string]string{
		"createdAt":       formatMessageCreatedAt(n.CreatedAt, n.TimezoneOffset),
		"actor":           n.Actor,
		"message":         n.Message,
		"activityMessage": n.ActivityMessage,
		"objectType":      n.ObjectType,
	}
}

func formatMessageCreatedAt(createdAt time.Time, timezoneOffset int) string {
	loc := time.FixedZone("", timezoneOffset*-60)

	createdDate := createdAt
	if loc != nil {
		createdDate = createdDate.In(loc)
	}

	return createdDate.Format(TimeLayout)
}
