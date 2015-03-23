package main

import (
	"log"
	"socialapi/workers/common/runner"
	"socialapi/workers/email/emailsender"

	"github.com/koding/eventexporter"
)

var (
	Name        = "MailSender"
	QueueLength = 1

	// TODO: move this to config
	SegmentIOKey = "kb2hfdgf20"
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		log.Fatal(err)
	}

	exporter := eventexporter.NewSegmentIOExporter(SegmentIOKey, QueueLength)
	constructor := emailsender.New(exporter, r.Log)

	r.SetContext(constructor)

	r.Register(emailsender.Mail{}).On(emailsender.SendEmailEventName).Handle(
		(*emailsender.Controller).Process)

	r.Listen()
	r.Wait()
}
