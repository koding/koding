package main

import (
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"koding/tools/config"
	"koding/tools/sockjs"
	"strconv"
	"strings"
	"time"

	"github.com/streadway/amqp"
)

type Client struct {
	Session        *sockjs.Session
	ControlChannel *amqp.Channel
	SocketId       string
	Broker         *Broker
	LastPayload    string
	Subscriptions  map[string]bool
}

// NewClient retuns a new client that is defined on a given session.
func NewClient(session *sockjs.Session, broker *Broker) *Client {
	socketID := randomString()
	session.Tag = socketID

	controlChannel, err := broker.PublishConn.Channel()
	if err != nil {
		panic(err)
	}

	subscriptions := make(map[string]bool)

	fmt.Println("adding to subscriptionsMap")
	globalMapMutex.Lock()
	socketSubscriptionsMap[socketID] = &subscriptions
	globalMapMutex.Unlock()

	fmt.Println("returning new client")
	return &Client{
		Session:        session,
		SocketId:       socketID,
		ControlChannel: controlChannel,
		Broker:         broker,
		Subscriptions:  subscriptions,
	}
}

// Close should be called whenever a client disconnects.
func (c *Client) Close() {
	globalMapMutex.Lock()
	for routingKeyPrefix := range c.Subscriptions {
		c.RemoveFromRoute(routingKeyPrefix)
	}
	globalMapMutex.Unlock()

	time.AfterFunc(5*time.Minute, func() {
		globalMapMutex.Lock()
		delete(socketSubscriptionsMap, c.SocketId)
		globalMapMutex.Unlock()
	})

	for {
		err := c.ControlChannel.Publish(config.Current.Broker.AuthAllExchange, "broker.clientDisconnected", false, false, amqp.Publishing{Body: []byte(c.SocketId)})
		if err == nil {
			break
		}
		if amqpError, isAmqpError := err.(*amqp.Error); !isAmqpError || amqpError.Code != amqp.ChannelError {
			panic(err)
		}
		c.resetControlChannel()
	}

	c.ControlChannel.Close()
}

// handleSessionMessage handles the received message from the client. It
// passes a response back to the client or publish the received message to a
// rabbitmq exchange for further process.
func (c *Client) handleSessionMessage(data interface{}) {
	defer log.RecoverAndLog()

	message := data.(map[string]interface{})
	log.Debug("Received message: %v", message)

	action := message["action"]
	switch action {
	case "subscribe":
		globalMapMutex.Lock()
		defer globalMapMutex.Unlock()
		for _, routingKeyPrefix := range strings.Split(message["routingKeyPrefix"].(string), " ") {
			c.Subscribe(routingKeyPrefix)
		}

		sendToClient(c.Session, "broker.subscribed", message["routingKeyPrefix"])

	case "resubscribe":
		globalMapMutex.Lock()
		defer globalMapMutex.Unlock()
		oldSubscriptions, found := socketSubscriptionsMap[message["socketId"].(string)]
		if found {
			for routingKeyPrefix := range *oldSubscriptions {
				c.Subscribe(routingKeyPrefix)
			}
		}
		sendToClient(c.Session, "broker.resubscribed", found)

	case "unsubscribe":
		globalMapMutex.Lock()
		defer globalMapMutex.Unlock()
		for _, routingKeyPrefix := range strings.Split(message["routingKeyPrefix"].(string), " ") {
			c.Unsubscribe(routingKeyPrefix)
		}

	case "publish":
		exchange := message["exchange"].(string)
		routingKey := message["routingKey"].(string)
		payload := message["payload"].(string)

		publish := func(exchange, routingKey, payload string) error {
			if !strings.HasPrefix(routingKey, "client.") {
				return fmt.Errorf("Invalid routing key: %v socketId: %v", routingKey, c.SocketId)
			}

			for {
				c.LastPayload = ""
				err := c.ControlChannel.Publish(exchange, routingKey, false, false, amqp.Publishing{CorrelationId: c.SocketId, Body: []byte(payload)})
				if err == nil {
					c.LastPayload = payload
					break
				}

				if amqpError, isAmqpError := err.(*amqp.Error); !isAmqpError || amqpError.Code != amqp.ChannelError {
					log.Warning("payload: %v routing key: %v exchange: %v err: %v",
						payload, routingKey, exchange, err)
				}

				time.Sleep(time.Second / 4) // penalty for crashing the AMQP channel
				c.resetControlChannel()
			}

			return nil
		}

		publish(exchange, routingKey, payload)

	case "ping":
		sendToClient(c.Session, "broker.pong", nil)

	default:
		log.Warning("Invalid action. message: %v socketId: %v", message, c.SocketId)

	}
}

