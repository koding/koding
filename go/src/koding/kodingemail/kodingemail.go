package kodingemail

import (
	"github.com/sendgrid/sendgrid-go"
	"github.com/sendgrid/smtpapi-go"
)

var (
	DefaultFromAddress = "support@koding.com"
	DefaultFromName    = "Koding"
)

type Client interface {
	Send(*sendgrid.SGMail) error
}

type SG struct {
	FromAddress, FromName string
	Client                Client
}

func InitializeSG(username, password string) *SG {
	return &SG{
		FromAddress: DefaultFromAddress, FromName: DefaultFromName,
		Client: sendgrid.NewSendGridClient(username, password),
	}
}

func (s *SG) SendTemplateEmail(to, tId string, sub Options) error {
	message := sendgrid.NewMail()

	// sendgrid api requries not empty value, but I decided to put
	// all the required info in template itself
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
	message.AddTo(to)

	return s.Client.Send(message)
}
