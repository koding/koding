// Package sender provides an API for mail sending operations
package sender

import (
	"fmt"

	"github.com/sendgrid/sendgrid-go"
)

// SendGridMail includes the required Sendgrid struct
type SendGridMail struct {
	Sendgrid *sendgrid.SGClient
}

// Send implements Emailer interface
func (sg *SendGridMail) Send(m *Mail) error {
	message := sendgrid.NewMail()

	if err := message.AddTo(m.To); err != nil {
		return err
	}

	if err := message.SetFrom("mail@koding.com"); err != nil {
		return err
	}

	if m.From != "" {
		message.SetFrom(m.From)
	}

	message.SetText(m.Text)
	message.SetHTML(m.HTML)
	message.SetSubject(m.Subject)
	message.SetFromName(m.FromName)
	if m.ReplyTo != "" {
		if err := message.SetReplyTo(m.ReplyTo); err != nil {
			return err
		}
	}

	if err := sg.Sendgrid.Send(message); err != nil {
		return fmt.Errorf("an error occurred while sending email error as %+v ", err.Error())
	}

	return nil
}
