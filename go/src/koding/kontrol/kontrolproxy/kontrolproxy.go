package main

import (
	"errors"
	"fmt"
	"html/template"
	"io"
	"koding/db/mongodb/modelhelper"
	"koding/kontrol/kontrolproxy/resolver"
	"koding/kontrol/kontrolproxy/utils"
	"koding/newkite/kite"
	"koding/newkite/protocol"
	"koding/tools/config"
	"log"
	"log/syslog"
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

	"github.com/gorilla/handlers"
	"github.com/gorilla/sessions"
	"github.com/hoisie/redis"
	libgeo "github.com/nranchev/go-libGeoIP"
)

func init() {
	log.SetPrefix(fmt.Sprintf("proxy [%5d] ", os.Getpid()))
}

const (
	vmCookieName = "kodingproxy-vm"
)

var (
	// used to extract the Country information via the IP
	geoIP *libgeo.GeoIP

	proxyName, _ = os.Hostname()

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

	// used for all our logs, currently it uses our local syslog server
	logs *syslog.Writer

	// used for various kinds of use cases like validator, 404 pages,
	// maintenance,...
	templates = template.Must(template.ParseFiles(
		"go/templates/proxy/securepage.html",
		"go/templates/proxy/notfound.html",
		"go/templates/proxy/notactiveVM.html",
		"go/templates/proxy/accessVM.html",
		"go/templates/proxy/quotaExceeded.html",
		"website/maintenance.html",
	))
)

// Proxy is implementing the http.Handler interface (via ServeHTTP). This is
// used as the main handler for our HTTP and HTTPS listeners.
type Proxy struct {
	// mux implies the http.Handler interface. Currently we use the default
	// http.ServeMux but it can be swapped with any other mux that satisfies the
	// http.Handler
	mux *http.ServeMux

	// enableFirewall is used to activate the internal validator that uses the
	// restrictions and filter collections to validate the incoming requests
	// accoding to ip, country, requests and so on..
	enableFirewall bool

	// logDestination specifies the destination of requests logs in the
	// Combined Log Format.
	logDestination io.Writer

	// cacheTransports is used to enable cache based roundtrips for certaing
	// request hosts, such as koding.com.
	cacheTransports map[string]http.RoundTripper

	// oskite references
	oskites   map[string]*kite.RemoteKite
	oskitesMu sync.Mutex
}

// used by redis counter
type interval struct {
	name     string
	duration int64
}

func main() {
	runtime.GOMAXPROCS(runtime.NumCPU())
	fmt.Printf("[%s] I'm using %d cpus for goroutines\n", time.Now().Format(time.Stamp), runtime.NumCPU())

	configureProxy()
	startProxy()
}

// configureProxy is used to setup all necessary configuration procedures, like
// mongodb connection, syslog enabling and so on..
func configureProxy() {
	var err error
	logs, err = syslog.New(syslog.LOG_DEBUG|syslog.LOG_USER, "KONTROL_PROXY")
	if err != nil {
		fmt.Println(err)
	}

	res := "kontrol proxy started"
	fmt.Printf("[%s] %s\n", time.Now().Format(time.Stamp), res)
	logs.Info(res)

	err = modelhelper.AddProxy(proxyName)
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
	p := &Proxy{
		mux:             http.NewServeMux(),
		enableFirewall:  false,
		cacheTransports: make(map[string]http.RoundTripper),
		oskites:         make(map[string]*kite.RemoteKite),
	}

	go p.findAndDialOskite()

	p.mux.Handle("/", p)
	p.mux.Handle("/_resetcache_/", p.resetCacheHandler())

	p.setupLogging()
	p.startHTTPS() // non-blocking
	p.startHTTP()
}

func newKite() *kite.Kite {
	kontrolPort := strconv.Itoa(config.Current.NewKontrol.Port)
	kontrolHost := config.Current.NewKontrol.Host
	kontrolURL := &url.URL{
		Scheme: "ws",
		Host:   fmt.Sprintf("%s:%s", kontrolHost, kontrolPort),
		Path:   "/dnode",
	}

	options := &kite.Options{
		Kitename:    "kdproxy",
		Environment: config.FileProfile,
		Region:      config.Region,
		Version:     "0.0.1",
		KontrolURL:  kontrolURL,
	}

	return kite.New(options)
}

