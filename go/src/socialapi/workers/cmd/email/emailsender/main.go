package main

import (
	"log"
	"socialapi/workers/common/runner"
	"socialapi/workers/email/emailsender"

	"github.com/koding/eventexporter"
)

var (
	Name               = "MailSender"
	DefaultQueueLength = 1
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		log.Fatal(err)
	}

	exporter := eventexporter.NewSegementIOExporter("", DefaultQueueLength)

	constructor := emailsender.New(exporter, r.Log)
	constructor.ForcedRecipient = r.Conf.Email.ForcedRecipient

	r.SetContext(constructor)

	r.Register(emailsender.Mail{}).On(emailsender.SendEmailEventName).Handle(
		(*emailsender.Controller).Process)

	r.Listen()
	r.Wait()
}
