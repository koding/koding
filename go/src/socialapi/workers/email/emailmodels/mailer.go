package emailmodels

import (
	"errors"
	"fmt"
	"socialapi/models"
	"socialapi/workers/email/sender"
)

type Mailer struct {
	UserContact   *UserContact
	Mail          *sender.Mail
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
	m.Mail.Text = content
	m.Mail.To = m.getRecipient()
	m.Mail.ToName = fullname

	if err := sender.Send(m.Mail); err != nil {
		return err
	}

	return nil

}

func (m *Mailer) prepareContentWithLayout(contentType string) (string, error) {
	lc := NewLayoutContent(m.UserContact, contentType, m.Mail.Text)
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
	if m.Mail.Text == "" {
		return errors.New("Mailer body is not set")
	}

	if m.Mail.Subject == "" {
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
