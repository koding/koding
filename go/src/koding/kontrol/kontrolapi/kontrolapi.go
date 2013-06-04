package main

import (
	"github.com/gorilla/mux"
	"io"
	"koding/kontrol/kontroldaemon/clientconfig"
	"koding/kontrol/kontroldaemon/workerconfig"
	"koding/kontrol/kontrolproxy/proxyconfig"
	"koding/tools/config"
	"log"
	"net/http"
	"strconv"
)

var clientDB *clientconfig.ClientConfig
var kontrolConfig *workerconfig.WorkerConfig
var proxyDB *proxyconfig.ProxyConfiguration
var amqpWrapper *AmqpWrapper

func init() {
	log.SetPrefix("kontrol-api ")
}

func main() {
	amqpWrapper = setupAmqp()

	var err error
	kontrolConfig, err = workerconfig.Connect()
	if err != nil {
		log.Fatalf("wokerconfig mongodb connect: %s", err)
	}

	proxyDB, err = proxyconfig.Connect()
	if err != nil {
		log.Fatalf("proxyconfig mongodb connect: %s", err)
	}

	clientDB, err = clientconfig.Connect()
	if err != nil {
		log.Fatalf("proxyconfig mongodb connect: %s", err)
	}

	port := strconv.Itoa(config.Current.Kontrold.Api.Port)

	rout := mux.NewRouter()
	rout.HandleFunc("/", home).Methods("GET")

	// Deployment handlers
	rout.HandleFunc("/deployments", GetClients).Methods("GET")
	rout.HandleFunc("/deployments", CreateClient).Methods("POST")
	rout.HandleFunc("/deployments/{build}", GetClient).Methods("GET")

	// Worker handlers
	rout.HandleFunc("/workers", GetWorkers).Methods("GET")
	rout.HandleFunc("/workers/{uuid}", GetWorker).Methods("GET")
	rout.HandleFunc("/workers/{uuid}/{action}", UpdateWorker).Methods("PUT")
	rout.HandleFunc("/workers/{uuid}", DeleteWorker).Methods("DELETE")

	// Proxy handlers
	rout.HandleFunc("/proxies", GetProxies).Methods("GET")
	rout.HandleFunc("/proxies/{uuid}", CreateProxy).Methods("POST")
	rout.HandleFunc("/proxies/{uuid}", DeleteProxy).Methods("DELETE")

	// Proxy service handlers
	rout.HandleFunc("/proxies/{uuid}/services", GetProxyUsers).Methods("GET")
	rout.HandleFunc("/proxies/{uuid}/services/{username}", GetProxyServices).Methods("GET")
	rout.HandleFunc("/proxies/{uuid}/services/{username}", CreateProxyUser).Methods("POST")
	rout.HandleFunc("/proxies/{uuid}/services/{username}/{servicename}", GetKeyList).Methods("GET")
	rout.HandleFunc("/proxies/{uuid}/services/{username}/{servicename}", CreateProxyService).Methods("POST")
	rout.HandleFunc("/proxies/{uuid}/services/{username}/{servicename}", DeleteProxyService).Methods("DELETE")
	rout.HandleFunc("/proxies/{uuid}/services/{username}/{servicename}/{key}", GetKey).Methods("GET")
	rout.HandleFunc("/proxies/{uuid}/services/{username}/{servicename}/{key}", DeleteProxyServiceKey).Methods("DELETE")

	// Proxy domain handlers
	rout.HandleFunc("/proxies/{uuid}/domains", GetProxyDomains).Methods("GET")
	rout.HandleFunc("/proxies/{uuid}/domains/{domain}", GetProxyDomain).Methods("GET")
	rout.HandleFunc("/proxies/{uuid}/domains/{domain}", CreateProxyDomain).Methods("POST")
	rout.HandleFunc("/proxies/{uuid}/domains/{domain}", DeleteProxyDomain).Methods("DELETE")

	// Proxy rule handlers
	rout.HandleFunc("/proxies/{uuid}/rules", GetRulesUsers).Methods("GET")
	rout.HandleFunc("/proxies/{uuid}/rules/{username}", GetRulesServices).Methods("GET")
	rout.HandleFunc("/proxies/{uuid}/rules/{username}/{servicename}", GetRule).Methods("GET")
	rout.HandleFunc("/proxies/{uuid}/rules/{username}/{servicename}", CreateRule).Methods("POST")

	// Rollbar api
	rout.HandleFunc("/rollbar", rollbar).Methods("POST")

	log.Printf("kontrol api is started. serving at :%s ...", port)

	http.Handle("/", rout)
	err = http.ListenAndServe(":"+port, nil)
	if err != nil {
		log.Println(err)
	}
}

func home(writer http.ResponseWriter, request *http.Request) {

	io.WriteString(writer, "Hello world - kontrol api!\n")
}
