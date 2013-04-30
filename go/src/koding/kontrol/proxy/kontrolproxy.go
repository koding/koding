package main

import (
	"bufio"
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"github.com/streadway/amqp"
	"io"
	"koding/kontrol/proxy/proxyconfig"
	"koding/tools/config"
	"log"
	"net"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"
)

func init() {
	log.SetPrefix("kontrol-proxy ")
}

type IncomingMessage struct {
	ProxyResponse *proxyconfig.ProxyResponse
}

type RabbitChannel struct {
	ReplyTo string
	Receive chan []byte
}

var proxy proxyconfig.Proxy // this will be only updated whenever we receive a msg from kontrold
var proxyDB *proxyconfig.ProxyConfiguration
var amqpStream *AmqpStream
var start chan bool
var first bool = true
var connections map[string]RabbitChannel

func main() {
	log.Printf("kontrol proxy started ")
	start = make(chan bool)
	connections = make(map[string]RabbitChannel)

	// open kontrol-daemon database connection
	var err error
	proxyDB, err = proxyconfig.Connect()
	if err != nil {
		log.Fatalf("proxyconfig mongodb connect: %s", err)
	}

	// register fujin instance to kontrol-daemon
	amqpStream = setupAmqp()
	log.Printf("register fujin to kontrold with uuid '%s'", amqpStream.uuid)
	amqpStream.Publish("infoExchange", "input.proxy", buildProxyCmd("addProxy", amqpStream.uuid))
	log.Println("register command is send. waiting for response from kontrold...")
	go handleInput(amqpStream.input, amqpStream.uuid)

	<-start // wait until we got message from kontrold or exit via above chan

	reverseProxy := &ReverseProxy{}
	http.HandleFunc("/", reverseProxy.ServeHTTP)

	port := strconv.Itoa(config.Current.Kontrold.Proxy.Port)
	portssl := strconv.Itoa(config.Current.Kontrold.Proxy.PortSSL)

	go func() {
		err = http.ListenAndServeTLS(":"+portssl, "cert.pem", "key.pem", nil)
		if err != nil {
			log.Println("https mode is disabled. please add cert.pem and key.pem files.")
		} else {
			log.Printf("https mode is enabled. serving at :%s ...", portssl)
		}
	}()

	log.Printf("normal mode is enabled. serving at :%s ...", port)
	err = http.ListenAndServe(":"+port, nil)
	if err != nil {
		log.Println(err)
	}
}

func handleInput(input <-chan amqp.Delivery, uuid string) {
	for d := range input {
		// log.Printf("got %dB message data: [%v] %s",
		// 	len(d.Body),
		// 	d.DeliveryTag,
		// 	d.Body)

		switch d.RoutingKey {
		case "local.key":
		}

		var msg IncomingMessage

		err := json.Unmarshal(d.Body, &msg)
		if err != nil {
			log.Print("bad json incoming msg: ", err)
		}

		if msg.ProxyResponse != nil {
			if msg.ProxyResponse.Action == "updateProxy" {
				log.Println("update action received from kontrold. updating proxy route table")
				var err error
				proxy, err = proxyDB.GetProxy(uuid)
				if err != nil {
					log.Println(err)
				}

				if first {
					start <- true
					first = false
					log.Println("routing tables updated. ready to start servers.")
				}

			}

		} else {
			log.Println("incoming message is in wrong format")
		}

	}
}

func lookupKey(host string) (string, string, error) {
	log.Printf("lookup key table for host '%s'", host)
	counts := strings.Count(host, "-")
	if counts == 0 {
		return "", "", fmt.Errorf("no key found for host '%s'", host)
	}

	partsFirst := strings.Split(host, ".")
	firstSub := partsFirst[0]

	partsSecond := strings.Split(firstSub, "-")
	name := partsSecond[0]
	key := partsSecond[1]

	return name, key, nil
}

func lookupDomain(domainname string) (string, string, string, error) {
	log.Printf("lookup domain table for domain '%s'", domainname)

	domain, ok := proxy.DomainRoutingTable.Domains[domainname]
	if !ok {
		return "", "", "", fmt.Errorf("no domain lookup keys found for host '%s'", domainname)
	}

	return domain.Name, domain.Key, domain.FullUrl, nil
}

func targetUrl(name, key string) *url.URL {
	var target *url.URL
	var err error
	host := targetHost(name, key)

	target, err = url.Parse("http://" + host)
	if err != nil {
		log.Fatal(err)
	}

	log.Printf("proxy to %s (key: %s)", target.Host, key)

	return target
}

