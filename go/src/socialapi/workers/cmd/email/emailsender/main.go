package main

import (
	"fmt"
	"socialapi/workers/common/runner"
	"socialapi/workers/email/sender"

	"github.com/sendgrid/sendgrid-go"
)

var (
	Name = "MailSender"
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	sg := sendgrid.NewSendGridClient(r.Conf.Email.Username, r.Conf.Email.Password)
	sgm := &sender.SendGridMail{
		Sendgrid: sg,
	}

	constructor := sender.New(r.Log, sgm)
	constructor.ForcedRecipient = r.Conf.Email.ForcedRecipient

	r.SetContext(constructor)
	r.Register(sender.Mail{}).On("send").Handle((*sender.Controller).Process)
	r.Listen()
	r.Wait()
}
