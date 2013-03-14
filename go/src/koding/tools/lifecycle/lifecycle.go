package lifecycle

import (
	"fmt"
	"koding/tools/config"
	"koding/tools/log"
	"math/rand"
	"os"
	"runtime"
	"time"
)

var version string
var numClients int = 0
var ChangeNumClients chan int = make(chan int)
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

	go func() {
		for {
			numClients += <-ChangeNumClients
			if ShuttingDown && numClients == 0 {
				log.Info("Shutdown complete. Terminating.")
				os.Exit(0)
			}
		}
	}()
}

func BeginShutdown() {
	ShuttingDown = true
	ChangeNumClients <- 0
	log.Info("Beginning shutdown.")
}

func RunStatusLogger() {
	go func() {
		for {
			if ShuttingDown {
				log.Info(fmt.Sprintf("Shutting down, still %d clients.", numClients))
			}
			var m runtime.MemStats
			runtime.ReadMemStats(&m)
			log.Gauges(map[string]float64{
				"clients":    float64(numClients),
				"goroutines": float64(runtime.NumGoroutine()),
				"memory":     float64(m.Alloc),
			})
			time.Sleep(time.Duration(config.Current.Librato.Interval) * time.Millisecond)
		}
	}()
}
