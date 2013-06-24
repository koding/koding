package main

import (
	"crypto/tls"
	"fmt"
	"github.com/gorilla/sessions"
	"github.com/nranchev/go-libGeoIP"
	"html/template"
	"io"
	"koding/kontrol/kontrolhelper"
	"koding/kontrol/kontrolproxy/proxyconfig"
	"koding/kontrol/kontrolproxy/resolver"
	"koding/kontrol/kontrolproxy/utils"
	"koding/tools/config"
	"log"
	"net"
	"net/http"
	"net/http/httputil"
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

type Proxy struct {
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
var proxyName = kontrolhelper.CustomHostname()
var store = sessions.NewCookieStore([]byte("kontrolproxy-secret-key"))
var clients = make(map[string]client)
var clientsLock sync.RWMutex
var deadline = time.Now().Add(time.Second * 5)

func main() {
	log.Printf("kontrol proxy started ")
	// open and read from DB
	var err error
	proxyDB, err = proxyconfig.Connect()
	if err != nil {
		log.Fatalf("proxyconfig mongodb connect: %s", err)
	}

	err = proxyDB.AddProxy(proxyName)
	if err != nil {
		log.Println(err)
	}

	// load GeoIP db into memory
	dbFile := "GeoIP.dat"
	geoIP, err = libgeo.Load(dbFile)
	if err != nil {
		log.Printf("load GeoIP.dat: %s\n", err.Error())
	}

	reverseProxy := &Proxy{}

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

func (p *Proxy) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.TLS == nil && (r.Host == "koding.com" || r.Host == "www.koding.com") {
		http.Redirect(w, r, "https://koding.com"+r.RequestURI, http.StatusMovedPermanently)
		return
	}

	// Display error when someone hits the main page
	if proxyName == r.Host {
		io.WriteString(w, "Hello kontrol proxy :)")
		return
	}

	if h := p.handler(r); h != nil {
		h.ServeHTTP(w, r)
		return
	}

	log.Println("couldn't find any handler")
	http.Error(w, "Not found.", http.StatusNotFound)
	return
}

// handler returns the appropriate Handler for the given Request,
// or nil if none found.
func (p *Proxy) handler(req *http.Request) http.Handler {
	// remove www from the hostname (i.e. www.foo.com -> foo.com)
	if strings.HasPrefix(req.Host, "www.") {
		req.Host = strings.TrimPrefix(req.Host, "www.")
	}

	userIP, userCountry := getIPandCountry(req.RemoteAddr)

	target, err := resolver.GetTarget(req.Host)
	if err != nil {
		if err == resolver.ErrGone {
			return templateHandler("notfound.html", req.Host, 410)
		}
		log.Println("resolver error", err)
		return templateHandler("notfound.html", req.Host, 404)
	}

	switch target.Mode {
	case "maintenance":
		return templateHandler("maintenance.html", nil, 200)
	case "redirect":
		return http.RedirectHandler(target.Url.String()+req.RequestURI, http.StatusFound)
	case "vm":
		err := utils.CheckServer(target.Url.Host)
		if err != nil {
			log.Printf("vm host %s is down: '%s'", req.Host, err)
			return templateHandler("notactiveVM.html", req.Host, 404)
		}
	}

	switch target.Persistence {
	case "cookie":
		// sessionName := fmt.Sprintf("kodingproxy-%s-%s", host, ip)
		// session, _ := store.Get(req, sessionName)
		// session.Options = &sessions.Options{MaxAge: 20} //seconds
		// targetURL, ok := session.Values["GOSESSIONID"]
		// if ok {
		// 	target, err = url.Parse(targetURL.(string))
		// 	if err != nil {
		// 		log.Println("could not parse targetUrl", targetURL.(string))
		// 		return nil, ErrNotFound
		// 	}
		// } else {
		// 	session.Values["GOSESSIONID"] = target.String()
		// 	session.Save(req, w)
		// }
	case "sourceAddress":
		if client, ok := getClient(userIP); !ok {
			target.Url, err = url.Parse(client.target)
			if err != nil {
				log.Println("could not parse client.target", client.target)
				return templateHandler("notfound.html", req.Host, 404)
			}
		}
	}

	_, err = validate(userIP, userCountry, req.Host)
	if err != nil {
		if err == ErrSecurePage {
			sessionName := fmt.Sprintf("kodingproxy-%s-%s", req.Host, userIP)
			session, _ := store.Get(req, sessionName)
			session.Options = &sessions.Options{MaxAge: 20} //seconds
			_, ok := session.Values["securePage"]
			if !ok {
				return sessionHandler("securePage", req.Host)
			}
		} else {
			log.Printf("error validating user: %s", err.Error())
			return templateHandler("notfound.html", req.Host, 404)
		}
	}

	go func() {
		if _, ok := getClient(userIP); !ok {
			go registerClient(userIP, target.Url.String())
			go logDomainRequests(req.Host)
			go logProxyStat(proxyName, userCountry)
		}
	}()

	fmt.Printf("--\nmode '%s'\t: %s %s\n", target.Mode, userIP, userCountry)
	fmt.Printf("proxy via db\t: %s --> %s\n", req.Host, target.Url.String())

	if isWebsocket(req) {
		return websocketHandler(target.Url.String())
	}

	return reverseProxyHandler(target.Url)
}

func reverseProxyHandler(target *url.URL) http.Handler {
	return &httputil.ReverseProxy{
		Director: func(req *http.Request) {
			if !utils.HasPort(target.Host) {
				req.URL.Host = utils.AddPort(target.Host, "80")
			} else {
				req.URL.Host = target.Host
			}
			req.URL.Scheme = target.Scheme
		},
	}
}

func sessionHandler(val, userIP string) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		sessionName := fmt.Sprintf("kodingproxy-%s-%s", r.Host, userIP)
		session, _ := store.Get(r, sessionName)
		session.Values[val] = time.Now().String()
		session.Save(r, w)
		err := templates.ExecuteTemplate(w, "securepage.html", r.Host)
		if err != nil {
			log.Println("template securepage could not be executed")
			return
		}
	})
}

