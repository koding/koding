package main

import (
	"fmt"
	"github.com/streadway/amqp"
	"koding/kontrol/daemon/handler"
	"koding/kontrol/daemon/handler/proxy"
	"koding/tools/amqputil"
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

	_, err := startRouting()
	if err != nil {
		log.Fatalf("Could not start routing of api messages: %s", err)
	}

	select {}
}

func startRouting() (*Consumer, error) {
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
		bind{"kontrol-webapi", "input.webapi"},
		bind{"kontrol-proxy", "input.proxy"},
	}

	workerBindings := []bind{
		bind{"kontrol-worker", "input.worker"},
	}

	log.Printf("creating connection to handle incoming cli and api messages")
	user := config.Current.Kontrold.RabbitMq.Login
	password := config.Current.Kontrold.RabbitMq.Password
	host := config.Current.Kontrold.RabbitMq.Host
	port := config.Current.Kontrold.RabbitMq.Port

	/* We use one connection and channel for our three consumers */
	c.conn = amqputil.CreateAmqpConnection(user, password, host, port)
	c.channel = amqputil.CreateChannel(c.conn)
	err := c.channel.ExchangeDeclare("infoExchange", "topic", true, false, false, false, nil)
	if err != nil {
		log.Fatal("info exchange.declare: %s", err)
	}

	err = c.channel.ExchangeDeclare("workerExchange", "topic", true, false, false, false, nil)
	if err != nil {
		log.Fatal("worker exchange.declare: %s", err)
	}

	for _, a := range apiBindings {
		_, err = c.channel.QueueDeclare(a.queue, true, false, false, false, nil)
		if err != nil {
			log.Fatal("queue.declare: %s", err)
		}

		err = c.channel.QueueBind(a.queue, a.key, "infoExchange", false, nil)
		if err != nil {
			log.Fatal("queue.bind: %s", err)
		}

	}

	for _, w := range workerBindings {
		_, err = c.channel.QueueDeclare(w.queue, true, false, false, false, nil)
		if err != nil {
			log.Fatal("queue.declare: %s", err)
		}

		err = c.channel.QueueBind(w.queue, w.key, "workerExchange", false, nil)
		if err != nil {
			log.Fatal("queue.bind: %s", err)
		}

	}

	err = c.channel.Qos(4, 0, false)
	if err != nil {
		log.Fatal("basic.qos: %s", err)
	}

	cliStream, err := c.channel.Consume("kontrol-cli", "", true, true, false, false, nil)
	if err != nil {
		log.Fatal("basic.consume: %s", err)
	}

	webapiStream, err := c.channel.Consume("kontrol-webapi", "", true, true, false, false, nil)
	if err != nil {
		log.Fatal("basic.consume: %s", err)
	}

	workerStream, err := c.channel.Consume("kontrol-worker", "", true, true, false, false, nil)
	if err != nil {
		log.Fatal("basic.consume: %s", err)
	}

	proxyStream, err := c.channel.Consume("kontrol-proxy", "", true, true, false, false, nil)
	if err != nil {
		log.Fatal("basic.consume: %s", err)
	}

	go func() {
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
			case d := <-webapiStream:
				if config.Verbose {
					log.Printf("webapi handle got %dB message data: [%v] %s", len(d.Body), d.DeliveryTag, d.Body)
				}
				handler.HandleApiMessage(d.Body, "")
			case d := <-proxyStream:
				if config.Verbose {
					log.Printf("proxy handle got %dB message data: [%v] %s", len(d.Body), d.DeliveryTag, d.Body)
				}
				// d.AppId is stored in d.Body.ProxyMessage.Uuid...
				proxy.HandleMessage(d.Body)
			}
		}
	}()

	return c, nil
}

func (c *Consumer) Shutdown() error {
	// will close() the deliveries channel
	if err := c.channel.Cancel(c.tag, true); err != nil {
		return fmt.Errorf("Consumer cancel failed: %s", err)
	}

	if err := c.conn.Close(); err != nil {
		return fmt.Errorf("AMQP connection close error: %s", err)
	}

	defer log.Printf("AMQP shutdown OK")

	// wait for handle() to exit
	return <-c.done
}
