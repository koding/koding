package main

import (
	"encoding/json"
	"fmt"
	"github.com/nranchev/go-libGeoIP"
	"github.com/streadway/amqp"
	"io"
	"koding/kontrol/kontrolproxy/proxyconfig"
	"koding/tools/config"
	"log"
	"net"
	"net/http"
	"os"
	"strconv"
	"strings"
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
var geoIP *libgeo.GeoIP

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

	// load GeoIP db into memory
	dbFile := "GeoIP.dat"
	geoIP, err = libgeo.Load(dbFile)
	if err != nil {
		log.Printf("load GeoIP.dat: %s\n", err.Error())
	}

	// register proxy instance to kontrol-daemon
	amqpStream = setupAmqp()

	// declare rabbitproxy exchange. this is used by rabbitclients to create
	// artifical host in form {name}-{key}-{username}.x.koding.com and use it
	err = amqpStream.channel.ExchangeDeclare("kontrol-rabbitproxy", "direct", true, false, false, false, nil)
	if err != nil {
		log.Printf("exchange.declare: %s\n", err.Error())
	}

	log.Printf("register proxy to kontrold with uuid '%s'", amqpStream.uuid)
	amqpStream.Publish("infoExchange", "input.proxy", buildProxyCmd("addProxy", amqpStream.uuid))
	log.Println("register command is send. waiting for response from kontrold...")
	go handleInput(amqpStream.input, amqpStream.uuid)

	<-start // wait until we got message from kontrold or exit via above chan

	reverseProxy := &ReverseProxy{}
	// http.HandleFunc("/", reverseProxy.ServeHTTP) this works for 1.1
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		reverseProxy.ServeHTTP(w, r)
	})

	port := strconv.Itoa(config.Current.Kontrold.Proxy.Port)
	portssl := strconv.Itoa(config.Current.Kontrold.Proxy.PortSSL)

	for _, sslip := range strings.Split(config.Current.Kontrold.Proxy.SSLIPS, ",") {
		go func() {
			err = http.ListenAndServeTLS(sslip+":"+portssl, sslip+".pem", sslip+".pem", nil)
			if err != nil {
				log.Println("https mode is disabled. please add cert.pem and key.pem files.")
			} else {
				log.Printf("https mode is enabled. serving at :%s ...", portssl)
			}
		}()
	}

	log.Printf("normal mode is enabled. serving at :%s ...", port)
	err = http.ListenAndServe(":"+port, nil)
	if err != nil {
		log.Println(err)
	}
}

func handleInput(input <-chan amqp.Delivery, uuid string) {
	for d := range input {
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

/*************************************************
*
*  modified version of go's reverseProxy source code
*  has support for dynamic target url, websockets and amqp
*
*  - arslan
*************************************************/

// ReverseProxy is an HTTP Handler that takes an incoming request and
// sends it to another server, proxying the response back to the
// client.
type ReverseProxy struct {
	// The transport used to perform proxy requests.
	// If nil, http.DefaultTransport is used.
	Transport http.RoundTripper
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
	if req.TLS == nil && req.Host == "new.koding.com" {
		http.Redirect(rw, req, "https://new.koding.com"+req.RequestURI, http.StatusMovedPermanently)
	}

	outreq := new(http.Request)
	*outreq = *req // includes shallow copies of maps, but okay

	websocket := checkWebsocket(outreq)

	userInfo, err := populateUser(outreq)
	if err != nil {
		io.WriteString(rw, fmt.Sprintf("{\"err\":\"%s\"}\n", err.Error()))
		log.Printf("error parsing subdomain %s: %v", outreq.Host, err)
		return
	}
	fmt.Printf("--\nconnected user information %v\n", userInfo)

	result, ok := validateUser(userInfo)
	if !ok {
		http.NotFound(rw, req)
		return
	}
	fmt.Printf("validation result: %s\n", result)

	// either userInfo.FullUrl or userInfo.Servicename-Key lookup will be made
	target, err := targetHost(userInfo)
	if err != nil {
		if err.Error() == "redirect" {
			http.Redirect(rw, req, target.String(), http.StatusTemporaryRedirect)
			return
		}
		log.Printf("error running key proxy %s: %v", userInfo.FullUrl, err)
		io.WriteString(rw, fmt.Sprintf("{\"err\":\"%s\"}\n", err.Error()))
		return
	}
	fmt.Printf("proxy to %s\n", target.Host)

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
	if websocket {
		fmt.Println("connection via websocket")
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

		res := new(http.Response)
		rabbitKey := lookupRabbitKey(userInfo.Username, userInfo.Servicename, userInfo.Key)

		if rabbitKey != "" {
			fmt.Println("connection via rabbitmq")
			res, err = rabbitTransport(outreq, userInfo, rabbitKey)
			if err != nil {
				log.Printf("rabbit proxy %s", err.Error())
				io.WriteString(rw, fmt.Sprintf("{\"err\":\"%s\"}\n", err.Error()))
				return
			}
		} else {
			fmt.Println("connection via normal http")
			// add :80 if not available
			ok := hasPort(outreq.URL.Host)
			if !ok {
				outreq.URL.Host = addPort(outreq.URL.Host, "80")
			}

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
	io.Copy(dst, src)
}
