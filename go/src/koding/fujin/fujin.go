package main

import (
	"crypto/tls"
	"encoding/json"
	"errors"
	"github.com/streadway/amqp"
	"io"
	"koding/fujin/fastproxy"
	"koding/fujin/proxyconfig"
	"koding/tools/config"
	"log"
	"net"
	"net/http"
	"net/url"
	"os"
	"strings"
	"sync"
	"time"
)

func init() {
	log.SetPrefix("fujin ")
}

type IncomingMessage struct {
	ProxyResponse *proxyconfig.ProxyResponse
}

var proxy proxyconfig.Proxy // this will be only updated whenever we receive a msg from kontrold
var proxyDB *proxyconfig.ProxyConfiguration
var amqpStream *AmqpStream
var start chan bool
var first bool = true

func main() {
	log.Printf("fujin proxy started ")
	start = make(chan bool)

	// open kontrol-daemon database connection
	var err error
	proxyDB, err = proxyconfig.Connect()
	if err != nil {
		log.Fatalf("proxyconfig mongodb connect: %s", err)
	}

	// register fujin instance to kontrol-daemon
	amqpStream = setupAmqp()
	log.Printf("register fujin to kontrold with uuid '%s'", amqpStream.uuid)
	amqpStream.Publish(buildProxyCmd("addProxy", amqpStream.uuid))
	log.Println("register command is send. waiting for response from kontrold...")
	go handleInput(amqpStream.input, amqpStream.uuid)

	select {
	case <-time.After(time.Second * 15):
		log.Fatalf("ERROR: no repsonse received from kontrold, aborting process.")
		os.Exit(1)
	case <-start: // wait until we got message from kontrold or exit via above chan
	}

	// addHTTP, err := net.ResolveTCPAddr("tcp", ":"+config.HttpPort)
	// if err != nil {
	// 	log.Println(err)
	// 	return
	// }

	// addHTTPS, err := net.ResolveTCPAddr("tcp", ":"+config.HttpsPort)
	// if err != nil {
	// 	log.Println(err)
	// 	return
	// }

	// cert, err := tls.LoadX509KeyPair("cert.pem", "key.pem")
	// if err != nil {
	// 	log.Println("https mode is disabled. please add cert.pem and key.pem files.")
	// } else {
	// 	log.Printf("https mode is enabled. serving at :%s ...", config.HttpsPort)
	// 	go listenProxy(addHTTPS, &cert, amqpStream.uuid)
	// }

	// log.Printf("normal mode is enabled. serving at :%s ...", config.HttpPort)
	// listenProxy(addHTTP, nil, amqpStream.uuid)

	reverseProxy := NewSingleHostReverseProxy()
	http.Handle("/", reverseProxy)

	// http.HandleFunc("/hello", func(w http.ResponseWriter, r *http.Request) {
	// 	fmt.Fprintf(w, "Hello, %q", html.EscapeString(r.URL.Path))
	// })

	// start one with go in order not to block the other one
	go func() {
		err = http.ListenAndServeTLS(":"+config.HttpsPort, "cert.pem", "key.pem", nil)
		if err != nil {
			log.Println("https mode is disabled. please add cert.pem and key.pem files.")
		} else {
			log.Printf("https mode is enabled. serving at :%s ...", config.HttpsPort)
		}
	}()

	log.Printf("normal mode is enabled. serving at :%s ...", config.HttpPort)
	http.ListenAndServe(":"+config.HttpPort, nil)
}

func Handler(writer http.ResponseWriter, req *http.Request) {

	// writer.Write([]byte(data))
}

// func newReverseProxy() *httputil.ReverseProxy {
// 	director := func(req *http.Request) {
// 		log.Println("HOST:", req.RequestURI, req.Host)
// 		var deaths int
// 		name, key := parseKey(req.Host)
// 		if name == "homepage" {
// 			log.Println("hello world!")
// 			return
// 		}
//
// 		target := targetUrl(deaths, name, key)
//
// 		targetQuery := target.RawQuery
//
// 		req.URL.Scheme = target.Scheme
// 		req.URL.Host = target.Host
// 		req.URL.Path = singleJoiningSlash(target.Path, req.URL.Path)
// 		if targetQuery == "" || req.URL.RawQuery == "" {
// 			req.URL.RawQuery = targetQuery + req.URL.RawQuery
// 		} else {
// 			req.URL.RawQuery = targetQuery + "&" + req.URL.RawQuery
// 		}
// 	}
//
// 	reverseProxy := &httputil.ReverseProxy{Director: director}
//
// 	return reverseProxy
// }

