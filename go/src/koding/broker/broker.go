package main

import (
	"encoding/json"
	"fmt"
	"github.com/streadway/amqp"
	"koding/tools/log"
	"koding/tools/sockjs"
	"koding/tools/utils"
	"math/rand"
	"net"
	"net/http"
	"strings"
	"time"
)

func main() {
	utils.Startup("broker", false)
	utils.RunStatusLogger()

	utils.AmqpAutoReconnect(func(consumeConn, publishConn *amqp.Connection) {

		service := sockjs.NewService("http://localhost/sockjs.js", true, false, 10*time.Minute, 0, func(receiveChan <-chan interface{}, sendChan chan<- interface{}) {
			defer log.RecoverAndLog()

			socketId := fmt.Sprintf("%x", rand.Int63())
			exchanges := make([]string, 0)

			utils.ChangeNumClients <- 1
			log.Debug("Client connected: " + socketId)
			defer func() {
				utils.ChangeNumClients <- -1
				log.Debug("Client disconnected: " + socketId)
			}()

			publishChannel := utils.CreateAmqpChannel(publishConn)
			defer publishChannel.Close()

			body, _ := json.Marshal(map[string]string{"socket_id": socketId})
			err := publishChannel.Publish("private-broker", "connected", false, false, amqp.Publishing{Body: body})
			if err != nil {
				panic(err)
			}

			consumerFinished := make(chan bool)
			defer close(consumerFinished)
			func() {
				defer log.RecoverAndLog()
				consumeChannel := utils.CreateAmqpChannel(consumeConn)
				defer consumeChannel.Close()

				_, err = consumeChannel.QueueDeclare("", false, true, false, false, nil)
				if err != nil {
					panic(err)
				}

				stream, err := consumeChannel.Consume("", "", true, false, false, false, nil)
				if err != nil {
					panic(err)
				}

				go func() {
					defer log.RecoverAndLog()
					defer func() { consumerFinished <- true }()

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
					log.Debug(message)

					event := message["event"]
					exchange := message["channel"]

					switch event {
					case "client-subscribe":
						err = consumeChannel.QueueBind("", "#", exchange, false, nil)
						if err != nil {
							panic(err)
						}
						exchanges = append(exchanges, exchange)

						body, _ = json.Marshal(map[string]string{"event": "broker:subscription_succeeded", "channel": exchange, "payload": ""})
						sendChan <- string(body)

					case "client-unsubscribe":
						err = consumeChannel.QueueUnbind("", "#", exchange, nil)
						if err != nil {
							panic(err)
						}
						for i, e := range exchanges {
							if e == exchange {
								exchanges[i] = exchanges[len(exchanges)-1]
								exchanges = exchanges[:len(exchanges)-1]
								break
							}
						}

					case "client-bind-event":

					case "client-unbind-event":

					case "client-presence":

					default:
						if strings.HasPrefix(event, "client-") && strings.HasPrefix(exchange, "secret-") {
							err := publishChannel.Publish(exchange, event, false, false, amqp.Publishing{Body: []byte(message["payload"])})
							if err != nil {
								panic(err)
							}
						} else {
							log.Warn(fmt.Sprintf("Invalid message: %v", message))
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
		})
		defer service.Close()

		server := &http.Server{Handler: &sockjs.Mux{
			Services: map[string]*sockjs.Service{
				"/subscribe": service,
			},
		}}
		listener, err := net.Listen("tcp", ":8008")
		if err != nil {
			panic(err)
		}

		go func() {
			for _ = range consumeConn.NotifyClose(make(chan *amqp.Error)) {
				listener.Close()
			}
		}()

		go func() {
			for _ = range publishConn.NotifyClose(make(chan *amqp.Error)) {
				listener.Close()
			}
		}()

		err = server.Serve(listener)
		if err != nil {
			log.Warn("Server error: " + err.Error())
		}
	})
}
