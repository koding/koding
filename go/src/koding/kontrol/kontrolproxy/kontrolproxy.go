package main

import (
	"fmt"
	"html/template"
	"io"
	"koding/db/mongodb/modelhelper"
	"koding/kontrol/kontrolproxy/resolver"
	"koding/kontrol/kontrolproxy/utils"
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
	"syscall"
	"time"

	"github.com/gorilla/handlers"
	"github.com/gorilla/sessions"
	"github.com/hoisie/redis"
	libgeo "github.com/nranchev/go-libGeoIP"
)

func init() {
	log.SetPrefix(fmt.Sprintf("proxy [%5d] ", os.Getpid()))
}

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
}

// used by redis counter
type interval struct {
	name     string
	duration int64
}

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
		"go/templates/proxy/notOnVM.html",
		"go/templates/proxy/quotaExceeded.html",
		"website/maintenance.html",
	))
)

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
	}

	p.mux.Handle("/", p)
	p.mux.Handle("/_resetcache_/", p.resetCacheHandler())

	p.setupLogging()
	p.startHTTPS() // non-blocking
	p.startHTTP()
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
				err := http.ListenAndServe(":"+port, p)
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
	if r.TLS == nil && (r.Host == "koding.com" || r.Host == "www.koding.com") {
		http.Redirect(w, r, "https://koding.com"+r.RequestURI, http.StatusMovedPermanently)
		return
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

	logs.Alert("couldn't find any handler")
	http.Error(w, "Not found.", http.StatusNotFound)
	return
}

// getHandler returns the appropriate Handler for the given Request,
// or nil if none found.
func (p *Proxy) getHandler(req *http.Request) http.Handler {
	userIP := getIP(req.RemoteAddr)

	// remove www from the hostname (i.e. www.foo.com -> foo.com)
	if strings.HasPrefix(req.Host, "www.") {
		req.Host = strings.TrimPrefix(req.Host, "www.")
	}

	target, err := resolver.GetTarget(req)
	if err != nil {
		logs.Info(fmt.Sprintf("resolver error of %s (%s): %s", req.Host, userIP, err))

		if err == resolver.ErrVMOff {
			return templateHandler("notOnVM.html", req.Host, 404)
		}

		return templateHandler("notfound.html", req.Host, 404)
	}

	defer func() {
		logs.Notice(fmt.Sprintf("mode '%s' [%s] via %s : %s --> %s\n",
			target.Proxy.Mode, userIP, target.FetchedSource, req.Host, target.URL.String()))
	}()

	if p.enableFirewall {
		_, err = validate(userIP, req.Host)
		if err == ErrSecurePage {
			return securePageHandler(userIP)
		}

		if err != nil {
			logs.Info(fmt.Sprintf("error validating user: %s", err.Error()))
			return templateHandler("quotaExceeded.html", req.Host, 509)
		}
	}

	switch target.Proxy.Mode {
	case resolver.ModeMaintenance:
		return templateHandler("maintenance.html", nil, 503)
	case resolver.ModeRedirect:
		return http.RedirectHandler(target.URL.String()+req.RequestURI, http.StatusFound)
	case resolver.ModeVM:
		err := utils.CheckServer(target.URL.Host)
		if err != nil {
			logs.Info(fmt.Sprintf("vm host %s is down: '%s'", req.Host, err))
			return templateHandler("notactiveVM.html", req.Host, 404)
		}
	case resolver.ModeInternal:
		// roundrobin to next target
		err := target.Resolve(req.Host)
		if err != nil {
			logs.Info(fmt.Sprintf("internal resolver error for %s (%s) - %s", req.Host, userIP, err))
			if err == resolver.ErrGone {
				return templateHandler("notfound.html", req.Host, 410)
			}

			if err == resolver.ErrNoHost {
				return templateHandler("maintenance.html", nil, 503)
			}

			return templateHandler("notfound.html", req.Host, 404)
		}
	}

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

// securePageHandler is used currently for the securepage feature of our
// validator/firewall. It is used to setup cookies to invalidate users visits.
func securePageHandler(userIP string) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		sessionName := fmt.Sprintf("kodingproxy-%s-%s", r.Host, userIP)
		session, _ := store.Get(r, sessionName)
		session.Options = &sessions.Options{MaxAge: 20} //seconds
		_, ok := session.Values["securePage"]
		if !ok {
			session.Values["securePage"] = time.Now().String()
		}
		session.Save(r, w)
		err := templates.ExecuteTemplate(w, "securepage.html", r.Host)
		if err != nil {
			logs.Err(fmt.Sprintf("template securepage could not be executed %s", err))
			http.Error(w, "error code - 2", 404)
			return
		}
	})
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
