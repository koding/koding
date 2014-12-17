package emailmodels

import (
	"errors"
	"fmt"
	"socialapi/models"

	"github.com/sendgrid/sendgrid-go"
)

type Mailer struct {
	UserContact   *UserContact
	Body          string
	Subject       string
	EmailSettings *EmailSettings
	Information   string
}

func NewMailer(a *models.Account, es *EmailSettings) (*Mailer, error) {
	// Fetch user contact
	uc, err := FetchUserContactWithToken(a.Id)
	if err != nil {
		return nil, err
	}

	return &Mailer{
		UserContact:   uc,
		EmailSettings: es,
	}, nil
}

func (m *Mailer) SendMail(contentType, body, subject string) error {
	m.Body = body
	m.Subject = subject

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

	m.Body = content

	sg := sendgrid.NewSendGridClient(m.EmailSettings.Username, m.EmailSettings.Password)
	fullname := fmt.Sprintf("%s %s", m.UserContact.FirstName, m.UserContact.LastName)

	message := sendgrid.NewMail()
	message.AddTo(m.getRecipient())
	message.AddToName(fullname)
	message.SetSubject(m.Subject)
	message.SetHTML(m.Body)
	message.SetFrom(m.EmailSettings.DefaultFromMail)
	message.SetFromName(m.EmailSettings.DefaultFromName)

	if err := sg.Send(message); err != nil {
		return fmt.Errorf("an error occurred while sending notification email to %s: %s", m.UserContact.Username, err)
	}

	return nil
}

func (m *Mailer) prepareContentWithLayout(contentType string) (string, error) {
	lc := NewLayoutContent(m.UserContact, contentType, m.Body)
	lc.Information = m.Information

	return lc.Render()
}

func (m *Mailer) getRecipient() string {
	if m.EmailSettings.ForcedRecipient != "" {
		return m.EmailSettings.ForcedRecipient
	}

	return m.UserContact.Email
}

func (m *Mailer) validateMailer() error {
	if m.Body == "" {
		return errors.New("Mailer body is not set")
	}

	if m.Subject == "" {
		return errors.New("Mailer subject is not set")
	}

	if m.EmailSettings == nil {
		return errors.New("Mailer email settings is not set")
	}

	if m.UserContact == nil {
		return errors.New("User contact settings is not set")
	}

	return nil
}
