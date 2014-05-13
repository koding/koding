package main

import (
	"flag"
	"fmt"
	"github.com/koding/worker"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/workers/helper"
	"socialapi/workers/notification/controller"
)

var (
	flagProfile = flag.String("c", "", "Configuration profile from file")
	flagDebug   = flag.Bool("d", false, "Debug mode")
	Name        = "NotificationWorker"
)

func main() {
	flag.Parse()
	if *flagProfile == "" {
		fmt.Println("Please define config file with -c", "Exiting...")
		return
	}

	conf := config.MustRead(*flagProfile)

	// create logger for our package
	log := helper.CreateLogger("NotificationWorker", *flagDebug)

	// panics if not successful
	bongo := helper.MustInitBongo(Name, conf, log)
	// do not forgot to close the bongo connection
	defer bongo.Close()

	// init mongo connection
	modelhelper.Initialize(conf.Mongo)

	//create connection to RMQ for publishing realtime events
	rmq := helper.NewRabbitMQ(conf, log)

	cacheEnabled := conf.Cache.Notification
	if cacheEnabled {
		// init redis
		redisConn := helper.MustInitRedisConn(conf.Redis)
		defer redisConn.Close()
	}

	handler, err := notification.NewNotificationWorkerController(rmq, log, cacheEnabled)
	if err != nil {
		panic(err)
	}

	listener := worker.NewListener("Notification", conf.EventExchangeName, log)
	// blocking
	// listen for events
	listener.Listen(rmq, handler)
	// close consumer
	defer listener.Close()
}
