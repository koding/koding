package main

import (
	"crypto/tls"
	"encoding/json"
	"koding/broker/cache"
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
	socketSubscriptionsMap = make(map[string]*cache.SubscriptionSet)
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
