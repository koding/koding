package main

import (
	"crypto/tls"
	"encoding/json"
	"flag"
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
	"runtime"
	"strconv"
	"strings"
	"sync"
	"syscall"
	"time"

	"github.com/koding/redis"

	"github.com/streadway/amqp"
	set "gopkg.in/fatih/set.v0"
)

const BROKER_NAME = "broker"

var (
	conf *config.Config
	log  = logger.New(BROKER_NAME)

	// routeMap holds the subscription list/set for any given routing key
	routeMap = make(map[string]*set.Set)

	// sessionsMap holds sessions with their socketIds
	sessionsMap = make(map[string]*sockjs.Session)

	globalMapMutex sync.Mutex

	changeClientsGauge          = lifecycle.CreateClientsGauge()
	changeNewClientsGauge       = logger.CreateCounterGauge("newClients", logger.NoUnit, true)
	changeWebsocketClientsGauge = logger.CreateCounterGauge("websocketClients", logger.NoUnit, false)

	flagProfile      = flag.String("c", "", "Configuration profile from file")
	flagBrokerDomain = flag.String("a", "", "Send kontrol a custom domain istead of os.Hostname")
	flagDuration     = flag.Duration("t", time.Second*5, "Duration for timeout in seconds - Duration flag accept any input valid for time.ParseDuration.")
	flagKontrolUUID  = flag.String("u", "", "Enable Kontrol mode")
	flagBrokerType   = flag.String("b", "broker", "Define broker type. Available: broker, premiumBroker and brokerKite, premiumBrokerKite. B")
	flagDebug        = flag.Bool("d", false, "Debug mode")
)

// Broker is a router/multiplexer that routes messages coming from a SockJS
// server to an AMQP exchange and vice versa. Broker basically listens to
// client messages (Koding users) from the SockJS server. The message is
// either passed to the appropriate exchange or a response is sent back to the
// client. Each message has an "action" field that defines how to act for a
// received message.
type Broker struct {
	Config            *config.Broker
	Hostname          string
	ServiceUniqueName string
	AuthAllExchange   string
	PublishConn       *amqp.Connection
	ConsumeConn       *amqp.Connection
	// we should open only one connection session to Redis for one broker
	RedisSingleton *redis.SingletonSession

	// Accepts SockJS connections
	listener net.Listener

	// Closed when SockJS server is ready to acccept connections
	ready chan struct{}
}

// NewBroker returns a new Broker instance with ServiceUniqueName and Hostname
// prepopulated. After creating a Broker instance, one has to call
// broker.Run() or broker.Start() to start the broker instance and call
// broker.Close() for a graceful stop.
func NewBroker(conf *config.Config) *Broker {
	// returns os.Hostname() if config.BrokerDomain is empty, otherwise it just
	// returns config.BrokerDomain back
	brokerHostname := kontrolhelper.CustomHostname(*flagBrokerDomain)
	sanitizedHostname := strings.Replace(brokerHostname, ".", "_", -1)
	serviceUniqueName := BROKER_NAME + "|" + sanitizedHostname

	return &Broker{
		Hostname:          brokerHostname,
		ServiceUniqueName: serviceUniqueName,
		ready:             make(chan struct{}),
		RedisSingleton:    redis.Singleton(conf.Redis),
	}
}

func main() {
	flag.Parse()
	if *flagProfile == "" {
		log.Fatal("Please specify profile via -c. Aborting.")
	}

	conf = config.MustConfig(*flagProfile)
	broker := NewBroker(conf)

	switch *flagBrokerType {
	case "premiumBroker":
		broker.Config = &conf.PremiumBroker
	case "brokerKite":
		broker.Config = &conf.BrokerKite
	case "premiumBrokerKite":
		broker.Config = &conf.PremiumBrokerKite
	default:
		broker.Config = &conf.Broker
	}

	// update broker name
	log = logger.New(broker.Config.Name)
	var logLevel logger.Level
	if *flagDebug {
		logLevel = logger.DEBUG
	} else {
		logLevel = logger.GetLoggingLevelFromConfig(BROKER_NAME, *flagProfile)
	}

	log.SetLevel(logLevel)
	broker.Run()
}

// Run starts the broker.
func (b *Broker) Run() {
	// sets the maximum number of CPUs that can be executing simultaneously
	runtime.GOMAXPROCS(runtime.NumCPU())

	lifecycle.Startup(BROKER_NAME, false)
	logger.RunGaugesLoop(log)

	// Register broker to kontrol
	if err := b.registerToKontrol(); err != nil {
		log.Critical("Couldnt register to kontrol, stopping... %v", err)
		return
	}

	// Create AMQP exchanges/queues/bindings
	if err := b.startAMQP(); err != nil {
		log.Critical("Couldnt create amqp bindings, stopping... %v", err)
		return
	}

	// start listening/serving socket server
	b.startSockJS() // blocking
}

