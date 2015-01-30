package kodingemail

import (
	"github.com/sendgrid/sendgrid-go"
	"github.com/sendgrid/smtpapi-go"
)

var (
	DefaultFromAddress = "support@koding.com"
	DefaultFromName    = "Koding"
)

// The default interface to send emails.
type Client interface {
	SendTemplateEmail(string, string, Options) error
}

func New(username, password string) Client {
	return New(username, password)
}

// This interface defines the implementation of those sending emails.
type SenderClient interface {
	Send(*sendgrid.SGMail) error
}

// Sengrid implementation of `Client`.
type SG struct {
	FromAddress, FromName string
	SenderClient          SenderClient
}

func NewSG(username, password string) *SG {
	return &SG{
		FromAddress: DefaultFromAddress, FromName: DefaultFromName,
		SenderClient: sendgrid.NewSendGridClient(username, password),
	}
}

func (s *SG) SendTemplateEmail(to, tId string, sub Options) error {
	message := sendgrid.NewMail()

	// sendgrid api requries non empty values, but subject and html are
	// in template itself so it's easier to manage; to get around the
	// api validation, space is being used
	message.SetSubject(" ")
	message.SetHTML(" ")

	for key, value := range sub {
		message.AddSubstitution(key, value)
	}

	filter := &smtpapi.Filter{
		Settings: map[string]string{"enabled": "1", "template_id": tId},
	}

	message.SetFilter("templates", filter)
	message.SetFrom(s.FromAddress)
	message.SetFromName(s.FromName)

	message.AddTo(to)

	return s.SenderClient.Send(message)
}
