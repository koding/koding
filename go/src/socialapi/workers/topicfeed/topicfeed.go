package main

import (
	"flag"

	"socialapi/config"
	"socialapi/workers/helper"
	topicfeed "socialapi/workers/topicfeed/lib"
	"github.com/koding/worker"
)

var (
	flagProfile = flag.String("c", "", "Configuration profile from file")
	flagDebug   = flag.Bool("d", false, "Debug mode")
)

func main() {
	flag.Parse()
	if *flagProfile == "" {
		panic("Please define config file with -c")
	}

	conf := config.Read(*flagProfile)

	// create logger for our package
	log := helper.CreateLogger("TopicFeedWorker", *flagDebug)

	// panics if not successful
	bongo := helper.MustInitBongo(conf, log)
	// do not forgot to close the bongo connection
	defer bongo.Close()

	// create message handler
	handler := topicfeed.NewTopicFeedController(log)

	listener := worker.NewListener("TopicFeed", conf.EventExchangeName, log)
	// blocking
	// listen for events
	listener.Listen(helper.NewRabbitMQ(conf, log), handler)
	// close consumer
	defer listener.Close()
}
