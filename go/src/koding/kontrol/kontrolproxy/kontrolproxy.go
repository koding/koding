// Kontrolproxy

package main

import (
	"fmt"
	"github.com/gorilla/sessions"
	"github.com/hoisie/redis"
	libgeo "github.com/nranchev/go-libGeoIP"
	"html/template"
	"io"
	"koding/kontrol/kontrolhelper"
	"koding/kontrol/kontrolproxy/proxyconfig"
	"koding/kontrol/kontrolproxy/resolver"
	"koding/kontrol/kontrolproxy/utils"
	"koding/tools/config"
	"koding/tools/fastproxy"
	"log"
	"log/syslog"
	"net"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"runtime"
	"strconv"
	"strings"
	"sync"
	"time"
)

func init() {
	log.SetPrefix(fmt.Sprintf("proxy [%5d] ", os.Getpid()))
}

// Proxy is implementing the http.Handler interface (via ServeHTTP). This is
// used as the main handler for our HTTP and HTTPS listeners.
type Proxy struct {
	// EnableFirewall is used to activate the internal validator that uses the
	// restrictions and filter collections to validate the incoming requests
	// accoding to ip, country, requests and so on..
	EnableFirewall bool
}

// Client is used to register incoming request with an 1 hour cache. After that
// it get removed. This is used to gather unique (in our case one IP per one
// hour) statical information.
type Client struct {
	Target     string    `json:"target"`
	Registered time.Time `json:"firstVist"`
}

// used by redis counter
type interval struct {
	name     string
	duration int64
}

var (
	// mongoDB connection wrapper
	proxyDB *proxyconfig.ProxyConfiguration

	// used to extract the Country information via the IP
	geoIP *libgeo.GeoIP

	// A wrapper around os.Hostname()),
	proxyName = kontrolhelper.CustomHostname()

	// redis client, connects once
	redisClient = redis.Client{
		Addr: "127.0.0.1:6379", // for future reference
	}

	// used for request limiter, counting every hit
	redisIntervals = []interval{
		interval{"second", 1},
		interval{"minute", 60},
		interval{"hour", 3600},
		interval{"day", 86400},
	}

	// cookie handling is used for features like securePage
	store = sessions.NewCookieStore([]byte("kontrolproxy-secret-key"))

	// clients and clientsLock are used together with the Client struct
	clients     = make(map[string]Client)
	clientsLock sync.RWMutex

	// used for all our logs, currently it uses our local syslog server
	logs *syslog.Writer

	// used for various kinds of use cases like validator, 404 pages,
	// maintenance,...
	templates = template.Must(template.ParseFiles(
		"go/templates/proxy/securepage.html",
		"go/templates/proxy/notfound.html",
		"go/templates/proxy/notactiveVM.html",
		"go/templates/proxy/quotaExceeded.html",
		"client/maintenance.html",
	))
)

func main() {
	runtime.GOMAXPROCS(runtime.NumCPU())
	log.Printf("I'm using %d cpus for goroutines\n", runtime.NumCPU())

	configureProxy()
	startProxy()
}

// configureProxy is used to setup all necessary configuration procedures, like
// mongodb connection, syslog enabling and so on..
func configureProxy() {
	var err error
	logs, err = syslog.New(syslog.LOG_DEBUG|syslog.LOG_USER, "KONTROL_PROXY")
	if err != nil {
		log.Println(err)
	}

	res := "kontrol proxy started"
	log.Println(res)
	logs.Info(res)

	proxyDB, err = proxyconfig.Connect()
	if err != nil {
		res := fmt.Sprintf("proxyconfig mongodb connect: %s", err)
		logs.Alert(res)
		log.Fatalln(res)
	}

	err = proxyDB.AddProxy(proxyName)
	if err != nil {
		logs.Warning(err.Error())
	}

	// load GeoIP db into memory
	dbFile := "GeoIP.dat"
	geoIP, err = libgeo.Load(dbFile)
	if err != nil {
		res := fmt.Sprintf("load GeoIP.dat: %s\n", err.Error())
		logs.Warning(res)
	}
}

// startProxy is used to fire off all our ftp, https and http proxies
func startProxy() {
	reverseProxy := &Proxy{
		EnableFirewall: true,
	}

	startFTP()
	startHTTPS(reverseProxy)
	startHTTP(reverseProxy)
}

// startFTP is used to reverse proxy FTP connections on port 21
func startFTP() {
	logs.Info("ftp mode is enabled. serving at :21...")
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
}