func (p *Proxy) findAndDialOskite() {
	k := newKite()
	k.Start()

	query := protocol.KontrolQuery{
		Username:    "arslan", // TODO: going to be changed with koding
		Environment: config.FileProfile,
		Name:        "oskite",
		Version:     "0.0.1",
		Region:      config.Region,
	}

	onEvent := func(e *protocol.KiteEvent) {
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

			auth := kite.Authentication{
				Type: "token",
				Key:  e.Token,
			}

			// update oskite instance with new one
			oskite = k.NewRemoteKite(e.Kite, auth)
			err := oskite.Dial()
			if err != nil {
				log.Println(err)
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

	err := k.Kontrol.WatchKites(query, onEvent)
	if err != nil {
		log.Println(err)
	}
}

// startVM starts the vm and returns back the initalized IP
func (p *Proxy) startVM(hostnameAlias, hostkite string) (string, error) {
	fmt.Println("starting vm", hostnameAlias)
	p.oskitesMu.Lock()
	defer p.oskitesMu.Unlock()

	// hostkite is in form: "kite-os-sj|kontainer1_sj_koding_com"
	s := strings.Split(hostkite, "|")
	if len(s) < 2 {
		return "", fmt.Errorf("hostkite '%s' is malformed", hostkite)
	}

	serviceUniqueHostname := s[1] // gives kontainer1_sj_koding_com

	oskite, ok := p.oskites[serviceUniqueHostname]
	if !ok {
		return "", fmt.Errorf("oskite not available for %s", serviceUniqueHostname)
	}

	if oskite == nil {
		return "", errors.New("oskite not connected")
	}

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
		log.Println(err)
	}

	logPath := "/var/log/koding/kontrolproxyCLH.log"
	logFile, err := os.OpenFile(logPath, os.O_WRONLY|os.O_APPEND|os.O_CREATE, 0755)
	if err != nil {
		log.Printf("err: '%s'. \nusing stderr for log destination\n", err)
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
				log.Println("got an sighup")
				logFile.Close()
				newFile, err := os.Create(logPath)
				if err != nil {
					log.Println(err)
				} else {
					log.Println("creating new file")
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
	portssl := strconv.Itoa(config.Current.Kontrold.Proxy.PortSSL)
	logs.Info(fmt.Sprintf("https mode is enabled. serving at :%s ...", portssl))

	// don't change it to "*.pem", otherwise you'll get duplicate IP's
	pemFiles, _ := filepath.Glob("*_cert.pem")

	for _, file := range pemFiles {
		s := strings.Split(file, "_")
		if len(s) != 2 {
			fmt.Println("file is malformed", file)
			continue
		}

		ip := s[0] // contains the IP of the interface
		go func(ip string) {
			err := http.ListenAndServeTLS(ip+":"+portssl, ip+"_cert.pem", ip+"_key.pem", p.mux)
			if err != nil {
				logs.Alert(err.Error())
				fmt.Printf("[%s] %s\n", time.Now().Format(time.Stamp))
			}
		}(ip)
	}
}

// startHTTP is used to reverse proxy incoming requests on the port 80 and
// 1024-10000. The listener that listens on port 80 is not started on a
// seperate go routine, and thus is blocking.
func (p *Proxy) startHTTP() {
	// HTTP Handling for VM port forwardings
	logs.Info("normal mode is enabled. serving ports between 1024-10000 for vms...")

	if config.VMProxies {
		for i := 1024; i <= 10000; i++ {
			go func(i int) {
				port := strconv.Itoa(i)
				err := http.ListenAndServe("0.0.0.0:"+port, p)
				if err != nil {
					logs.Alert(err.Error())
					log.Println(err)
				}
			}(i)
		}
	}

	// HTTP handling (port 80, main)
	port := strconv.Itoa(config.Current.Kontrold.Proxy.Port)
	logs.Info(fmt.Sprintf("normal mode is enabled. serving at :%s ...", port))
	err := http.ListenAndServe(":"+port, p.mux)
	if err != nil {
		logs.Alert(err.Error())
		// don't use panic. It output full stack which we don't care.
		fmt.Printf("[%s] %s\n", time.Now().Format(time.Stamp), err.Error())
		os.Exit(1)
	}
}

// ServeHTTP is needed to satisfy the http.Handler interface.
func (p *Proxy) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// redirect http to https
	if r.TLS == nil && (r.Host == "koding.com" || r.Host == "www.koding.com") {
		http.Redirect(w, r, "https://koding.com"+r.RequestURI, http.StatusMovedPermanently)
		return
	}

	// remove www from the hostname (i.e. www.foo.com -> foo.com)
	if strings.HasPrefix(r.Host, "www.") {
		r.Host = strings.TrimPrefix(r.Host, "www.")
	}

	// our main handler mux function goes and picks the correct handler
	if h := p.getHandler(r); h != nil {
		if config.VMProxies {
			// don't wrap this around CLH logging handler, because it breaks websocket
			h.ServeHTTP(w, r)
		} else {
			loggingHandler := handlers.CombinedLoggingHandler(p.logDestination, h)
			loggingHandler.ServeHTTP(w, r)
		}

		return
	}

	// it should never reach here, if yes something badly happens and needs to be fixed
	logs.Alert("couldn't find any handler")
	http.Error(w, "Not found.", http.StatusNotFound)
	return
}

func (p *Proxy) checkAndStartVM(hostnameAlias, hostkite, port string) error {
	vmAddr, err := p.startVM(hostnameAlias, hostkite)
	if err != nil {
		return err
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
			fmt.Println("checking if vm is alive", hostnameAlias)
			err := utils.CheckServer(targetURL.Host)
			if err != nil {
				continue
			}
			return nil
		case <-timeout:
			return errors.New("timeout")
		}
	}
}

// getHandler returns the appropriate Handler for the given Request or nil if
// none found.
func (p *Proxy) getHandler(req *http.Request) http.Handler {
	userIP := getIP(req.RemoteAddr)

	target, err := resolver.GetTarget(req)
	if err != nil {
		logs.Info(fmt.Sprintf("GetTarget err: %s (%s) %s", req.Host, userIP, err))
		return templateHandler("notfound.html", req.Host, 404)
	}

	switch target.Proxy.Mode {
	case resolver.ModeMaintenance:
		return templateHandler("maintenance.html", nil, 503)
	case resolver.ModeRedirect:
		return http.RedirectHandler(target.URL.String()+req.RequestURI, http.StatusFound)
	case resolver.ModeVM:
		// TODO: the whole case needs a refactor at some time. Probably when
		// we decide to split koding-proxy and user-proxy into two seperate
		// kites.
		hostnameAlias := target.HostnameAlias[0]
		hostkite := target.Properties["hostkite"].(string)

		var port string
		if !utils.HasPort(req.Host) {
			port = "80"
		} else {
			_, port, err = net.SplitHostPort(req.Host)
			if err != nil {
				log.Println(err)
			}
		}

		if target.Err == resolver.ErrVMNotFound {
			logs.Info(fmt.Sprintf("ModeVM err: %s (%s) %s", req.Host, userIP, target.Err))
			return templateHandler("notfound.html", req.Host, 404)
		}

		if target.Err == resolver.ErrVMOff {
			fmt.Println("vm is off, going to start", hostnameAlias)
			err = p.checkAndStartVM(hostnameAlias, hostkite, port)
			if err != nil {
				logs.Info(fmt.Sprintf("vm %s timed out, it's still not up, this is not good!", hostnameAlias))
				return templateHandler("notactiveVM.html", req.Host, 404)
			}
		}

		fmt.Printf("checking if vm %s is alive.\n", hostnameAlias)
		err := utils.CheckServer(target.URL.Host)
		if err != nil {
			oerr, ok := err.(*net.OpError)
			if !ok {
				fmt.Println("vm can't be reached,", err)
				logs.Info(fmt.Sprintf("vm host %s is down: '%s'", req.Host, err))
				return templateHandler("notactiveVM.html", req.Host, 404)
			}

			if oerr.Err != syscall.EHOSTUNREACH {
				fmt.Println("vm can't be reached, net.OpError", oerr.Err)
				logs.Info(fmt.Sprintf("vm host %s is down: '%s'", req.Host, err))
				return templateHandler("notactiveVM.html", req.Host, 404)
			}

			// EHOSTUNREACH means "no route to host". This error is passed
			// when the VM is down, therefore turn it on.
			err = p.checkAndStartVM(hostnameAlias, hostkite, port)
			if err != nil {
				logs.Info(fmt.Sprintf("vm %s timed out, it's still not up, this is not good!", hostnameAlias))
				return templateHandler("notactiveVM.html", req.Host, 404)
			}
		}

		session, _ := store.Get(req, vmCookieName)
		_, ok := session.Values["visited"]
		if !ok {
			return context.ClearHandler(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				session.Values["visited"] = time.Now().String()
				session.Options = &sessions.Options{MaxAge: 3600} //seconds -> 1h
				session.Save(r, w)

				err := templates.ExecuteTemplate(w, "accessVM.html", r.Host)
				if err != nil {
					logs.Err(fmt.Sprintf("template notOnVM could not be executed %s", err))
					http.Error(w, "error code - 5", 404)
					return
				}
			}))
		}
	case resolver.ModeInternal:
		// roundrobin to next target
		target.Resolve(req.Host)
		if target.Err != nil {
			logs.Info(fmt.Sprintf("internal resolver error for %s (%s) - %s", req.Host, userIP, err))

			statusCode := 503
			if err == resolver.ErrGone {
				statusCode = 410 // Gone
			}

			return templateHandler("maintenance.html", nil, statusCode)
		}
	default:
		logs.Info(fmt.Sprintf("target not defined: %s (%s) %v", req.Host, userIP, target))
		return templateHandler("notfound.html", req.Host, 404)
	}

	logs.Notice(fmt.Sprintf("mode '%s' [%s] via %s : %s --> %s\n",
		target.Proxy.Mode, userIP, target.FetchedSource, req.Host, target.URL.String()))

	// do now reverse proxy stuff
	if isWebsocket(req) {
		return websocketHandler(target.URL.Host)
	}

	return reverseProxyHandler(nil, target.URL)
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

