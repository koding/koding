package main

import (
	"crypto/rand"
	"crypto/tls"
	"encoding/base64"
	"encoding/json"
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

func randomString() string {
	r := make([]byte, 128/8)
	rand.Read(r)
	return base64.StdEncoding.EncodeToString(r)
}

// sessionGaugeStart starts the gauge for a given session. It returns a new
// function which ends the gauge for the given session. Usually one invokes
// sessionGaugeStart and calls the returned function in a defer statement.
func sessionGaugeStart(session *sockjs.Session) (sessionGaugeEnd func()) {
	log.Debug("Client connected: %v", session.Tag)
	changeClientsGauge := lifecycle.CreateClientsGauge()
	changeNewClientsGauge := logger.CreateCounterGauge("newClients", logger.NoUnit, true)
	changeWebsocketClientsGauge := logger.CreateCounterGauge("websocketClients", logger.NoUnit, false)

	changeClientsGauge(1)
	changeNewClientsGauge(1)
	if session.IsWebsocket {
		changeWebsocketClientsGauge(1)
	}

	return func() {
		log.Debug("Client disconnected: %v", session.Tag)
		changeClientsGauge(-1)
		if session.IsWebsocket {
			changeWebsocketClientsGauge(-1)
		}
	}
}

func (b *Broker) sockjsSession(session *sockjs.Session) {
	defer log.RecoverAndLog()

	socketId := randomString()
	session.Tag = socketId

	sessionGaugeEnd := sessionGaugeStart(session)
	defer sessionGaugeEnd()

	var controlChannel *amqp.Channel
	var lastPayload string
	resetControlChannel := func() {
		if controlChannel != nil {
			controlChannel.Close()
		}
		var err error
		controlChannel, err = b.PublishConn.Channel()
		if err != nil {
			panic(err)
		}
		go func() {
			defer log.RecoverAndLog()

			for amqpErr := range controlChannel.NotifyClose(make(chan *amqp.Error)) {
				if !(strings.Contains(amqpErr.Error(), "NOT_FOUND") && (strings.Contains(amqpErr.Error(), "koding-social-") || strings.Contains(amqpErr.Error(), "auth-"))) {
					log.Warning("AMQP channel: %v Last publish payload: %v", amqpErr.Error(), lastPayload)
				}

				sendToClient(session, "broker.error", map[string]interface{}{"code": amqpErr.Code, "reason": amqpErr.Reason, "server": amqpErr.Server, "recover": amqpErr.Recover})
			}
		}()
	}
	resetControlChannel()
	defer func() { controlChannel.Close() }()

	subscriptions := make(map[string]bool)
	globalMapMutex.Lock()
	socketSubscriptionsMap[socketId] = &subscriptions
	globalMapMutex.Unlock()

	removeFromRouteMap := func(routingKeyPrefix string) {
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

	subscribe := func(routingKeyPrefix string) {
		if subscriptions[routingKeyPrefix] {
			log.Warning("Duplicate subscription to same routing key. %v %v", session.Tag, routingKeyPrefix)
			return
		}
		if len(subscriptions) > 0 && len(subscriptions)%2000 == 0 {
			log.Warning("Client with more than %v subscriptions %v", strconv.Itoa(len(subscriptions)), session.Tag)
		}
		routeMap[routingKeyPrefix] = append(routeMap[routingKeyPrefix], session)
		subscriptions[routingKeyPrefix] = true
	}

	unsubscribe := func(routingKeyPrefix string) {
		removeFromRouteMap(routingKeyPrefix)
		delete(subscriptions, routingKeyPrefix)
	}

	defer func() {
		globalMapMutex.Lock()
		for routingKeyPrefix := range subscriptions {
			removeFromRouteMap(routingKeyPrefix)
		}
		globalMapMutex.Unlock()

		time.AfterFunc(5*time.Minute, func() {
			globalMapMutex.Lock()
			delete(socketSubscriptionsMap, socketId)
			globalMapMutex.Unlock()
		})

		for {
			err := controlChannel.Publish(config.Current.Broker.AuthAllExchange, "broker.clientDisconnected", false, false, amqp.Publishing{Body: []byte(socketId)})
			if err == nil {
				break
			}
			if amqpError, isAmqpError := err.(*amqp.Error); !isAmqpError || amqpError.Code != 504 {
				panic(err)
			}
			resetControlChannel()
		}
	}()

	err := controlChannel.Publish(config.Current.Broker.AuthAllExchange, "broker.clientConnected", false, false, amqp.Publishing{Body: []byte(socketId)})
	if err != nil {
		panic(err)
	}

	sendToClient(session, "broker.connected", socketId)

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
				subscribe(routingKeyPrefix)
			}
			sendToClient(session, "broker.subscribed", message["routingKeyPrefix"])

		case "resubscribe":
			globalMapMutex.Lock()
			defer globalMapMutex.Unlock()
			oldSubscriptions, found := socketSubscriptionsMap[message["socketId"].(string)]
			if found {
				for routingKeyPrefix := range *oldSubscriptions {
					subscribe(routingKeyPrefix)
				}
			}
			sendToClient(session, "broker.resubscribed", found)

		case "unsubscribe":
			globalMapMutex.Lock()
			defer globalMapMutex.Unlock()
			for _, routingKeyPrefix := range strings.Split(message["routingKeyPrefix"].(string), " ") {
				unsubscribe(routingKeyPrefix)
			}

		case "publish":
			exchange := message["exchange"].(string)
			routingKey := message["routingKey"].(string)
			if !strings.HasPrefix(routingKey, "client.") {
				log.Warning("Invalid routing key: message: %v socketId: %v", message, socketId)
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
					log.Warning("payload: %v routing key: %v exchange: %v err: %v", message["payload"], message["routingKey"], message["exchange"], err)
				}
				time.Sleep(time.Second / 4) // penalty for crashing the AMQP channel
				resetControlChannel()
			}

		case "ping":
			sendToClient(session, "broker.pong", nil)

		default:
			log.Warning("Invalid action. message: %v socketId: %v", message, socketId)

		}
	}
}
