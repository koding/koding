package main

import (
	"encoding/json"
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
	"koding/tools/fastproxy"
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

type Proxy struct{}

type Client struct {
	Target     string    `json:"target"`
	Registered time.Time `json:"firstVist"`
	Reset      bool      `json:"-"`
	Mode       string    `json:"-"`
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
var clients = make(map[string]Client)
var clientsLock sync.RWMutex
var cacheTimeout = time.Second * 20

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

	// FTP handling
	log.Println("ftp mode is enabled. serving at :21...")
	go fastproxy.ListenFTP(&net.TCPAddr{IP: nil, Port: 21}, net.ParseIP(config.Current.Kontrold.Proxy.FTPIP), nil, func(req *fastproxy.FTPRequest) {
		userName := req.User
		vmName := req.User
		if userParts := strings.SplitN(userName, "@", 2); len(userParts) == 2 {
			userName = userParts[0]
			vmName = userParts[1]
		}

		vm, err := proxyDB.GetVM(vmName)
		if err != nil {
			req.Respond("530 No Koding VM with name '" + vmName + "' found.\r\n")
			return
		}

		if err = req.Relay(&net.TCPAddr{IP: vm.IP, Port: 21}, userName); err != nil {
			req.Respond("530 The Koding VM '" + vmName + "' did not respond.")
		}
	})

	// HTTPS handling
	portssl := strconv.Itoa(config.Current.Kontrold.Proxy.PortSSL)
	log.Printf("https mode is enabled. serving at :%s ...", portssl)
	sslips := strings.Split(config.Current.Kontrold.Proxy.SSLIPS, ",")
	for _, sslip := range sslips {
		go func(sslip string) {
			err := http.ListenAndServeTLS(sslip+":"+portssl, sslip+"_cert.pem", sslip+"_key.pem", reverseProxy)
			if err != nil {
				log.Println(err)
			}
		}(sslip)
	}

	// HTTP Handling for VM port forwardings
	log.Println("normal mode is enabled. serving ports between 1024-10000 for vms...")
	for i := 1024; i <= 10000; i++ {
		go func(i int) {
			port := strconv.Itoa(i)
			err := http.ListenAndServe(":"+port, reverseProxy)
			if err != nil {
				log.Println(err)
			}
		}(i)
	}

	// HTTP handling (port 80, main)
	port := strconv.Itoa(config.Current.Kontrold.Proxy.Port)
	log.Printf("normal mode is enabled. serving at :%s ...", port)
	err = http.ListenAndServe(":"+port, reverseProxy)
	if err != nil {
		log.Panic(err)
	}
}

func (p *Proxy) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.TLS == nil && (r.Host == "koding.com" || r.Host == "www.koding.com") {
		http.Redirect(w, r, "https://koding.com"+r.RequestURI, http.StatusMovedPermanently)
		return
	}

	// our main handler mux function goes and picks the correct handler
	if h := p.getHandler(r); h != nil {
		h.ServeHTTP(w, r)
		return
	}

	log.Println("couldn't find any handler")
	http.Error(w, "Not found.", http.StatusNotFound)
	return
}

// handler returns the appropriate Handler for the given Request,
// or nil if none found.
func (p *Proxy) getHandler(req *http.Request) http.Handler {
	// Execute endpoint handlers for in-memory lookup table
	if proxyName == req.Host {
		return endpointHandler(req.URL.Path)
	}

	// remove www from the hostname (i.e. www.foo.com -> foo.com)
	if strings.HasPrefix(req.Host, "www.") {
		req.Host = strings.TrimPrefix(req.Host, "www.")
	}

	userIP, userCountry := getIPandCountry(req.RemoteAddr)

	// in memory lookup
	target := &resolver.Target{}
	uniqueIP := userIP + "-" + req.Host
	var err error
	client, ok := getClient(uniqueIP)
	if !ok {
		target, err = resolver.GetTarget(req.Host)
		if err != nil {
			if err == resolver.ErrGone {
				return templateHandler("notfound.html", req.Host, 410)
			}
			log.Println("resolver error", err)
			return templateHandler("notfound.html", req.Host, 404)
		}

		go logDomainRequests(req.Host)
		go logProxyStat(proxyName, userCountry)
		go registerClient(uniqueIP, target.Url.String(), target.Mode)

		fmt.Printf("--\nmode '%s'\t: %s %s\n", target.Mode, userIP, userCountry)
		fmt.Printf("proxy via db\t: %s --> %s\n", req.Host, target.Url.String())
	} else {
		target.Url, err = url.Parse(client.Target)
		if err != nil {
			log.Println("could not parse client.target", client.Target)
			return templateHandler("notfound.html", req.Host, 404)
		}
		target.Mode = client.Mode
		fmt.Printf("--\nmode '%s'\t: %s %s\n", target.Mode, userIP, userCountry)
		fmt.Printf("proxy via inmem\t: %s --> %s\n", req.Host, target.Url.String())
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

	if isWebsocket(req) {
		return websocketHandler(target.Url.String())
	}

	return reverseProxyHandler(target.Url)
}

/* Handlers */

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

func endpointHandler(endpoint string) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if ok := strings.Contains(endpoint, "/reset/"); ok {
			if key := strings.TrimPrefix(r.URL.Path, "/reset/"); key == "1123581321" {
				log.Printf("clients are purged\n")
				resetClients()
				fmt.Fprintln(w, "clients are purged")
				return
			}
			log.Println("wrong key")
			w.WriteHeader(404)
			fmt.Fprintln(w, "wrong key")
			return
		}

		if ok := strings.Contains(endpoint, "/clients/"); ok {
			if key := strings.TrimPrefix(r.URL.Path, "/clients/"); key == "1123581321" {
				clients := getClients()
				data, err := json.MarshalIndent(clients, "", "  ")
				if err != nil {
					io.WriteString(w, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
					return
				}
				w.Write([]byte(data))
				return
			}
			log.Println("wrong key")
			w.WriteHeader(404)
			fmt.Fprintln(w, "wrong key")
			return
		}

		w.WriteHeader(404)
		err := templates.ExecuteTemplate(w, "notfound.html", r.Host)
		if err != nil {
			log.Printf("template notfound.html could not be executed")
			return
		}
		return
	})
}

/*************************************************
*
*  unique IP handling and cleaner
*
*  - arslan
*************************************************/

func resetClients() {
	clientsLock.Lock()
	defer clientsLock.Unlock()
	clients = make(map[string]Client)
}

func registerClient(ip, target, mode string) {
	clientsLock.Lock()
	defer clientsLock.Unlock()
	clients[ip] = Client{Target: target, Registered: time.Now(), Mode: mode}
	if len(clients) == 1 {
		go cleaner()
	}
}

func getClients() map[string]Client {
	clientsLock.RLock()
	defer clientsLock.RUnlock()
	return clients
}

// Needed to avoid race condition between multiple go routines
func getClient(ip string) (Client, bool) {
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
			if nextTime.IsZero() || c.Registered.Before(nextTime) {
				nextTime = c.Registered
				nextClient = ip
			}
		}
		clientsLock.RUnlock()
		// negative duration is no-op, means it will not panic
		time.Sleep(cacheTimeout - time.Now().Sub(nextTime))
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
