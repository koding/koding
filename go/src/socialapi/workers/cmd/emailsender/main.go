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

	constructor := sender.New(r.Log, sg)
	r.SetContext(constructor)
	r.Register(sender.Mail{}).On("send").Handle((*sender.Controller).Send)
	r.Listen()
	r.Wait()
}
