package kodingemail

import "github.com/sendgrid/sendgrid-go"

type SenderTestClient struct {
	Mail *sendgrid.SGMail
}

func (s *SenderTestClient) Send(mail *sendgrid.SGMail) error {
	s.Mail = mail
	return nil
}
