package tunnel

import (
	"encoding/json"
	"log"
	"net"
	"sync"
	"time"
)

type control struct {
	conn     net.Conn
	start    time.Time
	sendChan chan ServerMsg
}

func newControl(conn net.Conn) *control {
	return &control{
		conn:     conn,
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
			log.Println("control decode", err)
			return
		}
	}
}

func (c *control) encoder() {
	e := json.NewEncoder(c.conn)
	for msg := range c.sendChan {
		err := e.Encode(msg)
		if err != nil {
			log.Println("control encode", err)
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
