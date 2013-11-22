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
		controlConn: newControlConn(serverAddr, "arslan"),
		localConns:  make(map[string]net.Conn),
		serverAddr:  serverAddr,
		localAddr:   localAddr,
		sendChan:    make(chan ClientMsg),
	}

	return tunnel
}

func (c *Client) Run() {
	go c.encoder()
	c.decoder()
}

func (c *Client) sendMsg(msg string) {
	c.sendChan <- ClientMsg{Action: msg}
}

func (c *Client) encoder() {
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

func (c *Client) decoder() {
	d := json.NewDecoder(c.controlConn)

	for {
		msg := new(ServerMsg)
		log.Println("waiting msg from control connection")
		err := d.Decode(msg)
		if err != nil {
			log.Println("decode", err)
			return
		}

		if msg.Protocol == "" || msg.TunnelID == "" || msg.Username == "" {
			log.Printf("protocol or tunnelID should not be empty")
			continue
		}

		if msg.Protocol != "http" && msg.Protocol != "websocket" {
			log.Printf("protocol is not valid %s", msg.Protocol)
			continue
		}

		go c.proxy(msg)
	}
}

// proxy joins (proxies) the remote tcp connection with the local one.
// the data between the two connections are copied vice versa.
func (c *Client) proxy(serverMsg *ServerMsg) {
	log.Printf("starting a proxy %+v\n", *serverMsg)
	remote := newTunnelConn(c.serverAddr, serverMsg)
	local := newClientConn(c.localAddr, true)

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
