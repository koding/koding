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

func Startup(facility string, needRoot bool) {
	if needRoot && os.Getuid() != 0 {
		fmt.Println("Must be run as root.")
		os.Exit(1)
	}

	runtime.GOMAXPROCS(runtime.NumCPU())
	rand.Seed(time.Now().UnixNano())

	flag.Parse()
	if flag.NArg() != 0 {
		flag.PrintDefaults()
		os.Exit(1)
	}
	config.LoadConfig()
	log.Facility = fmt.Sprintf("%s %d", facility, os.Getpid())
	log.Info(fmt.Sprintf("Process '%v' started (version '%v').", facility, version))

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

type statusMessage struct {
	*log.GelfMessage
	NumberOfClients    int `json:"_number_of_clients"`
	NumberOfGoroutines int `json:"_number_of_goroutines"`
}

func RunStatusLogger() {
	go func() {
		for {
			message := "Status: Serving %d clients."
			if ShuttingDown {
				message = "Status: Shutting down, still %d clients."
			}
			log.Send(&statusMessage{
				log.NewGelfMessage(log.INFO, "", 0, fmt.Sprintf(message, numClients)),
				numClients,
				runtime.NumGoroutine(),
			})
			time.Sleep(60 * time.Second)
		}
	}()
}
