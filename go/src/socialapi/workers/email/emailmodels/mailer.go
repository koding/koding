package emailmodels

import (
	"errors"
	"fmt"
	"socialapi/models"
	"socialapi/workers/email/emailsender"
)

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
		Mail:        new(sender.Mail),
	}, nil
}

func (m *Mailer) SendMail(contentType, body, subject string) error {
	if m.Mail == nil {
		m.Mail = new(sender.Mail)
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
	m.Mail.Text = content
	m.Mail.To = m.UserContact.Email
	m.Mail.ToName = fullname

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
