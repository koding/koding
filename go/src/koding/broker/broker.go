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
	"sync"
	"time"
)

func main() {
	utils.Startup("broker", false)
	utils.RunStatusLogger()

	utils.AmqpAutoReconnect("broker", func(consumeConn, publishConn *amqp.Connection) {
		consumeChannel := utils.CreateAmqpChannel(consumeConn)
		defer consumeChannel.Close()

		routeMap := make(map[string]([]chan<- interface{}))
		var routeMapMutex sync.RWMutex

		service := sockjs.NewService("http://localhost/sockjs.js", true, false, 10*time.Minute, 0, func(receiveChan <-chan interface{}, sendChan chan<- interface{}) {
			defer log.RecoverAndLog()

			socketId := fmt.Sprintf("%x", rand.Int63())

			utils.ChangeNumClients <- 1
			log.Debug("Client connected: " + socketId)
			defer func() {
				utils.ChangeNumClients <- -1
				log.Debug("Client disconnected: " + socketId)
			}()

			addToRouteMap := func(routingKeyPrefix string) {
				routeMapMutex.Lock()
				routeMap[routingKeyPrefix] = append(routeMap[routingKeyPrefix], sendChan)
				routeMapMutex.Unlock()
			}
			removeFromRouteMap := func(routingKeyPrefix string) {
				routeMapMutex.Lock()
				channels := routeMap[routingKeyPrefix]
				for i, channel := range channels {
					if channel == sendChan {
						channels[i] = channels[len(channels)-1]
						routeMap[routingKeyPrefix] = channels[:len(channels)-1]
						break
					}
				}
				routeMapMutex.Unlock()
			}

			subscriptions := make(map[string]bool)

			controlChannel := utils.CreateAmqpChannel(publishConn)
			defer func() { controlChannel.Close() }() // controlChannel is replaced on error

			body, err := json.Marshal(map[string]string{"event": "connected", "socketId": socketId})
			if err != nil {
				panic(err)
			}
			// inform auth endpoint
			err = controlChannel.Publish("authEndpoint", "connected", false, false, amqp.Publishing{Body: body})
			if err != nil {
				panic(err)
			}
			// inform client
			sendChan <- body

			defer func() {
				for routingKeyPrefix := range subscriptions {
					removeFromRouteMap(routingKeyPrefix)
				}
				// inform auth endpoint
				body, err = json.Marshal(map[string]interface{}{"event": "disconnected", "socketId": socketId})
				if err != nil {
					panic(err)
				}
				err = controlChannel.Publish("authEndpoint", "disconnected", false, false, amqp.Publishing{Body: body})
				if err != nil {
					panic(err)
				}
			}()

			for data := range receiveChan {
				func() {
					defer func() {
						err := recover()
						if err != nil {
							log.LogError(err)
							controlChannel.Close()
							controlChannel = utils.CreateAmqpChannel(publishConn)
						}
					}()

					var message map[string]string
					err := json.Unmarshal([]byte(data.(string)), &message)
					if err != nil {
						panic(err)
					}
					log.Debug(message)

					action := message["action"]
					switch action {
					case "subscribe":
						routingKeyPrefix := message["routingKeyPrefix"]
						addToRouteMap(routingKeyPrefix)
						subscriptions[routingKeyPrefix] = true

						body, err = json.Marshal(map[string]string{"event": "subscribed", "routingKeyPrefix": routingKeyPrefix})
						if err != nil {
							panic(err)
						}
						sendChan <- string(body)

					case "unsubscribe":
						routingKeyPrefix := message["routingKeyPrefix"]
						removeFromRouteMap(routingKeyPrefix)
						delete(subscriptions, routingKeyPrefix)

					case "publish":
						exchange := message["exchange"]
						routingKey := message["routingKey"]
						if strings.HasPrefix(routingKey, "client.") {
							err := controlChannel.Publish(exchange, routingKey, false, false, amqp.Publishing{Body: []byte(message["payload"])})
							if err != nil {
								panic(err)
							}
						} else {
							log.Warn(fmt.Sprintf("Invalid routing key: %v", message))
						}

					default:
						log.Warn(fmt.Sprintf("Invalid action: %v", message))

					}
				}()
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
		defer listener.Close()

		go func() {
			err = server.Serve(listener)
			if err != nil {
				log.Warn("Server error: " + err.Error())
			}
			consumeConn.Close()
		}()

		stream := utils.DeclareBindConsumeAmqpQueue(consumeChannel, "topic", "broker", "#")
		for message := range stream {
			routingKey := message.RoutingKey
			body, err := json.Marshal(map[string]string{"event": routingKey, "exchange": message.Exchange, "payload": string(message.Body)})
			if err != nil {
				panic(err)
			}
			bodyStr := string(body)

			pos := 0
			for {
				index := strings.IndexRune(routingKey[pos:], '.')
				if index == -1 {
					break
				}
				pos += index
				prefix := routingKey[:pos]
				routeMapMutex.RLock()
				channels := routeMap[prefix]
				routeMapMutex.RUnlock()
				for _, channel := range channels {
					select {
					case channel <- bodyStr:
						// successful
					default:
						log.Warn("Dropped message")
					}
				}
			}
		}
	})
}
