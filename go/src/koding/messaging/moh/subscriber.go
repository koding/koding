package moh

import (
	"code.google.com/p/go.net/websocket"
	"log"
	"time"
)

type Subscriber struct {
	addr    string
	ws      *websocket.Conn
	handler MessageHandler
}

// NewSubscriber opens a websocket connection to a Publisher and
// returns a pointer to newly created Subscriber.
// After creating a Subscriber you should subscribe to messages with Subscribe function.
func NewSubscriber(addr string, handler MessageHandler) (*Subscriber, error) {
	sub := &Subscriber{
		addr:    addr,
		handler: handler,
	}
	err := sub.connect()
	if err != nil {
		return nil, err
	}

	go sub.consumer()
	return sub, err
}

// Subscribe registers the Subscriber to receive messages matching with the key.
func (s *Subscriber) Subscribe(key string) error {
	return websocket.Message.Send(s.ws, key)
}

func (s *Subscriber) connect() error {
	url := "ws://" + s.addr + "/"
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
			time.Sleep(100 * time.Millisecond)
			continue
		}
		go s.consumer()
		return
	}
}

// consumer reads the messages from websocket until the connection is dropped.
// When the connection drops it runs a connector() goroutine and returns.
func (s *Subscriber) consumer() {
	for {
		var message []byte
		log.Println("Reading from websocket")
		err := websocket.Message.Receive(s.ws, &message)
		if err != nil {
			log.Println("Cannot read message from websocket")
			s.ws.Close()
			// Connected() checks this pointer.
			// Set it to nil to indicate that we are disconnected.
			s.ws = nil
			go s.connector()
			return
		}
		log.Println("Received data:", message)
		s.handler(message)
	}
}
