package main

import (
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"github.com/streadway/amqp"
	"koding/tools/log"
	"koding/tools/sockjs"
	"koding/tools/utils"
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

			r := make([]byte, 128/8)
			rand.Read(r)
			socketId := base64.StdEncoding.EncodeToString(r)

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

			var controlChannel *amqp.Channel
			var lastPayload string
			resetControlChannel := func() {
				if controlChannel != nil {
					controlChannel.Close()
				}
				var err error
				controlChannel, err = publishConn.Channel()
				if err != nil {
					panic(err)
				}
				go func() {
					defer log.RecoverAndLog()

					for amqpErr := range controlChannel.NotifyClose(make(chan *amqp.Error)) {
						log.Warn("AMQP channel: "+amqpErr.Error(), "Last publish payload:", lastPayload)

						body, err := json.Marshal(map[string]interface{}{"routingKey": "broker.error", "code": amqpErr.Code, "reason": amqpErr.Reason, "server": amqpErr.Server, "recover": amqpErr.Recover})
						if err != nil {
							panic(err)
						}
						sendChan <- string(body)
					}
				}()
			}
			resetControlChannel()
			defer func() { controlChannel.Close() }()

			err := controlChannel.Publish("auth", "broker.clientConnected", false, false, amqp.Publishing{Body: []byte(socketId)})
			if err != nil {
				panic(err)
			}

			defer func() {
				for routingKeyPrefix := range subscriptions {
					removeFromRouteMap(routingKeyPrefix)
				}
				for {
					err := controlChannel.Publish("auth", "broker.clientDisconnected", false, false, amqp.Publishing{Body: []byte(socketId)})
					amqpError, isAmqpError := err.(*amqp.Error)
					if err == nil {
						break
					} else if isAmqpError && amqpError.Code == 504 {
						resetControlChannel()
					} else {
						panic(err)
					}
				}
			}()

			for data := range receiveChan {
				func() {
					defer log.RecoverAndLog()

					message := data.(map[string]interface{})
					log.Debug("Received message", message)

					action := message["action"]
					switch action {
					case "subscribe":
						routingKeyPrefix := message["routingKeyPrefix"].(string)
						addToRouteMap(routingKeyPrefix)
						subscriptions[routingKeyPrefix] = true

						body, err := json.Marshal(map[string]string{"routingKey": "broker.subscribed", "payload": routingKeyPrefix})
						if err != nil {
							panic(err)
						}
						sendChan <- string(body)

					case "unsubscribe":
						routingKeyPrefix := message["routingKeyPrefix"].(string)
						removeFromRouteMap(routingKeyPrefix)
						delete(subscriptions, routingKeyPrefix)

					case "publish":
						exchange := message["exchange"].(string)
						routingKey := message["routingKey"].(string)
						if strings.HasPrefix(routingKey, "client.") {
							for {
								lastPayload = ""
								err := controlChannel.Publish(exchange, routingKey, false, false, amqp.Publishing{CorrelationId: socketId, Body: []byte(message["payload"].(string))})
								amqpError, isAmqpError := err.(*amqp.Error)
								if err == nil {
									lastPayload = message["payload"].(string)
									break
								} else if isAmqpError && amqpError.Code == 504 {
									resetControlChannel()
								} else {
									panic(err)
								}
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
			defer log.RecoverAndLog()
			defer consumeChannel.Close()
			lastErrorTime := time.Now()
			for {
				err := server.Serve(listener)
				if err != nil {
					log.Warn("Server error: " + err.Error())
					if time.Now().Sub(lastErrorTime) < time.Second {
						break
					}
					lastErrorTime = time.Now()
				}
			}
		}()

		stream := utils.DeclareBindConsumeAmqpQueue(consumeChannel, "topic", "broker", "#")
		if err := consumeChannel.ExchangeDeclare("updateInstances", "fanout", false, true, false, false, nil); err != nil {
			panic(err)
		}
		if err := consumeChannel.ExchangeBind("broker", "", "updateInstances", false, nil); err != nil {
			panic(err)
		}

		for message := range stream {
			routingKey := message.RoutingKey
			body, err := json.Marshal(map[string]string{"routingKey": routingKey, "payload": string(message.Body)})
			if err != nil {
				panic(err)
			}
			bodyStr := string(body)

			pos := strings.IndexRune(routingKey, '.') // skip first dot, since we want at least two components to always include the secret
			for pos != -1 && pos < len(routingKey) {
				index := strings.IndexRune(routingKey[pos+1:], '.')
				if index == -1 {
					pos = len(routingKey)
				} else {
					pos += 1 + index
				}
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