func listenProxy(localAddr *net.TCPAddr, cert *tls.Certificate, uuid string) {
	err := fastproxy.Listen(localAddr, cert, func(req fastproxy.Request) {
		var deaths int
		name, key := parseKey(req.Host)
		if name == "homepage" {
			req.Write("Hello fujin proxy!")
			return
		}

		target := targetUrl(deaths, name, key)
		remoteAddr, err := net.ResolveTCPAddr("tcp", target.Host)
		if err != nil {
			log.Println(err)
			return
		}

		if err := req.Relay(remoteAddr); err != nil {
			log.Println(err)
			req.Redirect("http://example.com")
		}
	})

	if err != nil {
		log.Fatalf("FATAL ERROR: %s", err)
	}
}

func parseKey(host string) (string, string) {
	counts := strings.Count(host, "-")
	if counts == 0 {
		return "homepage", ""
	}

	partsFirst := strings.Split(host, ".")
	firstSub := partsFirst[0]

	partsSecond := strings.Split(firstSub, "-")
	name := partsSecond[0]
	key := partsSecond[1]

	return name, key
}

func handleInput(input <-chan amqp.Delivery, uuid string) {
	for {
		select {
		case d := <-input:
			// log.Printf("got %dB message data: [%v] %s",
			// 	len(d.Body),
			// 	d.DeliveryTag,
			// 	d.Body)

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
}

func targetUrl(numberOfDeaths int, name, key string) *url.URL {
	var target *url.URL
	var err error
	host := targetHost(name, key)

	keyRoutingTable := proxy.Services[name]
	v := len(keyRoutingTable.Keys[key])
	if v == numberOfDeaths {
		log.Println("All given servers are death. Fallback to localhost:8000")
		target, err = url.Parse("http://localhost:8000")
		if err != nil {
			log.Fatal(err)
		}
		return target
	}

	err = checkServer(host)
	if err != nil {
		log.Println(err)
		log.Printf("Server is death: %s. Trying to get another one", host)
		numberOfDeaths++

		target = targetUrl(numberOfDeaths, name, key)
	} else {
		target, err = url.Parse("http://" + host)
		if err != nil {
			log.Fatal(err)
		}

		log.Printf("got / request. using proxy to %s (key: %s)", target.Host, key)
	}
	return target
}

// Implement with fastProxy ...
func checkServer(host string) error {
	remoteAddr, err := net.ResolveTCPAddr("tcp", host)
	if err != nil {
		return err
	}

	remoteConn, err := net.DialTCP("tcp", nil, remoteAddr)
	if err != nil {
		return err
	}

	remoteConn.Close()
	return nil
}

func targetHost(name, key string) string {
	var hostname string

	keyRoutingTable := proxy.Services[name]

	v := len(keyRoutingTable.Keys)
	if v == 0 {
		hostname = "localhost:8000"
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

/*************************************************
*
*  modified version of go's reverseProxy source code
*  has support for dynamic url and websockets
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
	// Director must be a function which modifies
	// the request into a new request to be sent
	// using Transport. Its response is then copied
	// back to the original client unmodified.
	Director func(*http.Request)

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

// NewSingleHostReverseProxy returns a new ReverseProxy that rewrites
// URLs to the scheme, host, and base path provided in target. If the
// target's path is "/base" and the incoming request was for "/dir",
// the target request will be for /base/dir.
func NewSingleHostReverseProxy() *ReverseProxy {
	director := func(req *http.Request) {
		log.Println("HOST:", req.RequestURI, req.Host)
		var deaths int
		name, key := parseKey(req.Host)
		if name == "homepage" {
			log.Println("hello world!")
			return
		}

		target := targetUrl(deaths, name, key)

		targetQuery := target.RawQuery

		req.URL.Scheme = target.Scheme
		req.URL.Host = target.Host
		req.URL.Path = singleJoiningSlash(target.Path, req.URL.Path)
		if targetQuery == "" || req.URL.RawQuery == "" {
			req.URL.RawQuery = targetQuery + req.URL.RawQuery
		} else {
			req.URL.RawQuery = targetQuery + "&" + req.URL.RawQuery
		}
	}

	return &ReverseProxy{Director: director}
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
	reqHost, err := net.ResolveTCPAddr("tcp", req.Host)
	if err != nil {
		log.Println(err)
		return
	}
	localHost, err := localIP()

	if localHost.String() == reqHost.IP.String() {
		io.WriteString(rw, "hello, world!\n")
		return
	}

	transport := p.Transport
	if transport == nil {
		transport = http.DefaultTransport
	}

	outreq := new(http.Request)
	*outreq = *req // includes shallow copies of maps, but okay

	p.Director(outreq)
	outreq.Proto = "HTTP/1.1"
	outreq.ProtoMajor = 1
	outreq.ProtoMinor = 1
	outreq.Close = false

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

	res, err := transport.RoundTrip(outreq)
	if err != nil {
		log.Printf("http: proxy error: %v", err)
		rw.WriteHeader(http.StatusInternalServerError)
		return
	}
	defer res.Body.Close()

	copyHeader(rw.Header(), res.Header)

	rw.WriteHeader(res.StatusCode)
	p.copyResponse(rw, res.Body)
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
