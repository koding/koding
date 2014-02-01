package main

import (
	"crypto/rand"
	"crypto/tls"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"koding/kontrol/kontrolhelper"
	"koding/tools/amqputil"
	"koding/tools/config"
	"koding/tools/lifecycle"
	"koding/tools/logger"
	"koding/tools/sockjs"
	"koding/tools/utils"
	"net"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"sync"
	"syscall"
	"time"

	"github.com/streadway/amqp"
)

var (
	log                    = logger.New("broker")
	routeMap               = make(map[string]([]*sockjs.Session))
	socketSubscriptionsMap = make(map[string]*map[string]bool)
	globalMapMutex         sync.Mutex

	changeClientsGauge          = lifecycle.CreateClientsGauge()
	changeNewClientsGauge       = logger.CreateCounterGauge("newClients", logger.NoUnit, true)
	changeWebsocketClientsGauge = logger.CreateCounterGauge("websocketClients", logger.NoUnit, false)
)

type Broker struct {
	Hostname          string
	ServiceUniqueName string
	PublishConn       *amqp.Connection
}

func NewBroker() *Broker {
	// returns os.Hostname() if config.BrokerDomain is empty, otherwise it just
	// returns config.BrokerDomain back
	brokerHostname := kontrolhelper.CustomHostname(config.BrokerDomain)
	sanitizedHostname := strings.Replace(brokerHostname, ".", "_", -1)
	serviceUniqueName := "broker" + "|" + sanitizedHostname

	return &Broker{
		Hostname:          brokerHostname,
		ServiceUniqueName: serviceUniqueName,
	}
}

func main() {
	lifecycle.Startup("broker", false)
	logger.RunGaugesLoop(log)

	broker := NewBroker()
	broker.registerToKontrol()

	go broker.startSockJS()
	broker.startAMQP() // blocking

	time.Sleep(5 * time.Second) // give amqputil time to log connection error
}

func (b *Broker) registerToKontrol() {
	if err := kontrolhelper.RegisterToKontrol(
		"broker", // servicename
		"broker",
		b.ServiceUniqueName,
		config.Uuid,
		b.Hostname,
		config.Current.Broker.Port,
	); err != nil {
		panic(err)
	}
}

func (b *Broker) startAMQP() {
	b.PublishConn = amqputil.CreateConnection("broker")
	defer b.PublishConn.Close()

	consumeConn := amqputil.CreateConnection("broker")
	defer consumeConn.Close()

	consumeChannel := amqputil.CreateChannel(consumeConn)
	defer consumeChannel.Close()

	presenceQueue := amqputil.JoinPresenceExchange(
		consumeChannel,      // channel
		"services-presence", // exchange
		"broker",            // serviceType
		"broker",            // serviceGenericName
		b.ServiceUniqueName, // serviceUniqueName
		false,               // loadBalancing
	)

	go func() {
		sigusr1Channel := make(chan os.Signal)
		signal.Notify(sigusr1Channel, syscall.SIGUSR1)
		<-sigusr1Channel
		consumeChannel.QueueDelete(presenceQueue, false, false, false)
	}()

	stream := amqputil.DeclareBindConsumeQueue(consumeChannel, "topic", "broker", "#", false)

	if err := consumeChannel.ExchangeDeclare(
		"updateInstances", // name
		"fanout",          // kind
		false,             // durable
		false,             // autoDelete
		false,             // internal
		false,             // noWait
		nil,               // args
	); err != nil {
		panic(err)
	}

	if err := consumeChannel.ExchangeBind("broker", "", "updateInstances", false, nil); err != nil {
		panic(err)
	}

	// start to listen from "broker" topic exchange
	for amqpMessage := range stream {
		routingKey := amqpMessage.RoutingKey
		payload := json.RawMessage(utils.FilterInvalidUTF8(amqpMessage.Body))

		pos := strings.IndexRune(routingKey, '.') // skip first dot, since we want at least two components to always include the secret
		for pos != -1 && pos < len(routingKey) {
			index := strings.IndexRune(routingKey[pos+1:], '.')
			pos += index + 1
			if index == -1 {
				pos = len(routingKey)
			}
			prefix := routingKey[:pos]
			globalMapMutex.Lock()
			for _, routeSession := range routeMap[prefix] {
				sendToClient(routeSession, routingKey, &payload)
			}
			globalMapMutex.Unlock()
		}
	}
}

// startSockJS starts a new HTTPS listener that implies the SockJS protocol.
func (b *Broker) startSockJS() {
	service := sockjs.NewService(
		config.Current.Client.StaticFilesBaseUrl+"/js/sock.js",
		10*time.Minute,
		b.sockjsSession,
	)
	defer service.Close()

	service.MaxReceivedPerSecond = 50
	service.ErrorHandler = log.LogError

	// TODO use http.Mux instead of sockjs.Mux.
	server := &http.Server{
		Handler: &sockjs.Mux{
			Handlers: map[string]http.Handler{
				"/subscribe": service,
				"/buildnumber": http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
					w.Header().Set("Content-Type", "text/plain")
					w.Write([]byte(strconv.Itoa(config.Current.BuildNumber)))
				}),
			},
		},
	}

	var listener net.Listener
	listener, err := net.ListenTCP("tcp", &net.TCPAddr{IP: net.ParseIP(config.Current.Broker.IP), Port: config.Current.Broker.Port})
	if err != nil {
		log.Fatal(err)
	}

	if config.Current.Broker.CertFile != "" {
		cert, err := tls.LoadX509KeyPair(config.Current.Broker.CertFile, config.Current.Broker.KeyFile)
		if err != nil {
			log.Fatal(err)
		}
		listener = tls.NewListener(listener, &tls.Config{
			NextProtos:   []string{"http/1.1"},
			Certificates: []tls.Certificate{cert},
		})
	}

	lastErrorTime := time.Now()
	for {
		err := server.Serve(listener)
		if err != nil {
			log.Warning("Server error: %v", err)
			if time.Now().Sub(lastErrorTime) < time.Second {
				log.Fatal(nil)
			}
			lastErrorTime = time.Now()
		}
	}

}

