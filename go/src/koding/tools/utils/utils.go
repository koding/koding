package utils

import (
	"flag"
	"fmt"
	"koding/tools/config"
	"koding/tools/log"
	"math/rand"
	"os"
	"runtime"
	"time"
	"unicode/utf8"
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

	var profile string
	flag.StringVar(&profile, "c", "", "Configuration profile")
	flag.BoolVar(&log.LogDebug, "d", false, "Log debug messages")

	flag.Parse()
	if flag.NArg() != 0 {
		flag.PrintDefaults()
		os.Exit(1)
	}
	if profile == "" {
		fmt.Println("Please specify a configuration profile (-c).")
		flag.PrintDefaults()
		os.Exit(1)
	}

	config.LoadConfig(profile)

	log.Init(serviceName, profile)
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
				log.Info(fmt.Sprintf("Shutting down, still %d clients.", numClients), fmt.Sprintf("Number of goroutines: %d"))
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

func FilterInvalidUTF8(buf []byte) []byte {
	i := 0
	j := 0
	for {
		r, l := utf8.DecodeRune(buf[i:])
		if l == 0 {
			break
		}
		if r < 0xD800 {
			if i != j {
				copy(buf[j:], buf[i:i+l])
			}
			j += l
		}
		i += l
	}
	return buf[:j]
}
