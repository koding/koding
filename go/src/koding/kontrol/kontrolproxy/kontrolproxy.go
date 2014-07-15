package main

import (
	"errors"
	"flag"
	"fmt"
	"html/template"
	"io"
	"koding/db/mongodb/modelhelper"
	"koding/kodingkite"
	"koding/kontrol/kontrolproxy/resolver"
	"koding/kontrol/kontrolproxy/utils"
	"koding/tools/config"
	"koding/tools/logger"
	"math/rand"
	"net"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"os/signal"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"sync"
	"syscall"
	"time"

	"github.com/gorilla/context"
	"github.com/gorilla/sessions"
	"github.com/hoisie/redis"
	"github.com/koding/kite"
	"github.com/koding/kite/protocol"
	"github.com/nranchev/go-libGeoIP"
)

const (
	CookieVM      = "kdproxy-vm"
	CookieUseHTTP = "kdproxy-usehttp"

	// Used as a value for CookieVM
	MagicCookieValue = "KEbPptvE7dGLM5YFtcfz"

	KONTROLPROXY_NAME = "kontrolproxy"
)

var (
	proxyName, _ = os.Hostname()

	// used for all our log
	log      = logger.New(KONTROLPROXY_NAME)
	logLevel logger.Level

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

	// used for various kinds of use cases like validator, 404 pages,
	// maintenance,...
	templates *template.Template

	// geoip instances
	geo *libgeo.GeoIP

	// readed config
	conf *config.Config

	// flag variables
	flagConfig       = flag.String("c", "", "Configuration profile from file")
	flagRegion       = flag.String("r", "", "Region")
	flagVMProxies    = flag.Bool("v", false, "Enable ports for VM users (1024-10000)")
	flagDebug        = flag.Bool("d", false, "Debug mode")
	flagTemplates    = flag.String("template", "files/templates", "Change template directory")
	flagCerts        = flag.String("certs", ".", "Change Certificate directory")
	flagGeoIpDatFile = flag.String("g", "/opt/kite/kontrolproxy/files/GeoIP.dat", "Change geoIP dat file path")
)

// Proxy is implementing the http.Handler interface (via ServeHTTP). This is
// used as the main handler for our HTTP and HTTPS listeners.
type Proxy struct {
	// mux implies the http.Handler interface. Currently we use the default
	// http.ServeMux but it can be swapped with any other mux that satisfies the
	// http.Handler
	mux *http.ServeMux

	// resolvers are needed to resolve for different cases
	resolvers map[string]Resolver

	// enableFirewall is used to activate the internal validator that uses the
	// restrictions and filter collections to validate the incoming requests
	// accoding to ip, country, requests and so on..
	enableFirewall bool

	// logDestination specifies the destination of requests log in the
	// Combined Log Format.
	logDestination io.Writer

	// cacheTransports is used to enable cache based roundtrips for certaing
	// request hosts, such as koding.com.
	cacheTransports map[string]http.RoundTripper

	// oskite references
	oskites   map[string]*kite.Client
	oskitesMu sync.Mutex
}

type Resolver func(*http.Request, *resolver.Target) http.Handler

// used by redis counter
type interval struct {
	name     string
	duration int64
}

func main() {
	flag.Parse()
	if *flagConfig == "" || *flagRegion == "" {
		log.Error("No flags defined. -c, -r and -v is not set. Aborting")
		os.Exit(1)
	}

	conf = config.MustConfig(*flagConfig)
	modelhelper.Initialize(conf.Mongo)

	if *flagDebug {
		logLevel = logger.DEBUG
	} else {
		logLevel = logger.GetLoggingLevelFromConfig(KONTROLPROXY_NAME, *flagConfig)
	}
	log.SetLevel(logLevel)

	templates = template.Must(template.ParseFiles(
		*flagTemplates+"/notfound.html",
		*flagTemplates+"/notactiveVM.html",
		*flagTemplates+"/securepage.html",
		*flagTemplates+"/quotaExceeded.html",
		*flagTemplates+"/maintenance.html",
	))

	var err error
	geo, err = libgeo.Load(*flagGeoIpDatFile)
	if err != nil {
		log.Warning("geoip db loading err: %s", err.Error())
	}

	log.Info("Kontrolproxy started.")
	log.Info("I'm using %d cpus for GOMACPROCS", runtime.NumCPU())
	runtime.GOMAXPROCS(runtime.NumCPU())

	p := &Proxy{
		mux:             http.NewServeMux(),
		enableFirewall:  true,
		cacheTransports: make(map[string]http.RoundTripper),
		oskites:         make(map[string]*kite.Client),
		resolvers:       make(map[string]Resolver),
	}

	p.resolvers[resolver.ModeMaintenance] = p.maintenance
	p.resolvers[resolver.ModeRedirect] = p.redirect
	p.resolvers[resolver.ModeVM] = p.vm
	p.resolvers[resolver.ModeInternal] = p.internal

	go p.runNewKite()

	p.mux.Handle("/", p)
	p.mux.Handle("/_resetcache_/", p.resetCacheHandler())

	p.setupLogging()
	p.startHTTPS() // non-blocking
	p.startHTTP()
}