// sendToClient sends the given payload back to the client. It attachs the
// routintKey along with the payload. It closes the session if sending fails.
func sendToClient(session *sockjs.Session, routingKey string, payload interface{}) {
	var message struct {
		RoutingKey string      `json:"routingKey"`
		Payload    interface{} `json:"payload"`
	}
	message.RoutingKey = routingKey
	message.Payload = payload
	if !session.Send(message) {
		session.Close()
		log.Warning("Dropped session because of broker to client buffer overflow. %v", session.Tag)
	}
}

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

	return &Client{
		Session:        session,
		SocketId:       socketID,
		ControlChannel: controlChannel,
		Broker:         broker,
		Subscriptions:  make(map[string]bool),
	}
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

func (c *Client) Unsubscribe(routingKeyPrefix string) {
	c.RemoveFromRoute(routingKeyPrefix)
	delete(c.Subscriptions, routingKeyPrefix)
}

func (b *Broker) sockjsSession(session *sockjs.Session) {
	defer log.RecoverAndLog()

	client := NewClient(session, b)

	sessionGaugeEnd := client.gaugeStart()
	defer sessionGaugeEnd()

	defer client.ControlChannel.Close()

	globalMapMutex.Lock()
	socketSubscriptionsMap[client.SocketId] = &client.Subscriptions
	globalMapMutex.Unlock()

	defer func() {
		globalMapMutex.Lock()
		for routingKeyPrefix := range client.Subscriptions {
			client.RemoveFromRoute(routingKeyPrefix)
		}
		globalMapMutex.Unlock()

		time.AfterFunc(5*time.Minute, func() {
			globalMapMutex.Lock()
			delete(socketSubscriptionsMap, client.SocketId)
			globalMapMutex.Unlock()
		})

		for {
			err := client.ControlChannel.Publish(config.Current.Broker.AuthAllExchange, "broker.clientDisconnected", false, false, amqp.Publishing{Body: []byte(client.SocketId)})
			if err == nil {
				break
			}
			if amqpError, isAmqpError := err.(*amqp.Error); !isAmqpError || amqpError.Code != 504 {
				panic(err)
			}
			client.resetControlChannel()
		}
	}()

	err := client.ControlChannel.Publish(config.Current.Broker.AuthAllExchange, "broker.clientConnected", false, false, amqp.Publishing{Body: []byte(client.SocketId)})
	if err != nil {
		panic(err)
	}

	sendToClient(session, "broker.connected", client.SocketId)

	for data := range session.ReceiveChan {
		if data == nil || session.Closed {
			break
		}

		defer log.RecoverAndLog()

		message := data.(map[string]interface{})
		log.Debug("Received message: %v", message)

		action := message["action"]
		switch action {
		case "subscribe":
			globalMapMutex.Lock()
			defer globalMapMutex.Unlock()
			for _, routingKeyPrefix := range strings.Split(message["routingKeyPrefix"].(string), " ") {
				client.Subscribe(routingKeyPrefix)
			}
			sendToClient(session, "broker.subscribed", message["routingKeyPrefix"])

		case "resubscribe":
			globalMapMutex.Lock()
			defer globalMapMutex.Unlock()
			oldSubscriptions, found := socketSubscriptionsMap[message["socketId"].(string)]
			if found {
				for routingKeyPrefix := range *oldSubscriptions {
					client.Subscribe(routingKeyPrefix)
				}
			}
			sendToClient(session, "broker.resubscribed", found)

		case "unsubscribe":
			globalMapMutex.Lock()
			defer globalMapMutex.Unlock()
			for _, routingKeyPrefix := range strings.Split(message["routingKeyPrefix"].(string), " ") {
				client.Unsubscribe(routingKeyPrefix)
			}

		case "publish":
			exchange := message["exchange"].(string)
			routingKey := message["routingKey"].(string)
			payload := message["payload"].(string)

			publish := func(exchange, routingKey, payload string) error {
				if !strings.HasPrefix(routingKey, "client.") {
					return fmt.Errorf("Invalid routing key: %v socketId: %v", routingKey, client.SocketId)
				}

				for {
					client.LastPayload = ""
					err := client.ControlChannel.Publish(exchange, routingKey, false, false, amqp.Publishing{CorrelationId: client.SocketId, Body: []byte(payload)})
					if err == nil {
						client.LastPayload = payload
						break
					}

					if amqpError, isAmqpError := err.(*amqp.Error); !isAmqpError || amqpError.Code != 504 {
						log.Warning("payload: %v routing key: %v exchange: %v err: %v",
							payload, routingKey, exchange, err)
					}

					time.Sleep(time.Second / 4) // penalty for crashing the AMQP channel
					client.resetControlChannel()
				}

				return nil
			}

			publish(exchange, routingKey, payload)

		case "ping":
			sendToClient(session, "broker.pong", nil)

		default:
			log.Warning("Invalid action. message: %v socketId: %v", message, client.SocketId)

		}
	}
}

// randomString() returns a new 16 char length random string
func randomString() string {
	r := make([]byte, 128/8)
	rand.Read(r)
	return base64.StdEncoding.EncodeToString(r)
}