// startHTTPS is used to reverse proxy incoming request to the port 443 but for
// the IP's defined in the Kontrold.Proxy.SSLIPS string. Each  IP is created in
// a seperate goroutine, thus the functions is nonblocking.
func startHTTPS(reverseProxy *Proxy) {
	// HTTPS handling
	portssl := strconv.Itoa(config.Current.Kontrold.Proxy.PortSSL)
	logs.Info(fmt.Sprintf("https mode is enabled. serving at :%s ...", portssl))
	sslips := strings.Split(config.Current.Kontrold.Proxy.SSLIPS, ",")
	for _, sslip := range sslips {
		go func(sslip string) {
			err := http.ListenAndServeTLS(sslip+":"+portssl, sslip+"_cert.pem", sslip+"_key.pem", reverseProxy)
			if err != nil {
				logs.Alert(err.Error())
				log.Println(err)
			}
		}(sslip)
	}
}

// startHTTP is used to reverse proxy incoming requests on the port 80 and
// 1024-10000. The listener that listens on port 80 is not started on a
// seperate go routine, and thus is blocking.
func startHTTP(reverseProxy *Proxy) {
	// HTTP Handling for VM port forwardings
	logs.Info("normal mode is enabled. serving ports between 1024-10000 for vms...")
	for i := 1024; i <= 10000; i++ {
		go func(i int) {
			port := strconv.Itoa(i)
			err := http.ListenAndServe(":"+port, reverseProxy)
			if err != nil {
				logs.Alert(err.Error())
				log.Println(err)
			}
		}(i)
	}

	// HTTP handling (port 80, main)
	port := strconv.Itoa(config.Current.Kontrold.Proxy.Port)
	logs.Info(fmt.Sprintf("normal mode is enabled. serving at :%s ...", port))
	err := http.ListenAndServe(":"+port, reverseProxy)
	if err != nil {
		logs.Alert(err.Error())
		log.Panic(err)
	}
}

// ServeHTTP is needed to satisfy the http.Handler interface.
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

	logs.Alert("couldn't find any handler")
	http.Error(w, "Not found.", http.StatusNotFound)
	return
}

// getHandler returns the appropriate Handler for the given Request,
// or nil if none found.
func (p *Proxy) getHandler(req *http.Request) http.Handler {
	// remove www from the hostname (i.e. www.foo.com -> foo.com)
	if strings.HasPrefix(req.Host, "www.") {
		req.Host = strings.TrimPrefix(req.Host, "www.")
	}

	go hitCounter(req.Host)

	userIP, userCountry := getIPandCountry(req.RemoteAddr)
	target, source, err := resolver.GetMemTarget(req.Host)
	if err != nil {
		if err == resolver.ErrGone {
			return templateHandler("notfound.html", req.Host, 410)
		}
		logs.Info(fmt.Sprintf("resolver error %s", err))
		return templateHandler("notfound.html", req.Host, 404)
	}

	logs.Debug(fmt.Sprintf("mode '%s' [%s,%s] via %s : %s --> %s\n", target.Mode, userIP, userCountry, source, req.Host, target.Url.String()))

	if p.EnableFirewall {
		_, err = validate(userIP, userCountry, req.Host)
		if err != nil {
			if err == ErrSecurePage {
				sessionName := fmt.Sprintf("kodingproxy-%s-%s", req.Host, userIP)
				session, _ := store.Get(req, sessionName)
				session.Options = &sessions.Options{MaxAge: 20} //seconds
				_, ok := session.Values["securePage"]
				if !ok {
					return sessionHandler("securePage", userIP)
				}
			} else {
				logs.Info(fmt.Sprintf("error validating user: %s", err.Error()))
				return templateHandler("quotaExceeded.html", req.Host, 509)
			}
		}
	}

	if _, ok := getClient(userIP); !ok {
		go logDomainRequests(req.Host)
		go logProxyStat(proxyName, userCountry)
		go registerClient(userIP, target.Url.String())
	}

	switch target.Mode {
	case "maintenance":
		return templateHandler("maintenance.html", nil, 200)
	case "redirect":
		return http.RedirectHandler(target.Url.String()+req.RequestURI, http.StatusFound)
	case "vm":
		err := utils.CheckServer(target.Url.Host)
		if err != nil {
			logs.Info(fmt.Sprintf("vm host %s is down: '%s'", req.Host, err))
			return templateHandler("notactiveVM.html", req.Host, 404)
		}
	}

	if isWebsocket(req) {
		return websocketHandler(target.Url.Host)
	}

	return reverseProxyHandler(target.Url)
}

// reverseProxyHandler is the main handler that is used for copy the response
// back and forth to the request iniator. We use Go's main
// httputil.ReverseProxy but can easily switch to any custom handler in the
// future
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