func lookupRabbitKey(name, key string) string {
	var rabbitkey string
	keyRoutingTable := proxy.Services[name]
	keyDataList := keyRoutingTable.Keys[key]

	for _, keyData := range keyDataList {
		rabbitkey = keyData.RabbitKey
	}

	return rabbitkey //return empty if not found
}

func targetHost(name, key string) string {
	var hostname string

	keyRoutingTable := proxy.Services[name]
	v := len(keyRoutingTable.Keys)
	if v == 0 {
		hostname = "proxy.in.koding.com"
		log.Println("no keys are added, using default url ", hostname)
	} else {
		// use round-robin algorithm for each hostname
		for i, value := range keyRoutingTable.Keys[key] {
			currentIndex := value.CurrentIndex
			if currentIndex == i {
				hostname = value.Host
				for k, _ := range keyRoutingTable.Keys[key] {
					if len(keyRoutingTable.Keys[key])-1 == currentIndex {
						keyRoutingTable.Keys[key][k].CurrentIndex = 0 // reached end
					} else {
						keyRoutingTable.Keys[key][k].CurrentIndex = currentIndex + 1
					}
				}
				break
			}
		}
	}

	return hostname
}

/*************************************************
*
*  util functions
*
*  - arslan
*************************************************/

func buildProxyCmd(action, uuid string) []byte {
	var req proxyconfig.ProxyMessage
	req.Action = action
	req.Uuid = uuid

	data, err := json.Marshal(req)
	if err != nil {
		log.Println("json marshall error", err)
	}

	return data
}

// Given a string of the form "host", "host:port", or "[ipv6::address]:port",
// return true if the string includes a port.
func hasPort(s string) bool { return strings.LastIndex(s, ":") > strings.LastIndex(s, "]") }

// Given a string of the form "host", "port", returns "host:port"
func addPort(host, port string) string {
	if ok := hasPort(host); ok {
		return host
	}

	return host + ":" + port
}

// Check if a server is alive or not
func checkServer(host string) error {
	c, err := net.Dial("tcp", host)
	if err != nil {
		return err
	}
	c.Close()
	return nil
}

// Return local ipv4 adress
func localIP() (net.IP, error) {
	tt, err := net.Interfaces()
	if err != nil {
		return nil, err
	}
	for _, t := range tt {
		aa, err := t.Addrs()
		if err != nil {
			return nil, err
		}
		for _, a := range aa {
			ipnet, ok := a.(*net.IPNet)
			if !ok {
				continue
			}
			v4 := ipnet.IP.To4()
			if v4 == nil || v4[0] == 127 { // loopback address
				continue
			}
			return v4, nil
		}
	}
	return nil, errors.New("cannot find local IP address")
}

/*************************************************
*
*  modified version of go's reverseProxy source code
*  has support for dynamic target url, websockets and amqp
*
*  - arslan
*************************************************/

// onExitFlushLoop is a callback set by tests to detect the state of the
// flushLoop() goroutine.
var onExitFlushLoop func()

// ReverseProxy is an HTTP Handler that takes an incoming request and
// sends it to another server, proxying the response back to the
// client.
type ReverseProxy struct {
	// The transport used to perform proxy requests.
	// If nil, http.DefaultTransport is used.
	Transport http.RoundTripper

	// FlushInterval specifies the flush interval
	// to flush to the client while copying the
	// response body.
	// If zero, no periodic flushing is done.
	FlushInterval time.Duration
}

func singleJoiningSlash(a, b string) string {
	aslash := strings.HasSuffix(a, "/")
	bslash := strings.HasPrefix(b, "/")
	switch {
	case aslash && bslash:
		return a + b[1:]
	case !aslash && !bslash:
		return a + "/" + b
	}
	return a + b
}

func copyHeader(dst, src http.Header) {
	for k, vv := range src {
		for _, v := range vv {
			dst.Add(k, v)
		}
	}
}

// Hop-by-hop headers. These are removed when sent to the backend.
// http://www.w3.org/Protocols/rfc2616/rfc2616-sec13.html
var hopHeaders = []string{
	"Connection",
	"Keep-Alive",
	"Proxy-Authenticate",
	"Proxy-Authorization",
	"Te", // canonicalized version of "TE"
	"Trailers",
	"Transfer-Encoding",
	"Upgrade",
}

