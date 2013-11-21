package tunnel

import (
	"encoding/json"
	"fmt"
	"log"
	"net"
)

type Client struct {
	controlConn net.Conn
	localConns  map[string]net.Conn
	sendChan    chan ClientMsg
	serverAddr  string
	localAddr   string
}

// NewTunnelClient creates a new tunnel that is established between the
// serverAddr and localAddr.
func NewClient(serverAddr, localAddr string) *Client {
	tunnel := &Client{
		controlConn: NewControlConn(serverAddr, "arslan"),
		localConns:  make(map[string]net.Conn),
		serverAddr:  serverAddr,
		localAddr:   localAddr,
		sendChan:    make(chan ClientMsg),
	}

	return tunnel
}

func (c *Client) Run() {
	go c.Encoder()
	c.Decoder()
}

func (c *Client) sendMsg(msg string) {
	c.sendChan <- ClientMsg{Action: msg}
}

func (c *Client) Encoder() {
	e := json.NewEncoder(c.controlConn)

	for msg := range c.sendChan {
		fmt.Println("got msg, sending to control chan", msg)
		err := e.Encode(&msg)
		if err != nil {
			log.Println("encode", err)
			return
		}
	}
}

func (c *Client) Decoder() {
	d := json.NewDecoder(c.controlConn)

	for {
		var msg ServerMsg
		fmt.Println("waiting for msg from control chan")
		err := d.Decode(&msg)
		if err != nil {
			log.Println("decode", err)
			return
		}

		fmt.Printf("got msg from control chan %#v\n", msg)

		switch msg.Protocol {
		case "http":
			log.Println("creating a new http connection to tunnel server")

			go c.Proxy("http", msg.TunnelID)
		case "websocket":
			log.Println("creating a new websocket connection to tunnel server")

			go c.Proxy("websocket", msg.TunnelID)
		}
	}
}

// Proxy is like Start() but it joins (proxies) the remote tcp connection with
// the local one, that means all de handling is done via those two connection.
func (c *Client) Proxy(protocol, tunnelID string) {
	remote := NewTunnelConn(c.serverAddr, protocol, tunnelID)
	local := NewClientConn(c.localAddr)

	err := <-join(local, remote)
	log.Println(err)
}

// Start starts the tunnel between the remote and local server. It's a
// blocking function. Every requst is handled in a separete goroutine.
// func (c *Client) Start() {
// 	for {
// 		req, err := http.ReadRequest(bufio.NewReader(c.controlConn))
// 		if err != nil {
// 			fmt.Println("Server read", err)
// 			return
// 		}

// 		go c.handleReq(req)
// 	}
// }

// func (c *Client) handleReq(req *http.Request) {
// 	err := req.Write(c.localConn)
// 	if err != nil {
// 		log.Println("write clientConn ", err)
// 		return
// 	}

// 	resp, err := http.ReadResponse(bufio.NewReader(c.localConn), req)
// 	if err != nil {
// 		fmt.Println("read response", err)
// 		return
// 	}

// 	err = resp.Write(c.controlConn)
// 	if err != nil {
// 		fmt.Println("resp.write", err)
// 		return
// 	}
// }