// sessionHandler is used currently for the securepage feature of our
// validator/firewall. It is used to setup cookies to invalidate users visits.
func sessionHandler(val, userIP string) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		sessionName := fmt.Sprintf("kodingproxy-%s-%s", r.Host, userIP)
		session, _ := store.Get(r, sessionName)
		session.Values[val] = time.Now().String()
		session.Save(r, w)
		err := templates.ExecuteTemplate(w, "securepage.html", r.Host)
		if err != nil {
			logs.Err(fmt.Sprintf("template securepage could not be executed %s", err))
			return
		}
	})
}

// websocketHandler is used to reverseProxy websocket connection. It hijacks
// the underlying http connection and copies forth and back the response
func websocketHandler(target string) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		d, err := net.Dial("tcp", target)
		if err != nil {
			http.Error(w, "Error contacting backend server.", 500)
			logs.Notice(fmt.Sprintf("error dialing websocket backend %s: %v", target, err))
			return
		}
		hj, ok := w.(http.Hijacker)
		if !ok {
			http.Error(w, "not a hijacker?", 500)
			return
		}
		nc, _, err := hj.Hijack()
		if err != nil {
			logs.Notice(fmt.Sprintf("hijack error: %v", err))
			return
		}
		defer nc.Close()
		defer d.Close()

		// write back the request of the client to the server.
		err = r.Write(d)
		if err != nil {
			logs.Notice(fmt.Sprintf("error copying request to target: %v", err))
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

// templateHandler is used to show static complied html pages. The path
// variable is used to pick the correct template, data is used inside the
// template and code is set as the response code.
func templateHandler(path string, data interface{}, code int) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(code)
		err := templates.ExecuteTemplate(w, path, data)
		if err != nil {
			logs.Warning(fmt.Sprintf("template %s could not be executed", path))
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

func resetClients() {
	clientsLock.Lock()
	defer clientsLock.Unlock()
	clients = make(map[string]Client)
}

func registerClient(ip, target string) {
	clientsLock.Lock()
	defer clientsLock.Unlock()
	clients[ip] = Client{Target: target, Registered: time.Now()}
	if len(clients) == 1 {
		go cleaner()
	}
}

func getClients() map[string]Client {
	clientsLock.RLock()
	defer clientsLock.RUnlock()
	return clients
}

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
		time.Sleep(time.Hour - time.Now().Sub(nextTime))
		clientsLock.Lock()
		logs.Info(fmt.Sprintf("deleting client from internal map", nextClient))
		delete(clients, nextClient)
		clientsLock.Unlock()
		clientsLock.RLock()
	}
	clientsLock.RUnlock()
}

// isWebsocket checks wether the incoming request is a part of websocket
// handshake
func isWebsocket(req *http.Request) bool {
	if strings.ToLower(req.Header.Get("Upgrade")) != "websocket" ||
		!strings.Contains(strings.ToLower(req.Header.Get("Connection")), "upgrade") {
		return false
	}
	return true
}

func getIPandCountry(addr string) (ip, country string) {
	ip, _, err := net.SplitHostPort(addr)
	if err != nil {
		return
	}

	// return when geoIp is not initialized?
	if geoIP == nil {
		return
	}

	// return when location was not found
	loc := geoIP.GetLocationByIP(ip)
	if loc == nil {
		return
	}

	country = loc.CountryName
	return
}

func logDomainRequests(domain string) {
	if domain == "" {
		return
	}

	err := proxyDB.AddDomainRequests(domain)
	if err != nil {
		logs.Warning(fmt.Sprintf("could not add domain statistisitcs for %s\n", err.Error()))
	}
}

func logProxyStat(name, country string) {
	err := proxyDB.AddProxyStat(name, country)
	if err != nil {
		logs.Warning(fmt.Sprintf("could not add proxy statistisitcs for %s\n", err.Error()))
	}
}

func validate(ip, country, domain string) (bool, error) {
	restriction, err := proxyDB.GetRestrictionByDomain(domain)
	if err != nil {
		return true, nil //don't block if we don't get a rule (pre-caution))
	}

	return validator(restriction, ip, country, domain).AddRules().Check()
}

// increase request counters for the incoming host
func hitCounter(host string) {
	for _, item := range redisIntervals {
		res, err := redisClient.Incr(host + ":" + item.name)
		if err != nil {
			logs.Warning(err.Error())
			continue
		}

		if int(res) == 1 {
			_, err := redisClient.Expire(host+":"+item.name, item.duration)
			if err != nil {
				logs.Warning(err.Error())
			}
		}
	}
}
