// +build segment

package eventexporter

import sendgrid "github.com/sendgrid/sendgrid-go"

const (
	DefaultFromName    = "Koding"
	DefaultFromAddress = "hello@koding.com"
)

type SendgridExporter struct {
	Client *sendgrid.SGClient
}

func NewSendgridExporter(username, password string) *SendgridExporter {
	return &SendgridExporter{
		Client: sendgrid.NewSendGridClient(username, password),
	}
}

func (s *SendgridExporter) Send(event *Event) error {
	var err error

	mail := sendgrid.NewMail()
	if mail, err = setTo(mail, event); err != nil {
		return err
	}

	if mail, err = setFrom(mail, event); err != nil {
		return err
	}

	if mail, err = setBody(mail, event); err != nil {
		return err
	}

	if mail, err = setSubject(mail, event); err != nil {
		return err
	}

	return s.Client.Send(mail)
}

func (s *SendgridExporter) Close() error {
	return nil
}

func setTo(mail *sendgrid.SGMail, event *Event) (*sendgrid.SGMail, error) {
	err := mail.AddTo(event.User.Email)
	if err != nil {
		return nil, err
	}

	return mail, nil
}

func setFrom(mail *sendgrid.SGMail, event *Event) (*sendgrid.SGMail, error) {
	from, ok := event.Properties["from"]
	if !ok {
		from = DefaultFromAddress
	}

	if err := mail.SetFrom(from.(string)); err != nil {
		return nil, err
	}

	fromName, ok := event.Properties["fromName"]
	if !ok {
		fromName = DefaultFromName
	}

	mail.SetFromName(fromName.(string))

	return mail, nil
}

func setBody(mail *sendgrid.SGMail, event *Event) (*sendgrid.SGMail, error) {
	if event.Body == nil {
		return nil, ErrSendgridBodyEmpty
	}

	bodyType := event.Body.Type
	switch bodyType {
	case HtmlBodyType:
		mail.SetHTML(event.Body.Content)
	case TextBodyType:
		mail.SetText(event.Body.Content)
	}

	return mail, nil
}

func setSubject(mail *sendgrid.SGMail, event *Event) (*sendgrid.SGMail, error) {
	mail.SetSubject(event.Name)
	return mail, nil
}
