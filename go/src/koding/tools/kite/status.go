package kite

import (
	"fmt"
	"koding/tools/log"
	"os"
	"runtime"
	"time"
)

type statusMessage struct {
	*log.GelfMessage
	NumberOfClients    int `json:"_number_of_clients"`
	NumberOfGoroutines int `json:"_number_of_goroutines"`
}

var shutdown bool = false
var numClients int = 0
var changeNumClients chan int = make(chan int)

func init() {
	go func() {
		for {
			numClients += <-changeNumClients
			if shutdown && numClients == 0 {
				log.Info("Shutdown complete. Terminating.")
				os.Exit(0)
			}
		}
	}()
}

func beginShutdown() {
	shutdown = true
	changeNumClients <- 0
}

func runStatusLogger() {
	go func() {
		for {
			message := "Status: Serving %d clients."
			if shutdown {
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
