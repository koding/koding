package main

import (
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"koding/broker/cache"
	"koding/tools/config"
	"koding/tools/sockjs"
	"strconv"
	"strings"
	"time"

	"github.com/fatih/set"
	"github.com/streadway/amqp"
)

type Client struct {
	Session        *sockjs.Session
	ControlChannel *amqp.Channel
	SocketId       string
	Broker         *Broker
	LastPayload    string
	Subscriptions  *cache.SubscriptionStorage
}

// NewClient retuns a new client that is defined on a given session.
func NewClient(session *sockjs.Session, broker *Broker) *Client {
	socketId := randomString()
	session.Tag = socketId

	var err error
	controlChannel, err := broker.PublishConn.Channel()
	if err != nil {
		panic(err)
	}

	var subscriptions *cache.SubscriptionStorage

	subscriptions, err = cache.NewStorage(STORAGE_BACKEND, socketId)
	if err != nil {
		STORAGE_BACKEND = "set"
		subscriptions, err = cache.NewStorage(STORAGE_BACKEND, socketId)
		if err != nil {
			panic(err)
		}
	}

	globalMapMutex.Lock()
	sessionsMap[socketId] = session
	globalMapMutex.Unlock()

	return &Client{
		Session:        session,
		SocketId:       socketId,
		ControlChannel: controlChannel,
		Broker:         broker,
		Subscriptions:  subscriptions,
	}
}

// Close should be called whenever a client disconnects.
func (c *Client) Close() {
	log.Debug("Client Close Request for socketID: %v", c.SocketId)
	c.Subscriptions.Each(func(routingKeyPrefix interface{}) bool {
		c.RemoveFromRoute(routingKeyPrefix.(string))
		return true
	})

	c.Subscriptions.ClearWithTimeout()

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

	log.Debug("Closing control channel for socketID: %v", c.SocketId)
	c.ControlChannel.Close()

	globalMapMutex.Lock()
	defer globalMapMutex.Unlock()
	delete(sessionsMap, c.SocketId)
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
		for _, routingKeyPrefix := range strings.Split(message["routingKeyPrefix"].(string), " ") {
			if err := c.Subscribe(routingKeyPrefix); err != nil {
				log.Error(err.Error())
			}
		}

		sendToClient(c.Session, "broker.subscribed", message["routingKeyPrefix"])

	case "resubscribe":
		clientId := message["socketId"].(string)
		log.Debug("Resubscribe event for clientId: %v SocketId: %v", clientId, c.SocketId)
		found, err := c.Resubscribe(clientId)
		if err != nil {
			log.Error(err.Error())
		}
		log.Debug("Resubscribe found for socketID: %v, %v", clientId, found)
		sendToClient(c.Session, "broker.resubscribed", found)

	case "unsubscribe":
		routingKeyPrefixes := message["routingKeyPrefix"].(string)
		log.Debug("Unsubscribe event for socketID: %v, and prefixes", c.SocketId, routingKeyPrefixes)
		for _, routingKeyPrefix := range strings.Split(routingKeyPrefixes, " ") {
			c.Unsubscribe(routingKeyPrefix)
		}

	case "publish":
		exchange := message["exchange"].(string)
		routingKey := message["routingKey"].(string)
		payload := message["payload"].(string)

		log.Debug("Publish Event: Exchange: %v, RoutingKey %v, Payload %v",
			exchange,
			routingKey,
			payload,
		)

		err := c.Publish(exchange, routingKey, payload)
		if err != nil {
			log.Error(err.Error())
		}

	case "ping":
		sendToClient(c.Session, "broker.pong", nil)

	default:
		log.Warning("Invalid action. message: %v socketId: %v", message, c.SocketId)

	}
}

// Publish publish the given payload for to the given exchange and routingkey.
func (c *Client) Publish(exchange, routingKey, payload string) error {
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
	if _, ok := routeMap[routingKeyPrefix]; !ok {
		return
	}

	routeMap[routingKeyPrefix].Remove(c.SocketId)

	if routeMap[routingKeyPrefix].Size() == 0 {
		delete(routeMap, routingKeyPrefix)
	}
}

// Add to route
// todo ~ check for multiple subscriptions
func (c *Client) AddToRoute() {
	globalMapMutex.Lock()
	c.Subscriptions.Each(func(routingKeyPrefix interface{}) bool {
		c.AddToRouteMapNOTS(routingKeyPrefix.(string))
		return true
	})
	globalMapMutex.Unlock()

}

func (c *Client) AddToRouteMapNOTS(routingKeyPrefix string) {
	if _, ok := routeMap[routingKeyPrefix]; !ok {
		routeMap[routingKeyPrefix] = set.New()
	}
	routeMap[routingKeyPrefix].Add(c.SocketId)
}

// Subscribe add the given routingKeyPrefix to the list of subscriptions
// associated with this client.
func (c *Client) Subscribe(routingKeyPrefix string) error {
	res, err := c.Subscriptions.Has(routingKeyPrefix)
	if err != nil {
		return err
	}

	if res {
		return fmt.Errorf("Duplicate subscription to same routing key. %v %v", c.Session.Tag, routingKeyPrefix)
	}

	length, err := c.Subscriptions.Len()
	if err != nil {
		return err
	}

	if length > 0 && length%2000 == 0 {
		log.Warning("Client with more than %v subscriptions %v", strconv.Itoa(length), c.Session.Tag)
	}

	if err := c.Subscriptions.Subscribe(routingKeyPrefix); err != nil {
		return err
	}

	globalMapMutex.Lock()
	c.AddToRouteMapNOTS(routingKeyPrefix)
	globalMapMutex.Unlock()

	return nil
}

func (c *Client) Resubscribe(sessionId string) (bool, error) {
	found, err := c.Subscriptions.Resubscribe(sessionId)
	if err != nil {
		return false, err
	}

	if !found {
		return false, nil
	}

	c.AddToRoute()
	return true, nil
}

// Unsubscribe deletes the given routingKey prefix from the subscription list
// and removes it from the global route map
func (c *Client) Unsubscribe(routingKeyPrefix string) {
	c.RemoveFromRoute(routingKeyPrefix)
	if err := c.Subscriptions.Unsubscribe(routingKeyPrefix); err != nil {
		fmt.Errorf("%v", err)
	}
}

// randomString() returns a new 16 char length random string
func randomString() string {
	r := make([]byte, 128/8)
	rand.Read(r)
	return base64.StdEncoding.EncodeToString(r)
}
