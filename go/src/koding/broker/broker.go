package main

import (
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"github.com/streadway/amqp"
	"koding/tools/amqputil"
	"koding/tools/lifecycle"
	"koding/tools/log"
	"koding/tools/sockjs"
	"net"
	"net/http"
	"strings"
	"sync"
	"time"
)

func main() {
	lifecycle.Startup("broker", false)
	lifecycle.RunStatusLogger()

	consumeConn := amqputil.CreateConnection("broker")
	defer consumeConn.Close()

	publishConn := amqputil.CreateConnection("broker")
	defer publishConn.Close()

	consumeChannel := amqputil.CreateChannel(consumeConn)
	defer consumeChannel.Close()

	routeMap := make(map[string]([]*sockjs.Session))
	var routeMapMutex sync.Mutex

	service := sockjs.NewService("http://localhost/sockjs.js", func(session *sockjs.Session) {
		defer log.RecoverAndLog()

		r := make([]byte, 128/8)
		rand.Read(r)
		socketId := base64.StdEncoding.EncodeToString(r)

		lifecycle.ChangeNumClients <- 1
		log.Debug("Client connected: " + socketId)
		defer func() {
			lifecycle.ChangeNumClients <- -1
			log.Debug("Client disconnected: " + socketId)
		}()

		addToRouteMap := func(routingKeyPrefix string) {
			routeMapMutex.Lock()
			defer routeMapMutex.Unlock()
			routeMap[routingKeyPrefix] = append(routeMap[routingKeyPrefix], session)
		}
		removeFromRouteMap := func(routingKeyPrefix string) {
			routeMapMutex.Lock()
			defer routeMapMutex.Unlock()
			routeSessions := routeMap[routingKeyPrefix]
			for i, routeSession := range routeSessions {
				if routeSession == session {
					routeSessions[i] = routeSessions[len(routeSessions)-1]
					routeSessions = routeSessions[:len(routeSessions)-1]
					break
				}
			}
			if len(routeSessions) == 0 {
				delete(routeMap, routingKeyPrefix)
				return
			}
			routeMap[routingKeyPrefix] = routeSessions
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
				if err == nil {
					break
				}
				if amqpError, isAmqpError := err.(*amqp.Error); !isAmqpError || amqpError.Code != 504 {
					panic(err)
				}
				resetControlChannel()
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
					if !strings.HasPrefix(routingKey, "client.") {
						log.Warn(fmt.Sprintf("Invalid routing key: %v", message))
						return
					}
					for {
						lastPayload = ""
						err := controlChannel.Publish(exchange, routingKey, false, false, amqp.Publishing{CorrelationId: socketId, Body: []byte(message["payload"].(string))})
						if err == nil {
							lastPayload = message["payload"].(string)
							break
						}
						if amqpError, isAmqpError := err.(*amqp.Error); !isAmqpError || amqpError.Code != 504 {
							panic(err)
						}
						resetControlChannel()
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

	stream := amqputil.DeclareBindConsumeQueueNoDelete(consumeChannel, "topic", "broker", "#")
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
			pos += index + 1
			if index == -1 {
				pos = len(routingKey)
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
