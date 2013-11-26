package tunnel

import (
	"bufio"
	"encoding/json"
	"fmt"
	"log"
	"net"
	"net/http"
)

// Client is responsible for creating a control connection to a tunnel server,
// creating new tunnels and proxy them to tunnel server.
type Client struct {
	// underlying tcp connection responsible for sending/receiving control messages
	controlConn net.Conn

	// sendChan is used to encode ClientMsg and send them over the wire in
	// JSON format to the server.
	sendChan chan ClientMsg

	// serverAddr is the address of the tunnel-server
	serverAddr string

	// localAddr is the address of a local server that will be tunneled to the
	// public. Currently only one server is supported.
	localAddr string
}

// NewClient creates a new tunnel that is established between the serverAddr
// and localAddr. It exits if it can't create a new control connection to the
// server.
func NewClient(serverAddr, localAddr string) *Client {
	client := &Client{
		controlConn: newControlDial(serverAddr, "arslan"),
		serverAddr:  serverAddr,
		localAddr:   localAddr,
		sendChan:    make(chan ClientMsg),
	}

	return client
}

// Run starts the client begins to listen for control messages coming from the
// server. Run is blocking.
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
	log.Printf("starting a proxy to	%s\n", serverMsg.Host)
	remote := newTunnelDial(c.serverAddr, serverMsg)
	local := newLocalDial(c.localAddr)
	local.OnDisconnect(func() {
		log.Println("local connection is closed")
		remote.Close()
	})

	// time.AfterFunc(time.Second*10, func() { local.Close() })

	<-join(local, remote)
}

// start starts the tunnel between the remote and local server. It's a
// blocking function. Every requst is handled in a separete goroutine. It's
// like proxy() but the steps are more explicit.
func (c *Client) start(serverMsg *ServerMsg) {
	remote := newTunnelDial(c.serverAddr, serverMsg)
	for {
		req, err := http.ReadRequest(bufio.NewReader(remote))
		if err != nil {
			fmt.Println("Server read", err)
			return
		}

		go c.handleReq(req, remote)
	}
}

func (c *Client) handleReq(req *http.Request, remote net.Conn) {
	local := newLocalDial(c.localAddr)

	err := req.Write(local)
	if err != nil {
		log.Println("write clientConn ", err)
		return
	}

	resp, err := http.ReadResponse(bufio.NewReader(local), req)
	if err != nil {
		fmt.Println("read response", err)
		return
	}

	err = resp.Write(remote)
	if err != nil {
		fmt.Println("resp.write", err)
		return
	}
}
