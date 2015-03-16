package main

import (
	"fmt"
	"socialapi/config"
	"socialapi/workers/email/sender"

	"github.com/koding/runner"
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

	appConfig := config.MustRead(r.Conf.Path)
	sg := sendgrid.NewSendGridClient(appConfig.Email.Username, appConfig.Email.Password)
	sgm := &sender.SendGridMail{
		Sendgrid: sg,
	}

	constructor := sender.New(r.Log, sgm)
	constructor.ForcedRecipient = appConfig.Email.ForcedRecipient

	r.SetContext(constructor)
	r.Register(sender.Mail{}).On("send").Handle((*sender.Controller).Process)
	r.Listen()
	r.Wait()
}
