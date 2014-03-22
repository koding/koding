package main

import (
	"flag"
	"koding/messaging/rabbitmq"
	"koding/tools/config"
	"koding/tools/logger"
	realtime "socialapi/workers/realtime/lib"
)

func main() {
	flag.Parse()
	if *flagProfile == "" {
		log.Fatal("Please define config file with -c")
	}

	conf = config.MustConfig(*flagProfile)
	setLogLevel()

	// blocking
	realtime.Listen(rabbitmq.New(conf), startHandler)
	defer realtime.Consumer.Shutdown()
}

func setLogLevel() {
	var logLevel logger.Level

	if *flagDebug {
		logLevel = logger.DEBUG
	} else {
		logLevel = logger.INFO
	}
	log.SetLevel(logLevel)
}
