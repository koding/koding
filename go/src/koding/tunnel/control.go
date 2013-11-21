package tunnel

import (
	"encoding/json"
	"log"
	"net"
	"sync"
	"time"
)

type Control struct {
	conn     net.Conn
	start    time.Time
	sendChan chan ServerMsg
}

func NewControl(conn net.Conn) *Control {
	return &Control{
		conn:     conn,
		start:    time.Now(),
		sendChan: make(chan ServerMsg),
	}
}

func (c *Control) SendMsg(protocol, id string) {
	c.sendChan <- ServerMsg{Protocol: protocol, TunnelID: id}
}

func (c *Control) run() {
	go c.encoder()
	c.decoder()
}

func (c *Control) decoder() {
	d := json.NewDecoder(c.conn)
	for {
		var msg ClientMsg
		err := d.Decode(&msg)
		if err != nil {
			log.Println("decode", err)
			return
		}

		log.Println("got msg", msg)
	}
}

func (c *Control) encoder() {
	e := json.NewEncoder(c.conn)
	for msg := range c.sendChan {
		log.Println("got msg, sending to control chan", msg)
		err := e.Encode(msg)
		if err != nil {
			log.Println("encode", err)
			return
		}
	}

}

func (c *Control) Close() {
	c.conn.Close()
}

type Controls struct {
	sync.Mutex
	controls map[string]*Control
}

func NewControls() *Controls {
	return &Controls{
		controls: make(map[string]*Control),
	}
}

func (c *Controls) getControl(username string) (*Control, bool) {
	c.Lock()
	defer c.Unlock()

	control, ok := c.controls[username]
	return control, ok
}

func (c *Controls) addControl(username string, control *Control) {
	c.Lock()
	defer c.Unlock()

	c.controls[username] = control
}

func (c *Controls) deleteControl(username string) {
	c.Lock()
	defer c.Unlock()

	delete(c.controls, username)
}
