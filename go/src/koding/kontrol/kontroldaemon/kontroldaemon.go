package main

import (
	"github.com/streadway/amqp"
	"koding/kontrol/kontroldaemon/handler"
	"koding/kontrol/kontrolhelper"
	"log"
)

func init() {
	log.SetPrefix("kontrol-daemon ")
}

func main() {
	handler.Startup()
	startRouting()
}

func startRouting() {
	type bind struct {
		name     string
		queue    string
		key      string
		exchange string
		kind     string
	}

	streams := make(map[string]<-chan amqp.Delivery)

	bindings := []bind{ // redeclaring the same exchange is OK, we are doing it once
		bind{"cli", "kontrol-cli", "input.cli", "infoExchange", "topic"},
		bind{"api", "kontrol-api", "input.api", "infoExchange", "topic"},
		bind{"worker", "kontrol-worker", "input.worker", "workerExchange", "topic"},
		bind{"client", "kontrol-client", "", "clientExchange", "fanout"},
	}

	connection := kontrolhelper.CreateAmqpConnection()
	channel := kontrolhelper.CreateChannel(connection)

	for _, b := range bindings {
		streams[b.name] = kontrolhelper.CreateStream(channel, b.kind, b.exchange, b.queue, b.key, true, false)
	}

	err := channel.Qos(len(bindings), 0, false)
	if err != nil {
		log.Fatalf("basic.qos: %s", err)
	}

	log.Println("kontrold started")
	for {
		select {
		case d := <-streams["cli"]:
			handler.HandleApiMessage(d.Body, d.AppId)
		case d := <-streams["api"]:
			handler.HandleApiMessage(d.Body, "")
		case d := <-streams["worker"]:
			handler.HandleWorkerMessage(d.Body)
		case d := <-streams["client"]:
			handler.HandleClientMessage(d)
		}
	}
}