func (p *Proxy) runNewKite() {
	k, err := kodingkite.New(conf, KONTROLPROXY_NAME, "0.0.1")
	if err != nil {
		panic(err)
	}

	k.Config.Region = *flagRegion
	go k.Run()
	<-k.Kite.ServerReadyNotify()

	// TODO: remove this later, this is needed in order to reinitiliaze the logger package
	log.SetLevel(logLevel)

	query := protocol.KontrolQuery{
		Username:    "koding-kites",
		Environment: *flagConfig,
		Name:        "oskite",
		Version:     "0.0.1",
		Region:      *flagRegion,
	}

	onEvent := func(e *kite.Event, err *kite.Error) {
		if err != nil {
			log.Error(err.Error())
			return
		}

		serviceUniqueHostname := strings.Replace(e.Kite.Hostname, ".", "_", -1)
		if serviceUniqueHostname == "" {
			k.Log.Warning("serviceUniqueHostname is empty for %s", e)
			return
		}

		switch e.Action {
		case protocol.Register:
			k.Log.Info("Oskite registered.")

			p.oskitesMu.Lock()
			defer p.oskitesMu.Unlock()

			oskite, ok := p.oskites[serviceUniqueHostname]
			if ok && oskite != nil {
				k.Log.Info("Oskite registered already, discarding ...")
				return
			}

			// update oskite instance with new one
			oskite = e.Client()
			err := oskite.Dial()
			if err != nil {
				log.Warning(err.Error())
			}

			p.oskites[serviceUniqueHostname] = oskite
		case protocol.Deregister:
			k.Log.Warning("Oskite deregistered.")
			p.oskitesMu.Lock()
			defer p.oskitesMu.Unlock()

			// make sure we don't send msg's to a dead service
			p.oskites[serviceUniqueHostname] = nil
			delete(p.oskites, serviceUniqueHostname)
		}
	}

	_, err = k.Kite.WatchKites(query, onEvent)
	if err != nil {
		log.Warning(err.Error())
	}
}

func (p *Proxy) randomOskite() (*kite.Client, bool) {
	p.oskitesMu.Lock()
	defer p.oskitesMu.Unlock()

	i := 0
	n := len(p.oskites)
	if n == 0 {
		return nil, false
	}

	exit := rand.Intn(n)
	for _, oskite := range p.oskites {
		if i == exit {
			return oskite, true
		}
		i++
	}

	return nil, false
}

// startVM starts the vm and returns back the iniprandtalized IP
func (p *Proxy) startVM(hostnameAlias, hostkite string) (string, error) {
	log.Debug("starting vm %s", hostnameAlias)
	var oskite *kite.Client
	var ok bool

	if hostkite == "" {
		log.Debug("hostkite %s is empty", hostkite)
		oskite, ok = p.randomOskite()
		if !ok {
			return "", fmt.Errorf("no random oskite available")
		}
	} else {
		// hostkite is in form: "kite-os-sj|kontainer1_sj_koding_com"
		log.Debug("splitting hostkite %s to get serviceUniqueName", hostkite)
		s := strings.Split(hostkite, "|")
		if len(s) < 2 {
			return "", fmt.Errorf("hostkite '%s' is malformed", hostkite)
		}

		serviceUniqueHostname := s[1] // gives kontainer1_sj_koding_com

		p.oskitesMu.Lock()
		oskite, ok = p.oskites[serviceUniqueHostname]
		if !ok {
			p.oskitesMu.Unlock()
			return "", fmt.Errorf("oskite not available for %s", serviceUniqueHostname)
		}
		p.oskitesMu.Unlock()
	}

	if oskite == nil {
		return "", errors.New("oskite not connected")
	}

	log.Debug("oskite [%s] tell startVM %s", oskite.Hostname, hostnameAlias)
	response, err := oskite.Tell("startVM", hostnameAlias)
	if err != nil {
		return "", err
	}

	return response.MustString(), nil
}

