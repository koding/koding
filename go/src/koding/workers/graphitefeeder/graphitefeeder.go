package main

import (
	"flag"
	"fmt"
	"koding/db/mongodb"
	"koding/tools/config"
	"koding/tools/logger"
	"os"
	"strconv"
	"time"

	"github.com/peterbourgon/g2s"
)

var (
	ip     = config.Current.Statsd.Ip
	port   = config.Current.Statsd.Port
	STATSD g2s.Statter

	mongo         *mongodb.MongoDB
	configProfile string
	flagSet       *flag.FlagSet
	log           = logger.New("graphitefeeder")
)

func init() {
	var err error

	STATSD, err = g2s.Dial("udp", fmt.Sprintf("%v:%v", ip, port))
	if err != nil {
		panic(err)
	}

	flagSet = flag.NewFlagSet("graphitefeeder", flag.ContinueOnError)
	flagSet.StringVar(&configProfile, "c", "", "Configuration profile from file")
}

func main() {
	flagSet.Parse(os.Args)
	if configProfile == "" {
		log.Fatal("Please define config file with -c")
	}

	c := config.MustConfig(configProfile)
	mongo = mongodb.NewMongoDB(c.Mongo)

	l := logger.GetLoggingLevelFromConfig("graphitefeeder", c.Environment)
	log.SetLevel(l)

	for _, fn := range listOfAnalytics {
		name, count := fn()
		log.Info("%v %v", name, count)
		STATSD.Gauge(1, name, strconv.Itoa(count))
	}
}

var listOfAnalytics = make([]func() (string, int), 0)

func registerAnalytic(fn func() (string, int)) {
	listOfAnalytics = append(listOfAnalytics, fn)
}

//----------------------------------------------------------
// Helpers
//----------------------------------------------------------

var currentTimeLocation = time.UTC

func getTodayDate() time.Time {
	year, month, day := time.Now().Date()
	return time.Date(year, month, day, 0, 0, 0, 0, currentTimeLocation)
}
