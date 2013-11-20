package main

import (
	"koding/kontrol/kontroldaemon/handler"
	"koding/kontrol/kontrolhelper"
	"koding/tools/slog"
	"github.com/streadway/amqp"
)

func init() {
	slog.SetPrefixName("kontrold")
	slog.Println(slog.SetOutputFile("/var/log/koding/kontroldaemon.log"))
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
	bindings := []bind{
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
		slog.Fatalf("basic.qos: %s", err)
	}

	slog.Println("started")
	for {
		select {
		case d := <-streams["api"]:
			handler.ApiMessage(d.Body)
		case d := <-streams["worker"]:
			handler.WorkerMessage(d.Body)
		case d := <-streams["client"]:
			handler.ClientMessage(d)
		}
	}
}
