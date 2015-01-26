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
	SendTemplateEmail(string, string, Options) error
}

type SenderClient interface {
	Send(*sendgrid.SGMail) error
}

type SG struct {
	FromAddress, FromName string
	SenderClient          SenderClient
}

func Initialize(username, password string) Client {
	return InitializeSG(username, password)
}

func InitializeSG(username, password string) *SG {
	return &SG{
		FromAddress: DefaultFromAddress, FromName: DefaultFromName,
		SenderClient: sendgrid.NewSendGridClient(username, password),
	}
}

func (s *SG) SendTemplateEmail(to, tId string, sub Options) error {
	message := sendgrid.NewMail()

	// sendgrid api requries non empty values, but I decided to put
	// all the required info in template itself since it's easier to
	// edit in sendgrid ui than to edit in code and redeploy
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
