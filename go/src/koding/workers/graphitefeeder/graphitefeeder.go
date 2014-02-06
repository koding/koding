package main

import (
	"flag"
	"fmt"
	"koding/db/mongodb"
	"koding/tools/config"
	"koding/tools/logger"
	"strconv"
	"time"

	"github.com/marpaia/graphite-golang"
	"github.com/peterbourgon/g2s"
)

var (
	ip     string
	port   string
	log    = logger.New("graphitefeeder")
	STATSD g2s.Statter
	conf   *config.Config

	mongo         *mongodb.MongoDB
	log           = logger.New("graphitefeeder")
	configProfile = flag.String("c", "", "Configuration profile from file")
)

func init() {
	var err error

	STATSD, err = g2s.Dial("udp", fmt.Sprintf("%v:%v", ip, port))
	if err != nil {
		panic(err)
	}
}

func main() {
	flag.Parse()
	if *configProfile == "" {
		log.Fatal("Please define config file with -c")
	}

	conf = config.MustConfig(*configProfile)
	mongo = mongodb.NewMongoDB(conf.Mongo)

	l := logger.GetLoggingLevelFromConfig("graphitefeeder", *configProfile)
	log.SetLevel(l)

	ip = conf.Statsd.Ip
	port = conf.Statsd.Port

	for _, fn := range listOfAnalytics {
		name, count := fn()
		log.Info("Name: %v, Count: %v", name, count)
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

func PublishToGraphite(name string, value int, timestamp int64) error {
	log.Info("Publishing to graphite: name:%v, value:%v, timestamp:%v",
		name, value, timestamp)

	var graphiteServer *graphite.Graphite
	var ts int64
	var err error

	var host = conf.Graphite.Host
	var port = conf.Graphite.Port

	if !config.Current.Graphite.Use {
		return nil
	}

	graphiteServer, err = graphite.NewGraphite(host, port)
	if err != nil {
		log.Error("Publish to graphite failed: %v", err)
		return err
	}

	if timestamp == 0 {
		ts = time.Now().Unix()
	} else {
		ts = timestamp
	}

	metric := graphite.Metric{Name: name, Value: strconv.Itoa(value), Timestamp: ts}

	graphiteServer.SendMetric(metric)

	return nil
}
