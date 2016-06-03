package main

import (
	"koding/db/mongodb/modelhelper"
	"log"
	"socialapi/config"
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

	// TODO
	// this lines will not be commentout
	// datadogExporter := eventexporter.NewDatadogExporter(r.DogStatsD)

	// TODO
	// use config file for druid address
	// open this line !!
	// druidExporter := eventexporter.NewDruidExporter("address")

	// TODO
	//open this line also!!!
	// exporter := eventexporter.NewMultiExporter(segmentExporter, datadogExporter, druidExporter)
	exporter := eventexporter.NewMultiExporter(segmentExporter)

	constructor := emailsender.New(exporter, r.Log, appConfig)
	r.ShutdownHandler = constructor.Close

	r.SetContext(constructor)

	r.Register(emailsender.Mail{}).On(emailsender.SendEmailEventName).Handle((*emailsender.Controller).Process)

	r.Listen()
	r.Wait()
}
