package main

import (
	"flag"
	"koding/db/mongodb/modelhelper"
	"koding/tools/config"
	"koding/tools/logger"
	"koding/workers/topicmodifier"
	"os"
	"os/signal"
	"syscall"

	"github.com/robfig/cron"
)

var (
	log           = logger.New("go-cron")
	configProfile = flag.String("c", "", "Configuration profile from file")
	Cron          *cron.Cron
)

// later on this could be implemented as kite, and then we will no longer need hard coded
// method scheduling. Service just calls addFunc and registers itself
func init() {
	Cron = cron.New()
}

func main() {
	flag.Parse()
	if *configProfile == "" {
		log.Fatal("Please define config file with -c")
	}

	conf := config.MustConfig(*configProfile)

	// needed for topicModifer until it's done.
	modelhelper.Initialize(conf.Mongo)
	log.Notice("Starting Cron Scheduler")

	addFunc(conf.TopicModifier.CronSchedule, func() { topicmodifier.ConsumeMessage(conf) })

	Cron.Start()
	registerSignalHandler()
}

func registerSignalHandler() {
	signals := make(chan os.Signal, 1)
	signal.Notify(signals)
	for {
		signal := <-signals
		switch signal {
		case syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT, syscall.SIGSTOP:
			shutdown()
		}
	}
}

func addFunc(spec string, cmd func()) {
	Cron.AddFunc(spec, cmd)
}

func shutdown() {
	Cron.Stop()
	log.Notice("Stopping it")
	err := topicmodifier.Shutdown()
	if err != nil {
		panic(err)
	}
	os.Exit(1)
}
