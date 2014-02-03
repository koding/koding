package main

import (
	"io"
	"koding/tools/config"
	"log"
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

func init() {
	log.SetPrefix("kontrol-api ")
}

func main() {
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
	services.HandleFunc("/{username}", changeHandler(GetServices)).Methods("GET")
	services.HandleFunc("/{username}", changeHandler(DeleteServices)).Methods("DELETE")
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

	// Restriction/Rule handlers
	restrictions := rout.PathPrefix("/restrictions").Subrouter()
	restrictions.HandleFunc("/", changeHandler(GetRestrictions)).Methods("GET")
	restrictions.HandleFunc("/{domain}", changeHandler(GetRestrictionByDomain)).Methods("GET")
	restrictions.HandleFunc("/{domain}", changeHandler(DeleteRestriction)).Methods("DELETE")
	restrictions.HandleFunc("/{domain}/{name}", changeHandler(CreateRuleByName)).Methods("POST", "PUT")
	restrictions.HandleFunc("/{domain}/{name}", changeHandler(DeleteRuleByName)).Methods("DELETE")

	// Filter handlers
	filters := rout.PathPrefix("/filters").Subrouter()
	filters.HandleFunc("/", changeHandler(GetFilters)).Methods("GET")
	filters.HandleFunc("/", changeHandler(CreateFilterByName)).Methods("POST")
	filters.HandleFunc("/{name}", changeHandler(GetFilterByName)).Methods("GET")
	filters.HandleFunc("/{name}", changeHandler(DeleteFilterByName)).Methods("DELETE")

	// Statistics handlers
	stats := rout.PathPrefix("/stats").Subrouter()
	stats.HandleFunc("/domains", changeHandler(GetDomainStats)).Methods("GET")
	stats.HandleFunc("/domains/{domain}", changeHandler(GetDomainStat)).Methods("GET")
	stats.HandleFunc("/domains/{domain}", changeHandler(DeleteDomainStat)).Methods("DELETE")
	stats.HandleFunc("/proxies", changeHandler(GetProxyStats)).Methods("GET")
	stats.HandleFunc("/proxies/{proxy}", changeHandler(GetProxyStat)).Methods("GET")
	stats.HandleFunc("/proxies/{proxy}", changeHandler(DeleteProxyStat)).Methods("DELETE")

	port := strconv.Itoa(config.Current.Kontrold.Api.Port)
	log.Printf("kontrol api is started. serving at :%s ...", port)

	http.Handle("/", rout)
	log.Println(http.ListenAndServe(":"+port, nil))
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

		log.Printf("%s %s '%s'\n", r.Method, r.URL.String(), ip)
		w.Header().Set("Access-Control-Allow-Origin", "*")
		fn(w, r)
	}
}
