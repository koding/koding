package main

import (
	"flag"
	"fmt"
	"io"
	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"
	"koding/tools/config"
	"koding/tools/logger"
	"net"
	"net/http"
	"strconv"

	"github.com/gorilla/mux"
)

type ProxyPostMessage struct {
	Name          string
	Username      string
	Domain        string
	Persistence   string
	Mode          string
	Key           string
	RabbitKey     string
	Host          string
	HostnameAlias string
	FullUrl       string
	Hostdata      string
}

var flagProfile = flag.String("c", "", "Configuration profile from file")
var flagDebug = flag.Bool("d", false, "Debug mode")
var conf *config.Config
var log = logger.New("kontrolapi")

func main() {
	flag.Parse()
	if *flagProfile == "" {
		log.Fatal("Please define config file with -c")
	}

	rout := mux.NewRouter()
	rout.HandleFunc("/", home).Methods("GET")

	// Deployment handlers
	deployments := rout.PathPrefix("/deployments").Subrouter()
	deployments.HandleFunc("/", changeHandler(GetClients)).Methods("GET")
	deployments.HandleFunc("/", changeHandler(CreateClient)).Methods("POST")
	deployments.HandleFunc("/{build}", changeHandler(GetClient)).Methods("GET")
	deployments.HandleFunc("/{build}", changeHandler(DeleteClient)).Methods("DELETE")

	// Worker handlers
	workers := rout.PathPrefix("/workers").Subrouter()
	workers.HandleFunc("/", changeHandler(GetWorkers)).Methods("GET")
	workers.HandleFunc("/{uuid}", changeHandler(GetWorker)).Methods("GET")
	workers.HandleFunc("/url/{workername}", changeHandler(GetWorkerURL)).Methods("GET")

	// Proxy handlers
	proxies := rout.PathPrefix("/proxies").Subrouter()
	proxies.HandleFunc("/", changeHandler(GetProxies)).Methods("GET")
	proxies.HandleFunc("/{proxyname}", changeHandler(GetProxy)).Methods("GET")
	proxies.HandleFunc("/{proxyname}", changeHandler(CreateProxy)).Methods("POST")
	proxies.HandleFunc("/{proxyname}", changeHandler(DeleteProxy)).Methods("DELETE")

	// Service handlers
	services := rout.PathPrefix("/services").Subrouter()
	services.HandleFunc("/", changeHandler(GetUsers)).Methods("GET")
	services.HandleFunc("/{username}/", changeHandler(GetServices)).Methods("GET")
	services.HandleFunc("/{username}/", changeHandler(DeleteServices)).Methods("DELETE")
	services.HandleFunc("/{username}/{servicename}", changeHandler(GetService)).Methods("GET")
	services.HandleFunc("/{username}/{servicename}", changeHandler(DeleteService)).Methods("DELETE")
	services.HandleFunc("/{username}/{servicename}/{key}", changeHandler(GetKey)).Methods("GET")
	services.HandleFunc("/{username}/{servicename}/{key}", changeHandler(CreateKey)).Methods("POST")
	services.HandleFunc("/{username}/{servicename}/{key}", changeHandler(DeleteKey)).Methods("DELETE")

	// Domain handlers
	domains := rout.PathPrefix("/domains").Subrouter()
	domains.HandleFunc("/", changeHandler(GetDomains)).Methods("GET")
	domains.HandleFunc("/{domain}", changeHandler(GetDomain)).Methods("GET")
	domains.HandleFunc("/{domain}/resolv", changeHandler(ResolveDomain)).Methods("GET")
	domains.HandleFunc("/{domain}", changeHandler(CreateOrUpdateDomain)).Methods("POST", "PUT")
	domains.HandleFunc("/{domain}", changeHandler(DeleteDomain)).Methods("DELETE")

	// Filter handlers
	filters := rout.PathPrefix("/filters").Subrouter()
	filters.HandleFunc("/{id}", changeHandler(GetFilterByID)).Methods("GET")

	rest := rout.PathPrefix("/restrictions").Subrouter()
	rest.HandleFunc("/{domain}", changeHandler(GetRestrictionByDomain)).Methods("GET")

	conf = config.MustConfig(*flagProfile)

	var logLevel logger.Level
	if *flagDebug {
		logLevel = logger.DEBUG
	} else {
		logLevel = logger.GetLoggingLevelFromConfig("kontrolapi", *flagProfile)
	}
	log.SetLevel(logLevel)

	kontrolDB = mongodb.NewMongoDB(conf.MongoKontrol)
	modelhelper.Initialize(conf.Mongo)

	port := strconv.Itoa(conf.Kontrold.Api.Port)
	log.Info("kontrol api is started. serving at :%s ...", port)
	fmt.Printf("Kontrolapi started at port: %s\n", port)

	http.Handle("/", rout)
	err := http.ListenAndServe(":"+port, nil)
	if err != nil {
		log.Error(err.Error())
	}

}

func home(writer http.ResponseWriter, request *http.Request) {
	io.WriteString(writer, "Hello world - kontrol api!\n")
}

func changeHandler(fn func(w http.ResponseWriter, r *http.Request)) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		ip, _, err := net.SplitHostPort(r.RemoteAddr)
		if err != nil {
			ip = "non-ip"
		}

		log.Info("%s %s '%s'", r.Method, r.URL.String(), ip)
		w.Header().Set("Access-Control-Allow-Origin", "*")
		fn(w, r)
	}
}