func (p *ReverseProxy) ServeHTTP(rw http.ResponseWriter, req *http.Request) {
	conn_hdr := ""
	conn_hdrs := req.Header["Connection"]
	log.Printf("Connection headers: %v", conn_hdrs)
	if len(conn_hdrs) > 0 {
		conn_hdr = conn_hdrs[0]
	}

	upgrade_websocket := false
	if strings.ToLower(conn_hdr) == "upgrade" {
		log.Printf("got Connection: Upgrade")
		upgrade_hdrs := req.Header["Upgrade"]
		log.Printf("Upgrade headers: %v", upgrade_hdrs)
		if len(upgrade_hdrs) > 0 {
			upgrade_websocket = (strings.ToLower(upgrade_hdrs[0]) == "websocket")
		}
	}

	outreq := new(http.Request)
	*outreq = *req // includes shallow copies of maps, but okay

	var target *url.URL
	var fullurl string

	name, key, err := lookupKey(outreq.Host)
	if err != nil {
		log.Println(err)
		name, key, fullurl, err = lookupDomain(outreq.Host)
		if err != nil {
			log.Println(err)
		}

	}

	rabbitKey := lookupRabbitKey(name, key)
	if fullurl != "" {
		target, err = url.Parse("http://" + fullurl)
		if err != nil {
			log.Fatal(err)
		}
	} else {
		target = targetUrl(name, key)
	}

	// Reverseproxy.Director closure
	targetQuery := target.RawQuery
	outreq.URL.Scheme = target.Scheme
	outreq.URL.Host = target.Host
	outreq.URL.Path = singleJoiningSlash(target.Path, outreq.URL.Path)
	if targetQuery == "" || outreq.URL.RawQuery == "" {
		outreq.URL.RawQuery = targetQuery + outreq.URL.RawQuery
	} else {
		outreq.URL.RawQuery = targetQuery + "&" + outreq.URL.RawQuery
	}

	outreq.Proto = "HTTP/1.1"
	outreq.ProtoMajor = 1
	outreq.ProtoMinor = 1
	outreq.Close = false

	// https://groups.google.com/d/msg/golang-nuts/KBx9pDlvFOc/edt4iad96nwJ
	if upgrade_websocket {
		rConn, err := net.Dial("tcp", outreq.URL.Host)
		if err != nil {
			http.Error(rw, "Error contacting backend server.", http.StatusInternalServerError)
			log.Printf("Error dialing websocket backend %s: %v", outreq.URL.Host, err)
			return
		}

		hj, ok := rw.(http.Hijacker)
		if !ok {
			http.Error(rw, "Not a hijacker?", http.StatusInternalServerError)
			return
		}

		conn, _, err := hj.Hijack()
		if err != nil {
			log.Printf("Hijack error: %v", err)
			return
		}
		defer conn.Close()
		defer rConn.Close()

		err = req.Write(rConn)
		if err != nil {
			log.Printf("Error copying request to target: %v", err)
			return
		}

		go p.copyResponse(rConn, conn)
		p.copyResponse(conn, rConn)

	} else {
		transport := p.Transport
		if transport == nil {
			transport = http.DefaultTransport
		}

		// Display error when someone hits the main page
		hostname, _ := os.Hostname()
		if hostname == outreq.URL.Host {
			io.WriteString(rw, "{\"err\":\"no such host\"}\n")
			return
		}

		// Remove hop-by-hop headers to the backend.  Especially
		// important is "Connection" because we want a persistent
		// connection, regardless of what the client sent to us.  This
		// is modifying the same underlying map from req (shallow
		// copied above) so we only copy it if necessary.
		copiedHeaders := false
		for _, h := range hopHeaders {
			if outreq.Header.Get(h) != "" {
				if !copiedHeaders {
					outreq.Header = make(http.Header)
					copyHeader(outreq.Header, req.Header)
					copiedHeaders = true
				}
				outreq.Header.Del(h)
			}
		}

		if clientIP, _, err := net.SplitHostPort(req.RemoteAddr); err == nil {
			// If we aren't the first proxy retain prior
			// X-Forwarded-For information as a comma+space
			// separated list and fold multiple headers into one.
			if prior, ok := outreq.Header["X-Forwarded-For"]; ok {
				clientIP = strings.Join(prior, ", ") + ", " + clientIP
			}
			outreq.Header.Set("X-Forwarded-For", clientIP)
		}

		// Test values, will be removed - arslan
		// outreq.URL.Host = "localhost:3000"
		// outreq.Host = "localhost:3000"
		// outreq.URL.Host = "67.169.70.88"
		// outreq.Host = "67.169.70.88"

		// var err error
		res := new(http.Response)

		// add :80 if not available
		ok := hasPort(outreq.URL.Host)
		if !ok {
			outreq.URL.Host = addPort(outreq.URL.Host, "80")
		}

		err := checkServer(outreq.URL.Host)
		if err != nil {
			log.Println(err)
			// we can't connect to url, thus proxy trough amqp
			if rabbitKey == "" {
				io.WriteString(rw, fmt.Sprintf("{\"err\":\"no rabbit key defined for server '%s'. rabbit proxy aborted\"}\n", outreq.URL.Host))
				return
			}
			log.Println("proxy via rabbitmq to '%s'", outreq.URL.Host)
			output := new(bytes.Buffer)
			outreq.Host = outreq.URL.Host // WriteProxy overwrites outreq.URL.Host otherwise..
			err := outreq.WriteProxy(output)
			if err != nil {
				io.WriteString(rw, fmt.Sprint(err))
				return
			}

			// declare just once time
			if len(connections) == 0 {
				err = amqpStream.channel.ExchangeDeclare("kontrol-rabbitproxy", "direct", false, true, false, false, nil)
				if err != nil {
					log.Fatal("exchange.declare: %s", err)
				}
			}

			if _, ok := connections[rabbitKey]; !ok {
				queue, err := amqpStream.channel.QueueDeclare("", false, true, false, false, nil)
				if err != nil {
					log.Fatal("queue.declare: %s", err)
				}
				if err := amqpStream.channel.QueueBind("", "", "kontrol-rabbitproxy", false, nil); err != nil {
					log.Fatal("queue.bind: %s", err)
				}
				messages, err := amqpStream.channel.Consume("", "", true, false, false, false, nil)
				if err != nil {
					log.Fatal("basic.consume: %s", err)
				}

				connections[rabbitKey] = RabbitChannel{
					ReplyTo: queue.Name,
					Receive: make(chan []byte, 1),
				}

				go func() {
					for msg := range messages {
						log.Printf("got rabbit http message for %s", connections[rabbitKey].ReplyTo)
						connections[rabbitKey].Receive <- msg.Body

					}
				}()
			}

			log.Println("publishing http request to rabbit")
			msg := amqp.Publishing{
				ContentType: "text/plain",
				Body:        output.Bytes(),
				ReplyTo:     connections[rabbitKey].ReplyTo,
			}

			amqpStream.channel.Publish("kontrol-rabbitproxy", rabbitKey, false, false, msg)

			var respData []byte
			// why we don't use time.After: https://groups.google.com/d/msg/golang-dev/oZdV_ISjobo/5UNiSGZkrVoJ
			t := time.NewTimer(20 * time.Second)
			log.Println("...waiting for http response from rabbit")
			select {
			case respData = <-connections[rabbitKey].Receive:
			case <-t.C:
				log.Println("timeout. no rabbit proxy message receieved")
				io.WriteString(rw, "{\"err\":\"no rabbit proxy message received\"}\n")
				return
			}
			t.Stop()

			if respData == nil {
				rw.WriteHeader(http.StatusInternalServerError)
				return
			}
			buf := bytes.NewBuffer(respData)
			respreader := bufio.NewReader(buf)

			// ok got now response from rabbit :)
			res, err = http.ReadResponse(respreader, outreq)
			if err != nil {
				io.WriteString(rw, fmt.Sprint(err))
				return
			}
		} else {
			log.Println("proxy trough http ...")
			res, err = transport.RoundTrip(outreq)
			if err != nil {
				io.WriteString(rw, fmt.Sprint(err))
				return
			}
		}

		defer res.Body.Close()

		copyHeader(rw.Header(), res.Header)
		rw.WriteHeader(res.StatusCode)
		p.copyResponse(rw, res.Body)
	}

}