// setupLogging creates a new file for CLH logging and also sets a new signal
// listener for SIGHUP signals. It closes the old file and creates a new file
// for logging.
func (p *Proxy) setupLogging() {
	// no-op if exists
	err := os.MkdirAll("/var/log/koding/", 0755)
	if err != nil {
		log.Warning(err.Error())
	}

	logPath := "/var/log/koding/kontrolproxyCLH.log"
	logFile, err := os.OpenFile(logPath, os.O_WRONLY|os.O_APPEND|os.O_CREATE, 0755)
	if err != nil {
		log.Warning("err: '%s'. \nusing stderr for CLH log destination.", err)
		p.logDestination = os.Stderr
	} else {
		p.logDestination = logFile
	}

	go func() {
		signals := make(chan os.Signal, 1)
		signal.Notify(signals)
		for {
			signal := <-signals
			switch signal {
			case syscall.SIGHUP:
				log.Debug("got an sighup")
				logFile.Close()
				newFile, err := os.Create(logPath)
				if err != nil {
					log.Warning(err.Error())
				} else {
					log.Debug("creating new log file")
					p.logDestination = newFile
				}
			case syscall.SIGINT, syscall.SIGTERM:
				os.Exit(1)
			}
		}
	}()
}

// startHTTPS is used to reverse proxy incoming request to the port 443. It is
// creating a new listener for each file that ends with ".pem" and has the IP
// in his base filename, like 10.0.5.102_cert.pem.  Each listener is created in
// a seperate goroutine, thus the functions is nonblocking.
func (p *Proxy) startHTTPS() {
	// HTTPS handling, it is always 443, standart port for HTTPS protocol
	portssl := strconv.Itoa(conf.Kontrold.Proxy.PortSSL)
	log.Info("https mode is enabled. serving at :%s ...", portssl)

	// don't change it to "*.pem", otherwise you'll get duplicate IP's
	pemFiles, err := filepath.Glob(filepath.Join(*flagCerts, "*_cert.pem"))
	if err != nil {
		log.Critical(err.Error())
	}

	log.Info("using pem files %v", pemFiles)
	// hostname example: "koding_com_" or "kd_com_"
	hostname := strings.TrimSuffix(pemFiles[0], "cert.pem")
	if hostname == pemFiles[0] {
		log.Critical("file is malformed: %s", pemFiles[0])
	}

	go func() {
		err := http.ListenAndServeTLS(
			"0.0.0.0:"+portssl,  // addr
			hostname+"cert.pem", // cert file
			hostname+"key.pem",  // key file
			p.mux,               // http handler
		)
		if err != nil {
			log.Critical(err.Error())
		}
	}()
}

// startHTTP is used to reverse proxy incoming requests on the port 80 and
// 1024-10000. The listener that listens on port 80 is not started on a
// seperate go routine, and thus is blocking.
func (p *Proxy) startHTTP() {
	// HTTP Handling for VM port forwardings
	log.Info("normal mode is enabled. serving ports between 1024-10000 for vms...")

	if *flagVMProxies {
		for i := 1024; i <= 10000; i++ {
			go func(i int) {
				port := strconv.Itoa(i)
				err := http.ListenAndServe("0.0.0.0:"+port, p)
				if err != nil {
					log.Critical(err.Error())
				}
			}(i)
		}
	}

	// HTTP handling (port 80, main)
	port := strconv.Itoa(conf.Kontrold.Proxy.Port)
	log.Info("normal mode is enabled. serving at :%s ...", port)
	err := http.ListenAndServe(":"+port, p.mux)
	if err != nil {
		// don't use panic. It output full stack which we don't care.
		log.Critical("[%s] %s\n", time.Now().Format(time.Stamp), err.Error())
		os.Exit(1)
	}
}

