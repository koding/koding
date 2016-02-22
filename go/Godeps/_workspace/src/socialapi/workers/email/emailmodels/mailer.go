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

	fullname := fmt.Sprintf("%s %s", m.UserContact.FirstName, m.UserContact.LastName)
	m.Mail.To = m.UserContact.Email
	m.Mail.ToName = fullname

	m.Mail.Properties = emailsender.NewProperties()
	m.Mail.Properties.Username = m.UserContact.Username

	if err := emailsender.Send(m.Mail); err != nil {
		return err
	}

	return nil

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
	mail.Subject = m.MessageType
	mail.To = m.Email

	mail.Properties = emailsender.NewProperties()
	mail.Properties.Username = m.Username

	mail.Properties.Options = m.ToMap()

	return emailsender.Send(mail)
}
