// Package sender provides an API for mail sending operations
package sender

import "github.com/sendgrid/sendgrid-go"

// SendGridMail includes the required Sendgrid struct
type SendGridMail struct {
	Sendgrid *sendgrid.SGClient
}

const fromDefault = "mail@koding.com"

// Send implements Emailer interface
func (sg *SendGridMail) Send(m *Mail) error {
	message := sendgrid.NewMail()

	if err := message.AddTo(m.To); err != nil {
		return err
	}

	from := m.From
	if from == "" {
		from = fromDefault
	}

	if err := message.SetFrom(from); err != nil {
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
		return err
	}

	return nil
}