// ServeHTTP is needed to satisfy the http.Handler interface.
func (p *Proxy) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// redirect https://www.koding.com to https://koding.com
	if r.TLS != nil && strings.HasPrefix(r.Host, "www.") {
		r.Host = strings.TrimPrefix(r.Host, "www.")
		http.Redirect(w, r, "https://"+r.Host+r.RequestURI, http.StatusMovedPermanently)
		return
	}

	// redirect http to https
	if r.TLS == nil && (r.Host == "koding.com" || r.Host == "latest.koding.com") {
		// check if this cookie is set, if yes do not redirect to https
		_, err := r.Cookie(CookieUseHTTP)
		if err != nil {
			http.Redirect(w, r, "https://"+r.Host+r.RequestURI, http.StatusMovedPermanently)
			return
		}
	}

	// our main handler mux function goes and picks the correct handler
	var h http.Handler
	h = p.getHandler(r)
	if h == nil {
		// it should never reach here, if yes something badly happens and needs to be fixed
		log.Critical("couldn't find any handler")
		http.Error(w, "Not found.", http.StatusNotFound)
		return
	}

	if p.enableFirewall {
		h = firewallHandler(h)
	}

	h.ServeHTTP(w, r)
}

// getHandler returns the appropriate Handler for the given Request or nil if
// none found.
func (p *Proxy) getHandler(req *http.Request) http.Handler {
	userIP := getIP(req.RemoteAddr)

	target, err := resolver.GetTarget(req)
	if err != nil {
		log.Error("getTarget err: %s (%s) %s", req.Host, userIP, err)
		return templateHandler("notfound.html", req.Host, 404)
	}

	resolver, ok := p.resolvers[target.Proxy.Mode]
	if !ok {
		log.Warning("target not defined: %s (%s) %v", req.Host, userIP, target)
		return templateHandler("notfound.html", req.Host, 404)
	}

	return resolver(req, target)
}

func (p *Proxy) maintenance(req *http.Request, target *resolver.Target) http.Handler {
	return templateHandler("maintenance.html", nil, 503)
}

func (p *Proxy) redirect(req *http.Request, target *resolver.Target) http.Handler {
	return http.RedirectHandler(target.URL.String()+req.RequestURI, http.StatusFound)
}

func (p *Proxy) internal(req *http.Request, target *resolver.Target) http.Handler {
	// remove www from the hostname (i.e. www.foo.com -> foo.com)
	if strings.HasPrefix(req.Host, "www.") {
		req.Host = strings.TrimPrefix(req.Host, "www.")
	}

	// switch to websocket immediately
	if isWebsocket(req) {
		return websocketHandler(target.URL.Host)
	}

	userIP := getIP(req.RemoteAddr)

	service := target.GetService()
	round, err := service.NextRoundRing()
	if err != nil {
		log.Info("internal NextRoundRing resolver error for %s (%s) - %s", req.Host, userIP, err)
		return templateHandler("maintenance.html", nil, 503)
	}

	resp, err := RoundTrip(req, round)
	if err != nil {
		log.Info("internal recursive resolver error for %s (%s) - %s", req.Host, userIP, err)
		return templateHandler("maintenance.html", nil, 503)
	}

	// TODO: salt them before we send it back.
	// resp.Header.Set("X-Koding-Proxy-Fronted", proxyName)
	// resp.Header.Set("X-Koding-Proxy-Backend", resp.Request.Host)

	log.Debug("internal - %s [%s] goes to %s -->  [build: %s server: %s]",
		target.FetchedSource, userIP, resp.Request.Host, service.Build, resp.Request.Host)

	return internalReverseProxy(resp)
}

func internalReverseProxy(res *http.Response) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer res.Body.Close()
		copyHeader(w.Header(), res.Header)
		w.WriteHeader(res.StatusCode)
		io.Copy(w, res.Body)
	})
}

