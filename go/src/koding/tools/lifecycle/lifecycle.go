package lifecycle

import (
	"fmt"
	"koding/tools/log"
	"math/rand"
	"os"
	"runtime"
	"time"
)

var version string
var changeClientsGauge func(int)
var ShuttingDown bool = false

func Startup(serviceName string, needRoot bool) {
	if needRoot && os.Getuid() != 0 {
		fmt.Println("Must be run as root.")
		os.Exit(1)
	}

	runtime.GOMAXPROCS(runtime.NumCPU())
	rand.Seed(time.Now().UnixNano())

	log.Init(serviceName)
	log.Info(fmt.Sprintf("Process '%v' started (version '%v').", serviceName, version))
}

func BeginShutdown() {
	ShuttingDown = true
	changeClientsGauge(0)
	log.Info("Beginning shutdown.")
}

func CreateClientsGauge() func(int) {
	value := new(int)
	log.CreateGauge("clients", func() float64 { return float64(*value) })
	changeClientsGauge = func(diff int) {
		log.GaugeChanges <- func() {
			*value += diff
			if ShuttingDown && *value == 0 {
				log.Info("Shutdown complete. Terminating.")
				log.SendLogsAndExit(0)
			}
		}
	}
	return changeClientsGauge
}
