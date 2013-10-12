package moh

import (
	"code.google.com/p/go.net/websocket"
	"log"
	"net/url"
	"sync"
	"time"
)

const reconnectInterval = 100 * time.Millisecond

// Subscriber is a websocket client that is used to connect to a Publisher and
// consume published messages.
type Subscriber struct {
	// Path of the server to be connected
	url *url.URL

	// Connection to the Publisher.
	// Will be non-nil when the subscriber is connected.
	ws *websocket.Conn

	// Consumed messages will be handled with this function.
	handler func([]byte)

	// Subscription keys are also saved here so we can re-send "subscribe"
	// commands when re-connect.
	keys map[string]bool

	// For controlling access over keys
	keysMutex sync.Mutex
}

// NewSubscriber opens a websocket connection to a Publisher and returns a
// pointer to newly created Subscriber.  After creating a Subscriber you should
// subscribe to messages with Subscribe function.
func NewSubscriber(urlStr string, handler func([]byte)) (*Subscriber, error) {
	parsed, err := url.Parse(urlStr)
	if err != nil {
		return nil, err
	}

	sub := &Subscriber{
		url:     parsed,
		handler: handler,
		keys:    make(map[string]bool),
	}

	go sub.connector()
	return sub, err
}

type subscriberCommand struct {
	Name string `json:"name"`
	Args args   `json:"args"`
}

type args map[string]interface{}

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

// Connected returns the status of the websocket connection.
func (s *Subscriber) Connected() bool {
	// We are checking the pointer here because
	// it will be set to nil on disconnect by consumer().
	return s.ws != nil
}

// connector tries to connect to the server forever.
// When the connection is established it runs a consumer() goroutine and returns.
func (s *Subscriber) connector() {
	for {
		err := s.connect()
		if err != nil {
			time.Sleep(reconnectInterval)
			continue
		}

		err = s.sendSubscriptionCommands()
		if err != nil {
			log.Println("Error while sending subscription commands: %s", err)
		}

		go s.consumer()
		return
	}
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
			go s.connector()
			return
		}
		// log.Println("Received data:", string(message))
		s.handler(message)
	}
}
