package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"github.com/nranchev/go-libGeoIP"
	"github.com/streadway/amqp"
	"io"
	"koding/kontrol/kontrolproxy/proxyconfig"
	"koding/tools/config"
	"log"
	"net"
	"net/http"
	"net/url"
	"os"
	"sort"
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

type UserInfo struct {
	Username    string
	Servicename string
	Key         string
	FullUrl     string
	IP          string
	Country     string
}

func NewUserInfo(username, servicename, key, fullurl string) *UserInfo {
	return &UserInfo{
		Username:    username,
		Servicename: servicename,
		Key:         key,
		FullUrl:     fullurl,
	}
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

func validateUser(user UserInfo) bool {
	rules, ok := proxy.Rules[user.Username]
	if !ok { // if not available assume allowed for all
		return true
	}

	restriction, ok := rules.Services[user.Servicename]
	if !ok { // if not available assume allowed for all
		return true
	}

	return validator(restriction, user).IP().Country().Check()
}

func parseKey(host string) (UserInfo, error) {
	log.Printf("parse host '%s' to get key and name", host)

	switch counts := strings.Count(host, "-"); {
	case counts == 0:
		// host is in form {name}.x.koding.com, used for domain forwarding
		userInfo, err := lookupDomain(host)
		if err != nil {
			log.Println(err)
			return UserInfo{}, err
		}
		return userInfo, nil
	case counts == 1:
		// host is in form {name}-{key}.x.koding.com, used by koding
		partsFirst := strings.Split(host, ".")
		firstSub := partsFirst[0]

		partsSecond := strings.Split(firstSub, "-")
		servicename := partsSecond[0]
		key := partsSecond[1]

		return *NewUserInfo("koding", servicename, key, ""), nil
	case counts > 1:
		// host is in form {name}-{key}-{username}.x.koding.com, used by users
		partsFirst := strings.Split(host, ".")
		firstSub := partsFirst[0]

		partsSecond := strings.SplitN(firstSub, "-", 3)
		servicename := partsSecond[0]
		key := partsSecond[1]
		username := partsSecond[2]

		return *NewUserInfo(username, servicename, key, ""), nil
	default:
		return UserInfo{}, errors.New("no data available for proxy")
	}

}

func lookupDomain(domainname string) (UserInfo, error) {
	log.Printf("lookup domain table for domain '%s'", domainname)

	domain, ok := proxy.DomainRoutingTable.Domains[domainname]
	if !ok {
		return UserInfo{}, fmt.Errorf("no domain lookup keys found for host '%s'", domainname)
	}

	return *NewUserInfo(domain.Username, domain.Name, domain.Key, domain.FullUrl), nil
}

func targetUrl(username, servicename, key string) (*url.URL, error) {
	var target *url.URL
	host, err := targetHost(username, servicename, key)
	if err != nil {
		return nil, err
	}

	target, err = url.Parse("http://" + host)
	if err != nil {
		return nil, err
	}

	log.Printf("proxy to %s (key: %s)", target.Host, key)

	return target, nil
}

func lookupRabbitKey(username, servicename, key string) string {
	var rabbitkey string

	_, ok := proxy.RoutingTable[username]
	if !ok {
		log.Println("no user available in the db. rabbitkey not found")
		return rabbitkey
	}
	user := proxy.RoutingTable[username]

	keyRoutingTable := user.Services[servicename]
	keyDataList := keyRoutingTable.Keys[key]

	for _, keyData := range keyDataList {
		rabbitkey = keyData.RabbitKey
	}

	return rabbitkey //returns empty if not found
}

func targetHost(username, servicename, key string) (string, error) {
	var hostname string

	_, ok := proxy.RoutingTable[username]
	if !ok {
		return "", errors.New("no users availalable in the db. targethost not found")
	}

	user := proxy.RoutingTable[username]
	keyRoutingTable := user.Services[servicename]

	v := len(keyRoutingTable.Keys)
	if v == 0 {
		return "", fmt.Errorf("no keys are available for user %s", username)
	} else {
		if key == "latest" {
			// get all keys and sort them
			listOfKeys := make([]int, len(keyRoutingTable.Keys))
			i := 0
			for k, _ := range keyRoutingTable.Keys {
				listOfKeys[i], _ = strconv.Atoi(k)
				i++
			}
			sort.Ints(listOfKeys)

			// give precedence to the largest key number
			key = strconv.Itoa(listOfKeys[len(listOfKeys)-1])
		}

		_, ok := keyRoutingTable.Keys[key]
		if !ok {
			return "", fmt.Errorf("no key %s is available for user %s", key, username)
		}

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

	return hostname, nil
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
	fmt.Println("--")

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

	userInfo, err := parseKey(outreq.Host)
	if err != nil {
		io.WriteString(rw, fmt.Sprintf("{\"err\":\"%s\"}\n", err.Error()))
		log.Printf("error parsing subdomain %s: %v", outreq.Host, err)
		return
	}

	host, port, err := net.SplitHostPort(req.RemoteAddr)
	if err != nil {
		log.Printf("could not split host and port: %s", err.Error())
	} else {
		log.Printf("new connection from %s:%s\n", host, port)
		userInfo.IP = host
	}

	if geoIP != nil {
		loc := geoIP.GetLocationByIP(host)
		if loc != nil {
			fmt.Printf("country: %s (%s)\n", loc.CountryName, loc.CountryCode)
			userInfo.Country = loc.CountryName
		}
	}

	ok := validateUser(userInfo)
	if !ok {
		log.Println("not validated user")
		http.NotFound(rw, req)
		return
	}

	if userInfo.FullUrl != "" {
		target, err = url.Parse("http://" + userInfo.FullUrl)
		if err != nil {
			log.Printf("error running fullurl %s: %v", userInfo.FullUrl, err)
			io.WriteString(rw, fmt.Sprintf("{\"err\":\"%s\"}\n", err.Error()))
			return
		}
	} else {
		// otherwise lookup for matches in our database
		target, err = targetUrl(userInfo.Username, userInfo.Servicename, userInfo.Key)
		if err != nil {
			log.Printf("error running key proxy %s: %v", userInfo.FullUrl, err)
			io.WriteString(rw, fmt.Sprintf("{\"err\":\"%s\"}\n", err.Error()))
			return
		}
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

		res := new(http.Response)
		rabbitKey := lookupRabbitKey(userInfo.Username, userInfo.Servicename, userInfo.Key)

		if rabbitKey != "" {
			log.Printf("proxy via rabbitmq to '%s'", outreq.Host)
			res, err = rabbitTransport(outreq, userInfo, rabbitKey)
			if err != nil {
				log.Printf("rabbit proxy %s", err.Error())
				io.WriteString(rw, fmt.Sprintf("{\"err\":\"%s\"}\n", err.Error()))
				return
			}
		} else {
			// add :80 if not available
			ok := hasPort(outreq.URL.Host)
			if !ok {
				outreq.URL.Host = addPort(outreq.URL.Host, "80")
			}

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
