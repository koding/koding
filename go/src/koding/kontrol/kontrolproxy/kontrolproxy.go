package main

import (
	"bytes"
	"crypto/tls"
	"fmt"
	"github.com/gorilla/sessions"
	"github.com/nranchev/go-libGeoIP"
	"html/template"
	"io"
	"koding/kontrol/kontrolhelper"
	"koding/kontrol/kontrolproxy/proxyconfig"
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
	log.SetPrefix(fmt.Sprintf("proxy [%5d] ", os.Getpid()))
}

type client struct {
	target     string
	registered time.Time
}

var templates = template.Must(template.ParseFiles(
	"go/templates/proxy/securepage.html",
	"go/templates/proxy/notfound.html",
	"go/templates/proxy/notactiveVM.html",
	"client/maintenance.html",
))

var proxyDB *proxyconfig.ProxyConfiguration
var geoIP *libgeo.GeoIP
var hostname = kontrolhelper.CustomHostname()
var store = sessions.NewCookieStore([]byte("kontrolproxy-secret-key"))
var clients = make(map[string]client)
var clientsLock sync.RWMutex

func main() {
	log.Printf("kontrol proxy started ")
	// open and read from DB
	var err error
	proxyDB, err = proxyconfig.Connect()
	if err != nil {
		log.Fatalf("proxyconfig mongodb connect: %s", err)
	}

	err = proxyDB.AddProxy(hostname)
	if err != nil {
		log.Println(err)
	}

	// load GeoIP db into memory
	dbFile := "GeoIP.dat"
	geoIP, err = libgeo.Load(dbFile)
	if err != nil {
		log.Printf("load GeoIP.dat: %s\n", err.Error())
	}

	reverseProxy := &ReverseProxy{}

	// HTTPS handling
	portssl := strconv.Itoa(config.Current.Kontrold.Proxy.PortSSL)
	sslips := strings.Split(config.Current.Kontrold.Proxy.SSLIPS, ",")
	for _, sslip := range sslips {
		go func(sslip string) {
			cert, err := tls.LoadX509KeyPair(sslip+"_cert.pem", sslip+"_key.pem")
			if nil != err {
				log.Printf("https mode is disabled. please add cert.pem and key.pem files. %s %s", err, sslip)
				return
			}

			addr := sslip + ":" + portssl
			laddr, err := net.ResolveTCPAddr("tcp", addr)
			if nil != err {
				log.Fatalln(err)
			}

			listener, err := net.ListenTCP("tcp", laddr)
			if nil != err {
				log.Fatalln(err)
			}

			sslListener := tls.NewListener(listener, &tls.Config{
				NextProtos:   []string{"http/1.1"},
				Certificates: []tls.Certificate{cert},
			})

			log.Printf("https mode is enabled. serving at :%s ...", portssl)
			http.Serve(sslListener, reverseProxy)

		}(sslip)
	}

	// HTTP handling
	port := strconv.Itoa(config.Current.Kontrold.Proxy.Port)
	log.Printf("normal mode is enabled. serving at :%s ...", port)
	laddr, err := net.ResolveTCPAddr("tcp", ":"+port) // don't change this!
	if nil != err {
		log.Fatalln(err)
	}

	listener, err := net.ListenTCP("tcp", laddr)
	if nil != err {
		log.Fatalln(err)
	}

	err = http.Serve(listener, reverseProxy)
	if err != nil {
		log.Println("normal mode is disabled", err)
	}
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
	// redirect http to https
	if req.TLS == nil && (req.Host == "koding.com" || req.Host == "www.koding.com") {
		http.Redirect(rw, req, "https://koding.com"+req.RequestURI, http.StatusMovedPermanently)
		return
	}

	// Display error when someone hits the main page
	if hostname == req.Host {
		io.WriteString(rw, "Hello kontrol proxy :)")
		return
	}

	outreq := new(http.Request)
	*outreq = *req // includes shallow copies of maps, but okay

	user, buf, err := populateUser(outreq)
	if err != nil {
		rw.WriteHeader(http.StatusNotFound)
		log.Printf("parsing incoming request from %s to %s: %s", outreq.RemoteAddr, outreq.Host, err.Error())
		if buf != nil { // if any pre rendered html is available, use that for error displaying
			p.copyResponse(rw, buf)
			return
		}

		buf, err := executeTemplate("notfound.html", outreq.Host)
		if err != nil {
			log.Println("error executing template", err.Error())
			return
		}
		p.copyResponse(rw, buf)
		return
	}

	fmt.Printf("proxy via db\t: %s --> %s\n", user.Domain.Domain, user.Target.String())
	if user.Redirect {
		// 302 redirect
		http.Redirect(rw, req, user.Target.String()+req.RequestURI, http.StatusFound)
		return
	}

	switch user.Domain.Proxy.Mode {
	case "maintenance":
		p.copyResponse(rw, buf)
		return
	case "redirect":
		http.Redirect(rw, req, user.Target.String(), http.StatusTemporaryRedirect)
		return
	}

	var target *url.URL
	switch user.LoadBalancer.Persistence {
	case "cookie":
		sessionName := fmt.Sprintf("kodingproxy-%s-%s", outreq.Host, user.IP)
		session, _ := store.Get(req, sessionName)

		session.Options = &sessions.Options{MaxAge: 20} //seconds
		targetURL, ok := session.Values["GOSESSIONID"]
		if ok {
			target, err = url.Parse(targetURL.(string))
			if err != nil {
				io.WriteString(rw, fmt.Sprintf("{\"err\":\"%s\"}\n", err.Error()))
				return
			}
		} else {
			session.Values["GOSESSIONID"] = target.String()
			session.Save(outreq, rw)
		}
	case "sourceAddress":
		if client, ok := getClient(user.IP); !ok {
			target, err = url.Parse(client.target)
			if err != nil {
				io.WriteString(rw, fmt.Sprintf("{\"err\":\"%s\"}\n", err.Error()))
				return
			}
		}
	default:
		// if not set don't use session affinity
		target = user.Target
	}

	_, err = validate(user)
	if err != nil {
		if err == ErrSecurePage {
			sessionName := fmt.Sprintf("kodingproxy-%s-%s", outreq.Host, user.IP)
			// We're ignoring the error resulted from decoding an existing
			// session: Get() always returns a session, even if empty.
			session, _ := store.Get(req, sessionName)

			// Timeout for secure page. After timeout secure page is showed
			// again to the user
			session.Options = &sessions.Options{MaxAge: 20} //seconds

			_, ok := session.Values["securePage"]
			if !ok {
				session.Values["securePage"] = time.Now().String()
				session.Save(req, rw)
				err := templates.ExecuteTemplate(rw, "securepage.html", user)
				if err != nil {
					http.Error(rw, err.Error(), http.StatusInternalServerError)
				}
				return
			}
		} else {
			log.Printf("error validating user: %s", err.Error())
			io.WriteString(rw, fmt.Sprintf("{\"err\":\"%s\"}\n", err.Error()))
			return
		}
	}

	// Smart handling incoming request path/query, example:
	// incoming : foo.com/dir
	// target	: bar.com/base
	// proxy to : bar.com/base/dir
	outreq.URL.Scheme = target.Scheme
	outreq.URL.Host = target.Host
	outreq.URL.Path = singleJoiningSlash(target.Path, outreq.URL.Path)

	// incoming : foo.com/name=arslan
	// target	: bar.com/q=example
	// proxy to : bar.com/q=example&name=arslan
	if target.RawQuery == "" || outreq.URL.RawQuery == "" {
		outreq.URL.RawQuery = target.RawQuery + outreq.URL.RawQuery
	} else {
		outreq.URL.RawQuery = target.RawQuery + "&" + outreq.URL.RawQuery
	}

	outreq.Proto = "HTTP/1.1"
	outreq.ProtoMajor = 1
	outreq.ProtoMinor = 1
	outreq.Close = false

	go func() {
		if _, ok := getClient(user.IP); !ok {
			go registerClient(user.IP, target.String())
			go logDomainRequests(outreq.Host)
			go logProxyStat(hostname, user.Country)
		}
	}()

	// if connection is of type websocket, hijacking is used instead of http proxy
	// https://groups.google.com/d/msg/golang-nuts/KBx9pDlvFOc/edt4iad96nwJ
	if isWebsocket(outreq) {
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

		errc := make(chan error, 2)
		cp := func(dst io.Writer, src io.Reader) {
			_, err := io.Copy(dst, src)
			errc <- err
		}
		go cp(rConn, conn)
		go cp(conn, rConn)
		<-errc
		return
	} else {
		transport := p.Transport
		if transport == nil {
			transport = http.DefaultTransport
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

		if !hasPort(outreq.URL.Host) {
			outreq.URL.Host = addPort(outreq.URL.Host, "80")
		}

		res, err = transport.RoundTrip(outreq)
		if err != nil {
			io.WriteString(rw, fmt.Sprint(err))
			return
		}
		defer res.Body.Close()

		copyHeader(rw.Header(), res.Header)
		rw.WriteHeader(res.StatusCode)
		p.copyResponse(rw, res.Body)
		return
	}

}

func (p *ReverseProxy) copyResponse(dst io.Writer, src io.Reader) {
	io.Copy(dst, src)
}

/*************************************************
*
*  unique IP handling and cleaner
*
*  - arslan
*************************************************/
func registerClient(ip, host string) {
	clientsLock.Lock()
	defer clientsLock.Unlock()
	clients[ip] = client{target: host, registered: time.Now()}
	if len(clients) == 1 {
		go cleaner()
	}
}

// Needed to avoid race condition between multiple go routines
func getClient(ip string) (client, bool) {
	clientsLock.RLock()
	defer clientsLock.RUnlock()
	c, ok := clients[ip]
	return c, ok
}

// The goroutine basically does this: as long as there are clients in the map, it
// finds the one it should be deleted next, sleeps until it's time to delete it
// (one hour - time since client registration) and deletes it.  If there are no
// clients, the goroutine exits and a new one is created the next time a user is
// registered. The time.Sleep goes toward zero, thus it will not lock the
// for iterator forever.
func cleaner() {
	clientsLock.RLock()
	for len(clients) > 0 {
		var nextTime time.Time
		var nextClient string
		for ip, c := range clients {
			if nextTime.IsZero() || c.registered.Before(nextTime) {
				nextTime = c.registered
				nextClient = ip
			}
		}
		clientsLock.RUnlock()
		// negative duration is no-op, means it will not panic
		time.Sleep(time.Hour - time.Now().Sub(nextTime))
		clientsLock.Lock()
		log.Println("deleting client from internal map", nextClient)
		delete(clients, nextClient)
		clientsLock.Unlock()
		clientsLock.RLock()
	}
	clientsLock.RUnlock()
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
	c, err := net.DialTimeout("tcp", host, time.Second*5)
	if err != nil {
		return err
	}
	c.Close()
	return nil
}

func executeTemplate(filename string, data interface{}) (io.Reader, error) {
	buf := new(bytes.Buffer)
	err := templates.ExecuteTemplate(buf, filename, data)
	if err != nil {
		return buf, err
	}

	return buf, nil
}
