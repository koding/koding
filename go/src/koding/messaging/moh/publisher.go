package moh

import (
	"code.google.com/p/go.net/websocket"
	"log"
	"net/http"
)

// Publisher is the counterpart for Subscriber.
// It is a HTTP server accepting websocket connections.
type Publisher struct {
	// Registered filters, holds pointers to open connections.
	// All clients are registered to the "all" key by default for allowing broadcasting.
	// Modifier operations on this type is made by registrar() function.
	filters *Filters

	// Authenticate is an optional function to authenticate the user on websocket handshake.
	// If it returns an error, the websocket connection will not be accepted.
	// The returned username will be put in "Koding-Username" header,
	// the connection handler can read it from there.
	Authenticate func(*websocket.Config, *http.Request) (username string, err error)

	// ValidateCommand is an optional fucntion to be called on each command
	// coming from subscriber. Should return true if the command will be allowed.
	// If it returns false, then the connection will be dropped.
	ValidateCommand func(*websocket.Conn, *SubscriberCommand) bool

	websocket.Server // implements http.Handler interface
}

// This is the magic subscription key for broadcast events.
// Hoping that it is unique enough to not collide with another key.
const all = "4658f005d49885355f4e771ed9dace10cca9563e"

// NewPublisher creates a new Publisher and returns a pointer to it.  The
// publisher will listen on addr and accept websocket connections from
// Subscribers.
func NewPublisher() *Publisher {
	p := &Publisher{
		filters: NewFilters(),
		Server:  websocket.Server{},
	}
	p.Server.Handler = p.handleWebsocketConn
	p.Server.Handshake = p.handleHandshake
	return p
}

// Publish sends a message to registered Subscribers with the key.
func (p *Publisher) Publish(key string, message []byte) {
	// log.Println("Sending message to send channel", string(message))
	for c := range p.filters.Get(key) {
		select {
		case c.send <- message:
			// log.Println("Message sent to send channel")
		default:
			// Buffer is full, writer() is not fast enough to send all published messages .
			// Drop the websocket client and let it synchronize by re-connecting.
			log.Println("Websocket buffer is full. Dropping socket")
			go c.ws.Close()
		}
	}
}

// Broadcast sends a message to all of the connected Subscribers.
func (p *Publisher) Broadcast(message []byte) {
	p.Publish(all, message)
}

func (p *Publisher) handleHandshake(c *websocket.Config, r *http.Request) error {
	// Do not do anything if Authenticate function is not set.
	if p.Authenticate == nil {
		return nil
	}

	username, err := p.Authenticate(c, r)
	if err != nil {
		return err
	}

	r.Header.Set("Koding-Username", username)
	return nil
}

func (p *Publisher) handleWebsocketConn(ws *websocket.Conn) {
	c := &connection{
		ws:        ws,
		publisher: p,
		send:      make(chan []byte, 256),
		keys:      make(map[string]bool),
	}

	p.filters.Add(c, all)
	defer func() {
		p.filters.RemoveAll(c)
		close(c.send)
	}()

	go c.writer()
	c.reader()
}

// connection represents a connected Subscriber in Publisher.
type connection struct {
	ws        *websocket.Conn
	publisher *Publisher

	// Buffered channel of outbount messages
	send chan []byte

	// Subscription keys
	keys map[string]bool
}

// reader reads the subscription requests from websocket and saves it in a map
// for accessing later.
func (c *connection) reader() {
	for {
		var cmd SubscriberCommand
		err := websocket.JSON.Receive(c.ws, &cmd)
		if err != nil {
			log.Println("reader: Cannot receive message from websocket")
			break
		}

		// Drop the websocket connection if the command is invalid.
		if c.publisher.ValidateCommand != nil && !c.publisher.ValidateCommand(c.ws, &cmd) {
			break
		}

		// log.Printf("reader: Received a command from websocket: %+v\n", cmd)
		if cmd.Name == "subscribe" {
			key := cmd.Args["key"].(string)
			c.publisher.filters.Add(c, key)
		} else if cmd.Name == "unsubscribe" {
			key := cmd.Args["key"].(string)
			c.publisher.filters.Remove(c, key)
		} else {
			log.Println("Unknown command, dropping client")
			break
		}
	}
	c.ws.Close()
}

// writer writes the messages to the websocket from the send channel.
func (c *connection) writer() {
	for message := range c.send {
		err := websocket.Message.Send(c.ws, message)
		if err != nil {
			log.Println("writer: Cannot send message to websocket")
			break
		}
	}
	c.ws.Close()
}
