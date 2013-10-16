package moh

import (
	"code.google.com/p/go.net/websocket"
	"log"
	"net/url"
	"sync"
	"time"
)

const reconnectInterval = 700 * time.Millisecond

// Subscriber is a websocket client that is used to connect to a Publisher and
// consume published messages.
type Subscriber struct {
	// Path of the server to be connected
	url *url.URL

	// Connection to the Publisher.
	// Will be non-nil when the subscriber is connected.
	ws *websocket.Conn

	// Are we going to re-connect?
	reconnect bool

	// Consumed messages will be handled with this function.
	Handler func([]byte)

	// Subscription keys are also saved here so we can re-send "subscribe"
	// commands when re-connect.
	keys map[string]bool

	// For controlling access over keys
	keysMutex sync.Mutex

	// errCount defines the number o reconnection errors
	errCount int
}

type subscriberCommand struct {
	Name string `json:"name"`
	Args args   `json:"args"`
}

type args map[string]interface{}

// NewSubscriber opens a websocket connection to a Publisher and returns a
// pointer to newly created Subscriber.  After creating a Subscriber you should
// subscribe to messages with Subscribe() and call Connect() explicitly.
func NewSubscriber(urlStr string, handler func([]byte)) *Subscriber {
	parsed, err := url.Parse(urlStr)
	if err != nil {
		panic(err)
	}

	return &Subscriber{
		url:     parsed,
		Handler: handler,
		keys:    make(map[string]bool),
	}
}

// Connect tries connecting to the server. The function returns immediately
// before the connection happens. If you want to wait for a connection
// you can wait for a message from the channel returned.
func (s *Subscriber) Connect() chan bool {
	s.reconnect = true
	connected := make(chan bool, 1)
	go s.connector(connected)
	return connected
}

// Close closes the open websocket connection to the server. Does not do
// anything if it is already closed.
func (s *Subscriber) Close() {
	s.reconnect = false
	ws := s.ws
	if ws == nil {
		return
	}
	ws.Close()
}

// Subscribe registers the Subscriber to receive messages matching with the key.
func (s *Subscriber) Subscribe(key string) {
	// Put it into keys first
	s.keysMutex.Lock()
	s.keys[key] = true
	s.keysMutex.Unlock()

	// Do not send the command if it is not connected
	ws := s.ws
	if ws == nil {
		return
	}

	// Then send to the server
	cmd := subscriberCommand{
		Name: "subscribe",
		Args: args{"key": key},
	}

	// We do not check for the error here because if it fails the command will
	// be sent by sendSubscriptionCommands() after re-connecting.
	websocket.JSON.Send(ws, cmd)
}

// Unsubscribe stops the Subscriber from receiving messages matching with the key.
func (s *Subscriber) Unsubscribe(key string) {
	// Remove from the keys first
	s.keysMutex.Lock()
	delete(s.keys, key)
	s.keysMutex.Unlock()

	// Do not send the command if it is not connected
	ws := s.ws
	if ws == nil {
		return
	}

	// Then send to the server
	cmd := subscriberCommand{
		Name: "unsubscribe",
		Args: args{"key": key},
	}
	websocket.JSON.Send(ws, cmd)
}

// Connected returns the status of the websocket connection.
func (s *Subscriber) Connected() bool {
	// We are checking the pointer here because
	// it will be set to nil on disconnect by consumer().
	return s.ws != nil
}

func (s *Subscriber) connect() error {
	url := s.url.String()
	origin := "http://localhost/" // dont know if this is required

	log.Println("Connecting to url:", url)
	ws, err := websocket.Dial(url, "", origin)
	if err != nil {
		log.Println("Cannot connect")
		return err
	}

	log.Println("Connection is successfull")
	s.ws = ws
	return nil
}

// connector tries to connect to the server forever. When the connection is
// established it runs a consumer() goroutine and returns.
func (s *Subscriber) connector(connected chan bool) {
	for {
		// Do not try re-connecting if Close() is called.
		if !s.reconnect {
			return
		}

		err := s.connect()
		if err != nil {
			s.errCount++

			// for now we don't return an error, but in the future an error
			// will mean that it has reached it maximum number of reconnect
			// attempts, which then we will return.
			s.sleep()
			continue
		}

		s.errCount = 0

		err = s.sendSubscriptionCommands()
		if err != nil {
			log.Printf("Error while sending subscription commands: %s\n", err)
		}

		go s.consumer()
		connected <- true
		return
	}
}

func (s *Subscriber) sleep() {
	time.Sleep(reconnectInterval * time.Duration(s.errCount))
}

// sendSubscriptionCommands is called after connecting the server to subscribe saved keys.
func (s *Subscriber) sendSubscriptionCommands() error {
	s.keysMutex.Lock()
	defer s.keysMutex.Unlock()

	for key := range s.keys {
		cmd := subscriberCommand{
			Name: "subscribe",
			Args: args{"key": key},
		}

		err := websocket.JSON.Send(s.ws, cmd)
		if err != nil {
			return err
		}
	}

	return nil
}

// consumer reads the messages from websocket until the connection is dropped.
// When the connection drops it runs a connector() goroutine and returns.
func (s *Subscriber) consumer() {
	for {
		var message []byte
		err := websocket.Message.Receive(s.ws, &message)
		if err != nil {
			log.Println("Cannot read message from websocket")
			s.ws.Close()
			// Connected() checks this pointer.
			// Set it to nil to indicate that we are disconnected.
			// Also allow it be garbage collected.
			s.ws = nil
			go s.connector(make(chan bool, 1))
			return
		}

		// log.Println("Received data:", string(message))
		s.Handler(message)
	}
}
