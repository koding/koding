package models

import (
	"errors"
	"fmt"

	"github.com/sendgrid/sendgrid-go"
)

type Mailer struct {
	UserContact   *UserContact
	Body          string
	Subject       string
	EmailSettings *EmailSettings
}

func NewMailer() *Mailer {
	return &Mailer{}
}

func (m *Mailer) SendMail() error {
	if err := m.validateMailer(); err != nil {
		return err
	}

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
		return fmt.Errorf("an error occurred while sending notification email to %s", m.UserContact.Username)
	}

	return nil
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
