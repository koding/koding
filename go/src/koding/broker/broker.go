package main

import (
	"crypto/tls"
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

	changeClientsGauge          = lifecycle.CreateClientsGauge()
	changeNewClientsGauge       = logger.CreateCounterGauge("newClients", logger.NoUnit, true)
	changeWebsocketClientsGauge = logger.CreateCounterGauge("websocketClients", logger.NoUnit, false)
)

// Broker is a router/multiplexer that routes messages coming from a SockJS
// server to an AMQP exchange and vice versa. Broker basically listens to
// client messages (Koding users) from the SockJS server. The message is
// either passed to the appropriate exchange or a response is sent back to the
// client. Each message has an "action" field that defines how to act for a
// received message.
type Broker struct {
	Hostname          string
	ServiceUniqueName string
	PublishConn       *amqp.Connection
	ConsumeConn       *amqp.Connection

	// Accepts SockJS connections
	listener net.Listener

	// Closed when SockJS server is ready to acccept connections
	ready chan struct{}

	// Closed when AMQP connection and channel are setup
	amqpReady chan struct{}
}

// NewBroker returns a new Broker instance with ServiceUniqueName and Hostname
// prepopulated. After creating a Broker instance, one has to call
// broker.Run() or broker.Start() to start the broker instance and call
// broker.Close() for a graceful stop.
func NewBroker() *Broker {
	// returns os.Hostname() if config.BrokerDomain is empty, otherwise it just
	// returns config.BrokerDomain back
	brokerHostname := kontrolhelper.CustomHostname(config.BrokerDomain)
	sanitizedHostname := strings.Replace(brokerHostname, ".", "_", -1)
	serviceUniqueName := "broker" + "|" + sanitizedHostname

	return &Broker{
		Hostname:          brokerHostname,
		ServiceUniqueName: serviceUniqueName,
		ready:             make(chan struct{}),
		amqpReady:         make(chan struct{}),
	}
}

func main() {
	NewBroker().Run()
}

// Run starts the broker.
func (b *Broker) Run() {
	lifecycle.Startup("broker", false)
	logger.RunGaugesLoop(log)

	b.registerToKontrol()

	go b.startAMQP()
	<-b.amqpReady
	b.startSockJS() // blocking

	time.Sleep(5 * time.Second) // give amqputil time to log connection error
}

// Start is like Run() but waits until the SockJS listener is ready to be
// used.
func (b *Broker) Start() {
	go b.Run()
	<-b.ready

	// I don't know why this is happening because of recovering panics.
	// Putting this sleep here to prevent it from happening.
	// Remove this hack after getting rid of defer recoverAndLog() statements.
	time.Sleep(1 * time.Second)
}

// Close close all amqp connections and closes the SockJS server listener
func (b *Broker) Close() {
	b.PublishConn.Close()
	b.ConsumeConn.Close()
	b.listener.Close()
}

// registerToKontrol registers the broker to KontrolDaemon. This is needed to
// populate a list of brokers and show them to the client. The list is
// available at: https://koding.com/-/services/broker?all
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

// startAMQP setups the the neccesary publisher and consumer connections for
// the broker broker.
func (b *Broker) startAMQP() {
	b.PublishConn = amqputil.CreateConnection("broker")
	defer b.PublishConn.Close()

	b.ConsumeConn = amqputil.CreateConnection("broker")
	defer b.ConsumeConn.Close()

	consumeChannel := amqputil.CreateChannel(b.ConsumeConn)
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

	// signal that we are ready now
	close(b.amqpReady)

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
	mux := &sockjs.Mux{
		Handlers: map[string]http.Handler{
			"/subscribe": service,
			"/buildnumber": http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				w.Header().Set("Content-Type", "text/plain")
				w.Write([]byte(strconv.Itoa(config.Current.BuildNumber)))
			}),
		},
	}

	server := &http.Server{Handler: mux}

	var err error
	b.listener, err = net.ListenTCP("tcp", &net.TCPAddr{IP: net.ParseIP(config.Current.Broker.IP), Port: config.Current.Broker.Port})
	if err != nil {
		log.Fatal(err)
	}

	if config.Current.Broker.CertFile != "" {
		cert, err := tls.LoadX509KeyPair(config.Current.Broker.CertFile, config.Current.Broker.KeyFile)
		if err != nil {
			log.Fatal(err)
		}
		b.listener = tls.NewListener(b.listener, &tls.Config{
			NextProtos:   []string{"http/1.1"},
			Certificates: []tls.Certificate{cert},
		})
	}

	// signal that we are ready now
	close(b.ready)

	lastErrorTime := time.Now()
	for {
		err := server.Serve(b.listener)
		if err != nil {
			// comes when the broker is closed with Close() method. This error
			// is defined in net/net.go as "var errClosing", unfortunaly it's
			// not exported.
			if strings.Contains(err.Error(), "use of closed network connection") {
				return
			}

			log.Warning("Server error: %v", err)
			if time.Now().Sub(lastErrorTime) < time.Second {
				log.Fatal(nil)
			}
			lastErrorTime = time.Now()
		}
	}

}

// sockjsSession is called for every client connection and handles all the
// message trafic for a single client connection.
func (b *Broker) sockjsSession(session *sockjs.Session) {
	defer log.RecoverAndLog()

	client := NewClient(session, b)
	sessionGaugeEnd := client.gaugeStart()

	defer sessionGaugeEnd()
	defer client.Close()

	err := client.ControlChannel.Publish(config.Current.Broker.AuthAllExchange, "broker.clientConnected", false, false, amqp.Publishing{Body: []byte(client.SocketId)})
	if err != nil {
		panic(err)
	}

	sendToClient(session, "broker.connected", client.SocketId)

	for data := range session.ReceiveChan {
		if data == nil || session.Closed {
			break
		}

		client.handleSessionMessage(data)
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
