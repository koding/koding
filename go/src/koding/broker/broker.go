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

	consumeConn := utils.CreateAmqpConnection("broker")
	defer consumeConn.Close()

	publishConn := utils.CreateAmqpConnection("broker")
	defer publishConn.Close()

	consumeChannel := utils.CreateAmqpChannel(consumeConn)
	defer consumeChannel.Close()

	routeMap := make(map[string]([]*sockjs.Session))
	var routeMapMutex sync.Mutex

	service := sockjs.NewService("http://localhost/sockjs.js", func(session *sockjs.Session) {
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
			routeMap[routingKeyPrefix] = append(routeMap[routingKeyPrefix], session)
			routeMapMutex.Unlock()
		}
		removeFromRouteMap := func(routingKeyPrefix string) {
			routeMapMutex.Lock()
			routeSessions := routeMap[routingKeyPrefix]
			for i, routeSession := range routeSessions {
				if routeSession == session {
					routeSessions[i] = routeSessions[len(routeSessions)-1]
					routeMap[routingKeyPrefix] = routeSessions[:len(routeSessions)-1]
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

					session.Send(map[string]interface{}{"routingKey": "broker.error", "code": amqpErr.Code, "reason": amqpErr.Reason, "server": amqpErr.Server, "recover": amqpErr.Recover})
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

		for data := range session.ReceiveChan {
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
					session.Send(map[string]string{"routingKey": "broker.subscribed", "payload": routingKeyPrefix})

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
	service.PanicHandler = log.RecoverAndLog

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

	stream := utils.DeclareBindConsumeAmqpQueueNoDelete(consumeChannel, "topic", "broker", "#")
	if err := consumeChannel.ExchangeDeclare("updateInstances", "fanout", false, false, false, false, nil); err != nil {
		panic(err)
	}
	if err := consumeChannel.ExchangeBind("broker", "", "updateInstances", false, nil); err != nil {
		panic(err)
	}

	for amqpMessage := range stream {
		routingKey := amqpMessage.RoutingKey
		payload := json.RawMessage(amqpMessage.Body)
		jsonMessage := map[string]interface{}{"routingKey": routingKey, "payload": &payload}

		pos := strings.IndexRune(routingKey, '.') // skip first dot, since we want at least two components to always include the secret
		for pos != -1 && pos < len(routingKey) {
			index := strings.IndexRune(routingKey[pos+1:], '.')
			if index == -1 {
				pos = len(routingKey)
			} else {
				pos += 1 + index
			}
			prefix := routingKey[:pos]
			routeMapMutex.Lock()
			routeSessions := routeMap[prefix]
			for _, routeSession := range routeSessions {
				if !routeSession.Send(jsonMessage) {
					routeSession.Close()
					log.Warn("Dropped session because of broker to client buffer overflow.")
				}
			}
			routeMapMutex.Unlock()
		}
	}
}
