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

func CreateClientsGauge() func(int) {
	value := new(int)
	log.CreateGauge("clients", log.NoUnit, func() float64 { return float64(*value) })
	changeClientsGauge = func(diff int) {
		log.GaugeChanges <- func() {
			*value += diff
		}
	}
	return changeClientsGauge
}
