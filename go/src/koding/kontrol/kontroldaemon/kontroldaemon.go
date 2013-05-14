package main

import (
	"github.com/streadway/amqp"
	"koding/kontrol/helper"
	"koding/kontrol/kontroldaemon/handler"
	"koding/kontrol/kontroldaemon/handler/proxy"
	"koding/tools/config"
	"log"
)

type Consumer struct {
	conn    *amqp.Connection
	channel *amqp.Channel
	tag     string
	done    chan error
}

func init() {
	log.SetPrefix("kontrol-daemon ")
}

func main() {
	// Initialize db and startup settings
	log.Printf("initiliazing handlers")
	handler.Startup()
	proxy.Startup()

	err := startRouting()
	if err != nil {
		log.Fatalf("Could not start routing of api messages: %s", err)
	}

}

func startRouting() error {
	c := &Consumer{
		conn:    nil,
		channel: nil,
		tag:     "",
		done:    make(chan error),
	}

	type bind struct {
		queue string
		key   string
	}

	apiBindings := []bind{
		bind{"kontrol-cli", "input.cli"},
		bind{"kontrol-api", "input.api"},
		bind{"kontrol-proxy", "input.proxy"},
	}

	workerBindings := []bind{
		bind{"kontrol-worker", "input.worker"},
	}

	log.Printf("creating connection to receive cli, api, proxy and worker messages")
	/* We use one connection and channel for our three consumers */
	c.conn = helper.CreateAmqpConnection()
	c.channel = helper.CreateChannel(c.conn)
	err := c.channel.ExchangeDeclare("infoExchange", "topic", true, false, false, false, nil)
	if err != nil {
		log.Fatalf("info exchange.declare: %s", err)
	}

	err = c.channel.ExchangeDeclare("workerExchange", "topic", true, false, false, false, nil)
	if err != nil {
		log.Fatalf("worker exchange.declare: %s", err)

	}
	err = c.channel.ExchangeDeclare("clientExchange", "fanout", true, false, false, false, nil)
	if err != nil {
		log.Fatalf("worker exchange.declare: %s", err)
	}

	_, err = c.channel.QueueDeclare("kontrol-client", true, false, false, false, nil)
	if err != nil {
		log.Fatalf("queue.declare: %s", err)
	}

	err = c.channel.QueueBind("kontrol-client", "", "clientExchange", false, nil)
	if err != nil {
		log.Fatalf("queue.bind: %s", err)
	}

	for _, a := range apiBindings {
		_, err = c.channel.QueueDeclare(a.queue, true, false, false, false, nil)
		if err != nil {
			log.Fatalf("queue.declare: %s", err)
		}

		err = c.channel.QueueBind(a.queue, a.key, "infoExchange", false, nil)
		if err != nil {
			log.Fatalf("queue.bind: %s", err)
		}

	}

	for _, w := range workerBindings {
		_, err = c.channel.QueueDeclare(w.queue, true, false, false, false, nil)
		if err != nil {
			log.Fatalf("queue.declare: %s", err)
		}

		err = c.channel.QueueBind(w.queue, w.key, "workerExchange", false, nil)
		if err != nil {
			log.Fatalf("queue.bind: %s", err)
		}

	}

	err = c.channel.Qos(5, 0, false)
	if err != nil {
		log.Fatalf("basic.qos: %s", err)
	}

	cliStream, err := c.channel.Consume("kontrol-cli", "", true, true, false, false, nil)
	if err != nil {
		log.Fatalf("basic.consume: %s", err)
	}

	apiStream, err := c.channel.Consume("kontrol-api", "", true, true, false, false, nil)
	if err != nil {
		log.Fatalf("basic.consume: %s", err)
	}

	workerStream, err := c.channel.Consume("kontrol-worker", "", true, true, false, false, nil)
	if err != nil {
		log.Fatalf("basic.consume: %s", err)
	}

	proxyStream, err := c.channel.Consume("kontrol-proxy", "", true, true, false, false, nil)
	if err != nil {
		log.Fatalf("basic.consume: %s", err)
	}

	clientStream, err := c.channel.Consume("kontrol-client", "", true, true, false, false, nil)
	if err != nil {
		log.Fatalf("basic.consume: %s", err)
	}

	for {
		select {
		case d := <-workerStream:
			if config.Verbose {
				log.Printf("worker handle got %dB message data: [%v] %s %s", len(d.Body), d.DeliveryTag, d.Body, d.AppId)
			}
			handler.HandleWorkerMessage(d.Body)
		case d := <-cliStream:
			if config.Verbose {
				log.Printf("cli handle got %dB message data: [%v] %s", len(d.Body), d.DeliveryTag, d.Body)
			}
			handler.HandleApiMessage(d.Body, d.AppId)
		case d := <-apiStream:
			if config.Verbose {
				log.Printf("api handle got %dB message data: [%v] %s", len(d.Body), d.DeliveryTag, d.Body)
			}
			handler.HandleApiMessage(d.Body, "")
		case d := <-clientStream:
			if config.Verbose {
				log.Printf("got %dB message data: [%v]-[%s] %s",
					len(d.Body),
					d.DeliveryTag,
					d.RoutingKey,
					d.Body)
			}
			handler.HandleClientMessage(d)
		case d := <-proxyStream:
			if config.Verbose {
				log.Printf("proxy handle got %dB message data: [%v] %s", len(d.Body), d.DeliveryTag, d.Body)
			}
			// d.AppId is stored in d.Body.ProxyMessage.Uuid...
			proxy.HandleMessage(d.Body)
		}
	}

	return nil
}
