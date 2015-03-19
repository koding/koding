// Package sender provides an API for mail sending operations
package emailsender

// Mail struct hold the required parameters for sending an email
type Mail struct {
	To      string
	ToName  string
	Subject string
	Text    string
	// TODO maybe we can remove this HTML field
	HTML       string
	From       string
	Bcc        string
	FromName   string
	ReplyTo    string
	Properties *Properties
}

type Properties struct {
	Username string
	Options  map[string]interface{}
}

func NewMail(to, from, subject, username string) *Mail {
	options := map[string]interface{}{}
	properties := &Properties{Username: username, Options: options}

	return &Mail{
		To: to, From: from, Subject: subject,
		Properties: properties,
	}
}

func (m Mail) GetId() int64 {
	return 0
}

func (m Mail) BongoName() string {
	return "api.mail"
}
