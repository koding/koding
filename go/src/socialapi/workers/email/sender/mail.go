package sender

type Mail struct {
	To       string
	Subject  string
	Text     string
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
