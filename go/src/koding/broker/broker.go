package main

import (
	"encoding/json"
	"fmt"
	"github.com/streadway/amqp"
	"koding/config"
	"koding/tools/sockjs"
	"koding/tools/utils"
	"math/rand"
	"net/http"
	"strings"
	"time"
)

func main() {
	utils.DefaultStartup("broker", false)

	consumeConn := utils.CreateAmqpConnection(config.Current.AmqpUri)
	publishConn := utils.CreateAmqpConnection(config.Current.AmqpUri)

	publishChannel := utils.CreateAmqpChannel(publishConn)

	mux := &sockjs.Mux{
		Services: map[string]*sockjs.Service{
			"/subscribe": sockjs.NewService("http://localhost/sockjs.js", true, false, 10*time.Minute, 0, func(receiveChan <-chan interface{}, sendChan chan<- interface{}) {
				socketId := fmt.Sprintf("%x", rand.Int63())
				exchanges := make([]string, 0)

				body, _ := json.Marshal(map[string]string{"socket_id": socketId})
				err := publishChannel.Publish("private-broker", "connected", false, false, amqp.Publishing{Body: body})
				if err != nil {
					panic(err)
				}

				consumerFinished := make(chan bool)
				func() {
					consumeChannel := utils.CreateAmqpChannel(consumeConn)
					defer consumeChannel.Close()

					_, err = consumeChannel.QueueDeclare("", false, true, false, false, nil)
					if err != nil {
						panic(err)
					}

					go func() {
						defer func() { consumerFinished <- true }()

						stream, err := consumeChannel.Consume("", "", true, false, false, false, nil)
						if err != nil {
							panic(err)
						}

						for message := range stream {
							body, _ = json.Marshal(map[string]string{"event": message.RoutingKey, "channel": message.Exchange, "payload": string(message.Body)})
							sendChan <- string(body)
						}
					}()

					for data := range receiveChan {
						var message map[string]string
						err := json.Unmarshal([]byte(data.(string)), &message)
						if err != nil {
							panic(err)
						}
						fmt.Println(message)

						event := message["event"]
						switch event {
						case "client-subscribe":
							channel := message["channel"]
							if channel != "updateInstances" {
								err = consumeChannel.QueueBind("", "*", channel, false, nil)
								if err != nil {
									panic(err)
								}
							}
							exchanges = append(exchanges, channel)

							body, _ = json.Marshal(map[string]string{"event": "broker:subscription_succeeded", "channel": channel, "payload": ""})
							sendChan <- string(body)

						case "client-unsubscribe":
							err = consumeChannel.QueueUnbind("", "*", message["channel"], nil)
							if err != nil {
								panic(err)
							}
							for i, exchange := range exchanges {
								if exchange == message["channel"] {
									exchanges[i] = exchanges[len(exchanges)-1]
									exchanges = exchanges[:len(exchanges)-1]
									break
								}
							}

						case "client-bind-event":

						case "client-unbind-event":

						case "client-presence":

						default:
							if strings.HasPrefix(event, "client-") {
								err := publishChannel.Publish(message["channel"], event, false, false, amqp.Publishing{Body: []byte(message["payload"])})
								if err != nil {
									panic(err)
								}
							}

						}
					}
				}()

				<-consumerFinished

				body, _ = json.Marshal(map[string]interface{}{"socket_id": socketId, "exchanges": exchanges})
				err = publishChannel.Publish("private-broker", "disconnected", false, false, amqp.Publishing{Body: body})
				if err != nil {
					panic(err)
				}
				body, _ = json.Marshal(map[string]interface{}{"socket_id": socketId})
				for _, exchange := range exchanges {
					err = publishChannel.Publish(exchange, "disconnected", false, false, amqp.Publishing{Body: body})
					if err != nil {
						panic(err)
					}
				}
			}),
		},
	}

	s := &http.Server{
		Addr:    ":8008",
		Handler: mux,
	}
	fmt.Println("Ready...")
	err := s.ListenAndServe()
	if err != nil {
		panic(err)
	}
}
