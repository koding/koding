package kite

import (
	"fmt"
	"koding/tools/log"
	"runtime"
	"time"
)

type statusMessage struct {
	*log.GelfMessage
	NumberOfClients    int `json:"_number_of_clients"`
	NumberOfGoroutines int `json:"_number_of_goroutines"`
}

var numClients int = 0
var changeNumClients chan int = make(chan int)

func init() {
	go func() {
		for {
			numClients += <-changeNumClients
		}
	}()
}

func RunStatusLogger() {
	go func() {
		for {
			log.Send(&statusMessage{
				log.NewGelfMessage(log.INFO, "", 0, fmt.Sprintf("Status: Serving %d clients.", numClients)),
				numClients,
				runtime.NumGoroutine(),
			})
			time.Sleep(60 * time.Second)
		}
	}()
}