func websocketHandler(target string) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		d, err := net.Dial("tcp", target)
		if err != nil {
			http.Error(w, "Error contacting backend server.", 500)
			log.Printf("Error dialing websocket backend %s: %v", target, err)
			return
		}
		hj, ok := w.(http.Hijacker)
		if !ok {
			http.Error(w, "Not a hijacker?", 500)
			return
		}
		nc, _, err := hj.Hijack()
		if err != nil {
			log.Printf("Hijack error: %v", err)
			return
		}
		defer nc.Close()
		defer d.Close()

		// write back the request of the client to the server.
		err = r.Write(d)
		if err != nil {
			log.Printf("Error copying request to target: %v", err)
			return
		}

		errc := make(chan error, 2)
		cp := func(dst io.Writer, src io.Reader) {
			_, err := io.Copy(dst, src)
			errc <- err
		}
		go cp(d, nc)
		go cp(nc, d)
		<-errc
	})
}

func templateHandler(path string, data interface{}, code int) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(code)
		err := templates.ExecuteTemplate(w, path, data)
		if err != nil {
			log.Printf("template %s could not be executed", path)
			return
		}
	})
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

// is the incoming request a part of websocket handshake?
func isWebsocket(req *http.Request) bool {
	if strings.ToLower(req.Header.Get("Upgrade")) != "websocket" ||
		!strings.Contains(strings.ToLower(req.Header.Get("Connection")), "upgrade") {
		return false
	}
	return true
}

func getIPandCountry(addr string) (string, string) {
	var ip, country string
	ip, _, err := net.SplitHostPort(addr)
	if err == nil {
		if geoIP != nil {
			loc := geoIP.GetLocationByIP(ip)
			if loc != nil {
				country = loc.CountryName
			}
		}
	}
	return ip, country
}

func logDomainRequests(domain string) {
	if domain == "" {
		return
	}

	err := proxyDB.AddDomainRequests(domain)
	if err != nil {
		fmt.Printf("could not add domain statistisitcs for %s\n", err.Error())
	}
}

func logProxyStat(name, country string) {
	err := proxyDB.AddProxyStat(name, country)
	if err != nil {
		fmt.Printf("could not add proxy statistisitcs for %s\n", err.Error())
	}
}

func logDomainDenied(domain, ip, country, reason string) {
	if domain == "" {
		return
	}

	err := proxyDB.AddDomainDenied(domain, ip, country, reason)
	if err != nil {
		fmt.Printf("could not add domain statistisitcs for %s\n", err.Error())
	}
}

func validate(ip, country, domain string) (bool, error) {
	// restrictionId, err := proxyDB.GetDomainRestrictionId(u.Domain.Id)
	// if err != nil {
	// 	return true, nil //don't block if we don't get a rule (pre-caution))
	// }

	restriction, err := proxyDB.GetRestrictionByDomain(domain)
	if err != nil {
		return true, nil //don't block if we don't get a rule (pre-caution))
	}

	// restriction, err := proxyDB.GetRestrictionByID(restrictionId)
	// if err != nil {
	// 	return true, nil //don't block if we don't get a rule (pre-caution))
	// }

	return validator(restriction, ip, country, domain).AddRules().Check()
}