func (p *ReverseProxy) copyResponse(dst io.Writer, src io.Reader) {
	if p.FlushInterval != 0 {
		if wf, ok := dst.(writeFlusher); ok {
			mlw := &maxLatencyWriter{
				dst:     wf,
				latency: p.FlushInterval,
				done:    make(chan bool),
			}
			go mlw.flushLoop()
			defer mlw.stop()
			dst = mlw
		}
	}

	io.Copy(dst, src)
}

type writeFlusher interface {
	io.Writer
	http.Flusher
}

type maxLatencyWriter struct {
	dst     writeFlusher
	latency time.Duration

	lk   sync.Mutex // protects Write + Flush
	done chan bool
}

func (m *maxLatencyWriter) Write(p []byte) (int, error) {
	m.lk.Lock()
	defer m.lk.Unlock()
	return m.dst.Write(p)
}

func (m *maxLatencyWriter) flushLoop() {
	t := time.NewTicker(m.latency)
	defer t.Stop()
	for {
		select {
		case <-m.done:
			if onExitFlushLoop != nil {
				onExitFlushLoop()
			}
			return
		case <-t.C:
			m.lk.Lock()
			m.dst.Flush()
			m.lk.Unlock()
		}
	}
}

func (m *maxLatencyWriter) stop() { m.done <- true }
