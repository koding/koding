package main

import (
	"flag"
	"fmt"

	"socialapi/config"
	"socialapi/workers/helper"
	"socialapi/workers/topicfeed/topicfeed"
	"github.com/koding/worker"
)

var (
	flagConfFile = flag.String("c", "", "Configuration file")
	flagDebug    = flag.Bool("d", false, "Debug mode")
)

func main() {
	flag.Parse()
	if *flagConfFile == "" {
		fmt.Println("Please define config file with -c", "Exiting...")
		return
	}

	conf := config.MustRead(*flagConfFile)

	// create logger for our package
	log := helper.CreateLogger("TopicFeedWorker", *flagDebug)

	// panics if not successful
	bongo := helper.MustInitBongo(conf, log)
	// do not forgot to close the bongo connections
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