// websocketHandler is used to reverseProxy websocket connection. It hijacks
// the underlying http connection and copies forth and back the response
func websocketHandler(target string) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		hj, ok := w.(http.Hijacker)
		if !ok {
			http.Error(w, "not a hijacker?", 500)
			logs.Notice(fmt.Sprintf("websocket: [%s] not a hijacker?", target))
			return
		}

		nc, _, err := hj.Hijack()
		if err != nil {
			http.Error(w, "Error contacting backend server.", 500)
			logs.Notice(fmt.Sprintf("websocket: [%s] hijack error: %v", target, err))
			return
		}
		defer nc.Close()

		d, err := net.Dial("tcp", target)
		if err != nil {
			http.Error(w, "Error contacting backend server.", 500)
			logs.Notice(fmt.Sprintf("websocket: [%s] error dialing websocket backend: %v",
				target, err))
			return
		}
		defer d.Close()

		// write back the request of the client to the server.
		err = r.Write(d)
		if err != nil {
			http.Error(w, "Error contacting backend server.", 500)
			logs.Notice(fmt.Sprintf("websocket [%s] error copying request to target: %v", target, err))
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
			http.Error(w, "error code - 1", 404)
			return
		}
	})
}

// resetCacheHandler is reseting the cache transport for the given host.
func (p *Proxy) resetCacheHandler() http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Host != proxyName {
			logs.Debug(fmt.Sprintf("resetcache handler: got hostame %s, expected %s\n",
				r.Host, proxyName))
			logs.Debug("resetcache handler: fallback to reverse proxy handler")
			p.ServeHTTP(w, r)
			return
		}

		logs.Debug(fmt.Sprintf("resetCache is invoked %s - %s\n", r.Host, r.URL.String()))
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

func validate(ip, domain string) (bool, error) {
	restriction, err := modelhelper.GetRestrictionByDomain(domain)
	if err != nil {
		return true, nil //don't block if we don't get a rule (pre-caution))
	}

	// TODO: enable geoIP and gather country from there
	country := ""
	return validator(restriction, ip, country, domain).AddRules().Check()
}
