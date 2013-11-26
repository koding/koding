package tunnel

import (
	"bufio"
	"encoding/json"
	"fmt"
	"koding/tunnel/conn"
	"log"
	"net"
	"net/http"
	"sync"
	"time"
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
}

func newControl(nc net.Conn, owner string) *control {
	c := &control{
		owner:    owner,
		sendChan: make(chan ServerMsg),
	}

	c.Conn = conn.New(nc, false)
	return c
}

func newControlDial(addr, username string) *control {
	c := &control{}
	c.Conn = conn.Dial(addr, true)

	request := func() {
		err := c.connect(username)
		if err != nil {
			log.Fatalln("newControlConn", err)
		}
	}

	// first call CONNECT request to establish the control connection
	request()

	// and then store it. it get called after each succesfull reconnection.
	c.OnReconnect(request)

	return c
}

func (c *control) connect(username string) error {
	remoteAddr := fmt.Sprintf("http://%s%s", c.RemoteAddr(), ControlPath)
	req, err := http.NewRequest("CONNECT", remoteAddr, nil)
	if err != nil {
		return fmt.Errorf("CONNECT", err)
	}

	req.Header.Set("username", username)
	req.Write(c)

	resp, err := http.ReadResponse(bufio.NewReader(c), req)
	if err != nil {
		return fmt.Errorf("read response", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 && resp.Status != Connected {
		return fmt.Errorf("Non-200 response from proxy server: %s", resp.Status)
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