// Start is like Run() but waits until the SockJS listener is ready to be
// used.
func (b *Broker) Start() {
	go b.Run()
	<-b.ready
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
func (b *Broker) registerToKontrol() error {
	if err := kontrolhelper.RegisterToKontrol(
		conf,
		b.Config.Name,
		b.Config.ServiceGenericName, // servicGenericName
		b.ServiceUniqueName,
		*flagKontrolUUID,
		b.Hostname,
		b.Config.Port,
	); err != nil {
		return err
	}
	return nil
}

// startAMQP setups the the neccesary publisher and consumer connections for
// the broker broker.
func (b *Broker) startAMQP() error {
	b.PublishConn = amqputil.CreateConnection(conf, b.Config.Name)
	b.ConsumeConn = amqputil.CreateConnection(conf, b.Config.Name)
	consumeChannel := amqputil.CreateChannel(b.ConsumeConn)

	go func() {
		sigusr1Channel := make(chan os.Signal)
		signal.Notify(sigusr1Channel, syscall.SIGUSR1)
		<-sigusr1Channel
	}()

	stream := amqputil.DeclareBindConsumeQueue(consumeChannel, "topic", b.Config.ServiceGenericName, "#", false)

	if err := consumeChannel.ExchangeDeclare(
		"updateInstances", // name
		"fanout",          // kind
		false,             // durable
		false,             // autoDelete
		false,             // internal
		false,             // noWait
		nil,               // args
	); err != nil {
		return fmt.Errorf("Couldnt create updateInstances exchange  %v", err)
	}

	if err := consumeChannel.ExchangeBind(BROKER_NAME, "", "updateInstances", false, nil); err != nil {
		return fmt.Errorf("Couldnt bind to updateInstances exchange  %v", err)
	}

	go func(stream <-chan amqp.Delivery) {
		// start to listen from "broker" topic exchange
		for amqpMessage := range stream {
			sendMessageToClient(amqpMessage)
		}

		b.Close()

	}(stream)

	return nil
}

// sendMessageToClient takes an amqp messsage and delivers it to the related
// clients which are subscribed to the routing key
func sendMessageToClient(amqpMessage amqp.Delivery) {
	routingKey := amqpMessage.RoutingKey
	payloadsByte := utils.FilterInvalidUTF8(amqpMessage.Body)

	// We are sending multiple bodies for updateInstances exchange
	// so that there will be another operations, if exchange is not "updateInstances"
	// no need to add more overhead
	if amqpMessage.Exchange != "updateInstances" {
		payloadRaw := json.RawMessage(payloadsByte)
		processMessage(routingKey, &payloadRaw)
		return
	}

	// this part is only for updateInstances exchange
	var payloads []interface{}
	// unmarshal data to slice of interface
	if err := json.Unmarshal(payloadsByte, &payloads); err != nil {
		log.Error("Error while unmarshalling:%v data:%v routingKey:%v", err, string(payloadsByte), routingKey)
		return
	}

	// range over the slice and send all of them to the same routingkey
	for _, payload := range payloads {
		payloadByte, err := json.Marshal(payload)
		if err != nil {
			log.Error("Error while marshalling:%v data:%v routingKey:%v", err, string(payloadByte), routingKey)
			continue
		}
		payloadByteRaw := json.RawMessage(payloadByte)
		processMessage(routingKey, &payloadByteRaw)
	}
}

// processMessage gets routingKey and a payload for sending them to the client
// Gets subscription bindings from global routeMap
func processMessage(routingKey string, payload interface{}) {
	pos := strings.IndexRune(routingKey, '.') // skip first dot, since we want at least two components to always include the secret
	for pos != -1 && pos < len(routingKey) {
		index := strings.IndexRune(routingKey[pos+1:], '.')
		pos += index + 1
		if index == -1 {
			pos = len(routingKey)
		}
		routingKeyPrefix := routingKey[:pos]
		globalMapMutex.Lock()

		if routes, ok := routeMap[routingKeyPrefix]; ok {
			routes.Each(func(sessionId interface{}) bool {
				if routeSession, ok := sessionsMap[sessionId.(string)]; ok {
					sendToClient(routeSession, routingKey, &payload)
				}
				return true
			})
		}
		globalMapMutex.Unlock()
	}
}

// startSockJS starts a new HTTPS listener that implies the SockJS protocol.
func (b *Broker) startSockJS() {
	service := sockjs.NewService(
		conf.Client.StaticFilesBaseUrl+"/js/sock.js",
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
				w.Write([]byte(strconv.Itoa(conf.BuildNumber)))
			}),
		},
	}

	server := &http.Server{Handler: mux}

	var err error
	b.listener, err = net.ListenTCP("tcp", &net.TCPAddr{IP: net.ParseIP(b.Config.IP), Port: b.Config.Port})
	if err != nil {
		log.Fatal(err)
	}

	if b.Config.CertFile != "" {
		cert, err := tls.LoadX509KeyPair(b.Config.CertFile, b.Config.KeyFile)
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
	clientChan := make(chan *Client, 0)
	errChan := make(chan error, 0)

	go createClient(b, session, clientChan, errChan)

	// Return if there is any error or if we don't get the result in 5 seconds back
	var client *Client
	select {
	case client = <-clientChan:
	case err := <-errChan:
		log.Critical("An error occured while creating client %v", err)
		return
	case <-time.After(*flagDuration):
		log.Critical("Client coulnt created in %s exiting ", flagDuration.String())
		return
	}

	sessionGaugeEnd := client.gaugeStart()

	defer sessionGaugeEnd()
	defer client.Close()

	for data := range session.ReceiveChan {
		if data == nil || session.Closed {
			break
		}

		client.handleSessionMessage(data)
	}
}

func createClient(b *Broker, session *sockjs.Session, clientChan chan *Client, errChan chan error) {
	// do not forget to close channels
	defer close(errChan)
	defer close(clientChan)

	client, err := NewClient(session, b)
	if err != nil {
		log.Critical("Couldnt create client %v", err)
		errChan <- err
		return
	}

	err = client.ControlChannel.Publish(b.Config.AuthAllExchange, "broker.clientConnected", false, false, amqp.Publishing{Body: []byte(client.SocketId)})
	if err != nil {
		log.Critical("Couldnt publish to control channel %v", err)
		errChan <- err
		return
	}

	// if session is closed before the client creation no need to send
	// client object to listeners
	if !session.Closed {
		sendToClient(session, "broker.connected", client.SocketId)
		clientChan <- client
	} else {
		errChan <- fmt.Errorf("Session already closed here")
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
