package main

import (
	"koding/db/mongodb/modelhelper"
	"log"
	"socialapi/config"
	"socialapi/workers/countly/exporter"
	"socialapi/workers/email/emailsender"

	"github.com/koding/eventexporter"
	"github.com/koding/runner"
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

	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	segmentExporter := eventexporter.NewSegmentIOExporter(appConfig.Segment, QueueLength)
	datadogExporter := eventexporter.NewDatadogExporter(r.DogStatsD)
	countlyExporter := exporter.NewCountlyExporter(appConfig)

	exporter := eventexporter.NewMultiExporter(segmentExporter, datadogExporter, countlyExporter)

	constructor := emailsender.New(exporter, r.Log, appConfig)
	r.ShutdownHandler = constructor.Close

	r.SetContext(constructor)

	r.Register(emailsender.Mail{}).On(emailsender.SendEmailEventName).Handle((*emailsender.Controller).Process)

	r.Listen()
	r.Wait()
}
