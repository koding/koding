// Package sender provides an API for mail sending operations
package sender

// Mail struct hold the required parameters for sending an email
type Mail struct {
	To      string
	ToName  string
	Subject string
	Text    string
	// TODO maybe we can remove this HTML field
	HTML     string
	From     string
	Bcc      string
	FromName string
	ReplyTo  string
}

func (m Mail) GetId() int64 {
	return 0
}

func (m Mail) BongoName() string {
	return "api.mail"
}
