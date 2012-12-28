package utils

import (
	"flag"
	"fmt"
	"koding/config"
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

	var profile string
	flag.StringVar(&profile, "c", "", "Configuration profile")
	flag.IntVar(&log.LogLevel, "l", 6, "Log level")

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

	log.LogToLoggly = config.Current.LogToLoggly
	log.Service = fmt.Sprintf("%s %d", serviceName, os.Getpid())
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
}

type statusEntry struct {
	*log.Entry
	NumberOfClients    int
	NumberOfGoroutines int
}

func RunStatusLogger() {
	go func() {
		for {
			message := "Status: Serving %d clients."
			if ShuttingDown {
				message = "Status: Shutting down, still %d clients."
			}
			log.Send(&statusEntry{
				log.NewEntry(log.INFO, fmt.Sprintf(message, numClients)),
				numClients,
				runtime.NumGoroutine(),
			})
			time.Sleep(60 * time.Second)
		}
	}()
}