func RoundTrip(req *http.Request, round *resolver.RoundRing) (*http.Response, error) {
	// means the healtChecker created a zero length ring. This is caused only
	// when all hosts are sick.
	if round.Ring == nil {
		return nil, errors.New("all servers are down")
	}

	outreq := new(http.Request)
	*outreq = *req // includes shallow copies of maps, but okay

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

	index := 0
	var res *http.Response
	for {
		if index == 2 {
			return nil, errors.New("to many servers are down in row")
		}

		// get backendServer and forward ring to the next value. the next value
		// will be used on the next request if this fails.
		err := round.Director(outreq)
		if err != nil {
			return nil, err
		}

		res, err = http.DefaultTransport.RoundTrip(outreq)
		if err != nil {
			log.Error("roundtrip error for server %s. picking up the next one. err: %s",
				outreq.URL.String(), err)

			index++
			continue
		}

		break
	}

	return res, nil
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

func copyHeader(dst, src http.Header) {
	for k, vv := range src {
		for _, v := range vv {
			dst.Add(k, v)
		}
	}
}

// reverseProxyHandler is the main handler that is used for copy the response
// back and forth to the request iniator. We use Go's main
// httputil.ReverseProxy but can easily switch to any custom handler in the
// future
func reverseProxyHandler(transport http.RoundTripper, target *url.URL) http.Handler {
	return &httputil.ReverseProxy{
		Transport: transport, // if nil, http.DefaultTransport is used.
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

type tempData struct {
	Host string
	Url  string
}

func (p *Proxy) vm(req *http.Request, target *resolver.Target) http.Handler {
	userIP := getIP(req.RemoteAddr)
	if len(target.HostnameAlias) == 0 {
		log.Error("Hostnamealias is empty! Target data: %v", target)
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			http.Error(w, "Bad data - error code 1", 502)
			return
		})
	}

	hostnameAlias := target.HostnameAlias[0]
	var port string
	var err error

	if !utils.HasPort(req.Host) {
		port = "80"
	} else {
		_, port, err = net.SplitHostPort(req.Host)
		if err != nil {
			log.Warning(err.Error())
		}
	}

	if target.Err == resolver.ErrVMNotFound {
		log.Warning("ModeVM err: %s (%s) %s", req.Host, userIP, target.Err)
		return templateHandler("notfound.html", req.Host, 404)
	}

	// these are set in resolver.go
	hostkite := target.Properties["hostkite"].(string)
	alwaysOn := target.Properties["alwaysOn"].(bool)
	disableSecurePage := target.Properties["disableSecurePage"].(bool)

	if target.Err == resolver.ErrVMOff {
		// log.Debug("vm %s is off, going to start", hostnameAlias)
		// target.URL might be nil, however if we start the VM, oskite sends a
		// new IP that we can use and update the current one. It will be nil
		// if an error is occured.
		target.URL, err = p.checkAndStartVM(hostnameAlias, hostkite, port)
		if err != nil {
			log.Warning("vm %s couldn't be started [ErrVMOff]: %s", hostnameAlias, err)
			return templateHandler("notactiveVM.html", req.Host, 404)
		}
	}

	log.Debug("checking if vm %s is alive.", hostnameAlias)

	if target.URL == nil {
		log.Error("Target URl is empty! Target data %v", target)
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			http.Error(w, "Bad data - error code 2", 502)
			return
		})
	}

	err = utils.CheckServer(target.URL.Host)
	if err != nil {
		oerr, ok := err.(*net.OpError)
		if !ok {
			log.Warning("vm host %s is down, non-net.OpError: '%s'", req.Host, err)
			return templateHandler("notactiveVM.html", req.Host, 404)
		}

		if oerr.Err == syscall.ECONNREFUSED {
			log.Debug("vm host %s is down net.OpError ECONNREFUSED: '%s'", req.Host, err)
			return templateHandler("notactiveVM.html", req.Host, 404)
		}

		if oerr.Err != syscall.EHOSTUNREACH {
			log.Error("vm host %s is down net.OpError %s: '%s'", req.Host, oerr.Err.Error(), err)
			return templateHandler("notactiveVM.html", req.Host, 404)
		}

		// EHOSTUNREACH means "no route to host". This error is passed
		// when the VM is down, therefore turn it on.
		target.URL, err = p.checkAndStartVM(hostnameAlias, hostkite, port)
		if err != nil {
			log.Warning("vm %s couldn't be started, err: %s", hostnameAlias, err)
			return templateHandler("notactiveVM.html", req.Host, 404)
		}
	}

	// switch to websocket before we even show the cookie
	if isWebsocket(req) {
		return websocketHandler(target.URL.Host)
	}

	// no cookies for alwaysOn or disabledSecurePage VMs
	if alwaysOn || disableSecurePage {
		log.Debug("secure page disabled for '%s'. alwaysOn: %v disableSecurePage: %v",
			hostnameAlias, alwaysOn, disableSecurePage)
		return reverseProxyHandler(nil, target.URL)
	}

	session, _ := store.Get(req, CookieVM)
	log.Debug("getting cookie for: %s", req.Host)
	cookieValue, ok := session.Values[req.Host]
	if !ok || cookieValue != MagicCookieValue {
		return securePageHandler(session)
	}

	log.Debug("mode '%s' [%s] via %s : %s --> %s",
		target.Proxy.Mode, userIP, target.FetchedSource, req.Host, target.URL.String())

	return reverseProxyHandler(nil, target.URL)
}

