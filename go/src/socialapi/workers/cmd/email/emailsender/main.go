package main

import (
	"koding/db/mongodb/modelhelper"
	"log"
	"socialapi/workers/common/runner"
	"socialapi/workers/email/emailsender"

	"github.com/koding/eventexporter"
)

var (
	Name        = "MailSender"
	QueueLength = 1
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		log.Fatal(err)
	}

	modelhelper.Initialize(r.Conf.Mongo)

	exporter := eventexporter.NewSegmentIOExporter(r.Conf.Segment, QueueLength)
	constructor := emailsender.New(exporter, r.Log)

	r.SetContext(constructor)

	r.Register(emailsender.Mail{}).On(emailsender.SendEmailEventName).Handle(
		(*emailsender.Controller).Process)

	r.Listen()
	r.Wait()
}
