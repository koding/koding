package moh

import (
	"code.google.com/p/go.net/websocket"
	"log"
	"sync"
)

type Publisher struct {
	MessagingServer

	// Registered connections
	connections map[*connection]bool

	// Registered filters
	filters      map[string]([]*connection)
	filtersMutex sync.Mutex

	// Register requests from the connections
	register chan *connection

	// Unregister requests from the connections
	unregister chan *connection
}

func NewPublisher(addr string) (*Publisher, error) {
	s, err := NewClosableServer(addr)
	if err != nil {
		return nil, err
	}

	p := &Publisher{
		MessagingServer: *s,
		connections:     make(map[*connection]bool),
		filters:         make(map[string]([]*connection)),
		register:        make(chan *connection),
		unregister:      make(chan *connection),
	}

	p.Mux.Handle("/", p.makeWsHandler())

	go s.Serve() // Starts HTTP server
	go p.registrar()

	return p, nil
}

func (p *Publisher) Publish(key string, message []byte) {
	p.filtersMutex.Lock()
	defer p.filtersMutex.Unlock()

	connections, ok := p.filters[key]
	if !ok {
		log.Println("No matching filters")
		return
	}

	log.Println("Sending message to send channel")
	for _, c := range connections {
		select {
		case (*c).send <- message:
			log.Println("Message sent to send channel")
		default:
			// TODO remove from filters
			// delete(connections, c)
			// close(c.send)
			go c.ws.Close()
		}
	}
}

func (p *Publisher) Broadcast(message []byte) {
	for c := range p.connections {
		select {
		case c.send <- message:
		default:
			delete(p.connections, c)
			close(c.send)
			go c.ws.Close()
		}
	}
}

func (p *Publisher) makeWsHandler() websocket.Handler {
	return func(ws *websocket.Conn) {
		c := connection{
			ws:   ws,
			send: make(chan []byte, 256),
		}
		p.register <- &c
		defer func() { p.unregister <- &c }()
		go c.writer()
		c.reader(&p.filters, &p.filtersMutex)
	}
}

// registrar selects over register and unregister channels and updates connections map.
func (p *Publisher) registrar() {
	for {
		select {
		case c := <-p.register:
			p.connections[c] = true
		case c := <-p.unregister:
			delete(p.connections, c)
			close(c.send)
		}
	}
}

type connection struct {
	ws *websocket.Conn

	// Buffered channel of outbount messages
	send chan []byte
}

// reader reads the subscription requests from websocket and saves it in a map for accessing later.
func (c *connection) reader(filters *map[string]([]*connection), m *sync.Mutex) {
	for {
		var key string
		err := websocket.Message.Receive(c.ws, &key)
		if err != nil {
			log.Println("reader: Cannot receive message from websocket")
			break
		}
		log.Println("reader: Received a message from websocket")

		// TODO looks ugly, refactor below
		m.Lock()
		connections, ok := (*filters)[key]
		if !ok {
			log.Println("reader: no slice of connections for this key:", key)
			(*filters)[key] = make([]*connection, 0)
		}

		connections = (*filters)[key]
		(*filters)[key] = append(connections, c)

		log.Println("reader: filters after inserting connection for key:", *filters)
		m.Unlock()
	}
	c.ws.Close()
}

// writer writes the messages to the websocket from the send channel.
func (c *connection) writer() {
	for message := range c.send {
		err := websocket.Message.Send(c.ws, message)
		if err != nil {
			break
		}
	}
	c.ws.Close()
}