// randomString() returns a new 16 char length random string
func randomString() string {
	r := make([]byte, 128/8)
	rand.Read(r)
	return base64.StdEncoding.EncodeToString(r)
}

// gaugeStart starts the gauge for a given session. It returns a new
// function which ends the gauge for the given session. Usually one invokes
// gaugeStart and calls the returned function in a defer statement.
func (c *Client) gaugeStart() (gaugeEnd func()) {
	log.Debug("Client connected: %v", c.Session.Tag)
	changeClientsGauge(1)
	changeNewClientsGauge(1)
	if c.Session.IsWebsocket {
		changeWebsocketClientsGauge(1)
	}

	return func() {
		log.Debug("Client disconnected: %v", c.Session.Tag)
		changeClientsGauge(-1)
		if c.Session.IsWebsocket {
			changeWebsocketClientsGauge(-1)
		}
	}
}

// resetControlChannel closes the current client's control channel and creates
// a new channel. It also listens to any server side error and publish back
// the error to the client.
func (c *Client) resetControlChannel() {
	if c.ControlChannel != nil {
		c.ControlChannel.Close()
	}

	var err error
	c.ControlChannel, err = c.Broker.PublishConn.Channel()
	if err != nil {
		panic(err)
	}

	go func() {
		defer log.RecoverAndLog()

		for amqpErr := range c.ControlChannel.NotifyClose(make(chan *amqp.Error)) {
			if !(strings.Contains(amqpErr.Error(), "NOT_FOUND") && (strings.Contains(amqpErr.Error(), "koding-social-") || strings.Contains(amqpErr.Error(), "auth-"))) {
				log.Warning("AMQP channel: %v Last publish payload: %v", amqpErr.Error(), c.LastPayload)
			}

			sendToClient(c.Session, "broker.error", map[string]interface{}{
				"code":    amqpErr.Code,
				"reason":  amqpErr.Reason,
				"server":  amqpErr.Server,
				"recover": amqpErr.Recover,
			})
		}
	}()
}

// RemoveFromRoute removes the sessions for the given routingKeyPrefix.
func (c *Client) RemoveFromRoute(routingKeyPrefix string) {
	routeSessions := routeMap[routingKeyPrefix]
	for i, routeSession := range routeSessions {
		if routeSession == c.Session {
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

// Subscribe add the given routingKeyPrefix to the list of subscriptions
// associated with this client.
func (c *Client) Subscribe(routingKeyPrefix string) {
	if c.Subscriptions[routingKeyPrefix] {
		log.Warning("Duplicate subscription to same routing key. %v %v", c.Session.Tag, routingKeyPrefix)
		return
	}

	if len(c.Subscriptions) > 0 && len(c.Subscriptions)%2000 == 0 {
		log.Warning("Client with more than %v subscriptions %v",
			strconv.Itoa(len(c.Subscriptions)), c.Session.Tag)
	}

	routeMap[routingKeyPrefix] = append(routeMap[routingKeyPrefix], c.Session)
	c.Subscriptions[routingKeyPrefix] = true

}

// Unsubscribe deletes the given routingKey prefix from the subscription list
// and removes it from the global route map
func (c *Client) Unsubscribe(routingKeyPrefix string) {
	c.RemoveFromRoute(routingKeyPrefix)
	delete(c.Subscriptions, routingKeyPrefix)
}
