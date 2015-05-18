package tunnel

import (
	"bufio"
	"encoding/json"
	"fmt"
	"log"
	"net"
	"net/http"
	"sync"
	"time"

	"github.com/koding/tunnel/conn"
)

type control struct {
	// underlying tcp connection
	*conn.Conn

	// start time of the control connection
	start time.Time

	// owner of the control connection
	owner string

	// sendChan is used to encode ServerMsg and send them over the wire in
	// JSON format to the client that initiated the control connection.
	sendChan chan ServerMsg

	// defines when control is ready
	ready chan bool
}

func newControl(nc net.Conn, owner string, ready chan bool) *control {
	c := &control{
		owner:    owner,
		sendChan: make(chan ServerMsg),
		ready:    ready,
	}

	c.Conn = conn.New(nc, false)
	return c
}

func newControlDial(addr, identifier string) *control {
	c := &control{}
	cn, err := conn.Dial(addr, true)
	if err != nil {
		log.Fatalln("newControlConn: ", err)
	}

	c.Conn = cn

	request := func() {
		err := c.connect(identifier)
		if err != nil {
			log.Fatalln("newControlConn: ", err)
		}
	}

	// first call CONNECT request to establish the control connection
	request()

	// and then store it. it get called after each succesfull reconnection.
	c.OnReconnect(request)

	return c
}

func (c *control) connect(identifier string) error {
	remoteAddr := fmt.Sprintf("http://%s%s", c.RemoteAddr(), ControlPath)
	req, err := http.NewRequest("CONNECT", remoteAddr, nil)
	if err != nil {
		return fmt.Errorf("CONNECT %s", err)
	}

	req.Header.Set("identifier", identifier)
	req.Write(c)

	resp, err := http.ReadResponse(bufio.NewReader(c), req)
	if err != nil {
		return fmt.Errorf("read response %s", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 && resp.Status != Connected {
		return fmt.Errorf("proxy server (%s): %s", remoteAddr, resp.Status)
	}

	return nil
}

func (c *control) send(msg ServerMsg) {
	c.sendChan <- msg
}

func (c *control) run() {
	go c.encoder()
	c.decoder()
}

func (c *control) decoder() {
	d := json.NewDecoder(c)
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
	e := json.NewEncoder(c)
	close(c.ready) // notify others that we are ready now
	for msg := range c.sendChan {
		err := e.Encode(msg)
		if err != nil {
			log.Printf("control connection from %s is closed: encode '%s\n",
				c.owner, err)
			return
		}
	}

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

func (c *controls) getControl(identifier string) (*control, bool) {
	c.Lock()
	defer c.Unlock()

	control, ok := c.controls[identifier]
	return control, ok
}

func (c *controls) addControl(identifier string, control *control) {
	c.Lock()
	defer c.Unlock()

	c.controls[identifier] = control
}

func (c *controls) deleteControl(identifier string) {
	c.Lock()
	defer c.Unlock()

	delete(c.controls, identifier)
}
