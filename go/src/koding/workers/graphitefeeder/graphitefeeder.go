package main

import (
	"fmt"
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
