package tunnel

import (
	"encoding/json"
	"log"
	"net"
	"sync"
	"time"
)

type control struct {
	// underlying tcp connection
	conn net.Conn

	// start time of the control connection
	start time.Time

	// owner of the control connection
	owner string

	// sendChan is used to encode ServerMsg and send them over the wire in
	// JSON format to the client that initiatet the control connection.
	sendChan chan ServerMsg
}

func newControl(conn net.Conn, owner string) *control {
	return &control{
		conn:     conn,
		owner:    owner,
		start:    time.Now(),
		sendChan: make(chan ServerMsg),
	}
}

func (c *control) send(msg ServerMsg) {
	c.sendChan <- msg
}

func (c *control) run() {
	go c.encoder()
	c.decoder()
}

func (c *control) decoder() {
	d := json.NewDecoder(c.conn)
	for {
		var msg ClientMsg
		err := d.Decode(&msg)
		if err != nil {
			log.Printf("control connection from %s is closed: decode '%s\n",
				c.owner, err)
			return
		}
	}
}

func (c *control) encoder() {
	e := json.NewEncoder(c.conn)
	for msg := range c.sendChan {
		err := e.Encode(msg)
		if err != nil {
			log.Printf("control connection from %s is closed: encode '%s\n",
				c.owner, err)
			return
		}
	}

}

func (c *control) close() {
	c.conn.Close()
}

type controls struct {
	sync.Mutex
	controls map[string]*control
}

func newControls() *controls {
	return &controls{
		controls: make(map[string]*control),
	}
}

func (c *controls) getControl(username string) (*control, bool) {
	c.Lock()
	defer c.Unlock()

	control, ok := c.controls[username]
	return control, ok
}

func (c *controls) addControl(username string, control *control) {
	c.Lock()
	defer c.Unlock()

	c.controls[username] = control
}

func (c *controls) deleteControl(username string) {
	c.Lock()
	defer c.Unlock()

	delete(c.controls, username)
}
