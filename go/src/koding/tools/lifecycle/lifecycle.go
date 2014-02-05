package lifecycle

import (
	"koding/tools/logger"
	"math/rand"
	"os"
	"runtime"
	"time"
)

var (
	log                logger.Log
	version            string
	changeClientsGauge func(int)
)

func Startup(serviceName, profile string, needRoot bool) {
	log = logger.New(serviceName)

	if needRoot && os.Getuid() != 0 {
		log.Fatal("Must be run as root.")
	}

	runtime.GOMAXPROCS(runtime.NumCPU())
	rand.Seed(time.Now().UnixNano())

	log.Notice("Process '%v' started (version '%v').", serviceName, version)
}

func CreateClientsGauge() func(int) {
	value := new(int)
	logger.CreateGauge("clients", logger.NoUnit, func() float64 { return float64(*value) })
	changeClientsGauge = func(diff int) {
		logger.GaugeChanges <- func() {
			*value += diff
		}
	}
	return changeClientsGauge
}