func (p *Proxy) checkAndStartVM(hostnameAlias, hostkite, port string) (*url.URL, error) {
	vmAddr, err := p.startVM(hostnameAlias, hostkite)
	if err != nil {
		return nil, err
	}

	if !utils.HasPort(vmAddr) {
		vmAddr = utils.AddPort(vmAddr, port)
	}

	targetURL, _ := url.Parse("http://" + vmAddr)

	// now check until the server is up
	ticker := time.NewTicker(500 * time.Millisecond).C
	timeout := time.After(15 * time.Second)

	for {
		select {
		case <-ticker:
			log.Debug("ticker is checking vm %s is alive", hostnameAlias)
			err := utils.CheckServer(targetURL.Host)
			if err != nil {
				continue
			}
			return targetURL, nil
		case <-timeout:
			return nil, errors.New("timeout")
		}
	}
}

// websocketHandler is used to reverseProxy websocket connection. It hijacks
// the underlying http connection and copies forth and back the response
func websocketHandler(target string) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		log.Debug("making websocket connection to %s", target)
		hj, ok := w.(http.Hijacker)
		if !ok {
			http.Error(w, "not a hijacker?", 500)
			log.Error("websocket: [%s] not a hijacker?", target)
			return
		}

		nc, _, err := hj.Hijack()
		if err != nil {
			http.Error(w, "Error contacting backend server.", 500)
			log.Error("websocket: [%s] hijack error: %v", target, err)
			return
		}
		defer nc.Close()

		d, err := net.Dial("tcp", target)
		if err != nil {
			http.Error(w, "Error contacting backend server.", 500)
			log.Error("websocket: [%s] error dialing websocket backend: %v", target, err)
			return
		}
		defer d.Close()

		// write back the request of the client to the server.
		err = r.Write(d)
		if err != nil {
			http.Error(w, "Error contacting backend server.", 500)
			log.Error("websocket [%s] error copying request to target: %v", target, err)
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

// securePageHandler is used to show a secure page to make the user click
func securePageHandler(session *sessions.Session) http.Handler {
	return context.ClearHandler(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		log.Debug("saving cookie for %s", r.Host)
		session.Values[r.Host] = MagicCookieValue
		session.Options = &sessions.Options{MaxAge: 3600} //seconds -> 1h
		session.Save(r, w)

		err := templates.ExecuteTemplate(w, "securepage.html", tempData{Host: r.Host, Url: r.Host + r.URL.String()})
		if err != nil {
			log.Warning("template notOnVM could not be executed %s", err)
			http.Error(w, "error code - 5", 404)
			return
		}
	}))
}

// templateHandler is used to show static complied html pages. The path
// variable is used to pick the correct template, data is used inside the
// template and code is set as the response code.
func templateHandler(path string, data interface{}, code int) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(code)
		err := templates.ExecuteTemplate(w, path, data)
		if err != nil {
			log.Error("template %s could not be executed: %s", path, err.Error())
			http.Error(w, "error code - 1", 404)
			return
		}
	})
}

// resetCacheHandler is reseting the cache transport for the given host.
func (p *Proxy) resetCacheHandler() http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Host != proxyName {
			log.Debug("resetcache handler: got hostame %s, expected %s", r.Host, proxyName)
			log.Debug("resetcache handler: fallback to reverse proxy handler")
			p.ServeHTTP(w, r)
			return
		}

		log.Debug("resetCache is invoked %s - %s", r.Host, r.URL.String())
		cacheHost := filepath.Base(r.URL.String())
		resolver.CleanCache(cacheHost)

		w.Write([]byte(fmt.Sprintf("cache is cleaned for %s", cacheHost)))
	})
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

func getIP(addr string) string {
	ip, _, err := net.SplitHostPort(addr)
	if err != nil {
		return ""
	}
	return ip
}

func getCountry(ip string) string {
	if geo == nil {
		return ""
	}

	if l := geo.GetLocationByIP(ip); l != nil {
		return l.CountryCode
	}

	return ""
}
