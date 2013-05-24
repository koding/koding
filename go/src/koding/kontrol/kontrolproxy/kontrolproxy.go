package main

import (
	"fmt"
	"github.com/bradfitz/gomemcache/memcache"
	"github.com/nranchev/go-libGeoIP"
	"io"
	"koding/kontrol/kontrolhelper"
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

type RabbitChannel struct {
	ReplyTo string
	Receive chan []byte
}

var proxyDB *proxyconfig.ProxyConfiguration
var amqpStream *AmqpStream
var connections map[string]RabbitChannel
var geoIP *libgeo.GeoIP
var memCache *memcache.Client

var uuid = kontrolhelper.CustomHostname()

func main() {
	log.Printf("kontrol proxy started ")
	connections = make(map[string]RabbitChannel)

	// open and read from DB
	var err error
	proxyDB, err = proxyconfig.Connect()
	if err != nil {
		log.Fatalf("proxyconfig mongodb connect: %s", err)
	}

	err = proxyDB.AddProxy(uuid)
	if err != nil {
		log.Println(err)
	}

	memCache = memcache.New("127.0.0.1:11211") // used for vm lookup

	// load GeoIP db into memory
	dbFile := "GeoIP.dat"
	geoIP, err = libgeo.Load(dbFile)
	if err != nil {
		log.Printf("load GeoIP.dat: %s\n", err.Error())
	}

	// create amqpStream for rabbitmq proxyieng
	amqpStream = setupAmqp()

	reverseProxy := &ReverseProxy{}
	// http.HandleFunc("/", reverseProxy.ServeHTTP) this works for 1.1
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		reverseProxy.ServeHTTP(w, r)
	})

	port := strconv.Itoa(config.Current.Kontrold.Proxy.Port)
	portssl := strconv.Itoa(config.Current.Kontrold.Proxy.PortSSL)
	sslips := strings.Split(config.Current.Kontrold.Proxy.SSLIPS, ",")

	for _, sslip := range sslips {
		go func(sslip string) {
			err = http.ListenAndServeTLS(sslip+":"+portssl, sslip+"_cert.pem", sslip+"_key.pem", nil)
			if err != nil {
				log.Printf("https mode is disabled. please add cert.pem and key.pem files. %s %s", err, sslip)
			} else {
				log.Printf("https mode is enabled. serving at :%s ...", portssl)
			}
		}(sslip)
	}

	log.Printf("normal mode is enabled. serving at :%s ...", port)
	err = http.ListenAndServe(":"+port, nil)
	if err != nil {
		log.Println(err)
	}
}

/*************************************************
*
*  util functions
*
*  - arslan
*************************************************/
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

	user, err := populateUser(outreq)
	if err != nil {
		log.Printf("error populating user %s: %s", outreq.Host, err.Error())
		io.WriteString(rw, fmt.Sprintf("{\"err\":\"%s\"}\n", err.Error()))
		return
	}

	if user.Redirect {
		http.Redirect(rw, req, user.Target.String(), http.StatusTemporaryRedirect)
		return
	}
	target := user.Target
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
		rabbitKey := lookupRabbitKey(user.Username, user.Servicename, user.Key)

		if rabbitKey != "" {
			fmt.Println("connection via rabbitmq")
			res, err = rabbitTransport(outreq, user, rabbitKey)
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
