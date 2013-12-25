package main

import (
	"fmt"
	"github.com/marpaia/graphite-golang"
	"github.com/peterbourgon/g2s"
	"koding/tools/config"
	"log"
	"strconv"
	"time"
)

var (
	ip     = config.Current.Statsd.Ip
	port   = config.Current.Statsd.Port
	STATSD g2s.Statter
)

func init() {
	var err error

	STATSD, err = g2s.Dial("udp", fmt.Sprintf("%v:%v", ip, port))
	if err != nil {
		panic(err)
	}
}

func PublishToGraphite(name string, value int, timestamp int64) error {
	log.Info("publishing to graphite. ", name, value, timestamp)

	var graphiteServer *graphite.Graphite
	var ts int64
	var err error

	if config.Current.Graphite.Use {
		graphiteServer, err = graphite.NewGraphite(config.Current.Graphite.Host, config.Current.Graphite.Port)
		if err != nil {
			fmt.Println("error connecting to graphite, falling back to noop: ", err)
			graphiteServer = graphite.NewGraphiteNop(config.Current.Graphite.Host, config.Current.Graphite.Port)
		}
	} else {
		graphiteServer = graphite.NewGraphiteNop(config.Current.Graphite.Host, config.Current.Graphite.Port)
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

func main() {
	for _, fn := range listOfAnalytics {
		name, count := fn()
		log.Println(name, count)
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
