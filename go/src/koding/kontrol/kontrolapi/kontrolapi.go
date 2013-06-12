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

type ProxyPostMessage struct {
	Name          string
	Username      string
	Domain        string
	Mode          string
	CurrentIndex  string
	Key           string
	RabbitKey     string
	Host          string
	HostnameAlias string
	FullUrl       string
	Hostdata      string
}

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
	rout.HandleFunc("/proxies/{proxyname}", GetProxy).Methods("GET")
	rout.HandleFunc("/proxies/{proxyname}", CreateProxy).Methods("POST")
	rout.HandleFunc("/proxies/{proxyname}", DeleteProxy).Methods("DELETE")

	// Service handlers
	rout.HandleFunc("/services", GetUsers).Methods("GET")
	rout.HandleFunc("/services/{username}", GetServices).Methods("GET")
	rout.HandleFunc("/services/{username}/{servicename}", GetService).Methods("GET")
	rout.HandleFunc("/services/{username}/{servicename}", DeleteService).Methods("DELETE")
	rout.HandleFunc("/services/{username}/{servicename}/{key}", GetKey).Methods("GET")
	rout.HandleFunc("/services/{username}/{servicename}/{key}", CreateKey).Methods("POST")
	rout.HandleFunc("/services/{username}/{servicename}/{key}", DeleteKey).Methods("DELETE")

	// Domain handlers
	rout.HandleFunc("/domains", GetDomains).Methods("GET")
	rout.HandleFunc("/domains/{domain}", GetDomain).Methods("GET")
	rout.HandleFunc("/domains/{domain}", CreateOrUpdateDomain).Methods("POST", "PUT")
	rout.HandleFunc("/domains/{domain}", DeleteDomain).Methods("DELETE")

	// Rule handlers
	rout.HandleFunc("/rules", GetRules).Methods("GET")
	rout.HandleFunc("/rules/{domain}", GetRule).Methods("GET")
	rout.HandleFunc("/rules/{domain}", CreateRule).Methods("POST")
	rout.HandleFunc("/rules/{domain}", DeleteRule).Methods("DELETE")
	rout.HandleFunc("/rules/{domain}/ips", GetRuleIps).Methods("GET")
	rout.HandleFunc("/rules/{domain}/ips/{ip}", GetRuleIp).Methods("GET")
	rout.HandleFunc("/rules/{domain}/ips/{ip}", DeleteRuleIp).Methods("Delete")
	rout.HandleFunc("/rules/{domain}/countries", GetRuleCountries).Methods("GET")
	rout.HandleFunc("/rules/{domain}/countries/{country}", GetRuleCountry).Methods("GET")
	rout.HandleFunc("/rules/{domain}/countries/{country}", DeleteRuleCountry).Methods("DELETE")

	// Statistics handlers
	rout.HandleFunc("/stats/domains", GetDomainStats).Methods("GET")
	rout.HandleFunc("/stats/domains/{domain}", GetDomainStat).Methods("GET")
	rout.HandleFunc("/stats/domains/{domain}", DeleteDomainStat).Methods("DELETE")
	rout.HandleFunc("/stats/proxies", GetProxyStats).Methods("GET")
	rout.HandleFunc("/stats/proxies/{proxy}", GetProxyStat).Methods("GET")
	rout.HandleFunc("/stats/proxies/{proxy}", DeleteProxyStat).Methods("DELETE")

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
