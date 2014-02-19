package main

import (
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"koding/broker/storage"
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
	Subscriptions  storage.Subscriptionable
}

// NewClient retuns a new client that is defined on a given session.
func NewClient(session *sockjs.Session, broker *Broker) (*Client, error) {
	socketId := randomString()
	session.Tag = socketId

	controlChannel, err := broker.PublishConn.Channel()
	if err != nil {
		return nil, fmt.Errorf("Couldnt create publish channel %v", err)
	}

	subscriptions, err := createSubscriptionStorage(socketId)
	if err != nil {
		return nil, err
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
	}, nil
}

func createSubscriptionStorage(socketId string) (storage.Subscriptionable, error) {

	if subscriptions, err := storage.NewStorage(conf, storage.REDIS, socketId); err == nil {
		return subscriptions, nil
	} else {
		log.Critical("Couldnt access to redis/create a key for client %v: Error: %v", socketId, err)
	}

	if subscriptions, err := storage.NewStorage(conf, storage.SET, socketId); err == nil {
		return subscriptions, nil
	}

	// this will never fail to here
	return nil, fmt.Errorf("Couldnt create subscription storage for Client: %v", socketId)
}

// Close should be called whenever a client disconnects.
func (c *Client) Close() {
	log.Debug("Client Close Request for socketID: %v", c.SocketId)
	c.Subscriptions.Each(func(routingKeyPrefix interface{}) bool {
		c.RemoveFromRoute(routingKeyPrefix.(string))
		return true
	})

	c.Subscriptions.ClearWithTimeout(time.Minute * 5)

	for {
		err := c.ControlChannel.Publish(c.Broker.Config.AuthAllExchange, "broker.clientDisconnected", false, false, amqp.Publishing{Body: []byte(c.SocketId)})
		if err == nil {
			break
		}
		if amqpError, isAmqpError := err.(*amqp.Error); !isAmqpError || amqpError.Code != amqp.ChannelError {
			log.Critical("Error while publising -not rabbitmq error- %v", err)
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
	message := data.(map[string]interface{})
	log.Debug("Received message: %v", message)

	action := message["action"]
	switch action {
	case "subscribe":
		routingKeyPrefixes := strings.Split(message["routingKeyPrefix"].(string), " ")
		if err := c.Subscribe(routingKeyPrefixes...); err != nil {
			log.Error(err.Error())
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
		routingKeyPrefix := message["routingKeyPrefix"].(string)
		log.Debug("Unsubscribe event for socketID: %v, and prefixes", c.SocketId, routingKeyPrefix)
		routingKeyPrefixes := strings.Split(routingKeyPrefix, " ")
		c.Unsubscribe(routingKeyPrefixes...)

	case "publish":
		exchange := message["exchange"].(string)
		routingKey := message["routingKey"].(string)
		payload := message["payload"].(string)

		log.Debug("Publish Event: Exchange: %v, RoutingKey %v, Payload %v",
			exchange,
			routingKey,
			payload,
		)

		if err := c.Publish(exchange, routingKey, payload); err != nil {
			log.Error(err.Error())
		}

	case "ping":
		sendToClient(c.Session, "broker.pong", nil)
		if c.Subscriptions.Backend() == storage.REDIS {
			// TOOD - may be we need to revisit this part later about duration and request count
			go c.Subscriptions.ClearWithTimeout(time.Minute * 59)
		}
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
	defer log.RecoverAndLog()

	if c.ControlChannel != nil {
		c.ControlChannel.Close()
	}

	var err error
	c.ControlChannel, err = c.Broker.PublishConn.Channel()
	if err != nil {
		log.Critical("Couldnt create publishing channel %v", err)
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
func (c *Client) RemoveFromRoute(routingKeyPrefixes ...string) {
	for _, routingKeyPrefix := range routingKeyPrefixes {
		if _, ok := routeMap[routingKeyPrefix]; !ok {
			continue
		}
		routeMap[routingKeyPrefix].Remove(c.SocketId)

		if routeMap[routingKeyPrefix].Size() == 0 {
			delete(routeMap, routingKeyPrefix)
		}
	}
}

// Add to route
// todo ~ check for multiple subscriptions
func (c *Client) AddToRoute() {
	c.Subscriptions.Each(func(routingKeyPrefix interface{}) bool {
		c.AddToRouteMapNOTS(routingKeyPrefix.(string))
		return true
	})
}

func (c *Client) AddToRouteMapNOTS(routingKeyPrefixes ...string) {
	for _, routingKeyPrefix := range routingKeyPrefixes {
		if _, ok := routeMap[routingKeyPrefix]; !ok {
			routeMap[routingKeyPrefix] = set.New()
		}
		routeMap[routingKeyPrefix].Add(c.SocketId)
	}
}

// Subscribe add the given routingKeyPrefix to the list of subscriptions
// associated with this client.
func (c *Client) Subscribe(routingKeyPrefixes ...string) error {
	if err := c.Subscriptions.Subscribe(routingKeyPrefixes...); err != nil {
		return err
	}

	globalMapMutex.Lock()
	c.AddToRouteMapNOTS(routingKeyPrefixes...)
	globalMapMutex.Unlock()

	// Log some information about the Client
	go func() {
		length, err := c.Subscriptions.Len()
		if err != nil {
			log.Warning("Error while trying to get Subscriptions.Len() for: %v Error: %v", c.Session.Tag, err)
		}

		if length > 0 && length%2000 == 0 {
			log.Warning("Client with more than %v subscriptions %v", strconv.Itoa(length), c.Session.Tag)
		}
	}()

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
func (c *Client) Unsubscribe(routingKeyPrefixes ...string) {
	c.RemoveFromRoute(routingKeyPrefixes...)
	if err := c.Subscriptions.Unsubscribe(routingKeyPrefixes...); err != nil {
		fmt.Errorf("%v", err)
	}
}

// randomString() returns a new 16 char length random string
func randomString() string {
	r := make([]byte, 128/8)
	rand.Read(r)
	return base64.StdEncoding.EncodeToString(r)
}
