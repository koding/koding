package main

import (
	"flag"
	"socialapi/config"
	followingfeed "socialapi/workers/followingfeed/lib"
	"socialapi/workers/helper"

	"github.com/koding/bongo"
	"github.com/koding/logging"
	"github.com/koding/worker"
)

var (
	Bongo       *bongo.Bongo
	log         logging.Logger
	conf        *config.Config
	flagProfile = flag.String("c", "", "Configuration profile from file")
	flagDebug   = flag.Bool("d", false, "Debug mode")
	handler     *followingfeed.FollowingFeedController
)

func main() {
	flag.Parse()
	if *flagProfile == "" {
		log.Fatal("Please define config file with -c", "")
	}

	conf = config.Read(*flagProfile)

	// create logger for our package
	log = helper.CreateLogger("TopicFeedWorker", *flagDebug)

	// panics if not successful
	Bongo = helper.MustInitBongo(conf, log)
	// do not forgot to close the bongo connection
	defer Bongo.Close()

	// create message handler
	handler = followingfeed.NewFollowingFeedController(log)

	listener := worker.NewListener("FollowingFeed", conf.EventExchangeName, log)
	// blocking
	// listen for events
	listener.Listen(helper.NewRabbitMQ(conf, log), handler)
	// close consumer
	defer listener.Close()
}
